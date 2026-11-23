import Foundation

// Checks Notion JSON parsing and agenda grouping. build.sh runs it before every build.
func json(_ s: String) -> [String: Any] { try! JSONSerialization.jsonObject(with: Data(s.utf8)) as! [String: Any] }

// Date property detection
precondition(Notion.dateProperty(json(#"{"properties": {"Name": {"type": "title"}, "Due": {"type": "date"}, "Tag": {"type": "select"}}}"#)) == "Due")
precondition(Notion.dateProperty(json(#"{"properties": {"Due": {"type": "date"}, "Date": {"type": "date"}}}"#)) == "Date")
precondition(Notion.database(json(#"{"id": "x", "title": [], "properties": {"Name": {"type": "title"}}}"#)) == nil)

// Database parsing
let db = Notion.database(json(#"{"id": "db1", "title": [{"plain_text": "Home"}, {"plain_text": "work"}], "properties": {"Due": {"type": "date"}}}"#))!
precondition(db.id == "db1" && db.name == "Homework" && db.dateProperty == "Due")
precondition(Notion.database(json(#"{"id": "db2", "title": [], "properties": {"When": {"type": "date"}}}"#))!.name == "Untitled")

// Page parsing
let allDay = Notion.item(json(#"""
{"properties": {"Name": {"type": "title", "title": [{"plain_text": "Ship "}, {"plain_text": "widget"}]},
                "Due": {"type": "date", "date": {"start": "2026-11-25", "end": null}}}}
"""#), in: db)!
precondition(allDay.title == "Ship widget" && allDay.allDay && allDay.end == nil && allDay.source == "Homework" && allDay.sourceID == "db1")
precondition(allDay.start == Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 25)))

let timed = Notion.item(json(#"""
{"properties": {"Task": {"type": "title", "title": []},
                "Due": {"type": "date", "date": {"start": "2026-11-25T14:30:00.000-05:00", "end": "2026-11-25T15:00:00-05:00"}}}}
"""#), in: db)!
precondition(timed.title == "Untitled" && !timed.allDay)
precondition(timed.start == ISO8601DateFormatter().date(from: "2026-11-25T19:30:00Z"))
precondition(timed.end!.timeIntervalSince(timed.start) == 1800)
precondition(Notion.item(json(#"{"properties": {"Due": {"type": "date", "date": null}}}"#), in: db) == nil)

// Grouping: headers on key change, budget respected, never ends on a header
let today = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 23))!
func at(_ day: Int, _ title: String) -> Item {
    Item(title: title, start: today.addingTimeInterval(Double(day) * 86400 + 3600), end: nil, allDay: false, source: "s", sourceID: "s", calendarColor: nil)
}
let items = [at(0, "a"), at(0, "b"), at(1, "c"), at(3, "d")]
func shape(_ lines: [Line]) -> String {
    lines.map { if case .header(let h) = $0 { return "[\(h)]" } else if case .item(let i) = $0 { return i.title } else { return "" } }.joined(separator: " ")
}
let byDay: (Item) -> String? = { dayLabel($0.start, today: today) }
precondition(shape(agendaLines(items, budget: 99, key: byDay)) == "[Today] a b [Tomorrow] c [\(byDay(items[3])!)] d")
precondition(byDay(items[3])!.contains("26"))
precondition(shape(agendaLines(items, budget: 4, key: byDay)) == "[Today] a b")   // trailing "[Tomorrow]" dropped
precondition(shape(agendaLines(items, budget: 3, key: { _ in nil })) == "a b c")
precondition(dayLabel(today.addingTimeInterval(-86400), today: today) == "Today")    // multi-day item started yesterday
precondition(dayLabel(today.addingTimeInterval(86400), today: today, short: true) == "Tmrw")

// Month grid: Nov 2026 starts on a Sunday and has 30 days
var gregorian = Calendar(identifier: .gregorian)
gregorian.locale = Locale(identifier: "en_US")
gregorian.timeZone = TimeZone(identifier: "UTC")!
let nov = gregorian.date(from: DateComponents(year: 2026, month: 11, day: 23))!
gregorian.firstWeekday = 1 // Sunday-first: no padding
precondition(monthCells(nov, calendar: gregorian).first! == 1 && monthCells(nov, calendar: gregorian).count == 30)
precondition(weekdayInitials(calendar: gregorian) == ["S", "M", "T", "W", "T", "F", "S"])
gregorian.firstWeekday = 2 // Monday-first: Sunday the 1st sits in the 7th column
let mondayFirst = monthCells(nov, calendar: gregorian)
precondition(mondayFirst.prefix(6).allSatisfy { $0 == nil } && mondayFirst[6] == 1 && mondayFirst.last! == 30)
precondition(weekdayInitials(calendar: gregorian) == ["M", "T", "W", "T", "F", "S", "S"])

print("Notion + agenda checks passed")
