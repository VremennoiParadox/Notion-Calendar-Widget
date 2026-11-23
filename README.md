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

- **Title**, **Show** (Calendar, Notion or both), **Hide lists**, **Days ahead**
- **Group by** day, list, or nothing; **Show list name**
- **Colors** (list colors, a single color, or monochrome), **Background** (system, tinted, dark, light), **Marker** (bar, dot, chip, none), **Text size**

Text colors and backgrounds need **System Settings → Appearance → Icon & widget style** set to Default. In Clear or Tinted style macOS tints the whole widget; the markers (bar, dot, chip) still keep their colors.

The widget refreshes about every 15 minutes. Clicking it opens the app, which refreshes it immediately.

## Building

Requires Xcode and an Apple Development certificate. Set your own team in `NotionAgenda.xcodeproj` (`DEVELOPMENT_TEAM`); the App Group ID is derived from it. The secret is stored in that App Group on your Mac, never in the source.
