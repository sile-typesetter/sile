#!/usr/bin/env bash
set -e +o pipefail

# Setup AUR helper and other build time dependencies in a way they will be removed from the final image
pacman --needed --noconfirm --asdeps -S git base-devel go poppler
useradd -m docker
echo 'docker:' | chpasswd -e
mkdir -p /etc/sudoers.d
echo 'docker ALL = NOPASSWD: ALL' > /etc/sudoers.d/99-docker
su docker -c 'cd; git clone https://aur.archlinux.org/yay.git; cd yay; makepkg -i --noconfirm --asdeps'

# Install SILE's own prerequisites in a way they will stay in the final image
deps="fontconfig harfbuzza icu lua ttf-gentium-plus"
deps+=" lua-{luaepnf,lpeg,cassowary,linenoise,zlib,cliargs,filesystem,repl,sec,socket,penlight,stdlib,vstruct}"
su docker -c "yay --needed --noconfirm --asexplicit -S $deps"

# Build and install SILE itself

# Tear down build time depencies before layer gets imaged
su docker -c 'yay --noconfirm -Yccq'
yes | pacman -Sccq
userdel -r -f docker
rm -rf /etc/sudoers.d
