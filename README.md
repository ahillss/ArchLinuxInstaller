#Arch Linux Installer

Bash script for installing arch linux.

##arch_install_base.sh
Edit top of file to specify paritions, swap, login, hostname etc. Then type ```arch_install_base.sh os``` to begin installation.

##arch_install_desktop.sh
Edit top of file to specify what packages to install and comment/uncomment settings. Then Type ```arch_install_desktop.sh all```. Must be run as root.

##aur.sh
Script for installing AUR packages. Type ```aur.sh package_name``` to run.

##usbboot_grub.cfg

Grub2 config file for a multiple boot USB, including Windows 7.