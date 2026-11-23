import AppKit

/// Settings shared by the app and the widget through an App Group (see Support/*.entitlements).
enum Store {
    static let defaults = UserDefaults(suiteName: Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String) ?? .standard

    static var notionToken: String {
        get { defaults.string(forKey: "notionToken") ?? "" }
        set { defaults.set(newValue, forKey: "notionToken") }
    }

    /// Picked in the app; fills widgets whose Background color is "Custom".
    static var widgetColor: NSColor {
        get { color("widgetColor") ?? NSColor(srgbRed: 0.17, green: 0.2, blue: 0.27, alpha: 1) }
        set { setColor(newValue, "widgetColor") }
    }

    /// Picked in the app; today's highlight, headers and time line in widgets whose Element color is "Custom".
    static var elementColor: NSColor {
        get { color("elementColor") ?? .systemRed }
        set { setColor(newValue, "elementColor") }
    }

    private static func color(_ key: String) -> NSColor? {
        let v = defaults.array(forKey: key) as? [Double] ?? []
        return v.count == 4 ? NSColor(srgbRed: v[0], green: v[1], blue: v[2], alpha: v[3]) : nil
    }

    private static func setColor(_ color: NSColor, _ key: String) {
        let c = color.usingColorSpace(.sRGB) ?? .black
        defaults.set([c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent].map(Double.init), forKey: key)
    }
}
