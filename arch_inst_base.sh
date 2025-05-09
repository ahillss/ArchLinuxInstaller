#!/bin/bash

grub_disk=/dev/sda
boot_diskpart=${grub_disk}1
root_diskpart=${grub_disk}2
home_diskpart=${grub_disk}3

#swap_diskpart=${grub_disk}4
# --- or ---
#swap_filesize=8G
#swap_filename=/swapfile

mylogin=arch
mypass=arch
myhostname=archpc
rootpass=$mypass

function on_grub() {
	echo ''
	#add_grub_boot "/dev/sda5" "Windows"
}

function on_fstab() {
	echo ''
	#add_fstab_mount "/dev/sdc1" "/mnt/t" "ext4"
	#add_fstab_win_mount "/dev/sda4" "/mnt/c" "ntfs-3g"
}

function on_samba() {
	echo ''
	#add_samba_share "/mnt/t"
}

###################################################

function install_os() {
	#
	format_partitions
	mount_partitions
	
	#
	pacstrap /mnt base base-devel
	genfstab -U /mnt > /mnt/etc/fstab
	setup_swap
	
	#chroot
	cp -f $0 /mnt/
	arch-chroot /mnt /bin/bash $(basename $0) install_os2
	rm /mnt/$(basename $0)
		
	#
	free_swap
	umount -R /mnt
}

function setup_packages() {
	packages=""
	packages+=" linux mkinitcpio dhcpcd nano"
	packages+=" grub memtest86+"
	packages+=" networkmanager openssh ntp"
	packages+=" pulseaudio pulseaudio-alsa alsa-utils"
	packages+=" htop lsof wget p7zip tmux"
	packages+=" ntfs-3g fuse-exfat exfat-utils dosfstools"
	packages+=" samba"
	packages+=" acpid"
	#packages+=" bluez bluez-plugins bluez-utils"
	#packages+=" alsa-plugins ladspa swh-plugins"
	packages+=" avahi nss-mdns"
	#packages+=" archlinux-keyring"
	
	#packages+=" lighttpd fcgi php php-cgi"

	#dirmngr < /dev/null
	#pacman -Scc
	#rm -rf /etc/pacman.d/gnupg
	#pacman-key --refresh-keys
	#pacman-key --init && pacman-key --populate archlinux
	
	pacman -S --needed --noconfirm $packages
}

function install_os2() {
	setup_packages
	setup_networkmanager
	setup_ssh
	setup_ntp
	setup_sudoers
	setup_user
	setup_fstab
	setup_mkinitcpio
	setup_grub
	setup_timezone
	setup_locale
	setup_pacman
	setup_lib_path
	setup_host
	setup_power
	#setup_bluetooth
	setup_runasuser
	setup_pulseaudio
	setup_samba
	setup_avahi
	setup_swap_sysctl
	setup_aur_script
	setup_acpi
	#setup_autologin
	setup_misc_scripts
	#disable_coredump
	#setup_lighttpd
	
}

function setup_misc_scripts() {
	echo -e '#!/bin/bash\n\ncmp -l $1 $2 | gawk '"'"'{printf "%08X %02X %02X\\n", $1, strtonum(0$2), strtonum(0$3)}'"'" > /usr/local/bin/bdiff.sh
	chmod +xr /usr/local/bin/bdiff.sh
}

function get_uuid() {
	echo `blkid -s UUID $1 | sed -n 's/.*UUID=\"\([^\"]*\)\".*/\1/p'`
}

function get_escaped() {
	echo `echo "$1" | sed 's/\//\\\\\//g'`
}

function format_partitions() {
	#boot
	if [ $boot_diskpart ]; then
		mkfs.ext2 $boot_diskpart
	fi

	#root
	mkfs.ext4 $root_diskpart
	
	#home
	if [ $home_diskpart ]; then
		mkfs.ext4 $home_diskpart
	fi
}

