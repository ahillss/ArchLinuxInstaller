#!/bin/bash

function setup_lightdm() {
	systemctl enable lightdm
	
	groupadd autologin	
	gpasswd -a $USER autologin
		
	sed -i "s/#\(autologin-user=\)/\1$USER/g" /etc/lightdm/lightdm.conf
	sed -i 's/#\(pam-service=lightdm\)/\1/g' /etc/lightdm/lightdm.conf
	sed -i 's/#\(pam-autologin-service=lightdm-autologin\)/\1/g' /etc/lightdm/lightdm.conf
	sed -i 's/#\(autologin-user-timeout=0\)/\1/g' /etc/lightdm/lightdm.conf
}

function setup_mousepad() {
	cp -f /usr/share/X11/xorg.conf.d/*-synaptics.conf /etc/X11/xorg.conf.d/
	echo -e '\n#\nSection "InputClass"\n        Identifier "Scrolling"\n        Option "VertEdgeScroll" "on"\n        Option "HorizEdgeScroll" "on"\nEndSection\n' >>  /etc/X11/xorg.conf.d/*-synaptics.conf
}

function setup_theme() {
	sed -i 's/\(Inherits=\).*/\1Vanilla-DMZ/g' /usr/share/icons/default/index.theme
}

function setup_x11vnc() {
	echo -e 'many\ndisplay :0\nnoscr\nnoxrecord\ngui tray\n#o .x11vnc.%VNCDISPLAY.log\nrfbport 5900\n\n#use: x11vnc -storepasswd YOURPASS ~/.x11vnc_passwd\nrfbauth .x11vnc_passwd\n\n#or:\n#passwd YOURPASS\n\n#or no pass:\n#nopw' > $HOME/.x11vncrc
}

function setup_tigervnc() {
	echo -e '#!/bin/bash\n\nPASSWD_FILE=~/.vnc/passwd\n\nif [ $1 ]; then\n\techo $1 | vncpasswd -f > $PASSWD_FILE\nfi\n\nvncviewer passwd=$PASSWD_FILE' > /usr/local/bin/tigervnc.sh
	chmod +xr /usr/local/bin/tigervnc.sh

	mkdir -p $HOME/.vnc
	echo -e 'TigerVNC Configuration file Version 1.0\n\nDotWhenNoCursor=1\nRemoteResize=1\nMenuKey=' > $HOME/.vnc/default.tigervnc
}

function setup_cups() {
	systemctl enable org.cups.cupsd.service
}

function setup_tmpcache() {
	mkdir -p $HOME/.local/share $HOME/.cache
	
	echo -e "\n#" >> /etc/fstab
	
	echo "/tmp $HOME/.local/share/gvfs-metadata none defaults,bind 0 0" >> /etc/fstab	
	echo "/tmp $HOME/.cache/thumbnails none defaults,bind 0 0" >> /etc/fstab
	echo "/tmp $HOME/.cache/vlc none defaults,bind 0 0" >> /etc/fstab
	
	echo "#/tmp /$HOME/.cache/chromium none defaults,bind 0 0" >> /etc/fstab
	echo "#/tmp /$HOME/.cache/mozilla none defaults,bind 0 0" >> /etc/fstab
}

function setup_xserver() {
	echo -e '#!/bin/sh\n\nif [ -d /etc/X11/xinit/xinitrc.d ]; then\n\tfor f in /etc/X11/xinit/xinitrc.d/*; do\n\t\t[ -x "$f" ] && . "$f"\n\tdone\n\tunset f\nfi\n\n' > $HOME/.xinitrc
	
	echo -e '[[ -f ~/.bashrc ]] && . ~/.bashrc\n#[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' > $HOME/.bash_profile
	
	echo "#xmodmap -e 'pointer = 1 10 3 4 5 6 7 8 9 2 11 12 13 14 15 16 17 18 19 20 21 22 23 24' &" >> $HOME/.xprofile
	echo '#xrandr --output HDMI1 --auto --primary --output HDMI2 --auto --right-of HDMI1 &' >> $HOME/.xprofile
	echo '#xrandr --output HDMI-2 --auto --primary --output HDMI-1 --auto --right-of HDMI-2 --rotate inverted &' >> $HOME/.xprofile
	echo '#xrandr -s 0 &' >> $HOME/.xprofile
	echo "#xautolock -detectsleep -time 45 -locker 'systemctl hybrid-sleep' &" >> $HOME/.xprofile
	echo '#system-config-printer-applet &' >> $HOME/.xprofile
	echo '#nm-applet &' >> $HOME/.xprofile
	echo '#x11vnc &' >> $HOME/.xprofile
	echo '#autocutsel -fork &' >> $HOME/.xprofile
	echo '#start-pulseaudio-x11 &' >> $HOME/.xprofile
	echo '#blueberry-tray &' >> $HOME/.xprofile	
	echo '#setxkbmap -option caps:ctrl_modifier &' >> $HOME/.xprofile
	echo '#unclutter -idle 2 -jitter 2 -root &' >> $HOME/.xprofile
}

