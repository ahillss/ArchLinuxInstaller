
function global_setup_lightdm() {
	systemctl enable lightdm
	
	groupadd autologin	
	
	if [ $1 ]; then
		USER=$1
		
		gpasswd -a $USER autologin
		
		sed -i "s/#\(autologin-user=\)/\1$USER/g" /etc/lightdm/lightdm.conf
		sed -i 's/#\(pam-service=lightdm\)/\1/g' /etc/lightdm/lightdm.conf
		sed -i 's/#\(pam-autologin-service=lightdm-autologin\)/\1/g' /etc/lightdm/lightdm.conf
		sed -i 's/#\(autologin-user-timeout=0\)/\1/g' /etc/lightdm/lightdm.conf
	fi
}

function global_setup_mousepad() {
	cp -f /usr/share/X11/xorg.conf.d/*-synaptics.conf /etc/X11/xorg.conf.d/
	echo -e '\n#\nSection "InputClass"\n        Identifier "Scrolling"\n        Option "VertEdgeScroll" "on"\n        Option "HorizEdgeScroll" "on"\nEndSection\n' >>  /etc/X11/xorg.conf.d/*-synaptics.conf
}

function global_setup_theme() {
	sed -i 's/\(Inherits=\).*/\1Vanilla-DMZ/g' /usr/share/icons/default/index.theme
}

function global_setup_x11vnc() {	
	echo -e '#!/bin/bash\n\nx11vnc -many -display :0 -rfbauth ~/.vnc/x11vnc_passwd -noscr -noxrecord -gui tray -o ~/.vnc/x11vnc_log.%VNCDISPLAY' > /usr/local/bin/x11vnc_start.sh
	echo -e '#!/bin/bash\n\nif [ $1 ]; then\n\tmkdir -p ~/.vnc\n\tx11vnc -storepasswd $1 ~/.vnc/x11vnc_passwd\nfi' > /usr/local/bin/x11vnc_passwd.sh
	chmod +xr /usr/local/bin/x11vnc_start.sh
	chmod +xr /usr/local/bin/x11vnc_passwd.sh
}

function global_setup_tigervnc() {
	echo -e '#!/bin/bash\n\nif [ $1 ]; then\n\tmkdir -p ~/.vnc\n\techo $1 | vncpasswd -f > ~/.vnc/client_passwd\nfi\n\nvncviewer passwd=~/.vnc/client_passwd' > /usr/local/bin/tigervnc.sh
	chmod +xr /usr/local/bin/tigervnc.sh
}

function global_setup_cups() {
	systemctl enable org.cups.cupsd.service
}

function user_setup_tigervnc() {
	mkdir -p $HOME/.vnc
	echo -e 'TigerVNC Configuration file Version 1.0\n\nDotWhenNoCursor=1\nRemoteResize=1\nMenuKey=' > $HOME/.vnc/default.tigervnc
}

function user_setup_xserver() {
	echo -e '#!/bin/sh\n\nif [ -d /etc/X11/xinit/xinitrc.d ]; then\n\tfor f in /etc/X11/xinit/xinitrc.d/*; do\n\t\t[ -x "$f" ] && . "$f"\n\tdone\n\tunset f\nfi\n\n' > $HOME/.xinitrc
	
	cp -n /etc/skel/.bash_profile $HOME/
	echo '#[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> $HOME/.bash_profile
	
	echo "#xmodmap -e 'pointer = 1 10 3 4 5 6 7 8 9 2 11 12 13 14 15 16 17 18 19 20 21 22 23 24' &" >> $HOME/.xprofile
	echo '#xrandr --output HDMI1 --auto --primary --output HDMI2 --auto --right-of HDMI1 &' >> $HOME/.xprofile
	echo '#xrandr --output HDMI-2 --auto --primary --output HDMI-1 --auto --right-of HDMI-2 --rotate inverted &' >> $HOME/.xprofile
	echo '#xrandr -s 0 &' >> $HOME/.xprofile
	echo "#xautolock -detectsleep -time 45 -locker 'systemctl hybrid-sleep' &" >> $HOME/.xprofile
	echo '#system-config-printer-applet &' >> $HOME/.xprofile
	echo '#nm-applet &' >> $HOME/.xprofile
	echo '#x11vnc_start.sh &' >> $HOME/.xprofile	
	echo 'start-pulseaudio-x11 &' >> $HOME/.xprofile
}

