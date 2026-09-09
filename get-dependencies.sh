#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package and its dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	git                 \
	glib2-devel         \
	gobject-introspection \
	gst-libav           \
	gst-plugin-va       \
	gst-plugins-bad     \
	gst-plugins-base    \
	gst-plugins-good    \
	gst-plugins-ugly    \
	gstreamer           \
	gtk4                \
	libpeas-2           \
	meson               \
	newsflash           \
	ninja               \
	python              \
	python-cairo        \
	python-gobject      \
	yt-dlp

# newsflash pulls in the (unpatched) system libclapper/libclapper-gtk packages,
# remove them so our patched build below is the only source of these libs
pacman -Rdd --noconfirm libclapper-gtk libclapper

echo "Building Clapper with upstream DMABuf fix..."
echo "---------------------------------------------------------------"
git clone https://github.com/Rafostar/clapper ./clapper && (
	cd ./clapper

	git fetch --tags origin
	TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|alpha\|beta' | head -1)
	git checkout "$TAG"

	git apply ../patches/*.patch

	meson setup build --prefix=/usr --libdir=lib --buildtype=release \
		-D clapper=enabled          \
		-D clapper-gtk=enabled      \
		-D clapper-app=disabled     \
		-D gst-plugin=enabled       \
		-D gluploader=enabled       \
		-D glimporter=enabled       \
		-D rawimporter=enabled      \
		-D enhancers-loader=enabled \
		-D discoverer=disabled      \
		-D mpris=disabled           \
		-D server=disabled          \
		-D introspection=enabled    \
		-D vapi=disabled            \
		-D doc=false

	meson compile -C build
	meson install -C build
)

echo "Building Clapper Enhancers (yt-dlp support)..."
echo "---------------------------------------------------------------"
git clone https://github.com/Rafostar/clapper-enhancers ./clapper-enhancers && (
	cd ./clapper-enhancers

	git fetch --tags origin
	TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|alpha\|beta' | head -1)
	git checkout "$TAG"

	meson setup build --prefix=/usr --libdir=lib --buildtype=release \
		-D enhancersdir=/usr/lib/clapper-0.0/enhancers

	meson compile -C build
	meson install -C build
)

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini

# yt-dlp uses a JS runtime to solve site challenges (e.g. YouTube). Deno is
# the default, but we use quickjs instead as it is much smaller.
echo "Building quickjs..."
echo "---------------------------------------------------------------"
git clone https://github.com/bellard/quickjs ./quickjs && (
	cd ./quickjs
	make -s
	make -s install PREFIX=/usr
)

# Make yt-dlp use quickjs instead of the default deno runtime
sed -i -e "s|default=\['deno'\]|default=['quickjs']|" /usr/lib/python*/site-packages/yt_dlp/options.py
# clapper-enhancers uses yt-dlp as a library, so patch the library default too
sed -i -e "s|self.params.get('js_runtimes', {'deno': {}})|self.params.get('js_runtimes', {'quickjs': {}})|" /usr/lib/python*/site-packages/yt_dlp/YoutubeDL.py
