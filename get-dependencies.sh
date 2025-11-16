#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package and its dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm newsflash

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano
