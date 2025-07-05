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
║   Created by Lotrando (c) 2024-2025 v 1.8   ║
╚═════════════════════════════════════════════╝
[INFO] ✓ User have root privileges
[INFO] ✓ Script is running in live environment
[INFO] ✓ All required commands are available
[INFO] ✓ Internet connectivity detected online
```
[ ... user inputs ... ]
```
[INFO] ✓ Starting installation process...
[INFO] ✓ Detected Intel GPU
[INFO] ✓ Detect CPU flags
[INFO] ✓ Detect MAKEOPTS
[INFO] ✓ Creating partitions on /dev/sda
[INFO] ✓ Creating filesystems on UEFI and ROOT partitions
[INFO] ✓ Mounting created filesystems
[INFO] ✓ Downloading: stage3-amd64-openrc-20250702T205201Z.tar.xz
[INFO] ✓ Extracting stage3: stage3-amd64-openrc-20250702T205201Z.tar.xz
[INFO] ✓ Cleaning up downloaded tarball
[INFO] ✓ Mounting [proc sys dev run] filesystems
[INFO] ✓ Creating chroot configuration file
[INFO] ✓ Creating install script
[INFO] ✓ Starting chroot installation
[INFO] ✓ Updating portage tree
[INFO] ✓ Configuring portage
[INFO] ✓ Configuring GPU
[INFO] ✓ Configuring CPU FLAGS
[INFO] ✓ Configuring MAKEOPTS in make.conf
[INFO] ✓ Update /etc/fstab file
[INFO] ✓ Setting [hostname, consolefont, hosts]
[INFO] ✓ Setting LAN
[INFO] ✓ Setting keymap
[INFO] ✓ Setting locales
[INFO] ✓ Setting timezone
[INFO] ✓ Installing kernel packages
```
[ ... emerge log oputput ... ]
```
[INFO] ✓ Installing firmware
```
[ ... emerge log oputput ... ]
```
[INFO] ✓ Starting generate kernel
```
[ ... genkernel log oputput ... ]
```
[INFO] ✓ Installing important packages
```
[ ... emerge log oputput ... ]
```
[INFO] ✓ Create root password
[INFO] ✓ Create user lotrando and his password
[INFO] ✓ Configuring SUDO for lotrando
[INFO] ✓ Configuring GRUB and setting resolution 1920x1080x32
[INFO] ✓ Installing GRUB and create config file
[INFO] ✓ Installing user configuration files
[INFO] ✓ Running services
[INFO] ✓ Installing additional packages and configs
```
[ ... emerge log oputput ... ]
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
