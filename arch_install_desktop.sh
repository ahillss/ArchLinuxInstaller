
mylogin=`ls /home | head -n 1`
	
packages+=" xorg-server xorg-xinit xcursor-themes"
packages+=" xf86-video-vesa xf86-video-fbdev"
packages+=" xf86-input-synaptics network-manager-applet"

#packages+=" xf86-video-intel"
#packages+=" xf86-video-nouveau"
#packages+=" xf86-video-ati"

packages+=" xclip numlockx xautolock xcursor-vanilla-dmz gksu pavucontrol"

packages+=" tigervnc"
packages+=" x11vnc tk"

packages+=" ttf-dejavu ttf-sazanami"
packages+=" unrar unzip unace lrzip"

packages+=" lightdm lightdm-gtk-greeter"
packages+=" i3 dmenu"
packages+=" lxtask terminator scite"
packages+=" thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman"
packages+=" nemo nemo-fileroller nemo-share nemo-preview"
packages+=" ffmpegthumbnailer tumbler gamin gvfs-smb polkit-gnome"
packages+=" file-roller viewnior pinta fbreader evince chromium vlc"
#packages+=" libreoffice-writer libreoffice-en-GB"

packages+=" cups system-config-printer foomatic-db-nonfree splix gutenprint hplip"

#packages+=" winetricks zenity wine mpg123 wmctrl lib32-ncurses"
#packages+=" python swi-prolog racket emacs emacs-php-mode emacs-lua-mode"
#packages+=" git mercurial svn cvs bzr premake cmake scons"
#packages+=" texlive-most erlang ocaml ghc emacs-haskell-mode lua sbt scala apache-ant sbcl bigloo boost clang chicken"

#packages+= " ht radare2 binutils"

function setup_apps() {
	setup_xserver
	setup_x11vnc vncpassw
	setup_tigervnc
	setup_xautolock
	setup_whitecursor
	setup_mousepad
	setup_lightdm
	setup_gtk
	setup_scite
	setup_terminator
	setup_vlc
	setup_thunar
	setup_nemo
	
	setup_cups
	
	setup_i3wm
	setup_i3status
	
	#setup_cache_tmp
}

###################################################
err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

set -e

HOME=/home/$mylogin
installer=$(dirname $0)/$(basename $0)

#sudo -- sh -c ""

function all() {
	pacman -S --needed --noconfirm $packages
	setup_apps
	
	chown -R $mylogin $HOME
	chown $mylogin $installer
	chmod 700 $installer
}

function all_chroot() {
	cp -f $installer /mnt
	arch-chroot /mnt /bin/bash -c "bash /$(basename $0) all"
}

function setup_cache_tmp() {
	ln -sf /tmp $HOME/.cache
	chown -h root $HOME/.cache
	
	ln -sf /tmp $HOME/.thumbnails
	chown -h root $HOME/.thumbnails
	
	mkdir -p $HOME/.local/share
	ln -sf /tmp $HOME/.local/share/gvfs-metadata
	chown -h root $HOME/.local/share/gvfs-metadata
}

function setup_xserver() {	
	echo -e '#!/bin/sh\n\nif [ -d /etc/X11/xinit/xinitrc.d ]; then\n  for f in /etc/X11/xinit/xinitrc.d/*; do\n    [ -x "$f" ] && . "$f"\n  done\n  unset f\nfi\n\n' > $HOME/.xinitrc	
	echo '#[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> $HOME/.bash_profile
	
	echo "#xmodmap -e 'pointer = 1 10 3 4 5 6 7 8 9 2 11 12 13 14 15 16 17 18 19 20 21 22 23 24' &" >> $HOME/.xprofile
	echo '#xrandr --output HDMI1 --auto --primary --output HDMI2 --auto --right-of HDMI1 &' >> $HOME/.xprofile
	echo 'nm-applet &' >> $HOME/.xprofile
	echo 'start-pulseaudio-x11 &' >> $HOME/.xprofile
}

