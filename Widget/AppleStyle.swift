import SwiftUI
import WidgetKit

/// Looks like Apple Calendar: the month view (bold month + year, right-aligned day numbers, today in a
/// filled circle, other months dimmed, event pills). Small widgets get Apple's small "today" widget layout.
extension AgendaView {
    var appleStyle: some View {
        GeometryReader { geo in
            let s = geo.size
            if s.width <= s.height * 1.3 && s.height < 250 {
                appleToday
            } else {
                appleMonth(s)
            }
        }
    }

    /// Small: red weekday, big date, then the next items with colored bars.
    private var appleToday: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.date.formatted(.dateTime.weekday(.wide)).uppercased())
                .font(.system(size: size, weight: .semibold)).foregroundStyle(Color(nsColor: theme))
            Text(entry.date.formatted(.dateTime.day()))
                .font(.system(size: size * 3, weight: .light))
            ForEach(Array(entry.items.prefix(3).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 5) {
                    swatch(NSColor(color(for: item))).frame(width: 3).clipShape(Capsule())
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title).font(.system(size: size, weight: .semibold)).lineLimit(1)
                        Text(timeLabel(item, withDay: !Calendar.current.isDate(max(item.start, today), inSameDayAs: today)))
                            .font(.system(size: size - 1)).foregroundStyle(.secondary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The month grid. If the whole month won't fit legibly, show the current week onward.
    private func appleMonth(_ s: CGSize) -> some View {
        let cal = Calendar.current
        let cells = monthCells(today)
        let monthRows = (cells.count + 6) / 7
        let headerH = min(28, max(16, s.height * 0.12))
        let weekdayH = headerH * 0.6
        let gridH = s.height - headerH - weekdayH
        let weeks = min(monthRows, max(1, Int(gridH / 44)))
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        let gridStart = weeks == monthRows
            ? cal.date(byAdding: .day, value: -cells.prefix { $0 == nil }.count, to: monthStart)!
            : cal.dateInterval(of: .weekOfYear, for: today)!.start
        let cellH = gridH / CGFloat(weeks)
        let font = min(12, cellH * 0.28, s.width / 7 * 0.28)

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(today.formatted(.dateTime.month(.wide))).fontWeight(.bold)
                Text(today.formatted(.dateTime.year()))
            }
            .font(.system(size: headerH * 0.72))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: headerH)
            HStack(spacing: 0) {
                ForEach(Array(weekdayNames().enumerated()), id: \.offset) { _, name in
                    Text(name).font(.system(size: weekdayH * 0.7)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 4)
                }
            }
            .frame(height: weekdayH)
            ForEach(0..<weeks, id: \.self) { week in
                Rectangle().fill(.quaternary).frame(height: 0.5)
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        if col > 0 { Rectangle().fill(.quaternary).frame(width: 0.5) }
                        appleCell(cal.date(byAdding: .day, value: week * 7 + col, to: gridStart)!, font: font, height: cellH)
                    }
                }
                .frame(height: cellH)
            }
        }
    }

    private func appleCell(_ day: Date, font: CGFloat, height: CGFloat) -> some View {
        let cal = Calendar.current
        let number = cal.component(.day, from: day)
        let isToday = cal.isDate(day, inSameDayAs: today)
        let inMonth = cal.isDate(day, equalTo: today, toGranularity: .month)
        let items = entry.items.filter { cal.isDate(max($0.start, today), inSameDayAs: day) }
        let badge = font * 1.75
        let pillH = font + 4
        let pills = max(0, Int((height - badge - 3) / (pillH + 1)))
        return VStack(alignment: .trailing, spacing: 1) {
            ZStack {
                if isToday { swatch(theme).frame(width: badge, height: badge).clipShape(Circle()) }
                Text(number == 1 ? day.formatted(.dateTime.day().month(.abbreviated)) : "\(number)")
                    .font(.system(size: font, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? Color.white : inMonth ? Color.primary : Color(nsColor: .tertiaryLabelColor))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(height: badge)
            if pills > 0 {
                ForEach(Array(items.prefix(pills).enumerated()), id: \.offset) { _, item in
                    applePill(item, font: font, height: pillH)
                }
            } else if !items.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                        swatch(NSColor(color(for: item))).frame(width: 4, height: 4).clipShape(Circle())
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func applePill(_ item: Item, font: CGFloat, height: CGFloat) -> some View {
        let color = color(for: item)
        return Text(item.title)
            .font(.system(size: font * 0.85, weight: .medium)).foregroundStyle(color).lineLimit(1)
            .padding(.horizontal, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background(swatch(NSColor(color)).opacity(0.25).clipShape(RoundedRectangle(cornerRadius: 3)))
    }
}
