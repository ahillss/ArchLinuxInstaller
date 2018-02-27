# Arch Linux Installer

Bash scripts for installing Arch Linux.

## arch_inst_base.sh

Edit top of file to specify paritions, swap, login, hostname, mounts, samba shares etc.

To install run: ```arch_inst_base.sh```.

## arch_inst_desktop.sh

Installs an i3wm based desktop. Use sudo under the user you want to install it for (it uses the ```SUDO_USER``` variable).

To install run: ```sudo bash arch_inst_desktop.sh```.