function mount_partitions() {
	#root
	mount $root_diskpart /mnt
	
	#
	mkdir -p /mnt/home /mnt/boot

	#boot
	if [ $boot_diskpart ]; then
		mount $boot_diskpart /mnt/boot
	fi
	
	#home
	if [ $home_diskpart ]; then
		mount $home_diskpart /mnt/home
	fi
}

function setup_swap() {
	if [ $swap_filename ] && [ $swap_filesize ]; then
		fallocate -l $swap_filesize /mnt${swap_filename}
		#dd if=/dev/zero of=$name bs=1M count=$swap_filesize
		chmod 600 /mnt${swap_filename}
		
		mkswap /mnt${swap_filename}
		swapon /mnt${swap_filename}
	elif [ $swap_diskpart ]; then
		mkswap $swap_diskpart
		swapon $swap_diskpart
	fi
}

function free_swap() {
	if [ $swap_filename ] && [ $swap_filesize ]; then
		swapoff /mnt${swap_filename}
	elif [ $swap_diskpart ]; then
		swapoff $swap_diskpart
	fi
}

function add_fstab_mount() {
	part=$1
	mounting=$2
	fsys=$3
	
	uuid=`get_uuid $part`
	
	#
	echo -e "\nUUID=$uuid $mounting $fsys relatime,nofail 0 0"  >> /etc/fstab
}

function add_fstab_win_mount() {
	part=$1
	mounting=$2
	fsys=$3
	
	uuid=`get_uuid $part`
	useuid=`id -u $mylogin`
	usegid=`id -g $mylogin`
	
	#
	echo -e "\nUUID=$uuid $mounting $fsys relatime,nofail,umask=000,uid=$useuid,gid=$usegid 0 0"  >> /etc/fstab
}

function setup_networkmanager() {
	systemctl enable NetworkManager
	systemctl enable systemd-resolved
	systemctl enable dhcpcd.service
}

function setup_ssh() {
	systemctl enable sshd
	
	sed -i 's/#\(PermitRootLogin \)prohibit-password/\1no/g' /etc/ssh/sshd_config

	echo -e '\n#\nAllowGroups ssh' >> /etc/ssh/sshd_config

	groupadd ssh
}

function setup_ntp() {
	systemctl enable ntpd.service
}

function setup_fstab() {
	#swap
	if [ $swap_filename ] && [ $swap_filesize ]; then
		echo -e "\n# \n$swap_filename none swap defaults 0 0" >> /etc/fstab
	elif [ $swap_diskpart ]; then
		echo -e "\n# $swap_diskpart\nUUID=$(get_uuid $swap_diskpart) none swap defaults 0 0" >> /etc/fstab
	fi

	#
	on_fstab
}

function setup_mkinitcpio() {
	sed -i 's/\(HOOKS=\).*/\1"base udev keymap autodetect modconf block resume filesystems keyboard fsck" /g' /etc/mkinitcpio.conf
	mkinitcpio -p linux
}

function add_grub_boot() {
	part=$1
	title=$2
	u=`get_uuid $part`
	old=`echo $part | sed 's/[/a-zA-Z]\+\([0-9]\+\)/\1/'`
	echo -e "menuentry \"$title\" {\n\tsearch --fs-uuid --no-floppy --set=root $u\n\t#set root=(hd0,$old)\n\tchainloader +1\n}" >> /etc/grub.d/40_custom;
}

