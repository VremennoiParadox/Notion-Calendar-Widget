import AppIntents
import EventKit
import SwiftUI
import WidgetKit

// MARK: - Options (right-click the widget → Edit "Notion Agenda")

struct AgendaConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Notion Agenda"
    static var description = IntentDescription("Choose what the widget shows and how it looks.")

    @Parameter(title: "Title") var heading: String?
    @Parameter(title: "Show", default: .everything) var show: ShowOption
    @Parameter(title: "Hide lists", default: []) var hidden: [ListEntity]
    @Parameter(title: "Days ahead", default: 7, inclusiveRange: (1, 30)) var days: Int
    @Parameter(title: "Group by", default: .day) var groupBy: GroupOption
    @Parameter(title: "Show list name", default: false) var showSource: Bool
    @Parameter(title: "Widget color", default: .system) var widgetColor: WidgetColorOption
    @Parameter(title: "Marker", default: .bar) var marker: MarkerOption
    @Parameter(title: "Marker color", default: .calendar) var colors: ColorOption
    @Parameter(title: "Text size", default: .medium) var textSize: SizeOption
}

enum ShowOption: String, AppEnum {
    case everything, calendar, notion
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Show"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .everything: "Calendar + Notion", .calendar: "Calendar only", .notion: "Notion only"]
}

enum GroupOption: String, AppEnum {
    case day, list, flat
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Group by"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .day: "Day", .list: "List", .flat: "Nothing (one list)"]
}

enum ColorOption: String, AppEnum {
    case calendar, blue, purple, pink, red, orange, yellow, green, teal, mono
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Marker color"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .calendar: "List colors", .blue: "Blue", .purple: "Purple", .pink: "Pink", .red: "Red",
        .orange: "Orange", .yellow: "Yellow", .green: "Green", .teal: "Teal", .mono: "Monochrome"]

    var fixed: Color? {
        switch self {
        case .calendar: nil
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .mono: .gray
        }
    }
}

// Widget settings can't hold a color picker, so the color itself is picked in the app (Store.widgetColor).
enum WidgetColorOption: String, AppEnum {
    case system, custom
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget color"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .system: "System", .custom: "Custom (pick it in the app)"]
}

enum MarkerOption: String, AppEnum {
    case bar, dot, chip, hidden
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Marker"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .bar: "Bar", .dot: "Dot", .chip: "Chip", .hidden: "None"]
}

enum SizeOption: String, AppEnum {
    case small, medium, large
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Text size"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .small: "Small", .medium: "Medium", .large: "Large"]

    var points: CGFloat { [.small: 9.5, .medium: 11, .large: 13][self]! }
}

/// A calendar or Notion database, offered in "Hide lists".
struct ListEntity: AppEntity {
    let id: String
    let name: String
    let kind: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "List"
    static var defaultQuery = ListQuery()
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)", subtitle: "\(kind)") }
}

struct ListQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ListEntity] {
        await allLists().filter { identifiers.contains($0.id) }
    }
    func suggestedEntities() async throws -> [ListEntity] { await allLists() }

    func allLists() async -> [ListEntity] {
        var lists = EKEventStore().calendars(for: .event).map { ListEntity(id: $0.calendarIdentifier, name: $0.title, kind: "Calendar") }
        if let dbs = try? await Notion.databases(token: Store.notionToken) {
            lists += dbs.map { ListEntity(id: $0.id, name: $0.name, kind: "Notion · \($0.dateProperty)") }
        }
        return lists
    }
}

// MARK: - Data

struct Entry: TimelineEntry {
    let date: Date
    let items: [Item]
    let note: String?
    let config: AgendaConfig
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entry {
        let sample = Item(title: "Team sync", start: .now, end: nil, allDay: false, source: "Work", sourceID: "", calendarColor: nil)
        return Entry(date: .now, items: [sample], note: nil, config: AgendaConfig())
    }

    func snapshot(for config: AgendaConfig, in context: Context) async -> Entry { await load(config) }

    func timeline(for config: AgendaConfig, in context: Context) async -> Timeline<Entry> {
        // ponytail: asks for a refresh every 15 min; macOS may stretch that to save battery.
        Timeline(entries: [await load(config)], policy: .after(.now.addingTimeInterval(15 * 60)))
    }

    func load(_ c: AgendaConfig) async -> Entry {
        let now = Date.now
        let today = Calendar.current.startOfDay(for: now)
        let end = Calendar.current.date(byAdding: .day, value: c.days, to: today)!
        let hidden = Set(c.hidden.map(\.id))
        var items: [Item] = []
        var notes: [String] = []

        if c.show != .notion {
            if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
                let store = EKEventStore()
                let calendars = store.calendars(for: .event).filter { !hidden.contains($0.calendarIdentifier) }
                if !calendars.isEmpty { // an empty list would mean "all calendars"
                    items += store.events(matching: store.predicateForEvents(withStart: today, end: end, calendars: calendars)).map {
                        Item(title: $0.title ?? "", start: $0.startDate, end: $0.endDate, allDay: $0.isAllDay,
                             source: $0.calendar.title, sourceID: $0.calendar.calendarIdentifier, calendarColor: $0.calendar.cgColor)
                    }
                }
            } else {
                notes.append("Open Notion Agenda to allow Calendar access.")
            }
        }

        if c.show != .calendar {
            let token = Store.notionToken
            if token.isEmpty {
                notes.append("Open Notion Agenda to add your Notion secret.")
            } else {
                do {
                    for db in try await Notion.databases(token: token) where !hidden.contains(db.id) {
                        items += try await Notion.items(in: db, from: today, to: end, token: token)
                    }
                } catch {
                    notes.append("Notion: \(error.localizedDescription)")
                }
            }
        }

