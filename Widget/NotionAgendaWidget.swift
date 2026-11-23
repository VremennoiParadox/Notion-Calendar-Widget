import EventKit
import SwiftUI
import WidgetKit

struct Entry: TimelineEntry {
    let date: Date
    let items: [Item]
    let note: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, items: [Item(title: "Team sync", start: .now, end: nil, allDay: false, color: nil)], note: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task { completion(await load()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // ponytail: asks for a refresh every 15 min; macOS may stretch that to save battery.
        Task { completion(Timeline(entries: [await load()], policy: .after(.now.addingTimeInterval(15 * 60)))) }
    }

    func load() async -> Entry {
        let now = Date.now
        let today = Calendar.current.startOfDay(for: now)
        let end = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        var items: [Item] = []
        var notes: [String] = []

        if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
            let store = EKEventStore()
            items += store.events(matching: store.predicateForEvents(withStart: today, end: end, calendars: nil)).map {
                Item(title: $0.title ?? "", start: $0.startDate, end: $0.endDate, allDay: $0.isAllDay, color: $0.calendar.cgColor)
            }
        } else {
            notes.append("Open Notion Agenda to allow Calendar access.")
        }

        if notionToken.isEmpty {
            notes.append("Add your Notion secret to Config.swift.")
        } else {
            do { items += try await Notion.fetch(token: notionToken, from: today, to: end) }
            catch { notes.append("Notion: \(error.localizedDescription)") }
        }

        items = items
            .filter { ($0.end ?? $0.start) >= ($0.allDay ? today : now) && $0.start < end }
            .sorted { $0.start < $1.start }
        return Entry(date: now, items: items, note: notes.isEmpty ? nil : notes.joined(separator: " "))
    }
}

struct AgendaView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let shown = Array(entry.items.prefix(family == .systemLarge ? 12 : 5))
        VStack(alignment: .leading, spacing: 3) {
            if shown.isEmpty && entry.note == nil {
                Text("Nothing in the next 7 days").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(shown.indices, id: \.self) { i in
                if i == 0 || dayLabel(shown[i - 1]) != dayLabel(shown[i]) {
                    Text(dayLabel(shown[i])).font(.caption.bold()).foregroundStyle(.secondary)
                        .padding(.top, i == 0 ? 0 : 3)
                }
                row(shown[i])
            }
            Spacer(minLength: 0)
            if let note = entry.note {
                Text(note).font(.caption2).foregroundStyle(.red).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
    }

    func row(_ item: Item) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(item.color.map { Color(cgColor: $0) } ?? .primary)
                .frame(width: 3, height: 13)
            Text(item.title).font(.caption).lineLimit(1)
            Spacer(minLength: 4)
            Text(item.allDay ? "all-day" : item.start.formatted(date: .omitted, time: .shortened))
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    func dayLabel(_ item: Item) -> String {
        let day = max(item.start, Calendar.current.startOfDay(for: entry.date))
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInTomorrow(day) { return "Tomorrow" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

@main
struct NotionAgendaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NotionAgenda", provider: Provider()) { AgendaView(entry: $0) }
            .configurationDisplayName("Notion Agenda")
            .description("Your calendar and Notion dates for the next 7 days.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