function setup_grub() {
	if [ $grub_disk ]; then
		grub-install $grub_disk
		sed -i "s/\(GRUB_DEFAULT=\)0/\1saved/g" /etc/default/grub
		sed -i "s/\(GRUB_TIMEOUT=\)5/\12/g" /etc/default/grub
		#echo "GRUB_DISABLE_OS_PROBER=true" >> /etc/default/grub
		echo -e '\n#quick fix for broken grub.cfg gen\nGRUB_DISABLE_SUBMENU=y' >> /etc/default/grub
		
		rootuuid=`get_uuid $root_diskpart`
		sed -i "s/\(GRUB_CMDLINE_LINUX_DEFAULT=\).*/\1\"linux \/boot\/vmlinuz-linux root=UUID=$rootuuid rw quiet splash\"/g" /etc/default/grub

		#
		if [ $swap_filename ] && [ $swap_filesize ]; then
			swap_diskpart2=`df -P $swap_filename | tail -1 | cut -d' ' -f 1`
			resoff=`filefrag -v $swap_filename | awk 'FNR == 4 {print $4}' | sed 's/\..//'`
			swapuuid=`get_uuid $swap_diskpart2`
			sed -i "s/\(GRUB_CMDLINE_LINUX_DEFAULT=\"\)\([^\"]*\"\)/\1resume=UUID=$swapuuid resume_offset=$resoff \2/g" /etc/default/grub
		elif [ $swap_diskpart ]; then
			swapuuid=`get_uuid $swap_diskpart`
			sed -i "s/\(GRUB_CMDLINE_LINUX_DEFAULT=\"\)\([^\"]*\"\)/\1resume=UUID=$swapuuid \2/g" /etc/default/grub
		fi
		
		#
		on_grub
		
		#
		grub-mkconfig -o /boot/grub/grub.cfg
	fi
}

function setup_timezone() {
	ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
}

function setup_locale() {
	sed -i "s/#\(en_AU.*\)/\1/g" /etc/locale.gen
	sed -i "s/#\(en_GB.*\)/\1/g" /etc/locale.gen
	sed -i "s/#\(en_US.*\)/\1/g" /etc/locale.gen
	echo -e 'LANG="en_AU.UTF-8"\nLANGUAGE="en_AU.UTF-8:en_US.UTF-8:en"\nLC_COLLATE="en_AU.UTF-8"\nLC_TIME="en_AU.UTF-8"' > /etc/locale.conf
	echo 'KEYMAP=us' > /etc/vconsole.conf
	locale-gen en_AU.UTF-8
}

function setup_pacman() {
	sed -i 'N;N;s/#\(\[multilib\]\)\n#/\1\n/g' /etc/pacman.conf
	sed -i '/^# Misc options$/ a\ILoveCandy' /etc/pacman.conf
}

function setup_sudoers() {
	groupadd sudo
	sed -i 's/# \(%sudo.*\)/\1/g' /etc/sudoers
	echo -e "\n$mylogin  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	echo -e '\n#\n#Defaults !env_reset' >> /etc/sudoers
}

function setup_lib_path() {
	echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
}

function setup_host() {
	echo $myhostname > /etc/hostname
}

function setup_user() {
	#root
	echo root:$rootpass | chpasswd

	#user
	useradd -m -U -G sudo,users,ssh -s /bin/bash $mylogin
	
	echo $mylogin:$mypass | chpasswd
}

function setup_power() {
	sed -i 's/#\(HandlePowerKey=\).*/\1suspend/g' /etc/systemd/logind.conf
	sed -i 's/#\(HandleLidSwitch=\).*/\1hybrid-sleep/g' /etc/systemd/logind.conf
	echo -e 'SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-3]", RUN+="/usr/bin/systemctl hibernate"' > /etc/udev/rules.d/99-lowbat.rules
}

function setup_bluetooth() {
	systemctl enable bluetooth.service
	
	#echo 1 > /sys/module/bluetooth/parameters/disable_ertm
	echo 'options bluetooth disable_ertm=Y' > /etc/modprobe.d/mybluetooth.conf
	
	#sed -i "s/#\(AutoEnable=\)false/\1true/g" /etc/bluetooth/main.conf
}


function setup_runasuser() {
	echo -e '#!/bin/bash\n\nif [ $1 ] && [ $2 ]; then\n\tsudo -u $1 env HOME=/home/$1 USER=$1 USERNAME=$1 LOGNAME=$1 "${@:2}"\nfi' > /usr/local/bin/runasuser
	chmod +xr /usr/local/bin/runasuser
}

