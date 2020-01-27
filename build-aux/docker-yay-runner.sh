#!/bin/sh
set -e +o pipefail

# Setup AUR helper
pacman --needed --noconfirm -Syyuq
pacman --needed --noconfirm --asdeps -Sq git base-devel go
useradd -m docker
echo 'docker:' | chpasswd -e
mkdir -p /etc/sudoers.d
echo 'docker ALL = NOPASSWD: ALL' > /etc/sudoers.d/99-docker
su docker -c 'cd; git clone https://aur.archlinux.org/yay.git; cd yay; makepkg -i --noconfirm --asdeps'

# Run
su docker -c "yay $@"

# Teardeawn
su docker -c 'yay --noconfirm -Yccq'
yes | pacman -Sccq
userdel -r -f docker
rm -rf /etc/sudoers.d
