import AppKit

/// Settings shared by the app and the widget through an App Group (see Support/*.entitlements).
enum Store {
    static let defaults = UserDefaults(suiteName: Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String) ?? .standard

    static var notionToken: String {
        get { defaults.string(forKey: "notionToken") ?? "" }
        set { defaults.set(newValue, forKey: "notionToken") }
    }

    /// Picked in the app; nil until picked (or after Reset). Fills every widget whose Background color is "App color".
    static var widgetColor: NSColor? {
        get { color("widgetColor") }
        set { setColor(newValue, "widgetColor") }
    }

    /// Picked in the app; nil until picked (or after Reset). Today's highlight, headers and time line.
    static var elementColor: NSColor? {
        get { color("elementColor") }
        set { setColor(newValue, "elementColor") }
    }

    private static func color(_ key: String) -> NSColor? {
        let v = defaults.array(forKey: key) as? [Double] ?? []
        return v.count == 4 ? NSColor(srgbRed: v[0], green: v[1], blue: v[2], alpha: v[3]) : nil
    }

    private static func setColor(_ color: NSColor?, _ key: String) {
        guard let color else { return defaults.removeObject(forKey: key) }
        let c = color.usingColorSpace(.sRGB) ?? .black
        defaults.set([c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent].map(Double.init), forKey: key)
    }
}
