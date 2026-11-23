#!/bin/sh
# Builds a release and packs it into a drag-to-Applications disk image:
#   ./make-dmg.sh 1.0.0   →   build/Notion-Calendar-Widget-1.0.0.dmg
set -e
cd "$(dirname "$0")"
version="${1:?usage: ./make-dmg.sh <version>}"

mkdir -p build
swiftc Shared/*.swift Check/main.swift -o build/check
build/check
xcodebuild -project NotionAgenda.xcodeproj -target NotionAgenda -configuration Release -quiet \
    MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION="$(date +%s)"
# Only an installed copy should be registered with macOS, not the build output.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "build/Release/Notion Agenda.app" || true

rm -rf build/dmg && mkdir -p build/dmg
cp -R "build/Release/Notion Agenda.app" build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -volname "Notion Calendar Widget" -srcfolder build/dmg -ov -format UDZO "build/Notion-Calendar-Widget-$version.dmg"
