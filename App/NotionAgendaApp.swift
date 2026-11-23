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
    @State private var backgroundDraft = Store.widgetColor
    @State private var elementDraft = Store.elementColor
    @State private var colorStatus = ""

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
            Section("Colors") {
                colorRow("Background", $backgroundDraft, none: "System", opacity: true)
                colorRow("Elements", $elementDraft, none: "Red", opacity: false)
                HStack {
                    Button("Save Colors") {
                        Store.widgetColor = backgroundDraft
                        Store.elementColor = elementDraft
                        WidgetCenter.shared.reloadAllTimelines()
                        colorStatus = "Saved. Widgets updated."
                    }
                    Text(colorStatus).foregroundStyle(.secondary)
                }
                Text("Pick colors, then Save Colors; they apply to every widget. Elements are today’s highlight, headers, the page band and the time line; set Item colors to “Element color” to match items too. Lower the background opacity for a tinted-glass look. To keep one widget plain, right-click it → Edit “Notion Agenda” → Background color: System or Element color: Red.")
                    .foregroundStyle(.secondary)
            }
            Section("Customize") {
                Text("Right-click the widget → Edit “Notion Agenda” to change colors, background, grouping, text size, which lists show, and more.")
                    .foregroundStyle(.secondary)
                HStack {
                    Text("Widget and marker colors work in every Icon & widget style. In Clear or Tinted, macOS draws all text in one tint.")
                        .foregroundStyle(.secondary)
                    Button("Open Appearance") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Appearance-Settings.extension")!)
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

    /// A color picker plus Reset (back to `none`). Changes wait for Save Colors.
    func colorRow(_ title: String, _ color: Binding<NSColor?>, none: String, opacity: Bool) -> some View {
        let edit = { (new: NSColor?) in
            color.wrappedValue = new
            colorStatus = "Not saved yet."
        }
        return HStack {
            ColorPicker(color.wrappedValue == nil ? "\(title) (\(none))" : title,
                        selection: Binding(get: { Color(nsColor: color.wrappedValue ?? .gray) }, set: { edit(NSColor($0)) }),
                        supportsOpacity: opacity)
            Button("Reset") { edit(nil) }.disabled(color.wrappedValue == nil)
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
