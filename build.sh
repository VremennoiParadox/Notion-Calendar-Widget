#!/bin/sh
# Checks, builds, installs Notion Agenda to /Applications, and opens it so the widget refreshes.
set -e
cd "$(dirname "$0")"

# Your Notion secret lives in Widget/Config.swift, which git ignores. Create it on first run.
[ -f Widget/Config.swift ] || printf '%s\n' '// Paste your Notion integration secret between the quotes, then run ./build.sh again.' 'let notionToken = ""' > Widget/Config.swift

mkdir -p build
swiftc Widget/Notion.swift Check/main.swift -o build/notion-check
build/notion-check

xcodebuild -project NotionAgenda.xcodeproj -target NotionAgenda -configuration Release -quiet

pkill -x "Notion Agenda" || true
rm -rf "/Applications/Notion Agenda.app"
cp -R "build/Release/Notion Agenda.app" /Applications/
open "/Applications/Notion Agenda.app"
echo "Installed /Applications/Notion Agenda.app"