function setup_pulseaudio() {
	echo -e '\nload-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket' >> /etc/pulse/default.pa
	echo -e '\ncookie-file = /tmp/pulse-cookie.$user' >> /etc/pulse/client.conf
}

function add_samba_share() {
	echo -e "\n[$(basename $1)]\n path = $1\n guest ok = yes\n guest only = yes\n guest account = nobody\n writeable = yes\n browsable = yes\n create mask = 777\n force directory mode = 777"  >> /etc/samba/smb.conf
	#setfacl -R -d -m o::rwx "$1"
}

function setup_samba() {
	systemctl enable smb.service
	systemctl enable nmb.service

	echo -e '[global]\n workgroup = WORKGROUP\n unix extensions = no\n restrict anonymous = 0\n map to guest = Bad User' > /etc/samba/smb.conf
	#echo -e ' guest account = nobody\n security = user\n hostname lookups = yes' >> /etc/samba/smb.conf

	on_samba
}

function setup_avahi() {
	#sed -i 's/\(host.*\)\(dns.*\)/\1mdns_minimal [NOTFOUND=return] \2/g' /etc/nsswitch.conf
	sed -i 's/\(host.*resolve \)\(.*\)/\1mdns_minimal [NOTFOUND=return] \2/g' /etc/nsswitch.conf
	echo -e '<?xml version="1.0" standalone="no" ?>\n<!DOCTYPE service-group SYSTEM "avahi-service.dtd">\n<service-group>\n\t<name replace-wildcards="yes">%h SMB</name>\n\t<service>\n\t\t<type>_smb._tcp</type>\n\t\t<port>445</port>\n\t</service>\n</service-group>' > /etc/avahi/services/samba.service
	systemctl enable avahi-daemon.service
}

function disable_coredump() {
	ln -s /dev/null /etc/sysctl.d/50-coredump.conf
	sysctl kernel.core_pattern=core
}

function setup_swap_sysctl() {
	echo 'vm.swappiness=50' >> /etc/sysctl.d/99-sysctl.conf
	echo 'vm.min_free_kbytes=131072' >> /etc/sysctl.d/99-sysctl.conf
	echo 'vm.vfs_cache_pressure=10' >> /etc/sysctl.d/99-sysctl.conf
}

function setup_aur_script() {
	echo -e '#!/bin/bash\n\nset -e\n\nif [ -z "$1" ]; then\n\techo "No package name specified."\n\texit\nfi\n\nmkdir -p $1\ncd $1\n\nwget -q "https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz"\n\ntar xzf $1.tar.gz\n\ncd $1\n\nmakepkg -s\n\nread -n 1 -s -p "Press any key to continue..."\necho -e "\\n"\n\nsudo pacman -U --noconfirm --needed $1*pkg.*' > /usr/local/bin/aur.sh
	#\n\nif [ -n "$2" ]; then\n\tsed -i "s/\\(arch=\\).*/\\1('"'"'$2'"'"')/g" PKGBUILD\nfi
	
	chmod +rx /usr/local/bin/aur.sh
}