function user_setup_i3wm() {
	echo -e "#exec i3" >> $HOME/.xinitrc
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
}

function user_setup_i3status() {
	mkdir -p $HOME/.config/i3status
	
	echo -e 'general {\n\tcolors = true\n\tinterval = 10\n}\n\ncpu_usage {\n\tformat = "%usage"\n}\n\ncpu_temperature 0 {\n\tformat = "%degrees\\xc2\\xb0C"\n#\tpath = "/sys/devices/platform/coretemp.0/temp3_input"\n}\n\nbattery 0 {\n\tlast_full_capacity = true\n\tformat="%percentage %remaining"\n\tpath="/sys/class/power_supply/BAT1/uevent"\n\tlow_threshold=5\n\tthreshold_type=percentage\n\thide_seconds = true\n\tinteger_battery_capacity=true\n}\n\ntime {\n\tformat = "%a %d %b, %I:%M %p"\n}\n\nvolume master {\n\tformat = "\\xE2\\x99\\xAA %volume"\n\tformat_muted = "\\xE2\\x99\\xAA %volume"\n\tdevice = "default"\n\tmixer = "Master"\n\tmixer_idx = 0\n}\n\n\norder += "cpu_usage"\n\n#order += "cpu_temperature 0"\n\n#order += "battery 0"\n\norder += "time"\n\norder += "volume master"\n' >> $HOME/.config/i3status/config
}

function user_setup_terminator() {
	mkdir -p $HOME/.config/terminator $HOME/.config/xfce4
	echo -e "[global_config]\n  inactive_color_offset = 1.0\n[profiles]\n [[default]]\n  show_titlebar = False\n  scrollbar_position = disabled" > $HOME/.config/terminator/config
	echo 'TerminalEmulator=terminator' >> $HOME/.config/xfce4/helpers.rc
}

function user_setup_thunar() {
	mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
	echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="thunar" version="1.0">\n\t<property name="last-show-hidden" type="bool"\nvalue="true"/>\n\t<property name="last-view" type="string" value="ThunarDetailsView"/>\n</channel>' >> $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
}

function user_setup_nemo() {
    gsettings set org.nemo.desktop show-desktop-icons false    
    gsettings set org.cinnamon.desktop.default-applications.terminal exec terminator
}

function user_setup_vlc() {
	mkdir -p $HOME/.config/vlc
	echo -e "[qt4]\nqt-recentplay=0\nqt-privacy-ask=0\n\n[core]\nvideo-title-show=0\nplay-and-exit=1\none-instance-when-started-from-file=0\nsnapshot-path=$HOME/Pictures" > $HOME/.config/vlc/vlcrc
	echo -e '[MainWindow]\nstatus-bar-visible=true' > $HOME/.config/vlc/vlc-qt-interface.conf
}

function global_setup_scite() {
    sudo sed -i "s/\(file\.patterns\.cpp=.*\)/\1;*.glsl/g" /usr/share/scite/cpp.properties
    sudo sed -i "s/\(file\.patterns\.lisp=.*\)/\1;*.el/g" /usr/share/scite/lisp.properties
    sudo sed -i "s/\(file\.patterns\.scheme=.*\)/\1;*.rkt/g" /usr/share/scite/lisp.properties
}

