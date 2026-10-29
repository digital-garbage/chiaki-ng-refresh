#!/bin/sh
# Copies Qt and every Homebrew library into the app so it runs without Homebrew.
# Usage: scripts/macos-bundle.sh /path/to/chiaki-ng.app [codesign identity]
set -e
APP="$1"
ID="${2:--}"
QML="$(cd "$(dirname "$0")/.." && pwd)/gui/src/qml"
macdeployqt "$APP" -qmldir="$QML"

# the web engine helper (PSN login) is not rewritten by macdeployqt
HELPER="$APP/Contents/Frameworks/QtWebEngineCore.framework/Versions/A/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess"
for old in $(otool -L "$HELPER" | awk '/\/opt\/homebrew\/opt\/qt/ {print $1}'); do
	fw=$(basename "$old")
	install_name_tool -change "$old" "@loader_path/../../../../../../../$fw.framework/Versions/A/$fw" "$HELPER"
done

codesign --force --deep --sign "$ID" "$APP"
