import CoreGraphics
import Foundation

struct Item {
    let title: String
    let start: Date
    let end: Date?
    let allDay: Bool
    let color: CGColor? // nil = Notion item
}

struct NotionError: LocalizedError { let errorDescription: String? }

enum Notion {
    /// Every database shared with your integration that has a date property shows up.
    // ponytail: reads the first 100 databases and 100 items per database; paginate if you outgrow that.
    static func fetch(token: String, from: Date, to: Date) async throws -> [Item] {
        let search = try await post("search", ["filter": ["property": "object", "value": "database"]], token)
        var items: [Item] = []
        for db in search["results"] as? [[String: Any]] ?? [] {
            guard let id = db["id"] as? String, let prop = dateProperty(db) else { continue }
            // Ask for a day extra on each side; the widget does the exact local-time cut.
            let body: [String: Any] = ["filter": ["and": [
                ["property": prop, "date": ["on_or_after": dayFormatter.string(from: from.addingTimeInterval(-86400))]],
                ["property": prop, "date": ["on_or_before": dayFormatter.string(from: to.addingTimeInterval(86400))]],
            ]]]
            let pages = try await post("databases/\(id)/query", body, token)
            items += (pages["results"] as? [[String: Any]] ?? []).compactMap { item($0, dateProperty: prop) }
        }
        return items
    }

    // ponytail: several date properties → "Date", else first A–Z. Make it configurable if that picks wrong.
    static func dateProperty(_ db: [String: Any]) -> String? {
        let props = db["properties"] as? [String: [String: Any]] ?? [:]
        let dates = props.filter { $0.value["type"] as? String == "date" }.keys.sorted()
        return dates.contains("Date") ? "Date" : dates.first
    }

    static func item(_ page: [String: Any], dateProperty: String) -> Item? {
        let props = page["properties"] as? [String: [String: Any]] ?? [:]
        guard let date = props[dateProperty]?["date"] as? [String: Any],
              let startText = date["start"] as? String,
              let start = parse(startText) else { return nil }
        let title = (props.values.first { $0["type"] as? String == "title" }?["title"] as? [[String: Any]] ?? [])
            .compactMap { $0["plain_text"] as? String }.joined()
        return Item(title: title.isEmpty ? "Untitled" : title, start: start,
                    end: (date["end"] as? String).flatMap(parse), allDay: startText.count == 10, color: nil)
    }

    static func parse(_ text: String) -> Date? {
        if text.count == 10 { return dayFormatter.date(from: text) } // "2026-11-25" = all-day, local midnight
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func post(_ path: String, _ body: [String: Any], _ token: String) async throws -> [String: Any] {
        var req = URLRequest(url: URL(string: "https://api.notion.com/v1/\(path)")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NotionError(errorDescription: json["message"] as? String ?? "request failed")
        }
        return json
    }
}
