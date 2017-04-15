# Arch Linux Installer

Bash script for installing arch linux.

## arch_install_base.sh
Edit top of file to specify paritions, swap, login, hostname etc. Then type ```arch_install_base.sh os``` to begin installation.

## arch_install_desktop.sh
Installs an i3wm based desktop, it is split into two modes.

First mode is to install the packages and setting up any config files that require root access. Run ```sudo ./arch_install_desktop.sh run_install```.

The second mode is to setup the user config files. Run ```./arch_install_desktop.sh run_user```

Make sure to run the script as the user you want to install to, it makes use of the ```HOME``` and ```USER``` variables.

## usbboot_grub.cfg

Grub2 config file for a multiple boot USB, including Windows 7.