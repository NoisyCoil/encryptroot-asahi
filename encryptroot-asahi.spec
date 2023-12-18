%global         scriptname encryptroot.asahi
%global         mansec 8

Name:           encryptroot-asahi
Version:        0.2.6
Release:        2
Summary:        Encrypt your Fedora Asahi root partition

License:        MIT
URL:            https://gitlab.com/noisycoil/encryptroot-asahi

Source0:        encryptroot-asahi-%version.tar.gz
Patch0:         patches/000-no-dependency-check.patch
BuildArch:      noarch
ExclusiveArch:  aarch64 noarch

Requires:       arch-install-scripts btrfs-progs cryptsetup e2fsprogs util-linux

%description
encryptroot.asahi is an interactive tool that allows you to encrypt the root
partition of your Fedora Asahi installation without deleting its contents.
It is meant to be executed from an external USB drive hosting a Fedora Asahi
OS, or from a regular Fedora virtual machine running on macOS.

%prep
%autosetup -p1

%install
install -d -m 0755 %{buildroot}/%{_sbindir}
install -d -m 0755 %{buildroot}/%{_mandir}/man%{mansec}
install -m 0755 src/%{scriptname} %{buildroot}/%{_sbindir}
install -m 0644 docs/%{scriptname}.%{mansec} %{buildroot}/%{_mandir}/man%{mansec}

%files
%license LICENSE
%{_sbindir}/%{scriptname}
%{_mandir}/man%{mansec}/%{scriptname}.%{mansec}*

%changelog
* Mon Dec 18 2023 NoisyCoil <noisycoil@tutanota.com> 0.2.6-2
- Adapt 000-no-dependency-check.patch to recent changes

* Mon Dec 18 2023 NoisyCoil <noisycoil@tutanota.com> 0.2.6-1
- Fix empty {root,boot}-label not recognized
- Avoid resizing ext4 FS twice before encryption

* Sat Dec 02 2023 NoisyCoil <noisycoil@tutanota.com> 0.2.5-1
- Btrfs: only resize if device slack < 32MiB

* Sat Dec 02 2023 NoisyCoil <noisycoil@tutanota.com> 0.2.4-1
- Improve incomplete_encryption_warning message
- Run grub2-mkconfig conditionally on whether LUKS_UUID is found in /boot

* Sat Dec 02 2023 NoisyCoil <noisycoil@tutanota.com> 0.2.3-1
- Improve docs
- Only update grub if /etc/default/grub changed

* Fri Dec 01 2023 NoisyCoil <noisycoil@tutanota.com> 0.2.2-1
- Improve docs

* Fri Dec 01 2023 NoisyCoil <noisycoil@tutanota.com> 0.2.1-1
- Update 000-no-dependency-check.patch
- Add Requires: e2fsprogs to spec file
- Fix repeated traps
- Add incomplete encryption warning
- Update docs
- Add --no-subvols and --ext4 options
- Add GRUB_CMDLINE_LINUX_DEFAULT to /etc/default/grub if none

* Fri Dec 01 2023 NoisyCoil <noisycoil@tutanota.com> 0.1.2-1
- Fix crypttab check in chroot

* Fri Dec 01 2023 NoisyCoil <noisycoil@tutanota.com> 0.1.1-1
- Add --root-label and --boot-label options

* Thu Nov 30 2023 NoisyCoil <noisycoil@tutanota.com> 0.1.0-1
- Initial (alpha) release.