function user_setup_scite() {
    echo -e 'check.if.already.open=1\nline.margin.visible=1\nline.margin.width=1+\nload.on.activate=1\nopen.filter=$(all.files)\noutput.wrap=1\nsave.session=1\nsave.recent=1\nsave.find=1\nstatusbar.visible=1\ntitle.full.path=1\ntoolbar.visible=1\nquit.on.close.last=1\nwrap=1' > $HOME/.SciTEUser.properties
    
    echo -e 'selection.back=#000000\nselection.alpha=50' >> $HOME/.SciTEUser.properties
    echo -e 'caret.line.back=#CCDDFF' >> $HOME/.SciTEUser.properties
    echo -e 'highlight.current.word=1\nhighlight.current.word.indicator=style:straightbox,colour:#FEE155,fillalpha:190,under' >> $HOME/.SciTEUser.properties
    echo -e 'style.*.34=back:#51DAEA' >> $HOME/.SciTEUser.properties
    
    echo -e '\nindent.size=4\ntabsize=4\nuse.tabs=0\nuse.tabs.$(file.patterns.make)=1' >> $HOME/.SciTEUser.properties
    
    echo -e '\nstatusbar.text.1=pos=$(CurrentPos),li=$(LineNumber), co=$(ColumnNumber) [$(EOLMode)]\next.lua.startup.script=$(SciteUserHome)/.SciTEStartup.lua' >> $HOME/.SciTEUser.properties
    echo -e 'function OnUpdateUI() props["CurrentPos"]=editor.CurrentPos end' > $HOME/.SciTEStartup.lua
}

function user_setup_gtk() {
	mkdir -p  $HOME/.config/gtk-2.0 $HOME/.config/gtk-3.0
	mkdir -p $HOME/Desktop $HOME/Documents $HOME/Downloads $HOME/Pictures $HOME/Videos
	
	echo 'gtk-recent-files-max-age=0' >> $HOME/.gtkrc-2.0
	echo -e '[Settings]\ngtk-recent-files-max-age=0\ngtk-recent-files-limit=0' > $HOME/.config/gtk-3.0/settings.ini
	echo -e "file://$HOME/Documents Documents\nfile://$HOME/Downloads Downloads\nfile://$HOME/Pictures Pictures\nfile://$HOME/Videos Videos\nfile:///tmp tmp" >> $HOME/.config/gtk-3.0/bookmarks	
	for d in /mnt/* ; do echo "file://$d $(basename "$d")" >> $HOME/.config/gtk-3.0/bookmarks; done
	echo -e '[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nShowSizeColumn=true\nSortColumn=name\nSortOrder=ascending\nStartupMode=recent' > $HOME/.config/gtk-2.0/gtkfilechooser.ini
}

function user_setup_shortcuts() {
	echo 'xbindkeys -p &' >> $HOME/.xprofile
	echo -e '"chromium"\nMod4+b\n\n"thunar"\nMod4+g\n\n"nemo --no-desktop"\nMod4+f\n\n"scite"\nMod4+s\n\n"lxtask"\nControl+Shift+Escape' > $HOME/.xbindkeysrc
}

function run_install() {
	packages="xorg-server xorg-xinit xcursor-themes"
	packages+=" xf86-video-vesa xf86-video-fbdev"
	packages+=" xf86-input-synaptics network-manager-applet"

	#packages+=" xf86-video-intel"
	#packages+=" xf86-video-nouveau"
	#packages+=" xf86-video-ati"
	#packages+=" virtualbox-guest-utils"

	packages+=" xclip numlockx xautolock xcursor-vanilla-dmz gksu pavucontrol xbindkeys"

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
	
	pacman -S --needed --noconfirm $packages
	
	global_setup_lightdm $1
	global_setup_mousepad
	global_setup_theme
	global_setup_x11vnc
	global_setup_tigervnc
	global_setup_cups
	global_setup_scite
}

function run_user() {
	user_setup_tigervnc
	user_setup_xserver
	user_setup_i3wm
	user_setup_i3status
	user_setup_terminator
	user_setup_thunar
	user_setup_nemo
	user_setup_vlc
	user_setup_scite
	user_setup_gtk
	user_setup_shortcuts
}

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

set -e

if [ $1 ]; then
	args=""
	for (( i=2;$i<=$#;i=$i+1 )); do args+=" ${!i}"; done
	eval $1 $args
	echo "install completed successfully!"
else
	echo "No option entered (to begin enter the option 'run_install' with sudo and 'run_user' afterwards)."
fi
