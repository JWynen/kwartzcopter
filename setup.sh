#!/usr/bin/env bash

cd $HOME
mkdir -p src
cd src
[ ! -d ardupilot-mpng ] && git clone git://github.com/MegaPirateNG/ardupilot-mpng
[ ! -d apm_planner ] && git clone git://github.com/diydrones/apm_planner
[ ! -d MAVProxy ] && git clone git://github.com/tridge/MAVProxy
[ ! -d mavlink ] && git clone git://github.com/mavlink/mavlink

# browser GCS plugin for MAVProxy
#git clone https://github.com/wiseman/mavelous.git

# andropilot
#git clone https://github.com/geeksville/arduleader.git
# droidplanner
#git clone https://github.com/DroidPlanner/droidplanner.git

#git clone https://github.com/sim-/tgy.git
#git clone https://github.com/tridge/SiK.git # 3DR radio

if [ ! -d "$HOME/.config/sublime-text-3/Installed Packages" ]
then
    DIR="$HOME/.config/sublime-text-3/Installed Packages"
    mkdir -p "$DIR"
    cd "$DIR"
    wget https://sublime.wbond.net/Package%20Control.sublime-package
    DIR="$HOME/.config/sublime-text-3/Packages/User"
    mkdir -p "$DIR"
    cat - >"$DIR/Package Control.sublime-settings" <<'END'
{
    "installed_packages":
    [
         "Git",
         "GitGutter",
         "SideBarGit"
    ]
}
END
fi

if [ ! -f $HOME/src/kwartzcopter.sublime-project ]
then
    cat - >$HOME/src/kwartzcopter.sublime-project <<'END'
{
    "folders":
    [
        {
            "follow_symlinks": true,
            "path": "ardupilot-mpng/ArduCopter"
        },
        {
            "follow_symlinks": true,
            "path": "ardupilot-mpng/libraries"
        },
        {
            "follow_symlinks": true,
            "path": "ardupilot-mpng/Tools"
        }
    ]
}
END
fi

if ! grep -q 'MAVProxy' $HOME/.bashrc 2>/dev/null
then
    cat - >>$HOME/.bashrc <<'END'
PATH=~/src/MAVProxy/MAVProxy:$PATH
export PYTHONPATH=~/src/mavlink

alias ac='cd ~/src/ardupilot-mpng/ArduCopter'

PATH=/opt/sublime_text:$PATH

xset q >/dev/null || startx
END
fi

if [ ! -f $HOME/src/mavlink/pymavlink/build/lib.linux-i686-2.7/pymavlink/dialects/v10/ardupilotmega.py ]
then
    cd $HOME/src/mavlink/pymavlink
    python setup.py build
    cd $HOME/src/MAVProxy
    ln -s ../mavlink .
fi

# patch source
cd $HOME/src/ardupilot-mpng
git apply --reject - 2>/dev/null <<'END'
diff --git a/ArduCopter/APM_Config.h b/ArduCopter/APM_Config.h
index 8c28c58..80473e7 100644
--- a/ArduCopter/APM_Config.h
+++ b/ArduCopter/APM_Config.h
@@ -3,7 +3,7 @@
 // User specific config file.  Any items listed in config.h can be overridden here.
 
 // Select Megapirate board type:
-//#define MPNG_BOARD_TYPE   CRIUS_V1
+#define MPNG_BOARD_TYPE HK_RED_MULTIWII_PRO
 /*
   RCTIMER_CRIUS_V2    -- (DEFAULT!!!) Use ONLY for RCTimer CRIUS V2 board
   CRIUS_V1            -- RCTimer CRIUS V1(1.1) board and all HobbyKing AIOP boards
@@ -36,7 +36,7 @@
 */
 
 // QuadCopter selected by default
