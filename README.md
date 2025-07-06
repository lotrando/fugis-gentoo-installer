# FUGIS
### Fast Universal Gentoo Installation Script
 is a tweaked bash script that quickly install Gentoo Linux onto your hard drive.

---
### How to use this script ?
- download minimal installation ISO from [gentoo.org](https://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/)
- create bootable USB stick with this ISO

#### Option 1. Download and run script
- download [script](https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main/installer.sh) from GitHub
- save script to bootable USB stick
- make script executable
```
chmod +x installer.sh
```
- boot from USB stick and run from USB
```
  ./installer.sh
```


#### Option 2. Run downloaded script direct from shell
- boot from USB stick
- in bash run next commands
```
wget https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main/installer.sh
```
```
chmod +x installer.sh && ./installer.sh
```

### Installation procedure
- setup script variables and run installer
- it will take some time to compile the kernel and packages
- reboot and use new clear Gentoo linux

<img src="screen.png" alt="Screenshot of settings before instalation procedure" />

### Installation steps
```
╔═════════════════════════════════════════════╗
║                - F U G I S -                ║
║  Fast Universal Gentoo Installation Script  ║
║   Created by Lotrando (c) 2024-2025 v 1.9   ║
╚═════════════════════════════════════════════╝
```
```
Choose installation type:
Select disk:
Enter UEFI/BOOT partition size:
Choose SWAP type:
Enter username:
Enter user password:
Enter root password:
Enter hostname:
Enter domain name:
Choose kernel type:
Enter GRUB gfx mode:
Setup locales:
Enter keymapP:
Enter timezone:
Select network interface:
Select network configuration:
```
```
[INFO] ✓ Checkig if have root privileges
[INFO] ✓ Checkig if script running in live environment
[INFO] ✓ Check if all required commands are available
[INFO] ✓ Check Internet connectivity
[INFO] ✓ Detected XXX GPU
[INFO] ✓ Detect CPU flags: XXX
[INFO] ✓ Detect MAKEOPTS: XXX
[INFO] ✓ Creating partitions on /dev/sda
[INFO] ✓ Creating filesystems on UEFI/BOOT and ROOT partitions
[INFO] ✓ Mounting created filesystems
[INFO] ✓ Downloading: stage3-amd64-openrc-XXXXXXXXXXXXXXXX.tar.xz
[INFO] ✓ Extracting downloaded stage
[INFO] ✓ Copying repos.conf
[INFO] ✓ Copying resolv.conf
[INFO] ✓ Cleaning up downloaded tarball
[INFO] ✓ Mounting [proc, sys, dev, run] filesystems
[INFO] ✓ Creating chroot configuration file
[INFO] ✓ Generate install script
[INFO] ✓ Starting chroot installation
[INFO] ✓ Updating portage tree
[INFO] ✓ Configuring portage
[INFO] ✓ Configuring GPU
[INFO] ✓ Configuring CPU FLAGS
[INFO] ✓ Configuring MAKEOPTS
[INFO] ✓ Update /etc/fstab file
[INFO] ✓ Setting hostname
[INFO] ✓ Setting consolefont
[INFO] ✓ Setting hosts
[INFO] ✓ Setting network
[INFO] ✓ Setting keymap
[INFO] ✓ Generate locales
[INFO] ✓ Setting timezone
[INFO] ✓ Installing kernel packages
```
```
>>> Emerging (01) dev-libs/elfutils
>>> Emerging (02) app-arch/cpio
>>> Emerging (03) virtual/libelf
>>> Emerging (04) app-alternatives/cpio
>>> Emerging (05) sys-kernel/gentoo-sources
```
```
[INFO] ✓ Installing firmware and genkernel
```
```
>>> Emerging (01) sys-kernel/linux-firmware
>>> Emerging (02) app-text/asciidoc
>>> Emerging (03) app-crypt/rhash
>>> Emerging (04) dev-libs/jsoncpp
>>> Emerging (05) net-dns/c-ares
>>> Emerging (06) net-libs/nghttp3
>>> Emerging (07) app-arch/libarchive
>>> Emerging (08) dev-libs/libuv
>>> Emerging (09) net-libs/nghttp2
>>> Emerging (10) net-libs/libpsl
>>> Emerging (11) net-misc/curl
>>> Emerging (12) dev-build/cmake
>>> Emerging (13) sys-kernel/genkernel
```

```
[INFO] ✓ Starting generate kernel
```
```
* kernel: >> Initializing ...
*         >> Running 'make mrproper' ...
*         >> Running 'make oldconfig' ...
*         >> Re-running 'make oldconfig' due to changed kernel options ...
*         >> Kernel version has changed (probably due to config change) since genkernel start:
*            We are now building Linux kernel 6.15.4-gentoo-x86_64 for x86_64 ...
*         >> Compiling 6.15.4-gentoo-x86_64 bzImage ...
*         >> Compiling 6.15.4-gentoo-x86_64 modules ...
*         >> Installing 6.15.4-gentoo-x86_64 modules (and stripping) ...
*         >> Generating module dependency data ...
*         >> Compiling out-of-tree module(s) ...
*         >> Saving config of successful build to '/etc/kernels/kernel-config-6.15.4-gentoo-x86_64' ...

* initramfs: >> Initializing ...
*         >> Appending devices cpio data ...
*         >> Appending base_layout cpio data ...
*         >> Appending util-linux cpio data ...
*         >> Appending eudev cpio data ...
*         >> Appending auxiliary cpio data ...
*         >> Appending busybox cpio data ...
*         >> Appending modprobed cpio data ...
*         >> Appending modules cpio data ...
*         >> Deduping cpio ...
*         >> Pre-generating initramfs' /etc/ld.so.cache ...
*         >> Compressing cpio data (.xz) ...

* Kernel compiled successfully!
```
```
[INFO] ✓ Installing important packages
```
```
>>> Emerging (01) sys-apps/hwdata
>>> Emerging (02) dev-lang/python-exec
>>> Emerging (03) app-text/mandoc
>>> Emerging (04) sys-fs/dosfstools
>>> Emerging (05) sys-fs/fuse-common
>>> Emerging (06) dev-libs/gobject-introspection-common
>>> Emerging (07) sys-libs/efivar
>>> Emerging (08) media-libs/libpng
>>> Emerging (09) app-text/lowdown
>>> Emerging (10) dev-python/pygments
>>> Emerging (11) dev-lang/python
>>> Emerging (12) dev-libs/libpcre
>>> Emerging (13) media-libs/freetype
>>> Emerging (14) dev-lang/nasm
>>> Emerging (15) sys-fs/f2fs-tools
>>> Emerging (16) sys-libs/slang
>>> Emerging (17) dev-python/olefile
>>> Emerging (18) app-text/xmlto
>>> Emerging (19) virtual/libudev
>>> Emerging (20) x11-base/xorg-proto
>>> Emerging (21) sys-fs/fuse
>>> Emerging (22) sys-fs/lvm2
>>> Emerging (23) sys-apps/pciutils
>>> Emerging (24) media-libs/libjpeg-turbo
>>> Emerging (25) sys-boot/efibootmgr
>>> Emerging (26) dev-python/pillow
>>> Emerging (27) x11-apps/bdftopcf
>>> Emerging (28) sys-boot/grub
>>> Emerging (29) dev-python/docutils
>>> Emerging (30) media-fonts/terminus-font
>>> Emerging (31) dev-libs/glib
>>> Emerging (32) x11-misc/shared-mime-info
>>> Emerging (33) app-misc/mc
>>> Emerging (34) dev-util/desktop-file-utils
>>> Emerging (35) sys-process/btop
>>> Emerging (36) app-admin/sudo
```
```
[INFO] ✓ Create root password
[INFO] ✓ Create user $GENTOO_USER and his password
[INFO] ✓ Configuring SUDO
[INFO] ✓ Setting GRUB resolution to 1920x1080x32
[INFO] ✓ Installing GRUB
```
```
Installing for x86_64-efi platform.
Installation finished. No error reported.
```
```
[INFO] ✓ Download GRUB background png
[INFO] ✓ Create GRUB config file
```
```
Generating grub configuration file ...
Found background: /boot/grub/grub.png
Found linux image: /boot/vmlinuz-6.15.4-gentoo-x86_64
Found initrd image: /boot/amd-uc.img
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
```
```
[INFO] ✓ Download gentoo configuration files archive
[INFO] ✓ Extracting downloaded configuration files
[INFO] ✓ Running services
```
```
 * service consolefont added to runlevel default
 * service numlock added to runlevel default
 * service sshd added to runlevel default
 ```
 ```
[INFO] ✓ Installing additional packages and configs
```
```
>>> Emerging additional (X) packages by installation type
```
```
[INFO] ✓ Removing chroot script
[INFO] ✓ Gentoo Linux installation completed successfully!
╔════════════════════════════════════════════════════════════════╗
║                    INSTALLATION COMPLETE !                     ║
║    Your Gentoo Linux system has been successfully installed    ║
║         You can now reboot and enjoy your new system!          ║
║    After reboot for update packages from stage3 run command    ║
╠════════════════════════════════════════════════════════════════╣
║                  sudo emerge -avNUDu @world                    ║
╚════════════════════════════════════════════════════════════════╝
```
### Screen after installation

<img src="after_install.png" alt="Screenshot after instalation procedure" />


### Positives of the Script
- **Installation type:**
possibility to choose installation type, 1.Clear Gentoo linux or 2.Gentoo Linux as Webserver, 3.Gentoo Linux as Hyprland desktop and finally 4.Gentoo Linux as Hyprland Desktop for Webdevelopment.

- **Interactive Setup:**
  Guides the user step-by-step through all key installation choices (disk, user, network, kernel, locale, etc.), making it very beginner-friendly.

- **Input Validation:**
  Validates user inputs (IP, hostname, username, partition sizes, etc.), reducing the risk of errors during installation.

- **Clear and Colored Output:**
  Uses colors and formatting for outputs, making the process easy to follow and visually organized.

- **Automates Routine Operations:**
  Handles partitioning, filesystem creation, Stage3 downloading, network and locale setup, and more, minimizing manual intervention.

- **Comprehensive Configuration:**
  Sets up kernel sources, users, sudo privileges, GRUB bootloader, and essential services - all in one script.

- **Logging:**
  Logs all installation actions into a file for troubleshooting and review.

- **Safety Warnings:**
  Clearly warns the user before performing destructive operations, such as wiping the target disk.

- **Hardware Detection:**
  Detects CPU and GPU types to optimize configuration and USE flags.

- **Supports Both DHCP and Static Network:**
  Allows the user to choose between DHCP and static network setups, with proper validation.

- **Swap Recommendation:**
  Calculates and recommends swap partition size based on system RAM.
