#!/usr/bin/env bash

# HOST=$(ip route show default|grep via|awk '{print $3}')
# echo "Attempting to use apt proxy on $HOST"
# echo "Acquire::http { Proxy \"http://$HOST:3142\"; };" >/etc/apt/apt.conf.d/02proxy

add-apt-repository ppa:webupd8team/sublime-text-3
apt-get update

apt-get upgrade -y

apt-get install -q -y linux-image-extra-$(uname -r) # includes usb-serial drivers

apt-get install -q -y python-software-properties vim

# base for arducopter-mpng
apt-get install -q -y git-core gawk make arduino-core g++ gdb

# used by sitl sim script
# apt-get install -q -y gnome-terminal libcanberra-gtk3-module

# MAVProxy 
apt-get install -q -y python-pip
#pip install MAVProxy
apt-get install -q -y python-matplotlib python-serial python-wxgtk2.8 python-scipy python-opencv 

# APM Planner
apt-get install -q -y phonon libqt4-dev libqt4-opengl-dev libphonon-dev libphonon4 phonon-backend-gstreamer qtcreator libsdl1.2-dev libflite1 flite1-dev build-essential libopenscenegraph-dev libssl-dev libqt4-opengl-dev libudev-dev libsndfile1-dev

pip install pexpect

echo "America/Toronto"|tee /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
usermod -a -G audio,dialout vagrant

apt-get install -q -y sublime-text-installer gitk

#X
apt-get install -q -y openbox obconf xinit x11-xserver-utils tint2 pcmanfm gmrun

# autologin
apt-get install -q -y mingetty

sed -i /etc/init/tty1.conf -e '/^exec.*$/s##exec /sbin/mingetty --autologin=vagrant tty1#'

sysctl vm.swappiness=10
echo "vm.swappiness=10" >>/etc/sysctl.conf

su vagrant -c "bash /vagrant/setup.sh"
