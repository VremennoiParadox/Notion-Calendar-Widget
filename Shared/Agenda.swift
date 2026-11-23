import CoreGraphics
import Foundation

struct Item {
    let title: String
    let start: Date
    let end: Date?
    let allDay: Bool
    let source: String         // calendar or database name
    let sourceID: String
    let calendarColor: CGColor? // nil for Notion items
}

enum Line {
    case header(String)
    case item(Item)
}

/// Inserts a header whenever `key` changes, keeps at most `budget` lines, and never ends on a header.
func agendaLines(_ items: [Item], budget: Int, key: (Item) -> String?) -> [Line] {
    var lines: [Line] = []
    var last: String?
    for item in items {
        if let k = key(item), k != last { lines.append(.header(k)); last = k }
        lines.append(.item(item))
    }
    lines = Array(lines.prefix(max(0, budget)))
    if case .header = lines.last { lines.removeLast() }
    return lines
}

/// "Today", "Tomorrow", "Wednesday, Nov 25" (short: "Today", "Tmrw", "Wed").
/// Items that started before today (multi-day) count as today.
func dayLabel(_ date: Date, today: Date, short: Bool = false) -> String {
    let cal = Calendar.current
    let day = max(date, today)
    if cal.isDate(day, inSameDayAs: today) { return "Today" }
    if cal.isDate(day, inSameDayAs: cal.date(byAdding: .day, value: 1, to: today)!) { return short ? "Tmrw" : "Tomorrow" }
    return short ? day.formatted(.dateTime.weekday(.abbreviated)) : day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
}

/// Day numbers for a month grid, padded with nil before the 1st so columns line up with `calendar.firstWeekday`.
func monthCells(_ date: Date, calendar cal: Calendar = .current) -> [Int?] {
    let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
    let count = cal.range(of: .day, in: .month, for: start)!.count
    let lead = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7
    return Array(repeating: nil, count: lead) + (1...count).map { $0 }
}

/// Weekday initials starting at `calendar.firstWeekday`, e.g. "M T W T F S S".
func weekdayInitials(calendar cal: Calendar = .current) -> [String] {
    let s = cal.veryShortStandaloneWeekdaySymbols
    return Array(s[(cal.firstWeekday - 1)...] + s[..<(cal.firstWeekday - 1)])
}
