#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q newsflash | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/scalable/apps/io.gitlab.news_flash.NewsFlash.svg
export DESKTOP=/usr/share/applications/io.gitlab.news_flash.NewsFlash.desktop
export DEPLOY_GSTREAMER=1
export DEPLOY_PYTHON=1
export STARTUPWMCLASS=io.gitlab.news_flash.NewsFlash # Default to Wayland's wmclass. For X11, GTK_CLASS_FIX will force the wmclass to be the Wayland one.
export GTK_CLASS_FIX=1

## This app uses libclapper for video playback, so the clapper lib dir is deployed
clapper_dir=$(echo /usr/lib/clapper-*)

# Trace and deploy all files and directories needed for the application (including binaries, libraries and others)
quick-sharun /usr/bin/newsflash \
             "$clapper_dir" \
             /usr/lib/gio/modules/libgiognutls.so* \
             /usr/lib/libpeas-2/loaders/*

# Ensure the patched clapper importers (incl. the DMABuf fix) and enhancers
# (yt-dlp based HTML page/media URL resolution) are found inside the AppImage
echo "CLAPPER_SINK_IMPORTER_PATH=\${SHARUN_DIR}/lib/${clapper_dir##*/}/gst/plugin/importers" >> ./AppDir/.env
echo "CLAPPER_ENHANCERS_PATH=\${SHARUN_DIR}/lib/${clapper_dir##*/}/enhancers" >> ./AppDir/.env

# Turn AppDir into AppImage
quick-sharun --make-appimage
