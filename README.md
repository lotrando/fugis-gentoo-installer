# FUGIS
### Fast Universal Gentoo Installation Script
 is a tweaked bash script that quickly install Gentoo Linux onto your hard drive.

---
### How to use this script ?
- download minimal installation ISO from [gentoo.org](https://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/)
- create bootable USB stick with this ISO
- download [script](https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main/installer.sh) from GitHub
- save script to bootable USB stick
- boot from USB stick find script and run
```
chmod +x installer.sh && ./installer.sh
```

or

- boot from USB stick
- in bash run next commands
```
wget https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main/installer.sh
```
```
chmod +x installer.sh && ./installer.sh
```
---

### Installation steps
- Choose some variables to setup script
- it will take some time to compile the kernel and packages
- reboot and use new clear Gentoo linux

#### Clear Gentoo Installation Procedure log file on Virtualbox
```
╔═════════════════════════════════════════════╗
║  ███████╗ ██╗   ██╗  ██████╗  ██╗ ███████╗  ║
║  ██╔════╝ ██║   ██║ ██╔════╝  ██║ ██╔════╝  ║
║  █████╗   ██║   ██║ ██║  ███╗ ██║ ███████╗  ║
║  ██╔══╝   ██║   ██║ ██║   ██║ ██║ ╚════██║  ║
║  ██║      ╚██████╔╝ ╚██████╔╝ ██║ ███████║  ║
║  ╚═╝       ╚═════╝   ╚═════╝  ╚═╝ ╚══════╝  ║
║  Fast Universal Gentoo Installation Script  ║
║   Created by Lotrando (c) 2024-2025 v 1.9   ║
╚═════════════════════════════════════════════╝
[INFO] ✓ No acceleration GPU detected

Installation type:

1. Classic (Clear Gentoo Linux)
2. Webserver (Gentoo Linux as LAMP server)
3. Hyprland (Gentoo Linux as Hyprland Desktop)
4. Webdevelop (Gentoo Linux as Development Workstation)

Choose installation type (1-4): 1
[INFO] Selected installation type: Classic (Clear Gentoo Linux)

Detected disks:

1. /dev/sda (  32G VBOX HARDDISK   )

Select disk by number (1-1): 1
You selected: /dev/sda (SSD/SATA)

UEFI/BOOT partition size in MB:

Enter UEFI/BOOT partition size [1024]:

SWAP config:

1. SWAP Off
2. SWAP Partition

Choose SWAP type (1-2): 2
You have chosen: SWAP Partition

Recommended swap partition size: 8192 MB
Swap partition size in MB [8192]:

Users and passwords:

Enter username [user]: lotrando
Enter user password [toor]:
Enter root password [toor]:

Setup computer:

Enter hostname [gentoo]:
Enter domain name [gentoo.dev]:

Kernel sources selection:

1. Zen (optimized for desktop)
2. Gentoo (stable for webserver)
3. Git (development kernel)

Choose kernel type (1-3): 2
You have chosen: Gentoo Sources

GRUB resolution:

Enter GRUB gfx mode [1920x1080x32]:

Setup locales:

1. English (en_US.UTF-8)
2. Czech (cs_CZ.UTF-8)
Select locale (1-2): 2
Enter keymap [us]:
Enter timezone [Europe/Prague]:

Detected network interfaces:

1. enp0s3

Select network interface by number (1-1): 1
You selected: enp0s3

Network configuration:
1. DHCP (automatic)
2. Static IP

Select network configuration (1-2): 1
You selected: DHCP

Summary of your settings:

Installation type: Classic (Clear Gentoo Linux)
Target disk: /dev/sda
Disk type: SSD/SATA
UEFI/BOOT size: 1024 MB
Locale: cs_CZ.UTF-8
Username: lotrando
User password: toor
Root password: toor
Hostname: gentoo
Domain name: gentoo.dev
Kernel: Gentoo Sources
GRUB Resolution: 1920x1080x32
Timezone: Europe/Prague
Keymap: us
Network interface: enp0s3
Network mode: dhcp
Swap type: partition
Swap partition: 8192 MB

WARNING: Confirm will COMPLETELY WIPE the selected disk!

Is everything set as you want? (y/n): y

[INFO] ✓ Checkig if have root privileges
[INFO] ✓ Checkig if script running in live environment
[INFO] ✓ Check if all required commands are available
[INFO] ✓ Check Internet connectivity
[INFO] ✓ No acceleration GPU detected, using generic drivers
[INFO] ✓ Detect CPU flags: aes avx avx2 bmi1 bmi2 f16c fma3 mmx mmxext pclmul popcnt rdrand sha sse sse2 sse3 sse4_1 sse4_2 sse4a ssse3
[INFO] ✓ Detect MAKEOPTS: -j6
[INFO] ✓ Creating partitions on /dev/sda
[INFO] ✓ Creating swap partition
[INFO] ✓ Creating filesystems on UEFI/BOOT and ROOT partitions
[INFO] ✓ Mounting created filesystems
[INFO] ✓ Activating swap partition
[INFO] ✓ Downloading: stage3-amd64-openrc-20250803T163732Z.tar.xz
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
[INFO] ✓ Update fstab
[INFO] ✓ Setting hostname to gentoo
[INFO] ✓ Setting consolefont
[INFO] ✓ Setting hosts to gentoo.gentoo.dev
[INFO] ✓ Setting network
[INFO] ✓ Setting keymap
[INFO] ✓ Generate locales
[INFO] ✓ Setting timezone
[INFO] ✓ Installing kernel packages
[INFO] ✓ Installing firmware and genkernel
[INFO] ✓ Starting generate kernel
[INFO] ✓ Installing important packages
[INFO] ✓ Create root password
[INFO] ✓ Create user realist and his password
[INFO] ✓ Configuring SUDO
[INFO] ✓ Setting GRUB resolution to 1920x1080x32
[INFO] ✓ Installing GRUB
[INFO] ✓ Download GRUB background png
[INFO] ✓ Create GRUB config file
[INFO] ✓ Download gentoo configuration files archive
[INFO] ✓ Extracting downloaded configuration files
[INFO] ✓ Running services
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
