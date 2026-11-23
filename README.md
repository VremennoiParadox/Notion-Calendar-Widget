# Notion Agenda

A macOS desktop widget that shows your upcoming days from your Mac's calendars (including the Google, iCloud or Outlook account behind Notion Calendar) together with dated items from your Notion databases.

## Setup

1. Add your calendar account in **System Settings → Internet Accounts** with Calendars turned on.
2. Run `./build.sh`. It builds the app, installs it to `/Applications` and opens it.
3. Click **Allow** when the app asks for Calendar access.
4. Create an internal integration at [notion.so/profile/integrations](https://www.notion.so/profile/integrations), copy its secret, and click **Paste & Save** in the app. It tells you how many databases it can see.
5. In Notion, open each database (or a parent page) → **•••** → **Connections** → add your integration. Any shared database with a date property shows up.
6. Right-click the desktop → **Edit Widgets** → search "Notion Agenda".

## Customize

Right-click the widget → **Edit "Notion Agenda"**. Each widget has its own settings:

- **Style**: List, Calendar page (a tear-off desk calendar page), Month (a month grid with today circled and dots on busy days), Apple Calendar look (month view with event pills), or Notion Calendar look (day columns on an hour grid with a current-time line). The calendar styles take their color from your Custom widget color, else the marker color, else red. Month grids only show items within **Days ahead**, so set it to 30 to fill the month.
- **Title**, **Show** (Calendar, Notion or both), **Hide lists**, **Days ahead**
- **Group by** day, list, or nothing; **Show list name**
- **Widget color** (System, or Custom: the color you pick in the app's color picker, opacity included), **Marker** (bar, dot, chip, none), **Marker color** (list colors, a single color, or monochrome), **Text size**

Widget and marker colors work in every **Appearance → Icon & widget style**. In Clear or Tinted style macOS draws all text in one tint.

The widget refreshes about every 15 minutes. Clicking it opens the app, which refreshes it immediately.

## Building

Requires Xcode and an Apple Development certificate. Set your own team in `NotionAgenda.xcodeproj` (`DEVELOPMENT_TEAM`); the App Group ID is derived from it. The secret is stored in that App Group on your Mac, never in the source.
