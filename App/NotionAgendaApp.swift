import EventKit
import SwiftUI
import WidgetKit

// Widgets have to ship inside an app. This one asks for Calendar access once and
// refreshes the widget each time it opens (clicking the widget opens it).
@main
struct NotionAgendaApp: App {
    @State private var status = "Asking for Calendar access…"

    var body: some Scene {
        WindowGroup {
            Text(status)
                .multilineTextAlignment(.center)
                .padding(40)
                .frame(width: 420)
                .task {
                    let granted = (try? await EKEventStore().requestFullAccessToEvents()) ?? false
                    WidgetCenter.shared.reloadAllTimelines()
                    status = granted
                        ? "Widget refreshed.\nTo add it: right-click the desktop → Edit Widgets → search “Notion Agenda”."
                        : "Calendar access is off. Turn it on in System Settings → Privacy & Security → Calendars, then reopen this app."
                }
        }
        .windowResizability(.contentSize)
    }
}
