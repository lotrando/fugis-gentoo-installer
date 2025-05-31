# FUGIS

### Fast Universal Gentoo Installation Script

... is a debugged bash script that quickly install basic clear Gentoo Linux with loging all actions and errors and save or load config file from disk where run script or optionally from GitHub Gist.

<img src="screen.png" alt="Screenshot of settings before instalation procedure" />

### How to use this script ?
- download minimal installation CD from [gentoo.org](https://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/)
- create bootable USB stick

#### 1. Download and run script
- download [script](https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main/installer.sh) from GitHub
- save script to USB stick
- optionaly edit token for Gist and Gist ID
- make script executable and run script
- boot from USB stick or CD ISO
```
chmod +x installer.sh && ./installer.sh
```


#### 2. Run downloaded script direct from shell
- boot from USB stick or CD ISO
- in command line run two command lines
 ```
wget https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main/installer.sh
```
- optionaly edit token for Gist and Gist ID
```
chmod +x installer.sh && ./installer.sh
```

### Installation procedure
- setup script variables and run installer
- it will take some time to compile the kernel and packages
- reboot and use new clear Gentoo linux

### Screen after installation

<img src="after_install.png" alt="Screenshot after instalation procedure" />

### In the current version, these preferences are currently possible
#### note: in brackets are the default script variables without fugis.conf file

- User name: <b>[user]</b>
- User password: <b>[toor]</b>
- Root password: <b>[toor]</b>
- Hostname: <b>[gentoo]</b>
- Domainname: <b>[gentoo.dev]</b>
- GRUB Resolution: <b>[1920x1080x32]</b>
- Locale: <b>interactive choose</b>
- Keymap: <b>[us]</b>
- Timezone: <b>[Europe/Prague]</b>
- Target Disk: <b>interactive choose</b>
- Network Interface: <b>interactive choose</b>
- Network Mode: <b>interactive choose</b>
- SWAP Mode: <b>interactive choose</b>
- UEFI size: <b>[1024]</b>
- SWAP Size: <b>[2048]</b>

### This script install only contain 32 important packages and kernel

#### Kernel Build part
```
(01) app-text/asciidoc
(02) sys-fs/f2fs-tools
(03) sys-fs/dosfstools
(04) dev-libs/elfutils
(05) app-arch/cpio
(06) virtual/libelf
(07) app-alternatives/cpio
(08) sys-kernel/linux-firmware
(09) sys-kernel/zen-sources
(10) sys-kernel/genkernel
```
#### Packages Install part
```
(11) acct-group/nullmail
(12) sys-apps/hwdata
(13) virtual/libudev
(14) x11-base/xorg-proto
(15) media-libs/libpng
(16) app-text/mandoc
(17) sys-fs/fuse-common
(18) app-admin/metalog
(19) acct-user/nullmail
(20) sys-fs/lvm2
(21) sys-apps/pciutils
(22) x11-apps/bdftopcf
(23) media-libs/freetype
(24) sys-libs/efivar
(25) sys-fs/fuse
(26) sys-boot/efibootmgr
(27) virtual/logger
(28) media-fonts/terminus-font
(29) mail-mta/nullmailer
(30) sys-boot/grub
(31) virtual/mta
(32) app-admin/sudo
```

### Installation steps
```
[INFO] ✓ Configuration saved to fugis.conf
[INFO] ✓ Starting installation process...
[INFO] ✓ Creating partitions on /dev/sda
[INFO] ✓ Creating filesystems
[INFO] ✓ Mounting filesystems
[INFO] ✓ Downloading latest stage3 tarball
[INFO] ✓ Downloading: stage3-amd64-openrc-20250518T165514Z.tar.xz
[INFO] ✓ Extracting stage3: stage3-amd64-openrc-20250518T165514Z.tar.xz
[INFO] ✓ Cleaning up downloaded tarball
[INFO] ✓ Mounting system filesystems
[INFO] ✓ Creating chroot installation script
[INFO] ✓ Entering chroot and starting installation
[INFO] ✓ Installation completed successfully!
[INFO] ✓ Cleaning up...
```

### Configuration save to Github Gist
#### To get a GitHub Personal Access Token for Gist, follow these steps:

- go to github.com and log in
- click on your avatar (top right) and select Settings
- click on Developer settings in the left menu at the very bottom
- click on Personal access tokens and select Tokens (classic)
- click Generate new token (classic) GitHub may ask you to confirm your password
- note: Expiration: set to Never.
- click Generate token
- paste Token into the script for save config to Gist or paste existing Gist ID into the script for load or update Gist config.

IMPORTANT: The token will only appear once! Copy it.

