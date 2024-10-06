# encryptroot.asahi

> ⚠️ **WARNING:** This is experimental software. Use it at your own risk.

**encryptroot.asahi** is an interactive script that allows you to encrypt the root partition of your Fedora Asahi installation without deleting its contents. It is meant to be executed from an external USB drive hosting an Asahi OS, or from a regular Linux virtual machine running on macOS. It may horribly screw up your system if executed from your Fedora Asahi installation (this scenario is completely untested, please, just don't).

Unless you've just installed Fedora Asahi, backup your system before running **encryptroot.asahi**. As the user of this script, you are expected to be able to manually recover from failure. If you are not able to do so, please don't run **encryptroot.asahi**.

The [OPERATIONS](docs/encryptroot.asahi.8.md#operations) section of the [manpage](docs/encryptroot.asahi.8.md) details the steps involved in the encryption process. The [RECOVERY](docs/encryptroot.asahi.8.md#recovery) section details its recovery logic. These sections can be of help if the process fails: they contain useful information and debug steps.

By running this script you agree not to hold its author accountable for any loss of data or any other form of damage resulting from its use.

## Credits

The encryption procedure followed by **encryptroot.asahi** is largely taken from David Alger, <https://davidalger.com/posts/fedora-asahi-remix-on-apple-silicon-with-luks-encryption> (October 2023 revision).

## Copyright

Copyright (c) 2023-2024 NoisyCoil (<noisycoil@tutanota.com>). License: MIT (<https://mit-license.org>).