-//#define FRAME_CONFIG HEXA_FRAME
+#define FRAME_CONFIG QUAD_FRAME
 /*
  *  options:
  *  QUAD_FRAME
diff --git a/Tools/autotest/sim_arducopter.sh b/Tools/autotest/sim_arducopter.sh
index 9da5556..9923572 100755
--- a/Tools/autotest/sim_arducopter.sh
+++ b/Tools/autotest/sim_arducopter.sh
@@ -33,11 +33,11 @@ make clean $target
 tfile=$(mktemp)
 echo r > $tfile
 #gnome-terminal -e "gdb -x $tfile --args /tmp/ArduCopter.build/ArduCopter.elf"
-gnome-terminal -e /tmp/ArduCopter.build/ArduCopter.elf
+xterm -e /tmp/ArduCopter.build/ArduCopter.elf&
 #gnome-terminal -e "valgrind -q /tmp/ArduCopter.build/ArduCopter.elf"
 sleep 2
 rm -f $tfile
-gnome-terminal -e "../Tools/autotest/pysim/sim_multicopter.py --frame=$frame --home=-35.362938,149.165085,584,180"
+xterm -e "../Tools/autotest/pysim/sim_multicopter.py --frame=$frame --home=-35.362938,149.165085,584,180"&
 sleep 2
 popd
 mavproxy.py --master tcp:127.0.0.1:5760 --sitl 127.0.0.1:5501 --out 127.0.0.1:14550 --out 127.0.0.1:14551 --quadcopter $*
diff --git a/libraries/AP_HAL_MPNG/RCInput_MPNG.cpp b/libraries/AP_HAL_MPNG/RCInput_MPNG.cpp
index 6a885bb..e2051af 100644
--- a/libraries/AP_HAL_MPNG/RCInput_MPNG.cpp
+++ b/libraries/AP_HAL_MPNG/RCInput_MPNG.cpp
@@ -14,7 +14,7 @@ using namespace MPNG;
 extern const HAL& hal;
 
 // PPM_SUM(CPPM) or PWM Signal processing
-//#define SERIAL_PPM SERIAL_PPM_ENABLED
+#define SERIAL_PPM SERIAL_PPM_DISABLED
 /*
 	SERIAL_PPM_DISABLED				// Separated channel signal (PWM) on A8-A15 pins
 	SERIAL_PPM_ENABLED				// DEFAULT!!! For all boards, PPM_SUM pin is A8
@@ -22,7 +22,7 @@ extern const HAL& hal;
 */   
 
 // Uncomment line below in order to use non Standard channel mapping
