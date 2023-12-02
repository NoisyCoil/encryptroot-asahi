# NAME

encryptroot.asahi - encrypt the root partition of your Fedora Asahi
installation

# SYNOPSIS

**encryptroot.asahi** \[ **--boot-label** *boot\_label* \] \[ **-d**
*device\_name* \] \[ **--root-label** *root\_label* \] \[ **-v** \]
*rootdisk* *bootdisk*

**encryptroot.asahi** \[ **-h** \]

# DESCRIPTION

**encryptroot.asahi** is an interactive script that allows you to
encrypt the root partition of your Fedora Asahi installation without
deleting its contents. It is meant to be executed from an external USB
drive hosting an Asahi OS, or from a regular Linux virtual machine
running on macOS. It may horribly screw up your system if executed from
your Fedora Asahi installation (this scenario is completely untested,
please, just don't).

Unless you've just installed Fedora Asahi, backup your system before
running **encryptroot.asahi**. As the user of this script, you are
expected to be able to manually recover from failure. If you are not
able to do so, please don't run **encryptroot.asahi**.

The **OPERATIONS** section of this manpage details the steps involved in
the encryption process. The **RECOVERY** section details its recovery
logic. These sections can be of help if the process fails: they contain
useful information and debug steps.

By running **encryptroot.asahi** you agree not to hold its author
accountable for any loss of data or any other form of damage resulting
from its use.

# ARGUMENTS

*rootdisk*  
The root disk (partition block device) to be encrypted.

*bootdisk*  
The boot disk (partition block device) which will boot the encrypted
root partition.

# OPTIONS

**--boot-label** *boot\_label*  
The expected boot partition label. See also '**OPERATIONS - 0.
Preliminary checks**'. Default if not provided: **BOOT**.

**-d** *device\_name*, **--device-name** *device\_name*  
The name of the mapped (decrypted) root device to be used on Fedora
Asahi, as in **/dev/mapper/device\_name**. Stored in **/etc/crypttab**.
Default if not provided: **fedora-root**.

**--ext4**  
Expect the root partition to be formatted with the **ext4** filesystem.
See also '**OPERATIONS - 0. Preliminary checks**'. Implies the
**--no-subvols** option.

**-h**, **--help**  
Print a synopsis and exit.

**--no-subvols**  
Expect no subvolumes in the root partition filesystem. See also
'**OPERATIONS - 0. Preliminary checks**'. Takes effect only for
btrfs-formatted root filesystems.

**--root-label** *root\_label*  
The expected root partition label. See also '**OPERATIONS - 0.
Preliminary checks**'. Default if not provided: **fedora**.

**-v**, **--verbose**  
Be more verbose.

# OPERATIONS

**0. Preliminary checks**  
We check that the root partition is formatted with the **btrfs**
filesystem (or with **ext4** if the **--ext4** option is enabled) and
that the boot partition is formatted with the **ext4** filesystem. Then,
if not otherwise specified via the **--root-label** and **--boot-label**
options, we check that the labels of the root and boot partions are,
respectively, **fedora** and **BOOT**. Unless the **--no-subvols**
option (implied by **--ext4**) is enabled, we check that the btrfs root
filesystem contains the **root** and **home** subvolumes. Finally, we
check that the root and boot partitions contain the files and binaries
required to complete the encryption process.

These checks are performed in order to prevent **encryptroot.asahi** (or
the user) from unintentionally overwriting non-Fedora Asahi partitions
(e.g. the macOS partitions), and to make sure that the encryption
process can be brought to completion. Vanilla Fedora Asahi installations
require no options to pass the checks (if they do it's a bug, please
report it if you can!)

**1. Filesystem resizing**  
The filesystem contained in your root partition needs to be shrunk to
make room for the (LUKS) headers generated during the encryption step.
This is achieved using the **btrfs-filesystem**(8) command (for btrfs
root filesystems),

\# **btrfs filesystem resize -32M** *mountpoint*

or the **resize2fs**(8) command (for ext4 root filesystems),

\# **resize2fs** *rootdisk* $((*oldsize* - 32M))

In the former case, whether this step was successful can be checked by
mounting the root partition and running

\# **btrfs device usage** *mountpoint*

If the "**Device slack**" field reads 32MiB (or 16MiB after encryption),
it was successful.

**2. Full-disk encryption**  
The root partition is encrypted while preserving the data (that is,
unless things go wrong) using **cryptsetup-reencrypt**(8):

\# **cryptsetup reencrypt --encrypt --reduce-device-size 32M**
*rootdisk*

From the moment this step starts, the system will detect the root
partition as a **crypto\_LUKS** device (e.g. run **lsblk -ndo FSTYPE**
*rootdisk*); the root partition can then be mounted using
**cryptsetup-open**(8). Nonetheless, the root partition is **only**
actually fully encrypted when this step is **completed**.

The encryption step can be interrupted and resumed at a later moment.
While this behavior is useful in the event of recovery from failure, we
advise the user not to intentionally stop the process while encryption
is in progress.

You can check the encryption status of the root partition by running

\# **cryptsetup luksDump** *rootdisk*

If the '**Requirements**' field in '**LUKS header information**' exists
and contains the string 'online-reencrypt', the encryption process was
interrupted and must be resumed. Otherwise it completed successfully.
Note that if the previous command complains about *rootdisk* being an
invalid LUKS device, it means that this step never started in the first
place.

**3. /etc/crypttab and grub (chroot)**  
The now-encrypted root partition is registered for boot-time decryption
first with the **/etc/crypttab** file (see also **crypttab**(5)) and
then with **grub** (see also **grub2-mkconfig**(8)). This step is
performed inside a chroot.

This step was successfull if **/etc/crypttab** and **/etc/default/grub**
both contain the root disk's LUKS UUID, which can be obtained by

\# **cryptsetup luksUUID** *rootdisk*

and if the same UUID is contained in the boot partition's grub files
(usually **/boot/grub2/grub.cfg** and the relevant files in
**/boot/loader/entries**).

**4. initramfs (chroot)**  
The initramfs is recreated to make sure that it can decrypt the root
partition at boot time. This step is also performed inside a chroot.

There is no obvious way to check that this step was successful, other
than unpacking the initramfs and looking for **cryptsetup**(8),
**systemd-ask-password**(1), etc., inside it.

# RECOVERY

**1. Filesystem resizing**  
For btrfs root filesystems, **encryptroot.asahi** detects whether the
root filesystem was already shrunk by 32 MiB. If this is the case,
re-running the script with the same arguments won't resize it a second
time. If you manually shrank the btrfs root filesystem by a different
amount (or if your root partition is formatted with the ext4
filesystem), **AND** if the full-disk encryption step was never
initiated, re-running the script will shrink the filesystem again by 32
MiB. And then again. And so on.

Filesystem resizing is **never** performed on either partially or fully
encrypted *rootdisk*s (see below).

**2. Full-disk encryption**  
At startup, **encryptroot.asahi** detects whether the encryption step
was already attempted on *rootdisk*. If it determines that the
encryption step was interrupted while in progress, it tries to resume it
and bring it to completion. It does so by re-executing

\# **cryptsetup reencrypt --encrypt --reduce-device-size 32M**
*rootdisk*

(see **cryptsetup-reencrypt**(8) for the relevant documentation). Under
normal circumstances, no data corruption will result from re-running the
command.

If, at startup, **encryptroot.asahi** detects that *rootdisk* is fully
encrypted, for good measure it asks whether you picked the wrong disk.
If you tell it to continue, it assumes that you're trying to resume the
process from a later step, and that the root disk you picked is the same
one you used in the previous steps.

**3. /etc/crypttab and grub (chroot)**  
**encryptroot.asahi** detects whether the encrypted root partition was
already registered with **/etc/crypttab** and **/etc/default/grub**, and
doesn't do so again if it was. If the encrypted root partition was
registered with the boot partition's grub files, it doesn't run
**grub2-mkconfig**.

**4. initramfs (chroot)**  
The initramfs is always recreated. This is a routine operation and will
not cause issues under normal circumstances.

**NOTE**  
Resuming the encryption process from the **Full-disk encryption** stage
or from later ones requires **encryptroot.asahi** to be executed with
the **same arguments** as its first run. The checks in step 0 (see
'**OPERATIONS - 0. Preliminary checks**') are still performed, but on
the decrypted device, which requires you to enter the root disk password
one additional time.

# CREDITS

The encryption procedure followed by **encryptroot.asahi** is largely
taken from David Alger,
&lt;https://davidalger.com/posts/fedora-asahi-remix-on-apple-silicon-with-luks-encryption&gt;
(October 2023 revision).

# REPORTING BUGS

Bug tracker: &lt;https://gitlab.com/noisycoil/encryptroot-asahi&gt;.

# COPYRIGHT

Copyright (c) 2023 NoisyCoil &lt;noisycoil@tutanota.com&gt;. License:
MIT &lt;https://mit-license.org&gt;.

# SEE ALSO

**btrfs-filesystem**(8), **cryptsetup-reencrypt**(8), **crypttab**(5),
**dracut**(8), **grub2-mkconfig**(8), **resize2fs**(8).