function setup_i3wm() {
	echo -e "#exec i3" >> $HOME/.xinitrc
	echo -e "[Desktop]\nSession=i3\n" > $HOME/.dmrc
	
	mkdir -p $HOME/.config/i3
	cp -f /etc/i3/config $HOME/.config/i3/

	sed -i 's/\(bindsym Mod1+d exec\) \(dmenu_run\)/\1 --no-startup-id \2/g' $HOME/.config/i3/config
	sed -i 's/\(exec i3-config-wizard\)/#\1/g' $HOME/.config/i3/config
	sed -i 's/# \(bindsym Mod1+\)\(d exec --no-startup-id i3-dmenu-desktop\)/\1Shift+\2/g' $HOME/.config/i3/config
	sed -i 's/\(set \$mod\) Mod4/\1 Mod1/g' $HOME/.config/i3/config
	sed -i '/^bar {$/ a\\t#mode hide\n\t#hidden_state hide\n\tmodifier Mod1' $HOME/.config/i3/config
	sed -i '/^bar {$/ a\\t#tray_output primary' $HOME/.config/i3/config
	#sed -i 's/^\(font pango:\).*/\1Ubuntu Mono 14/g' $HOME/.config/i3/config
	sed -i '/^font pango.*/a#font pango:Ubuntu Mono 14' $HOME/.config/i3/config
	
	echo 'bindsym Mod1+Shift+h bar mode toggle' >> $HOME/.config/i3/config
	echo -e '\n#\nworkspace_layout tabbed\ndefault_orientation vertical' >> $HOME/.config/i3/config
	echo 'for_window [window_role="pop-up"] floating enable' >> $HOME/.config/i3/config
	echo 'for_window [title="File Operation Progress"] floating enable' >> $HOME/.config/i3/config
	echo '#for_window [class="Chromium"] floating disable' >> $HOME/.config/i3/config
	
	sed -i '/^# kill focused window/abindsym Mod1+Shift+x exec xdotool getwindowfocus windowkill' $HOME/.config/i3/config
	
	echo 'bindsym Mod1+Control+Shift+s exec systemctl suspend' >> $HOME/.config/i3/config
	echo 'bindsym Mod1+Control+Shift+h exec systemctl hibernate' >> $HOME/.config/i3/config
}

function setup_i3blocks() {
	sed -i 's/\(status_command \)i3status/\1i3blocks/g' $HOME/.config/i3/config

	mkdir -p $HOME/.config/i3blocks
	echo -n '' >  $HOME/.config/i3blocks/config
	
	echo -e '\n[cpu]\ncolor=#FFFFFF\ncommand=mpstat -P ALL 1 1 |  awk '"'"'/Average:/ && $2 ~ /[0-9]/ {printf "%.0f\\x25 ",100-$12}'"'"'|awk '"'"'$1=$1'"'"'\ninterval=10' >> $HOME/.config/i3blocks/config
	echo -e '\n[memory_free]\ncolor=#FDEDAA\ncommand=awk '"'"'/MemAvailable/ {printf("%d\\xcb\\x96\\n", ($2/1000))}'"'"' /proc/meminfo\ninterval=2' >> $HOME/.config/i3blocks/config
	echo -e '\n#[memory_used]\n#color=#FFDDCC\n#command=awk '"'"'/MemTotal|MemAvailable/ {print $2}'"'"' /proc/meminfo | paste -sd'"'"' '"'"' | awk '"'"'{printf "%d\\xcb\\x97\\n",($1-$2)/1000}'"'"'\n#interval=2' >> $HOME/.config/i3blocks/config
	echo -e '\n#[swap_free]\n#command=awk '"'"'/SwapTotal|SwapFree/ {print $2}'"'"' /proc/meminfo | paste -sd'"'"' '"'"' | awk '"'"'{printf "<span color=\\"%s\\">%d\\xcb\\x96</span>\\n",$1=="0"?"#555555":"#FFDDCC",$2/1000}'"'"'\n#interval=2\n#markup=pango' >> $HOME/.config/i3blocks/config
	echo -e '\n[swap_used]\ncommand=awk '"'"'/SwapTotal|SwapFree/ {print $2}'"'"' /proc/meminfo | paste -sd'"'"' '"'"' | awk '"'"'{printf "<span color=\\"%s\\">%d\\xcb\\x97</span>\\n",$1=="0"?"#555555":"#FFDDCC",($1-$2)/1000}'"'"'\ninterval=2\nmarkup=pango' >> $HOME/.config/i3blocks/config
	echo -e '\n[temp]\ncolor=#85C1E9\ncommand=cat /sys/class/thermal/thermal_zone*/temp | awk '"'"'$1 {printf "%.0f\\xc2\\xb0 ",$1/1000}'"'"'|awk '"'"'$1=$1'"'"'\ninterval=2' >> $HOME/.config/i3blocks/config
	echo -e '\n[time]\ncommand=date "+%a %d %b, %I:%M %p"\ninterval=5' >> $HOME/.config/i3blocks/config
	echo -e '\n#[battery]\n#color=#58D68D\n#command=cat /sys/class/power_supply/BAT1/status /sys/class/power_supply/BAT1/capacity | tr "\\n" " " | awk '"'"'$1 $2 {printf "<span color=\\"%s\\">\\xe2\\x9a\\xa1</span>%s%%", $1=="Charging"?"yellow":"light grey",$2}'"'"'\n#interval=2\n#markup=pango' >> $HOME/.config/i3blocks/config
	echo -e '\n[volume]\ncommand=amixer -c 0 -M -D pulse get Master | sed "s/[][]//g" | awk '"'"'/Front Left:.+/ {printf "<span color=\\"%s\\">\\xE2\\x99\\xAA</span>%s\\n", $6=="off"?"grey":"#FFFFFF",$5}'"'"'\ninterval=5\nmarkup=pango' >> $HOME/.config/i3blocks/config
}