-//#define RC_MAPPING RC_MAP_STANDARD
+#define RC_MAPPING RC_MAP_JR
 /*
 	RC_MAP_STANDARD 1   // DEFAULT!!!
 	RC_MAP_GRAUPNER 2
diff --git a/mk/configure.mk b/mk/configure.mk
index e1a5a39..ee16854 100644
--- a/mk/configure.mk
+++ b/mk/configure.mk
@@ -12,7 +12,7 @@ configure:
 ifneq ($(findstring CYGWIN, $(SYSTYPE)),)
 	@echo PORT = COM3 >> $(SKETCHBOOK)/config.mk
 else
-	@echo PORT = /dev/ttyACM0 >> $(SKETCHBOOK)/config.mk
+	@echo PORT = /dev/ttyUSB0 >> $(SKETCHBOOK)/config.mk
 endif
 	@echo  >> $(SKETCHBOOK)/config.mk
 	@echo  \# uncomment and fill in the path to Arduino if installed in an exotic location >> $(SKETCHBOOK)/config.mk
END

cd $HOME/src/MAVProxy
git apply --reject - 2>/dev/null <<'END'
diff --git a/MAVProxy/mavproxy.py b/MAVProxy/mavproxy.py
index 2070c46..a32fbb8 100755
--- a/MAVProxy/mavproxy.py
+++ b/MAVProxy/mavproxy.py
@@ -14,7 +14,7 @@ import serial, Queue, select
 import select
 
 # allow running without installing
-#sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))
+sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))
 
 
 from MAVProxy.modules.lib import textconsole
END

if [ ! -f $HOME/src/ardupilot-mpng/config.mk ]
then
    cd $HOME/src/ardupilot-mpng/ArduCopter
    make configure
fi

if [ ! -f $HOME/.config/openbox/autostart.sh ]
then
    mkdir -p $HOME/.config/openbox
    echo -e "(sleep 2 && tint2)&\n(sleep 2 && pcmanfm --desktop)&" > $HOME/.config/openbox/autostart.sh
fi

if [ ! -f $HOME/Desktop/apm-planner.desktop ]
then
    mkdir -p $HOME/Desktop
    cat - >$HOME/Desktop/apm-planner.desktop <<'END'
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=APM Planner
Icon=/home/vagrant/src/apm_planner/files/images/apm_planner_logo.png
Exec=bash -c "cd ~/src/apm_planner && exec release/apmplanner2"
Comment=Launch APM Planner 2.0
END
    cp /usr/share/applications/sublime-text.desktop $HOME/Desktop
    cat - >$HOME/Desktop/terminal.desktop <<'END'
[Desktop Entry]
Type=Application
Name=Terminal
Comment=Terminal
Exec=xterm
Icon=/home/vagrant/src/apm_planner/qml/resources/apmplanner/toolbar/terminal.png
Terminal=false
StartupNotify=true
NoDisplay=true
END
    cat - >$HOME/Desktop/exit.desktop <<'END'
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=Exit Desktop
Name[en_US]=Exit Desktop
Exec=openbox --exit
Icon=/usr/share/icons/nuoveXT2/48x48/actions/stock_exit.png
END
    mkdir -p $HOME/.config/pcmanfm/default
    cat - >$HOME/.config/pcmanfm/default/desktop-items-0.conf <<'END'
[exit.desktop]
x=1
y=298

[apm-planner.desktop]
x=8
y=13

[sublime-text.desktop]
x=2
y=210

[terminal.desktop]
x=2
y=106

END
fi

if [ ! -d $HOME/Wallpaper ]
then
    mkdir $HOME/Wallpaper
    cd $HOME/Wallpaper
    wget 'http://www.nature.com/polopoly_fs/7.15782.1393446359!/sitegraphics/2513431918.jpg_gen/derivatives/default/2513431918.jpg' -O night.jpg || true
fi

if [ -d $HOME/src/apm_planner ] && [ ! -f $HOME/src/apm_planner/release/apmplanner2 ]
then
    until false
    do
        if ! read -p "Autobuild APM Mission Planner (5s timeout) Y/n: " -n 1 -r -t 5 || [[ $REPLY =~ [Yy] ]]
        then
	    cd $HOME/src/apm_planner
            qmake-qt4 qgroundcontrol.pro
            make -j3
            break
        elif [[ $REPLY =~ [Nn] ]]
        then
            break
        fi
    done
fi

if ! which tilda >/dev/null
then
    if sudo apt-get install -q -y tilda
    then
        echo -e "(sleep 2 && tilda -h)&" >> $HOME/.config/openbox/autostart.sh
        RC_FILE=~/.config/openbox/rc.xml
        [ ! -f $RC_FILE ] && cp /etc/xdg/openbox/rc.xml $RC_FILE
        sed -i $RC_FILE -e '/<applications>/a  <application name="tilda"><position><x>-50</x><y>0</y></position><size><width>50%</width><height>100%</height></size><layer>below</layer></application>'
        mkdir -p ~/.config/tilda
        (base64 -d | zcat >~/.config/tilda/config_0) << END
H4sICFnMj1MAA2NvbmZpZ18wAH1VS4/bNhC+81cYDtrTOhVJUZaCdIugRW8FCrS99EJQEm0RpkiH
olZ2iv73DPWgVkmc9QLUzPfNg8MZ0itdC15Zc1Jn/iJdp6zZ/bzb47fww3v0ZqdacZZBFYTKtq0w
9SSerPHh6w9rbHcVldzle3SR96D7HWxFXXtR8lnz/q9Gnfzz+1/Byln97MFBr3VXOSkNj2ZgV2nb
ye9YDntk5M2/ZizQn5Ar/80OZo+uTr48pPxz3aPWvoQoWp78o0hfcp06N98nT7HP1tsQG0fuB+2f
8QqQDUBWgG4AugLpBkhXgG0AtgLZBshW4LgBjiuQb4B8BYoNULzaYLJBEjg8e70/qlAFpyI6Lx/h
L3v0sVcPC/xxj7zyemzGv0Pf7lEpqsvZ2d7U0MPaugANjfIyNOtg3UWZM6+Vmxp2kCUvnR06OSpu
h2EYDrMCUOvASyNcF8DDh8O/4vApORRPb3/65Ycf37zje6SVkQHFSYJaceODqn0DcjbLjQwNEggM
FMpEAh6lFUbeCQMz46Sp7rPDG7/a4DxB9/gVarx8h72OYzbXJ0G11DJWE6Oaw9jwpUQUzcPK5U2F
oAR1VSNbOXI7rWrJOy3llfedrAKewB8SBgbewy3ArVPS+PF7ykW10nEnO6v7WUmCQe8tb4K3QJj9
ILDXcNTcSwc7F3pJIoEOgKQh65hMgrrGDhwsWmuUt46bvi3HI4ps+P4P45yQpx2mNEvDkh/zpx0j
KYElGf8hcpo97WjBAoRZCnSW0CMsKcZkIs32hAEL9ASnwKVJkhXBAcuAQnGG8eKA5kWaRqegImDG
GGEMFoqLYIbzFCRCKBslSsE6wymh4CRh9BgXytIMMmR5kq9bydJjWFiR5zjkQBOwIwUpIF6a5BmN
gdI0zYBCSUaDRPExi15mn/MCGwiBliXJGPkfzh/GSJfCzT1Fxp6CI61jg/FzuI5XsdT9dEYebtzI
HIWFmTFG2aSK7CkSX8cTtN71cgFCe/X+2oeWOAndSWSsl6W1EBHGcDz8SS+MV0Ir0W09wCYiBfqX
L6/UpDk7mJuTrfpoJUq4wRcBYonuMrkYFaXVMcMShvzSfZ3vNGUTRWodY7ne8PVZnHRXZYyMHuNI
RRzGpZarWMGcSagtb2DmPsFtJ7S+f43C8+xVtcGkCQ8Y/+I2GaPWtg9Q2Z9Or8sZpxW2NFaIw2vr
v423NpRWS7GW7jPCzpDLMAgAAA==
END
    fi
fi

if ! grep -q night ~/.config/openbox/autostart.sh
then
cat - >>~/.config/openbox/autostart.sh <<END
if [ -f ~/Wallpaper/night.jpg ] && [ ! -f ~/.wallpaper_set ]
then
    touch ~/.wallpaper_set
    (sleep 4 && pcmanfm --set-wallpaper=$HOME/Wallpaper/night.jpg --wallpaper-mode=crop)&
fi
END
fi

echo 2 >~/.vmver
