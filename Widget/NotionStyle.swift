import SwiftUI
import WidgetKit

/// Looks like Notion Calendar: month title, day columns on an hour grid, an "All-day" row, soft event blocks
/// with a colored edge and colored text, today's date in a colored badge, and a current-time line with the
/// time in the gutter. 1, 3 or 7 days depending on width.
extension AgendaView {
    var notionStyle: some View {
        GeometryReader { geo in
            let cal = Calendar.current
            let width = geo.size.width
            let days = (0..<(width > 600 ? 7 : width > 250 ? 3 : 1)).map { cal.date(byAdding: .day, value: $0, to: today)! }
            let onDay = { (item: Item, day: Date) in cal.isDate(max(item.start, today), inSameDayAs: day) }
            let inView = entry.items.filter { item in days.contains { onDay(item, $0) } }
            let timed = inView.filter { !$0.allDay }
            let allDay = inView.filter(\.allDay)
            let allDayRows = min(2, days.map { day in allDay.filter { onDay($0, day) }.count }.max() ?? 0)
            let window = hourWindow(timed)
            let gutter = size * 3.2
            VStack(alignment: .leading, spacing: 0) {
                if geo.size.height >= 250 {
                    Text(today.formatted(.dateTime.month(.wide))).font(.system(size: size * 1.8, weight: .bold))
                        .padding(.bottom, 2)
                }
                HStack(spacing: 0) {
                    Color.clear.frame(width: gutter)
                    ForEach(days, id: \.self) { notionHeader($0).frame(maxWidth: .infinity) }
                }
                .frame(height: size * 2)
                if allDayRows > 0 {
                    HStack(alignment: .top, spacing: 0) {
                        Text("All-day").font(.system(size: size * 0.7)).foregroundStyle(.secondary)
                            .frame(width: gutter - 5, alignment: .trailing).padding(.trailing, 5)
                        ForEach(days, id: \.self) { day in
                            VStack(spacing: 2) {
                                ForEach(Array(allDay.filter { onDay($0, day) }.prefix(allDayRows).enumerated()), id: \.offset) { _, item in
                                    notionAllDay(item)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .top).padding(.horizontal, 1)
                        }
                    }
                    .frame(height: CGFloat(allDayRows) * (size + 6))
                    .padding(.bottom, 3)
                }
                GeometryReader { g in
                    let perHour = g.size.height / CGFloat(window.end - window.start)
                    let labelEvery = perHour < size * 1.3 ? 2 : 1
                    let nowY = CGFloat(entry.date.timeIntervalSince(cal.date(bySettingHour: window.start, minute: 0, second: 0, of: today)!) / 3600) * perHour
                    let showNow = nowY >= 0 && nowY <= g.size.height
                    ZStack(alignment: .topLeading) {
                        ForEach(window.start...window.end, id: \.self) { hour in
                            let y = CGFloat(hour - window.start) * perHour
                            Rectangle().fill(.quaternary).frame(height: 0.5).padding(.leading, gutter).offset(y: y)
                            if hour < window.end && (hour - window.start) % labelEvery == 0 && !(showNow && abs(y - nowY) < size) {
                                gutterLabel(cal.date(bySettingHour: hour, minute: 0, second: 0, of: today)!.formatted(.dateTime.hour()), gutter: gutter)
                                    .foregroundStyle(.secondary)
                                    .offset(y: max(0, y - size * 0.45))
                            }
                        }
                        if showNow { // faint across the other days; the today column draws it strong
                            swatch(theme).opacity(0.35).frame(height: 1).padding(.leading, gutter).offset(y: nowY)
                        }
                        HStack(spacing: 0) {
                            Color.clear.frame(width: gutter)
                            ForEach(days, id: \.self) { notionColumn($0, timed: timed, startHour: window.start, perHour: perHour) }
                        }
                        if showNow {
                            gutterLabel(entry.date.formatted(date: .omitted, time: .shortened), gutter: gutter)
                                .fontWeight(.bold).foregroundStyle(Color(nsColor: theme))
                                .offset(y: max(0, nowY - size * 0.45))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private func gutterLabel(_ text: String, gutter: CGFloat) -> Text {
        Text(text).font(.system(size: size * 0.7))
    }

    /// The hours to show: from the earliest event start to the latest end (at least 4 hours).
    private func hourWindow(_ timed: [Item]) -> (start: Int, end: Int) {
        let cal = Calendar.current
        guard !timed.isEmpty else {
            let now = min(cal.component(.hour, from: entry.date), 20)
            return (now, now + 4)
        }
        let start = timed.map { cal.component(.hour, from: $0.start) }.min()!
        let end = timed.map { e -> Int in
            let finish = notionEnd(e)
            guard cal.isDate(finish, inSameDayAs: e.start) else { return 24 }
            let c = cal.dateComponents([.hour, .minute], from: finish)
            return c.hour! + (c.minute! > 0 ? 1 : 0)
        }.max()!
        return (start, min(24, max(end, start + 4)))
    }

    /// Items without an end (most Notion dates) are drawn 30 minutes long.
    private func notionEnd(_ e: Item) -> Date { max(e.end ?? e.start, e.start.addingTimeInterval(1800)) }

    /// Event text in a deeper (light mode) or lighter (dark mode) shade of the event color, like Notion Calendar.
    private func ink(_ color: NSColor) -> Color {
        Color(nsColor: color.blended(withFraction: 0.35, of: systemScheme == .dark ? .white : .black) ?? color)
    }

    private func notionHeader(_ day: Date) -> some View {
        let isToday = Calendar.current.isDate(day, inSameDayAs: today)
        return HStack(spacing: 4) {
            Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.system(size: size * 0.85)).foregroundStyle(.secondary)
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: size, weight: .semibold)).foregroundStyle(isToday ? Color.white : Color.primary)
                .padding(.horizontal, 4).padding(.vertical, 1)
                .background { if isToday { swatch(theme).clipShape(RoundedRectangle(cornerRadius: 4)) } }
        }
    }

    private func notionAllDay(_ e: Item) -> some View {
        let color = NSColor(color(for: e))
        return Text(e.title).font(.system(size: size * 0.8, weight: .medium)).foregroundStyle(ink(color)).lineLimit(1)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: size + 4)
            .background(swatch(color).opacity(0.22).clipShape(RoundedRectangle(cornerRadius: 3)))
    }

    private func notionColumn(_ day: Date, timed: [Item], startHour: Int, perHour: CGFloat) -> some View {
        let cal = Calendar.current
        let events = timed.filter { cal.isDate($0.start, inSameDayAs: day) }.sorted { $0.start < $1.start }
        let minLength = TimeInterval((size + 3) / perHour * 3600) // a block is never drawn shorter than this
        let laid = lanes(events.map { (start: $0.start, end: max(notionEnd($0), $0.start.addingTimeInterval(minLength))) })
        let dayStart = cal.date(bySettingHour: startHour, minute: 0, second: 0, of: day)!
        let isToday = cal.isDate(day, inSameDayAs: today)
        return GeometryReader { g in
            let laneWidth = g.size.width / CGFloat(laid.count)
            let nowY = CGFloat(entry.date.timeIntervalSince(dayStart) / 3600) * perHour
            ZStack(alignment: .topLeading) {
                Rectangle().fill(.quaternary).frame(width: 0.5)
                ForEach(events.indices, id: \.self) { i in
                    let e = events[i]
                    let height = max(size + 2, CGFloat(notionEnd(e).timeIntervalSince(e.start) / 3600) * perHour - 1)
                    notionBlock(e, compact: height < size * 2.6)
                        .frame(width: laneWidth - 3, height: height)
                        .offset(x: CGFloat(laid.lane[i]) * laneWidth + 2, y: CGFloat(e.start.timeIntervalSince(dayStart) / 3600) * perHour)
                }
                if isToday && nowY >= 0 && nowY <= g.size.height {
                    swatch(theme).frame(height: 1.5).offset(y: nowY)
                    swatch(theme).frame(width: 7, height: 7).clipShape(Circle()).offset(x: -3, y: nowY - 2.75)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func notionBlock(_ e: Item, compact: Bool) -> some View {
        let color = NSColor(color(for: e))
        let time = e.start.formatted(date: .omitted, time: .shortened)
        let range = e.end.map { "\(time)–\($0.formatted(date: .omitted, time: .shortened))" } ?? time
        return VStack(alignment: .leading, spacing: 0) {
            Text(e.title).font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(ink(color)).lineLimit(compact ? 1 : 2)
            if !compact {
                Text(range).font(.system(size: size * 0.75)).foregroundStyle(ink(color).opacity(0.75)).lineLimit(1)
            }
        }
        .padding(.leading, 6).padding(.trailing, 2).padding(.vertical, compact ? 0 : 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: compact ? .leading : .topLeading)
        .background(swatch(color).opacity(0.2))
        .overlay(alignment: .leading) { swatch(color).frame(width: 3) }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
