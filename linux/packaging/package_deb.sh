#!/usr/bin/env bash
set -e

APP_DIR="deb_pkg"
rm -rf "$APP_DIR" VINX-linux-amd64.deb

mkdir -p "$APP_DIR/opt/vinx"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APP_DIR/DEBIAN"

# Copy Linux bundle
cp -r build/linux/x64/release/bundle/* "$APP_DIR/opt/vinx/"
ln -s /opt/vinx/video_downloader "$APP_DIR/usr/bin/vinx"

# Desktop launcher entry
cat << 'DESKTOP' > "$APP_DIR/usr/share/applications/vinx.desktop"
[Desktop Entry]
Name=VINX
Comment=Modern Desktop Video Downloader
Exec=/opt/vinx/video_downloader
Icon=vinx
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Video;Network;
DESKTOP

# Icon
cp assets/icon.png "$APP_DIR/usr/share/icons/hicolor/256x256/apps/vinx.png"

# Control metadata
cat << 'CONTROL' > "$APP_DIR/DEBIAN/control"
Package: vinx
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: VINX <support@vinx.app>
Description: VINX - Modern Desktop Video Downloader
 Powerful cross-platform desktop video and audio downloader powered by yt-dlp and FFmpeg.
CONTROL

dpkg-deb --build "$APP_DIR" VINX-linux-amd64.deb
rm -rf "$APP_DIR"
echo "Successfully generated VINX-linux-amd64.deb"
