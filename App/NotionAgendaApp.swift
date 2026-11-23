import EventKit
import SwiftUI
import WidgetKit

// Widgets have to ship inside an app. This one holds the Notion secret, asks for
// Calendar access, and refreshes the widget each time it opens (clicking the widget opens it).
@main
struct NotionAgendaApp: App {
    var body: some Scene {
        WindowGroup { SettingsView() }
            .windowResizability(.contentSize)
    }
}

struct SettingsView: View {
    @State private var token = Store.notionToken
    @State private var notionStatus = ""
    @State private var calendarAllowed: Bool?

    var body: some View {
        Form {
            Section("Notion") {
                SecureField("Integration secret", text: $token)
                    .onSubmit { Task { await save() } }
                HStack {
                    Button("Paste & Save") {
                        token = NSPasteboard.general.string(forType: .string) ?? ""
                        Task { await save() }
                    }
                    Button("Save") { Task { await save() } }
                    Spacer()
                    Link("Get a secret", destination: URL(string: "https://www.notion.so/profile/integrations")!)
                }
                if !notionStatus.isEmpty {
                    Text(notionStatus).foregroundStyle(.secondary)
                }
            }
            Section("Calendar") {
                switch calendarAllowed {
                case true?: Text("Access allowed.")
                case false?:
                    HStack {
                        Text("Access is off.")
                        Spacer()
                        Button("Open Privacy Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                        }
                    }
                case nil: Text("Checking…")
                }
            }
            Section("Customize") {
                Text("Right-click the widget → Edit “Notion Agenda” to change colors, background, grouping, text size, which lists show, and more.")
                    .foregroundStyle(.secondary)
                HStack {
                    Text("Colors and backgrounds only show when Widget style is Full-color. On Automatic, macOS makes widgets monochrome while a window is in front.")
                        .foregroundStyle(.secondary)
                    Button("Open Widget Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")!)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .task {
            calendarAllowed = (try? await EKEventStore().requestFullAccessToEvents()) ?? false
            await save()
        }
    }

    func save() async {
        token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        Store.notionToken = token
        WidgetCenter.shared.reloadAllTimelines()
        guard !token.isEmpty else { notionStatus = "Paste your Notion integration secret above."; return }
        notionStatus = "Checking…"
        do {
            let count = try await Notion.databases(token: token).count
            notionStatus = count == 0
                ? "Connected, but no databases with a date are shared yet. In Notion: ••• → Connections → add your integration."
                : "Connected: \(count) database\(count == 1 ? "" : "s") with dates."
        } catch {
            notionStatus = "Couldn't connect: \(error.localizedDescription)"
        }
    }
}