        items = items.filter { ($0.end ?? $0.start) >= ($0.allDay ? today : now) && $0.start < end }
        if c.groupBy == .list {
            items.sort { ($0.source, $0.sourceID, $0.start) < ($1.source, $1.sourceID, $1.start) }
        } else {
            items.sort { $0.start < $1.start }
        }
        return Entry(date: now, items: items, note: notes.isEmpty ? nil : notes.joined(separator: " "), config: c)
    }
}

// MARK: - Look

struct AgendaView: View {
    let entry: Entry
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.widgetContentMargins) private var margins

    private var c: AgendaConfig { entry.config }
    private var size: CGFloat { c.textSize.points }
    private var lineHeight: CGFloat { size * 1.6 }
    private var today: Date { Calendar.current.startOfDay(for: entry.date) }
    private let palette: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .red, .yellow]

    var body: some View {
        GeometryReader { geo in
            let reserved = (entry.note == nil ? 0 : 2) + (hasHeading ? 1 : 0)
            let budget = Int(geo.size.height / lineHeight) - reserved
            VStack(alignment: .leading, spacing: 0) {
                if hasHeading {
                    Text(c.heading ?? "").font(.system(size: size + 2, weight: .bold))
                        .foregroundStyle(c.colors.fixed ?? .primary).frame(height: lineHeight)
                }
                if entry.items.isEmpty && entry.note == nil {
                    Text("Nothing in the next \(c.days) days").font(.system(size: size)).foregroundStyle(.secondary)
                }
                ForEach(Array(agendaLines(entry.items, budget: budget, key: groupKey).enumerated()), id: \.offset) { _, line in
                    switch line {
                    case .header(let text):
                        Text(text).font(.system(size: size, weight: .semibold)).foregroundStyle(.secondary)
                            .lineLimit(1).frame(height: lineHeight)
                    case .item(let item):
                        row(item).frame(height: lineHeight)
                    }
                }
                Spacer(minLength: 0)
                if let note = entry.note {
                    Text(note).font(.system(size: size - 1)).foregroundStyle(.red).lineLimit(2)
                }
            }
        }
        .padding(margins)
        // Drawn as content, not containerBackground: Clear style swaps the container background for glass.
        .background {
            if let bg = customColor { swatch(bg) }
        }
        .environment(\.colorScheme, scheme)
        .containerBackground(for: .widget) { Rectangle().fill(.background) }
    }

    private var customColor: NSColor? { c.widgetColor == .custom ? Store.widgetColor : nil }

    /// Dark text on light colors, light text on dark ones (Clear style draws text white regardless).
    private var scheme: ColorScheme {
        guard let bg = customColor, bg.alphaComponent > 0.5 else { return systemScheme }
        return 0.299 * bg.redComponent + 0.587 * bg.greenComponent + 0.114 * bg.blueComponent > 0.6 ? .light : .dark
    }

    private var hasHeading: Bool { !(c.heading ?? "").isEmpty }

    private func groupKey(_ item: Item) -> String? {
        switch c.groupBy {
        case .day: dayLabel(item.start, today: today)
        case .list: item.source
        case .flat: nil
        }
    }

    private func row(_ item: Item) -> some View {
        let color = color(for: item)
        return HStack(spacing: 6) {
            switch c.marker {
            case .bar: swatch(NSColor(color)).frame(width: 3, height: size + 2).clipShape(RoundedRectangle(cornerRadius: 1.5))
            case .dot: swatch(NSColor(color)).frame(width: size * 0.6, height: size * 0.6).clipShape(Circle())
            case .chip, .hidden: EmptyView()
            }
            Text(item.title).font(.system(size: size)).lineLimit(1).layoutPriority(1)
            if c.showSource {
                Text(item.source).font(.system(size: size - 1)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(timeLabel(item)).font(.system(size: size - 1)).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.horizontal, c.marker == .chip ? 5 : 0)
        .frame(maxHeight: lineHeight - 2)
        .background(c.marker == .chip ? swatch(NSColor(color)).opacity(0.25).clipShape(RoundedRectangle(cornerRadius: 4)) : nil)
    }

    /// A solid-color picture. In Clear/Tinted icon & widget style macOS repaints shapes and text in one tint,
    /// but a picture marked full-color keeps its real color.
    @ViewBuilder private func swatch(_ color: NSColor) -> some View {
        let ctx = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let _ = ctx.setFillColor(color.cgColor)
        let _ = ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = Image(decorative: ctx.makeImage()!, scale: 1).resizable()
        if #available(macOS 15, *) {
            image.widgetAccentedRenderingMode(.fullColor)
        } else {
            image
        }
    }

    private func timeLabel(_ item: Item) -> String {
        let time = item.allDay ? "all-day" : item.start.formatted(date: .omitted, time: .shortened)
        guard c.groupBy != .day else { return time }
        let day = dayLabel(item.start, today: today, short: true)
        return item.allDay ? day : "\(day) \(time)"
    }

    private func color(for item: Item) -> Color {
        if let fixed = c.colors.fixed { return fixed }
        if let cg = item.calendarColor { return Color(cgColor: cg) }
        // Notion databases have no color, so give each one a stable color of its own.
        return palette[item.sourceID.unicodeScalars.reduce(0) { $0 + Int($1.value) } % palette.count]
    }
}

@main
struct NotionAgendaWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "NotionAgenda", intent: AgendaConfig.self, provider: Provider()) { AgendaView(entry: $0) }
            .configurationDisplayName("Notion Agenda")
            .description("Your calendar and Notion dates. Right-click → Edit to customize.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
            .contentMarginsDisabled() // so the widget color reaches the edges; AgendaView pads itself
    }
}
