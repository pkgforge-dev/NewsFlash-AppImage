#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q newsflash | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/scalable/apps/io.gitlab.news_flash.NewsFlash.svg
export DESKTOP=/usr/share/applications/io.gitlab.news_flash.NewsFlash.desktop
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
quick-sharun /usr/bin/newsflash \
             /usr/bin/xdg-dbus-proxy \
             /usr/lib/gio/modules/libgiognutls.so*

# Turn AppDir into AppImage
quick-sharun --make-appimage
