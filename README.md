# Notion Agenda

A macOS desktop widget that shows the next 7 days from your Mac's calendars (including the Google, iCloud or Outlook account behind Notion Calendar) together with dated items from your Notion databases.

## Setup

1. Add your calendar account in **System Settings → Internet Accounts** with Calendars turned on.
2. Create an internal integration at [notion.so/profile/integrations](https://www.notion.so/profile/integrations) and copy its secret.
3. In Notion, open each database (or a parent page) → **•••** → **Connections** → add your integration. Any shared database with a date property shows up.
4. Run `./build.sh` once. It creates `Widget/Config.swift` (git-ignored). Paste the secret into it, then run `./build.sh` again.
5. Click **Allow** when the app asks for Calendar access.
6. Right-click the desktop → **Edit Widgets** → search "Notion Agenda".

Requires Xcode and an Apple Development certificate. Set your own team in `NotionAgenda.xcodeproj` (`DEVELOPMENT_TEAM`).

The widget refreshes about every 15 minutes. Clicking it opens the app, which refreshes it immediately.