function setup_acpi() {
	systemctl enable acpid.service
	
	mkdir -p /etc/acpi/actions
	
	echo -e '#!/bin/bash\n\nb="/sys/class/backlight/*/brightness"\nv=$(cat $(ls $b | head -n 1))\nd=$(ls $b | head -n 1)\n\nif [ "$1"x == "up"x ]; then\n\techo "$(($v + 1))" > "$d"\nfi\n\nif [ "$1"x == "down"x ]; then\n\techo "$(($v - 1))" > "$d"\nfi\n' > /etc/acpi/actions/brightness.sh
	
	echo -e '#!/bin/bash\n\nexport PULSE_RUNTIME_PATH=`find /run/user/*/ -name pulse | head -n 1`\nuid=$(basename $(dirname $PULSE_RUNTIME_PATH))\nuname=`getent passwd "$uid" | cut -d: -f1`\n\nif [ "$1"x == "up"x ]; then\n\t#su $uname -c "amixer -D pulse -q set Master 5%+ unmute"\n\tsu $uname -c "pactl set-sink-mute @DEFAULT_SINK@ false"\n\tsu $uname -c "pactl set-sink-volume @DEFAULT_SINK@ +5%"\nfi\n\nif [ "$1"x == "down"x ]; then\n\t#su $uname -c "amixer -D pulse -q set Master 5%- unmute"\n \tsu $uname -c "pactl set-sink-mute @DEFAULT_SINK@ false"\n\tsu $uname -c "pactl set-sink-volume @DEFAULT_SINK@ -5%"\nfi\n\nif [ "$1"x == "mute"x ]; then\n\t#su $uname -c "amixer -D pulse -q set Master toggle"\n\tsu $uname -c "pactl set-sink-mute @DEFAULT_SINK@ toggle"\nfi\n' > /etc/acpi/actions/volume.sh
	
	chmod +rx /etc/acpi/actions/brightness.sh /etc/acpi/actions/volume.sh
	
	echo -e 'event=video/brightnessup\naction=/etc/acpi/actions/brightness.sh up' > /etc/acpi/events/bl_u
	echo -e 'event=video/brightnessdown\naction=/etc/acpi/actions/brightness.sh down' > /etc/acpi/events/bl_d
	
	echo -e 'event=button/volumeup\naction=/etc/acpi/actions/volume.sh up' > /etc/acpi/events/vol_u
	echo -e 'event=button/volumedown\naction=/etc/acpi/actions/volume.sh down' > /etc/acpi/events/vol_d
	echo -e 'event=button/mute\naction=/etc/acpi/actions/volume.sh mute' > /etc/acpi/events/vol_m
}

function setup_autologin() {
	mkdir -p /etc/systemd/system/getty@tty1.service.d
	echo -e "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --autologin $mylogin --noclear %I 38400 linux" > /etc/systemd/system/getty@tty1.service.d/autologin.conf
}

function setup_lighttpd() {
	systemctl enable lighttpd

	mkdir -p /etc/lighttpd/conf.d/

	echo 'server.modules += ("mod_fastcgi")' >> /etc/lighttpd/conf.d/fastcgi.conf
	echo 'index-file.names += ("index.php")' >> /etc/lighttpd/conf.d/fastcgi.conf
	echo '' > /etc/lighttpd/conf.d/fastcgi.conf
	echo 'fastcgi.server = (' >> /etc/lighttpd/conf.d/fastcgi.conf
	echo '    ".php" => ("localhost" => ("bin-path" => "/usr/bin/php-cgi", "socket" => "/tmp/php-fastcgi.sock", "broken-scriptfilename" => "enable", "max-procs" => 4, "bin-environment" => ("PHP_FCGI_CHILDREN" => "1")))' >> /etc/lighttpd/conf.d/fastcgi.conf
	echo ')' >> /etc/lighttpd/conf.d/fastcgi.conf

	echo '' >>  /etc/lighttpd/lighttpd.conf
	echo 'include "conf.d/fastcgi.conf"' >>  /etc/lighttpd/lighttpd.conf

	echo '<?php phpinfo(); ?>' > /srv/http/index.php
	chmod 755 /srv/http/index.php
	
	#sed -i 's/;\(extension=mysql.so\)/\1/g' /etc/php/php.ini
	#sed -i "s/\(open_basedir = .*\)/\1:\/bin\/:\/usr\/bin\//g" /etc/php/php.ini
}

trap 'echo "Error on line $LINENO"' ERR
set -e

if [ $1 ]; then
	eval $1
	echo "'$1' completed successfully!"
else
	eval install_os
	echo "'install_os' completed successfully!"
fi
