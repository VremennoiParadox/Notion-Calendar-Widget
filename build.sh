#!/bin/sh
# Checks, builds, installs Notion Agenda to /Applications, and opens it so the widget refreshes.
set -e
cd "$(dirname "$0")"

mkdir -p build
swiftc Shared/*.swift Check/main.swift -o build/check
build/check

xcodebuild -project NotionAgenda.xcodeproj -target NotionAgenda -configuration Release -quiet

pkill -x "Notion Agenda" || true
rm -rf "/Applications/Notion Agenda.app"
cp -R "build/Release/Notion Agenda.app" /Applications/
open "/Applications/Notion Agenda.app"
echo "Installed /Applications/Notion Agenda.app"
