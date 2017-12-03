# Arch Linux Installer

Bash scripts for installing Arch Linux.

## arch_inst_base.sh

Edit top of file to specify paritions, swap, login, hostname, mounts, samba shares etc. Then run ```arch_inst_base.sh``` to begin installation.

## arch_inst_desktop.sh

Installs an i3wm based desktop. Run with sudo under user you want to install it to (uses the ```SUDO_USER``` value), ```sudo bash arch_inst_desktop.sh```.

## usbboot_grub.cfg

Grub2 config file for a multiple boot USB, including Windows 7.