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
	echo -e '#!/bin/bash\n\nx11vnc -many -display :0 -rfbauth ~/.vnc/x11vnc_passwd -noscr -noxrecord -gui tray -o ~/.vnc/x11vnc_log.%VNCDISPLAY' > /usr/local/bin/x11vnc_start.sh
	echo -e '#!/bin/bash\n\nif [ $1 ]; then\n\tmkdir -p ~/.vnc\n\tx11vnc -storepasswd $1 ~/.vnc/x11vnc_passwd\nfi' > /usr/local/bin/x11vnc_passwd.sh
	chmod +xr /usr/local/bin/x11vnc_start.sh
	chmod +xr /usr/local/bin/x11vnc_passwd.sh
}

function setup_tigervnc() {
	echo -e '#!/bin/bash\n\nif [ $1 ]; then\n\tmkdir -p ~/.vnc\n\techo $1 | vncpasswd -f > ~/.vnc/client_passwd\nfi\n\nvncviewer passwd=~/.vnc/client_passwd' > /usr/local/bin/tigervnc.sh
	chmod +xr /usr/local/bin/tigervnc.sh
}

function setup_tigervnc_local() {
	mkdir -p $HOME/.vnc
	echo -e 'TigerVNC Configuration file Version 1.0\n\nDotWhenNoCursor=1\nRemoteResize=1\nMenuKey=' > $HOME/.vnc/default.tigervnc
}

function setup_cups() {
	systemctl enable org.cups.cupsd.service
}

function setup_tmpcache() {
	mkdir -p $HOME/.cache $HOME/.thumbnails $HOME/.local/share/gvfs-metadata
	echo -e "\n#" >> /etc/fstab
	echo "/tmp /$HOME/.cache none defaults,bind 0 0" >> /etc/fstab
	echo "/tmp /$HOME/.thumbnails none defaults,bind 0 0" >> /etc/fstab
	echo "/tmp /$HOME/.local/share/gvfs-metadata none defaults,bind 0 0" >> /etc/fstab
}

function setup_xserver_local() {
	echo -e '#!/bin/sh\n\nif [ -d /etc/X11/xinit/xinitrc.d ]; then\n\tfor f in /etc/X11/xinit/xinitrc.d/*; do\n\t\t[ -x "$f" ] && . "$f"\n\tdone\n\tunset f\nfi\n\n' > $HOME/.xinitrc
	
	echo -e '[[ -f ~/.bashrc ]] && . ~/.bashrc\n#[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' > $HOME/.bash_profile
	
	echo "#xmodmap -e 'pointer = 1 10 3 4 5 6 7 8 9 2 11 12 13 14 15 16 17 18 19 20 21 22 23 24' &" >> $HOME/.xprofile
	echo '#xrandr --output HDMI1 --auto --primary --output HDMI2 --auto --right-of HDMI1 &' >> $HOME/.xprofile
	echo '#xrandr --output HDMI-2 --auto --primary --output HDMI-1 --auto --right-of HDMI-2 --rotate inverted &' >> $HOME/.xprofile
	echo '#xrandr -s 0 &' >> $HOME/.xprofile
	echo "#xautolock -detectsleep -time 45 -locker 'systemctl hybrid-sleep' &" >> $HOME/.xprofile
	echo '#system-config-printer-applet &' >> $HOME/.xprofile
	echo '#nm-applet &' >> $HOME/.xprofile
	echo '#x11vnc_start.sh &' >> $HOME/.xprofile
	echo '#autocutsel -fork &' >> $HOME/.xprofile
	echo '#start-pulseaudio-x11 &' >> $HOME/.xprofile
}

function setup_i3wm_local() {
	echo -e "#exec i3" >> $HOME/.xinitrc
	echo -e "[Desktop]\nSession=i3\n" > $HOME/.dmrc
	
	mkdir -p $HOME/.config/i3
	cp -f /etc/i3/config $HOME/.config/i3/

	sed -i 's/\(bindsym Mod1+d exec\) \(dmenu_run\)/\1 --no-startup-id \2/g' $HOME/.config/i3/config
	sed -i 's/\(exec i3-config-wizard\)/#\1/g' $HOME/.config/i3/config
	sed -i 's/# \(bindsym Mod1+\)\(d exec --no-startup-id i3-dmenu-desktop\)/\1Shift+\2/g' $HOME/.config/i3/config
	sed -i 's/\(set \$mod\) Mod4/\1 Mod1/g' $HOME/.config/i3/config
	sed -i "/^bar {$/ a\\\t#tray_output primary" $HOME/.config/i3/config
	#sed -i 's/^\(font pango:\).*/\1Ubuntu Mono 14/g' $HOME/.config/i3/config
	sed -i '/^font pango.*/a#font pango:Ubuntu Mono 14' $HOME/.config/i3/config

	echo -e '\n#\nworkspace_layout stacking\ndefault_orientation vertical' >> $HOME/.config/i3/config
	echo 'for_window [window_role="pop-up"] floating enable' >> $HOME/.config/i3/config
	echo '#for_window [class="Chromium"] floating disable' >> $HOME/.config/i3/config
}

