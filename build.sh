#!/bin/sh
# Checks, builds, installs Notion Agenda to /Applications, and opens it so the widget refreshes.
set -e
cd "$(dirname "$0")"

mkdir -p build
swiftc Shared/*.swift Check/main.swift -o build/check
build/check

# A new build number each time, or macOS keeps using the widget's cached description (e.g. its settings).
xcodebuild -project NotionAgenda.xcodeproj -target NotionAgenda -configuration Release -quiet CURRENT_PROJECT_VERSION="$(date +%s)"

pkill -x "Notion Agenda" || true
pkill -x AgendaWidget || true
rm -rf "/Applications/Notion Agenda.app"
cp -R "build/Release/Notion Agenda.app" /Applications/
# Only the /Applications copy should be registered, not the build output.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "build/Release/Notion Agenda.app" || true
open "/Applications/Notion Agenda.app"
echo "Installed /Applications/Notion Agenda.app ($(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "/Applications/Notion Agenda.app/Contents/Info.plist"))"
