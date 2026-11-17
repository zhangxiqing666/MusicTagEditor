#!/bin/zsh
set -e
ROOT="${0:A:h}"
APP="$ROOT/build/音乐标签编辑器.app"
FFMPEG="$ROOT/vendor/ffmpeg-arm64"
FFMPEG_LICENSE="$ROOT/vendor/FFmpeg-LICENSE.txt"
if [[ ! -x "$FFMPEG" ]]; then
  echo "Missing bundled FFmpeg: $FFMPEG" >&2
  exit 1
fi
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/bin"
cp "$ROOT/src/Info.plist" "$APP/Contents/Info.plist"
cp "$FFMPEG" "$APP/Contents/Resources/bin/ffmpeg-arm64"
cp "$FFMPEG_LICENSE" "$APP/Contents/Resources/FFmpeg-LICENSE.txt"
chmod +x "$APP/Contents/Resources/bin/ffmpeg-arm64"
xcrun --sdk macosx clang -fobjc-arc -framework Cocoa "$ROOT/src/main.m" -o "$APP/Contents/MacOS/音乐标签编辑器"
echo "Built: $APP"