function setup_cups() {
	systemctl enable org.cups.cupsd.service
	echo 'system-config-printer-applet &' >> $HOME/.xprofile
}

function setup_x11vnc() {
	mkdir -p $HOME/.vnc
	x11vnc -storepasswd $1 $HOME/.vnc/x11vnc_passwd
	
	echo 'x11vnc -many -display :0 -rfbauth ~/.vnc/x11vnc_passwd -noscr -noxrecord -gui tray -o ~/.vnc/x11vnc_log.%VNCDISPLAY &' >> $HOME/.xprofile
}

function setup_tigervnc() {
	mkdir -p $HOME/.vnc
	echo -e '#!/bin/bash\n\nif [ $1 ]; then\n\techo $1 | vncpasswd -f > ~/.vnc/client_passwd\nfi\n\nvncviewer passwd=~/.vnc/client_passwd' > /usr/local/bin/tigervnc.sh
	chmod +xr /usr/local/bin/tigervnc.sh
}

function setup_xautolock() {
	echo "xautolock -detectsleep -time 45 -locker 'systemctl hybrid-sleep' &" >> $HOME/.xprofile
}

function setup_whitecursor() {
	mkdir -p $HOME/.icons
	ln -sf /usr/share/icons/Vanilla-DMZ/ $HOME/.icons/default
}