function setup_terminator() {
	mkdir -p $HOME/.config/terminator $HOME/.config/xfce4
	echo -e '[global_config]\n  inactive_color_offset = 1.0\n[keybindings]\n  full_screen = ""\n   help = ""\n[profiles]\n [[default]]\n  show_titlebar = False\n  scrollbar_position = disabled' > $HOME/.config/terminator/config
	echo 'TerminalEmulator=terminator' >> $HOME/.config/xfce4/helpers.rc
}

function setup_thunar() {
	mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
	echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="thunar" version="1.0">\n\t<property name="last-show-hidden" type="bool"\nvalue="true"/>\n\t<property name="last-view" type="string" value="ThunarDetailsView"/>\n</channel>' >> $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
}

function setup_vlc() {
	mkdir -p $HOME/.config/vlc
	echo -e "[qt4]\nqt-recentplay=0\nqt-privacy-ask=0\n\n[core]\nvideo-title-show=0\nplay-and-exit=1\none-instance-when-started-from-file=0\nsnapshot-path=$HOME/Pictures\nsnapshot-prefix=$N_[$T]_\nsnapshot-sequential=1\nkey-vol-up=Ctrl+Up\nkey-vol-down=Ctrl+Down\nkey-vol-mute=m\nkey-stop=\nkey-snapshot=s\nstats=0\nstereo-mode=1" > $HOME/.config/vlc/vlcrc
	echo -e '[MainWindow]\nstatus-bar-visible=true' > $HOME/.config/vlc/vlc-qt-interface.conf
}