function setup_i3status_local() {
	mkdir -p $HOME/.config/i3status
	
	echo -e 'general {\n\tcolors = true\n\tinterval = 10\n}\n\ncpu_usage {\n\tformat = "%usage"\n}\n\ncpu_temperature 0 {\n\tformat = "%degrees\\xc2\\xb0C"\n#\tpath = "/sys/devices/platform/coretemp.0/temp3_input"\n}\n\nbattery 0 {\n\tlast_full_capacity = true\n\tformat="%percentage %remaining"\n\tpath="/sys/class/power_supply/BAT1/uevent"\n\tlow_threshold=5\n\tthreshold_type=percentage\n\thide_seconds = true\n\tinteger_battery_capacity=true\n}\n\ntime {\n\tformat = "%a %d %b, %I:%M %p"\n}\n\nvolume master {\n\tformat = "\\xE2\\x99\\xAA %volume"\n\tformat_muted = "\\xE2\\x99\\xAA %volume"\n\tdevice = "default"\n\tmixer = "Master"\n\tmixer_idx = 0\n}\n\n\norder += "cpu_usage"\n\n#order += "cpu_temperature 0"\n\n#order += "battery 0"\n\norder += "time"\n\norder += "volume master"\n' >> $HOME/.config/i3status/config
}

function setup_terminator_local() {
	mkdir -p $HOME/.config/terminator $HOME/.config/xfce4
	echo -e "[config]\n  inactive_color_offset = 1.0\n[profiles]\n [[default]]\n  show_titlebar = False\n  scrollbar_position = disabled" > $HOME/.config/terminator/config
	echo 'TerminalEmulator=terminator' >> $HOME/.config/xfce4/helpers.rc
}

function setup_thunar_local() {
	mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
	echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="thunar" version="1.0">\n\t<property name="last-show-hidden" type="bool"\nvalue="true"/>\n\t<property name="last-view" type="string" value="ThunarDetailsView"/>\n</channel>' >> $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
}

function setup_vlc_local() {
	mkdir -p $HOME/.config/vlc
	echo -e "[qt4]\nqt-recentplay=0\nqt-privacy-ask=0\n\n[core]\nvideo-title-show=0\nplay-and-exit=1\none-instance-when-started-from-file=0\nsnapshot-path=$HOME/Pictures\nkey-vol-up=Ctrl+Up\nkey-vol-down=Ctrl+Down\nkey-vol-mute=m" > $HOME/.config/vlc/vlcrc
	echo -e '[MainWindow]\nstatus-bar-visible=true' > $HOME/.config/vlc/vlc-qt-interface.conf
}

function setup_scite() {
	sed -i "s/\(file\.patterns\.cpp=.*\)/\1;*.glsl/g" /usr/share/scite/cpp.properties
	sed -i "s/\(file\.patterns\.lisp=.*\)/\1;*.el/g" /usr/share/scite/lisp.properties
	sed -i "s/\(file\.patterns\.scheme=.*\)/\1;*.rkt/g" /usr/share/scite/lisp.properties
}

function setup_scite_local() {
	echo -e 'check.if.already.open=1\nline.margin.visible=1\nline.margin.width=1+\nload.on.activate=1\nopen.filter=$(all.files)\noutput.wrap=1\nsave.session=1\nsave.recent=1\nsave.find=1\nstatusbar.visible=1\ntitle.full.path=1\ntoolbar.visible=1\nquit.on.close.last=1\nwrap=1' > $HOME/.SciTEUser.properties

	echo -e 'selection.back=#000000\nselection.alpha=50' >> $HOME/.SciTEUser.properties
	echo -e 'caret.line.back=#CCDDFF' >> $HOME/.SciTEUser.properties
	echo -e 'highlight.current.word=1\nhighlight.current.word.indicator=style:straightbox,colour:#FEE155,fillalpha:190,under' >> $HOME/.SciTEUser.properties
	echo -e 'style.*.34=back:#51DAEA' >> $HOME/.SciTEUser.properties

	echo -e '\nindent.size=4\ntabsize=4\nuse.tabs=0\nuse.tabs.$(file.patterns.make)=1' >> $HOME/.SciTEUser.properties

	echo -e '\nstatusbar.text.1=pos=$(CurrentPos),li=$(LineNumber), co=$(ColumnNumber) [$(EOLMode)]\next.lua.startup.script=$(SciteUserHome)/.SciTEStartup.lua' >> $HOME/.SciTEUser.properties
	echo -e 'function OnUpdateUI() props["CurrentPos"]=editor.CurrentPos end' > $HOME/.SciTEStartup.lua
}