function setup_mousepad() {
	cp -f /usr/share/X11/xorg.conf.d/*-synaptics.conf /etc/X11/xorg.conf.d/
	echo -e '\n#\nSection "InputClass"\n        Identifier "Scrolling"\n        Option "VertEdgeScroll" "on"\n        Option "HorizEdgeScroll" "on"\nEndSection\n' >>  /etc/X11/xorg.conf.d/*-synaptics.conf
}

function setup_lightdm() {
	systemctl enable lightdm

	groupadd autologin
	gpasswd -a $mylogin autologin
	#usermod -a -G autologin $mylogin

	sed -i 's/#\(pam-service=lightdm\)/\1/g' /etc/lightdm/lightdm.conf
	sed -i 's/#\(pam-autologin-service=lightdm-autologin\)/\1/g' /etc/lightdm/lightdm.conf
	sed -i "s/#\(autologin-user=\)/\1$mylogin/g" /etc/lightdm/lightdm.conf
	sed -i 's/#\(autologin-user-timeout=0\)/\1/g' /etc/lightdm/lightdm.conf
}

function setup_i3wm() {
	echo -e "\nexec i3" >> $HOME/.xinitrc
	echo -e "[Desktop]\nSession=i3\n" > $HOME/.dmrc
	
	mkdir -p $HOME/.config/i3
	cp -f /etc/i3/config $HOME/.config/i3/

	sed -i 's/\(bindsym Mod1+d exec\) \(dmenu_run\)/\1 --no-startup-id \2/g' $HOME/.config/i3/config
	sed -i 's/\(exec i3-config-wizard\)/#\1/g' $HOME/.config/i3/config
	sed -i 's/# \(bindsym Mod1+\)\(d exec --no-startup-id i3-dmenu-desktop\)/\1Shift+\2/g' $HOME/.config/i3/config
	sed -i 's/\(set \$mod\) Mod4/\1 Mod1/g' $HOME/.config/i3/config
	sed -i "/^bar {$/ a\\\t#tray_output primary" $HOME/.config/i3/config
	echo -e '\n#\nworkspace_layout stacking\ndefault_orientation vertical' >> $HOME/.config/i3/config
	echo 'for_window [window_role="pop-up"] floating enable' >> $HOME/.config/i3/config
	
	echo -e '\n#shortcuts' >> $HOME/.config/i3/config
	echo 'bindsym Control+Shift+Escape exec lxtask' >> $HOME/.config/i3/config
	echo 'bindsym Mod4+b exec chromium' >> $HOME/.config/i3/config
	echo 'bindsym Mod4+f exec nemo --no-desktop' >> $HOME/.config/i3/config
	echo 'bindsym Mod4+g exec thunar' >> $HOME/.config/i3/config
	echo 'bindsym Mod4+s exec scite' >> $HOME/.config/i3/config
}

function setup_i3status() {
	mkdir -p $HOME/.config/i3status
	
	echo -e 'general {\n\tcolors = true\n\tinterval = 10\n}\n' > $HOME/.config/i3status/config
	echo -e 'cpu_usage {\n\tformat = "%usage"\n}\n' >> $HOME/.config/i3status/config
	echo -e 'cpu_temperature 0 {\n\tformat = "%degrees\\xc2\\xb0C"\n#\tpath = "/sys/devices/platform/coretemp.0/temp3_input"\n}\n' >> $HOME/.config/i3status/config
	echo -e 'battery 0 {\n\tlast_full_capacity = true\n\tformat="%percentage %remaining"\n\tpath="/sys/class/power_supply/BAT1/uevent"\n\tlow_threshold=5\n\tthreshold_type=percentage\n\thide_seconds = true\n\tinteger_battery_capacity=true\n}\n' >> $HOME/.config/i3status/config
	echo -e 'time {\n\tformat = "%a %d %b, %I:%M %p"\n}\n' >> $HOME/.config/i3status/config
	echo -e 'volume master {\n\tformat = "\\xE2\\x99\\xAA %volume"\n\tformat_muted = "\\xE2\\x99\\xAA %volume"\n\tdevice = "default"\n\tmixer = "Master"\n\tmixer_idx = 0\n}\n' >> $HOME/.config/i3status/config
	
	echo '' >> $HOME/.config/i3/config
	echo -e 'order += "cpu_usage"\n' >> $HOME/.config/i3status/config
	echo -e 'order += "cpu_temperature 0"\n' >> $HOME/.config/i3status/config
	echo -e '#order += "battery 0"\n' >> $HOME/.config/i3status/config
	echo -e 'order += "time"\n' >> $HOME/.config/i3status/config
	echo -e 'order += "volume master"\n' >> $HOME/.config/i3status/config
}

function setup_gtk() {
	mkdir -p  $HOME/.config/gtk-2.0 $HOME/.config/gtk-3.0
	mkdir -p $HOME/Documents $HOME/Downloads $HOME/Pictures $HOME/Desktop
	
	echo 'gtk-recent-files-max-age=0' >> $HOME/.gtkrc-2.0
	echo -e '[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nShowSizeColumn=true\nSortColumn=name\nSortOrder=ascending\nStartupMode=recent' > $HOME/.config/gtk-2.0/gtkfilechooser.ini
	echo -e '[Settings]\ngtk-recent-files-max-age=0\ngtk-recent-files-limit=0' > $HOME/.config/gtk-3.0/settings.ini
	
	echo "file:///$HOME/Documents Documents" >> $HOME/.config/gtk-3.0/bookmarks
	echo "file:///$HOME/Downloads Downloads" >> $HOME/.config/gtk-3.0/bookmarks
	echo "file:///$HOME/Pictures Pictures" >> $HOME/.config/gtk-3.0/bookmarks
	
	echo "file:///tmp tmp" >> $HOME/.config/gtk-3.0/bookmarks
	
	#for d in /mnt ; do 
	#	if [ -d $d ]; then
	#		echo "file://$d $(basename "$d")" >> $HOME/.config/gtk-3.0/bookmarks ;
	#	fi
	#done
}

function setup_scite() {
	echo -e 'load.on.activate=1\nquit.on.close.last=1\ncheck.if.already.open=1' >> $HOME/.SciTEUser.properties
	echo -e 'open.filter=$(all.files)\nfile.patterns.lisp=$(file.patterns.lisp);.emacs;*.el' >> $HOME/.SciTEUser.properties
	echo -e 'title.full.path=1\ntoolbar.visible=1\nstatusbar.visible=1' >> $HOME/.SciTEUser.properties
	echo -e 'save.session=1\nsave.recent=1\nsave.find=1' >> $HOME/.SciTEUser.properties
	echo -e 'wrap=1\noutput.wrap=1\nwrap.style=1' >> $HOME/.SciTEUser.properties
	echo -e 'line.margin.visible=1\nline.margin.width=1+' >> $HOME/.SciTEUser.properties
	echo -e 'caret.line.back=#6BC9A8\ncaret.line.back.alpha=50' >> $HOME/.SciTEUser.properties
	echo -e 'selection.back=#f21b1b\nselection.alpha=75' >> $HOME/.SciTEUser.properties
	echo -e 'highlight.current.word=1\nhighlight.current.word.colour=#2635DE\nhighlight.current.word.alpha=75\nhighlight.current.word.by.style=1' >> $HOME/.SciTEUser.properties
	echo -e 'indicators.alpha=100\nindicators.under=1' >> $HOME/.SciTEUser.properties
	echo -e 'style.*.34=fore:#000000,back:#A1A4ED,bold\nstyle.*.35=fore:#000000,back:#A1A4ED,bold' >> $HOME/.SciTEUser.properties
	echo -e 'statusbar.text.1=pos=$(CurrentPos), li=$(LineNumber), co=$(ColumnNumber) [$(EOLMode)]' >> $HOME/.SciTEUser.properties
	echo -e 'function OnUpdateUI() props["CurrentPos"]=editor.CurrentPos end' > $HOME/SciTEStartup.lua
	
	cp $HOME/.SciTEUser.properties $HOME/SciTEStartup.lua /root/
	
	echo -e '#!/bin/bash\ngksudo "scite -check.if.already.open=0"' > /usr/local/bin/sciteroot.sh
	chmod o+rx /usr/local/bin/sciteroot.sh
}

function setup_terminator() {
	mkdir -p $HOME/.config/terminator /usr/share/xfce4/helpers $HOME/.config/xfce4
	echo -e "[global_config]\n  inactive_color_offset = 1.0\n[profiles]\n [[default]]\n  show_titlebar = False\n  scrollbar_position = disabled" > $HOME/.config/terminator/config
	echo -e "[Desktop Entry]\nIcon=terminator\nType=X-XFCE-Helper\nName=Terminator\nX-XFCE-Binaries=terminator;\nX-XFCE-Category=TerminalEmulator\nX-XFCE-Commands=%B;\nX-XFCE-CommandsWithParameter=%B -x %s;" > /usr/share/xfce4/helpers/terminator.desktop
	echo 'TerminalEmulator=terminator' >> $HOME/.config/xfce4/helpers.rc
}

function setup_thunar() {
	mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
	echo -e '<?xml version="1.0" encoding="UTF-8"?>
<channel name="thunar" version="1.0">
  <property name="last-show-hidden" type="bool" value="true"/>
  <property name="last-view" type="string" value="ThunarDetailsView"/>
</channel>' >> $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
}

function setup_nemo() {
	gsettings set org.cinnamon.desktop.default-applications.terminal exec terminator
	gsettings set org.nemo.desktop show-desktop-icons false
}

function setup_vlc() {
	mkdir -p $HOME/.config/vlc
	echo -e "[qt4]\nqt-recentplay=0\nqt-privacy-ask=0\n\n[core]\nvideo-title-show=0\nplay-and-exit=1\none-instance-when-started-from-file=0\nsnapshot-path=$HOME/Pictures" > $HOME/.config/vlc/vlcrc
	echo -e '[MainWindow]\nstatus-bar-visible=true' > $HOME/.config/vlc/vlc-qt-interface.conf
}

if [ $1 ]; then
	args=""
	for (( i=2;$i<=$#;i=$i+1 )); do args+=" ${!i}"; done
	eval $1 $args
	echo "install completed successfully!"
else
	echo "No option entered (to begin installation enter the option: all)."
fi