function setup_scite() {
	
	echo '' > $HOME/.SciTEUser.properties



	#echo -e 'selection.back=#CCBDFF\nselection.alpha=50\nselection.layer=1\n' >> $HOME/.SciTEUser.properties
	#echo -e 'caret.line.back=#CCDDFF\ncaret.fore=#FFFFFF\n' >> $HOME/.SciTEUser.properties
	#echo -e 'highlight.current.word=1\nhighlight.current.word.indicator=style:straightbox,colour:#FFBBDD,fillalpha:255,under\nstyle.*.34=back:#51DAEA\n' >> $HOME/.SciTEUser.properties


	echo -e 'selection.back=#227733\nselection.alpha=50\nselection.layer=1\n' >> $HOME/.SciTEUser.properties
	echo -e 'caret.line.back=#444444\n' >> $HOME/.SciTEUser.properties
	echo -e 'highlight.current.word=1\nhighlight.current.word.indicator=style:straightbox,colour:#777777,fillalpha:255,under\nstyle.*.34=back:#22AAFF\n' >> $HOME/.SciTEUser.properties
	echo -e 'style.*.32=$(font.base),back:#101010,fore:#BBBBDD\nstyle.*.33=$(font.base),back:#101010\n' >> $HOME/.SciTEUser.properties
	echo -e 'font.base=font:Verdana,size:16\nfont.small=font:Verdana,size:14\nfont.comment=font:Georgia,size:16\n' >> $HOME/.SciTEUser.properties

	echo -e 'check.if.already.open=1\nload.on.activate=1\nquit.on.close.last=1\n' >> $HOME/.SciTEUser.properties
	echo -e 'open.filter=$(all.files)\n' >> $HOME/.SciTEUser.properties
	echo -e 'statusbar.visible=1\ntitle.full.path=1\ntoolbar.visible=0\n' >> $HOME/.SciTEUser.properties
	echo -e 'line.margin.visible=1\nline.margin.width=1+\noutput.wrap=1\nwrap=1\n' >> $HOME/.SciTEUser.properties
	echo -e 'save.session=1\nsave.recent=0\nsave.find=1\nsave.position=1\n' >> $HOME/.SciTEUser.properties
	echo -e '\nindent.size=4\ntabsize=4\nuse.tabs=0\n' >> $HOME/.SciTEUser.properties
	echo -e 'use.tabs.$(file.patterns.make)=1\n' >> $HOME/.SciTEUser.properties
	echo -e '\nstatusbar.text.1=pos=$(CurrentPos),li=$(LineNumber), co=$(ColumnNumber) [$(EOLMode)]\next.lua.startup.script=$(SciteUserHome)/.SciTEStartup.lua\n' >> $HOME/.SciTEUser.properties
	echo -e 'function OnUpdateUI() props["CurrentPos"]=editor.CurrentPos end' > $HOME/.SciTEStartup.lua



	sed -i "s/\(file\.patterns\.cpp=.*\)/\1;*.glsl/g" /usr/share/scite/cpp.properties
	sed -i "s/\(file\.patterns\.lisp=.*\)/\1;*.el/g" /usr/share/scite/lisp.properties
	sed -i "s/\(file\.patterns\.scheme=.*\)/\1;*.rkt/g" /usr/share/scite/lisp.properties


 
	mkdir -p /usr/local/share/applications
	echo -e '[Desktop Entry]\nName=SciTE New Window\nType=Application\nExec=SciTE -check.if.already.open=0 %F\nIcon=Sci48M\nMimeType=text/plain;' > /usr/local/share/applications/scitenew.desktop
	echo -e '[Desktop Entry]\nName=SciTE as Root\nType=Application\nExec=gksudo -k "SciTE -check.if.already.open=0 %F"\nIcon=Sci48M\nMimeType=text/plain;' > /usr/local/share/applications/sciteroot.desktop
	sed -i 's/rust //g' /usr/share/scite/SciTEGlobal.properties
}

