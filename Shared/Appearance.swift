import SwiftUI

// How every widget looks. Set in the app (Appearance → Save), read by the widget. Kept out of the widget's
// Edit menu so that menu stays short enough to fit on screen.

enum MarkerOption: String, CaseIterable {
    case bar, dot, chip, hidden
    var title: String { [.bar: "Bar", .dot: "Dot", .chip: "Chip", .hidden: "None"][self]! }
}

enum ColorOption: String, CaseIterable {
    case calendar, element, blue, purple, pink, red, orange, yellow, green, teal, mono
    var title: String {
        [.calendar: "List colors", .element: "Element color", .blue: "Blue", .purple: "Purple", .pink: "Pink", .red: "Red",
         .orange: "Orange", .yellow: "Yellow", .green: "Green", .teal: "Teal", .mono: "Monochrome"][self]!
    }

    var fixed: Color? {
        switch self {
        case .calendar, .element: nil
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

enum SizeOption: String, CaseIterable {
    case small, medium, large
    var title: String { [.small: "Small", .medium: "Medium", .large: "Large"][self]! }
    var points: CGFloat { [.small: 9.5, .medium: 11, .large: 13][self]! }
}

extension Store {
    static var marker: MarkerOption {
        get { MarkerOption(rawValue: defaults.string(forKey: "marker") ?? "") ?? .bar }
        set { defaults.set(newValue.rawValue, forKey: "marker") }
    }

    static var itemColors: ColorOption {
        get { ColorOption(rawValue: defaults.string(forKey: "itemColors") ?? "") ?? .calendar }
        set { defaults.set(newValue.rawValue, forKey: "itemColors") }
    }

    static var textSize: SizeOption {
        get { SizeOption(rawValue: defaults.string(forKey: "textSize") ?? "") ?? .medium }
        set { defaults.set(newValue.rawValue, forKey: "textSize") }
    }
}
