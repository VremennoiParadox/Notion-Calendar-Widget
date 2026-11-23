# Notion Agenda

A macOS desktop widget that shows your upcoming days from your Mac's calendars (including the Google, iCloud or Outlook account behind Notion Calendar) together with dated items from your Notion databases.

## Install

Download the `.dmg` from [Releases](../../releases), open it, and drag **Notion Agenda** into Applications.

The app isn't notarized by Apple, so the first launch is blocked: open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to "Notion Agenda". Then follow the setup below, skipping step 2.

## Setup

1. Add your calendar account in **System Settings → Internet Accounts** with Calendars turned on.
2. Run `./build.sh`. It builds the app, installs it to `/Applications` and opens it.
3. Click **Allow** when the app asks for Calendar access.
4. Create an internal integration at [notion.so/profile/integrations](https://www.notion.so/profile/integrations), copy its secret, and click **Paste & Save** in the app. It tells you how many databases it can see.
5. In Notion, open each database (or a parent page) → **•••** → **Connections** → add your integration. Any shared database with a date property shows up.
6. Right-click the desktop → **Edit Widgets** → search "Notion Agenda".

## Customize

Right-click a widget → **Edit "Notion Agenda"** for what it shows (each widget has its own):

- **Style**: List, Calendar page (a tear-off desk calendar page), Month (a month grid with today circled and dots on busy days), Apple Calendar look (month view with event pills), or Notion Calendar look (day columns on an hour grid with a current-time line). Month grids only show items within **Days ahead**, so set it to 30 to fill the month.
- **Title**, **Show** (Calendar, Notion or both), **Hide lists**, **Days ahead**, **Group by** day, list, or nothing, **Show list name**. The Apple and Notion looks hide the rows they don't use.

How every widget looks is set in the app under **Appearance**, then **Save Appearance**:

- **Background** and **Elements** colors (color pickers, background opacity included; Reset goes back to System and Red). Elements are today's highlight, headers, the page band and the time line.
- **Marker** (bar, dot, chip, none), **Item colors** (list colors, the element color, a single color, or monochrome), **Text size**.

Colors work in every **Appearance → Icon & widget style**. In Clear or Tinted style macOS draws all text in one tint.

The widget refreshes about every 15 minutes. Clicking it opens the app, which refreshes it immediately.

## Building

`./build.sh` builds, installs and opens the app. `./make-dmg.sh 1.2.0` builds a release disk image in `build/`.

Requires Xcode and an Apple Development certificate. Set your own team in `NotionAgenda.xcodeproj` (`DEVELOPMENT_TEAM`); the App Group ID is derived from it. The secret is stored in that App Group on your Mac, never in the source.