function setup_gtk() {
	mkdir -p  $HOME/.config/gtk-2.0 $HOME/.config/gtk-3.0
	mkdir -p $HOME/Desktop $HOME/Documents $HOME/Downloads $HOME/Pictures $HOME/Videos
	
	echo 'gtk-recent-files-max-age=0' >> $HOME/.config/gtk-2.0/gtkrc
	echo -e '[Settings]\ngtk-recent-files-max-age=0\ngtk-recent-files-limit=0' > $HOME/.config/gtk-3.0/settings.ini
	echo -e "file://$HOME/Documents Documents\nfile://$HOME/Downloads Downloads\nfile://$HOME/Pictures Pictures\nfile://$HOME/Videos Videos\nfile:///tmp tmp" >> $HOME/.config/gtk-3.0/bookmarks	
	for d in /mnt/* ; do echo "file://$d $(basename "$d")" >> $HOME/.config/gtk-3.0/bookmarks; done
	echo -e '[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nShowSizeColumn=true\nSortColumn=name\nSortOrder=ascending\nStartupMode=recent' > $HOME/.config/gtk-2.0/gtkfilechooser.ini
}

function setup_shortcuts() {
	echo 'xbindkeys -p &' >> $HOME/.xprofile
	
	echo -e '"chromium"\nMod4+b\n' >> $HOME/.xbindkeysrc
	echo -e '"thunar"\nMod4+f\n' >> $HOME/.xbindkeysrc
	echo -e '"scite"\nMod4+s\n' >> $HOME/.xbindkeysrc
	echo -e '"lxtask"\nControl+Shift+Escape\n' >> $HOME/.xbindkeysrc
	
	echo -e '"moonlight"\nMod4+m\n' >> $HOME/.xbindkeysrc	
	echo -e '"imlib2_grab ~/Pictures/screenshot_$(date +%Y_%m_%d_%H_%M_%S_%3N).png"\nMod4+p\n' >> $HOME/.xbindkeysrc
}

function setup_viewnior() {
	mkdir -p $HOME/.config/viewnior
	echo -e '[prefs]\nzoom-mode=3\nfit-on-fullscreen=true\nshow-hidden=true\nsmooth-images=true\nconfirm-delete=true\nreload-on-save=true\nshow-menu-bar=false\nshow-toolbar=true\nstart-maximized=false\nslideshow-timeout=5\nauto-resize=false\nbehavior-wheel=2\nbehavior-click=0\nbehavior-modify=2\njpeg-quality=100\npng-compression=9\ndesktop=1\n' > $HOME/.config/viewnior/viewnior.conf
}

function setup_wine() {
	useradd -m -U -G users -s /bin/bash wineuser
		
	echo -e '\n#\nALL ALL=(wineuser) NOPASSWD: ALL' >> /etc/sudoers
	echo -e 'xhost +SI:localuser:wineuser &' >> $HOME/.xprofile

	mkdir -p /home/wineuser/.config/pulse
	echo 'default-server = unix:/tmp/pulse-socket' >> /home/wineuser/.config/pulse/client.conf

	mkdir -p /usr/local/share/applications
	echo -e '[Desktop Entry]\nType=Application\nName=Run as wine\nExec=/usr/local/bin/runasuser wineuser wine start /unix %f\nMimeType=application/x-ms-dos-executable;application/x-msi;application/x-ms-shortcut;\nIcon=wine' > /usr/local/share/applications/runaswine.desktop
	
	chmod -R o=rwx /home/wineuser
	setfacl -R -d -m o::rwx /home/wineuser
}

function setup_mount_iso_shortcut() {
	echo -e '[Desktop Entry]\nType=Application\nName=Mount ISO\nExec=/usr/bin/udisksctl loop-setup --no-user-interaction -r -f %f\nMimeType=application/octetstream;\nIcon=package-x-generic' > /usr/local/share/applications/mountiso.desktop

	#udisksctl mount -b $( | grep -Po '/dev/loop[0-9]+')
}

function setup_packages() {
	packages=""
	packages+=" xorg-server xorg-xinit xcursor-themes"
	packages+=" xf86-video-vesa xf86-video-fbdev"
	packages+=" xf86-input-synaptics network-manager-applet"

	#packages+=" xf86-video-intel"
	#packages+=" xf86-video-nouveau"
	#packages+=" xf86-video-ati"

	packages+=" xorg-xprop xclip numlockx xautolock xcursor-vanilla-dmz gksu pavucontrol xbindkeys"
	packages+=" unclutter"

	packages+=" tigervnc"
	packages+=" x11vnc tk autocutsel"

	packages+=" ttf-dejavu ttf-sazanami"
	packages+=" unrar unzip unace lrzip"

	packages+=" lightdm lightdm-gtk-greeter"
	packages+=" i3 dmenu i3blocks sysstat"
	packages+=" lxtask terminator scite"
	packages+=" thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman"
	packages+=" ffmpegthumbnailer tumbler gamin gvfs-smb polkit-gnome"
	packages+=" file-roller viewnior evince chromium vlc imlib2"
	#packages+=" fbreader mcomix pinta libreoffice-en-GB"
	#packages+=" vbindiff"

	packages+=" cups system-config-printer"
	#packages+=" foomatic-db-nonfree splix gutenprint hplip"
	
	#packages+=" blueberry"
	
	packages+=" wine winetricks wine_gecko wine-mono lib32-mpg123 lib32-ncurses lib32-libpulse xorg-xhost lib32-gnutls wmctrl zenity lib32-openal lib32-libldap lib32-gstreamer"
	#packages+=" qemu qemu-arch-extra gnome-boxes"
	
	#packages+=" emacs python racket chicken swi-prolog texlive-most"
	
	pacman -S --needed --noconfirm $packages
}

function install_all() {
	setup_packages
	setup_lightdm
	setup_mousepad
	setup_theme
	setup_x11vnc
	setup_tigervnc
	setup_scite
	setup_xserver
	setup_i3wm
	setup_i3blocks
	setup_terminator
	setup_thunar
	setup_vlc
	setup_gtk
	setup_shortcuts
	setup_viewnior
	setup_cups
	setup_wine
	setup_mount_iso_shortcut
	#setup_tmpcache
}

trap 'echo "Error on line $LINENO"' ERR
set -e

if [ $SUDO_USER ]; then
	HOME=/home/$SUDO_USER
	USER=$SUDO_USER
fi

if [ $1 ]; then
	eval $1
	echo "'$1' run successfully!"
else
	install_all
	echo "install completed successfully!"
fi
