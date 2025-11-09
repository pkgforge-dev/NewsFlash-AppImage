#!/bin/sh

set -eux

ARCH="$(uname -m)"
VERSION="$(cat ~/version)"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

# Variables used by quick-sharun
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export OUTNAME=NewsFlash-"$VERSION"-anylinux-"$ARCH".AppImage
export DESKTOP=/usr/share/applications/io.gitlab.news_flash.NewsFlash.desktop
export ICON=/usr/share/icons/hicolor/scalable/apps/io.gitlab.news_flash.NewsFlash.svg
export DEPLOY_OPENGL=1
export DEPLOY_GSTREAMER=1
export STARTUPWMCLASS=newsflash # For Wayland, this is 'io.gitlab.news_flash.NewsFlash', so this needs to be changed in desktop file manually by the user in that case until some potential automatic fix exists for this

## This app uses libclapper for video playback, so this is needed
sys_clapper_dir=$(echo /usr/lib/clapper-*)
if [ -d "$sys_clapper_dir" ]; then
	export PATH_MAPPING="
		$sys_clapper_dir:\${SHARUN_DIR}/lib/${sys_clapper_dir##*/}
	"
else
	>&2 echo "ERROR: Cannot find the clapper lib dir"
	exit 1
fi

# Trace and deploy all files and directories needed for the application (including binaries, libraries and others)
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/newsflash /usr/bin/xdg-dbus-proxy /usr/lib/gio/modules/libgiognutls.so*

## Set gsettings to save to keyfile, instead to dconf
echo "GSETTINGS_BACKEND=keyfile" >> ./AppDir/.env

# Make the AppImage with uruntime
./quick-sharun --make-appimage

# Prepare the AppImage for release
mkdir -p ./dist
mv -v ./*.AppImage* ./dist
mv -v ~/version     ./dist
