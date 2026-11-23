import Foundation

// Checks the Notion JSON parsing. build.sh runs it before every build.
func json(_ s: String) -> [String: Any] { try! JSONSerialization.jsonObject(with: Data(s.utf8)) as! [String: Any] }

precondition(Notion.dateProperty(json(#"{"properties": {"Name": {"type": "title"}, "Due": {"type": "date"}, "Tag": {"type": "select"}}}"#)) == "Due")
precondition(Notion.dateProperty(json(#"{"properties": {"Due": {"type": "date"}, "Date": {"type": "date"}}}"#)) == "Date")
precondition(Notion.dateProperty(json(#"{"properties": {"Name": {"type": "title"}}}"#)) == nil)

let allDay = Notion.item(json(#"""
{"properties": {"Name": {"type": "title", "title": [{"plain_text": "Ship "}, {"plain_text": "widget"}]},
                "Due": {"type": "date", "date": {"start": "2026-11-25", "end": null}}}}
"""#), dateProperty: "Due")!
precondition(allDay.title == "Ship widget" && allDay.allDay && allDay.end == nil)
precondition(allDay.start == Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 25)))

let timed = Notion.item(json(#"""
{"properties": {"Task": {"type": "title", "title": []},
                "Due": {"type": "date", "date": {"start": "2026-11-25T14:30:00.000-05:00", "end": "2026-11-25T15:00:00-05:00"}}}}
"""#), dateProperty: "Due")!
precondition(timed.title == "Untitled" && !timed.allDay)
precondition(timed.start == ISO8601DateFormatter().date(from: "2026-11-25T19:30:00Z"))
precondition(timed.end!.timeIntervalSince(timed.start) == 1800)

precondition(Notion.item(json(#"{"properties": {"Due": {"type": "date", "date": null}}}"#), dateProperty: "Due") == nil)
print("Notion parsing check passed")