function setup_gtk_local() {
	mkdir -p  $HOME/.config/gtk-2.0 $HOME/.config/gtk-3.0
	mkdir -p $HOME/Desktop $HOME/Documents $HOME/Downloads $HOME/Pictures $HOME/Videos
	
	echo 'gtk-recent-files-max-age=0' >> $HOME/.gtkrc-2.0
	echo -e '[Settings]\ngtk-recent-files-max-age=0\ngtk-recent-files-limit=0' > $HOME/.config/gtk-3.0/settings.ini
	echo -e "file://$HOME/Documents Documents\nfile://$HOME/Downloads Downloads\nfile://$HOME/Pictures Pictures\nfile://$HOME/Videos Videos\nfile:///tmp tmp" >> $HOME/.config/gtk-3.0/bookmarks	
	for d in /mnt/* ; do echo "file://$d $(basename "$d")" >> $HOME/.config/gtk-3.0/bookmarks; done
	echo -e '[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nShowSizeColumn=true\nSortColumn=name\nSortOrder=ascending\nStartupMode=recent' > $HOME/.config/gtk-2.0/gtkfilechooser.ini
}

function setup_shortcuts_local() {
	echo 'xbindkeys -p &' >> $HOME/.xprofile
	echo -e '"chromium"\nMod4+b\n\n"thunar"\nMod4+g\n\n"nemo --no-desktop"\nMod4+f\n\n"scite"\nMod4+s\n\n"lxtask"\nControl+Shift+Escape' > $HOME/.xbindkeysrc
}

function setup_viewnior_local() {
	mkdir -p $HOME/.config/viewnior
	echo -e '[prefs]\nzoom-mode=3\nfit-on-fullscreen=true\nshow-hidden=true\nsmooth-images=true\nconfirm-delete=true\nreload-on-save=true\nshow-menu-bar=false\nshow-toolbar=true\nstart-maximized=false\nslideshow-timeout=5\nauto-resize=false\nbehavior-wheel=2\nbehavior-click=0\nbehavior-modify=2\njpeg-quality=100\npng-compression=9\ndesktop=1\n' > $HOME/.config/viewnior/viewnior.conf
}

function install_all() {
	packages="xorg-server xorg-xinit xcursor-themes"
	packages+=" xf86-video-vesa xf86-video-fbdev"
	packages+=" xf86-input-synaptics network-manager-applet"

	#packages+=" xf86-video-intel"
	#packages+=" xf86-video-nouveau"
	#packages+=" xf86-video-ati"

	packages+=" xorg-xprop xclip numlockx xautolock xcursor-vanilla-dmz gksu pavucontrol xbindkeys"

	packages+=" tigervnc"
	packages+=" x11vnc tk autocutsel"

	packages+=" ttf-dejavu ttf-sazanami"
	packages+=" unrar unzip unace lrzip"

	packages+=" lightdm lightdm-gtk-greeter"
	packages+=" i3 dmenu"
	packages+=" lxtask terminator scite"
	packages+=" thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman"
	packages+=" ffmpegthumbnailer tumbler gamin gvfs-smb polkit-gnome"
	packages+=" file-roller viewnior fbreader evince chromium vlc"

	packages+=" cups system-config-printer"
	#packages+=" foomatic-db-nonfree splix gutenprint hplip"
	#packages+=" pinta"
	packages+=" libreoffice-en-GB"
	
	pacman -S --needed --noconfirm $packages
	
	setup_lightdm
	setup_mousepad
	setup_theme
	setup_x11vnc
	setup_tigervnc
	setup_tigervnc_local
	setup_scite
	setup_scite_local
	setup_xserver_local
	setup_i3wm_local
	setup_i3status_local
	setup_terminator_local
	setup_thunar_local
	setup_vlc_local
	setup_gtk_local
	setup_shortcuts_local
	setup_viewnior_local
	setup_cups
	#setup_tmpcache
}

err_report() {
	echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

set -e

if [ $SUDO_USER ]; then
	HOME=/home/$SUDO_USER
	USER=$SUDO_USER
fi

if [ $1 ]; then
	args=""
	for (( i=2;$i<=$#;i=$i+1 )); do args+=" ${!i}"; done
	eval $1 $args
	echo "$1 run successfully!"
else
	install_all
	echo "install completed successfully!"
fi
