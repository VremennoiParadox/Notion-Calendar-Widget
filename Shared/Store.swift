import AppKit

/// Settings shared by the app and the widget through an App Group (see Support/*.entitlements).
enum Store {
    static let defaults = UserDefaults(suiteName: Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String) ?? .standard

    static var notionToken: String {
        get { defaults.string(forKey: "notionToken") ?? "" }
        set { defaults.set(newValue, forKey: "notionToken") }
    }

    /// Picked in the app; used by widgets whose Widget color is "Custom".
    static var widgetColor: NSColor {
        get {
            let v = defaults.array(forKey: "widgetColor") as? [Double] ?? []
            return v.count == 4 ? NSColor(srgbRed: v[0], green: v[1], blue: v[2], alpha: v[3])
                                : NSColor(srgbRed: 0.17, green: 0.2, blue: 0.27, alpha: 1)
        }
        set {
            let c = newValue.usingColorSpace(.sRGB) ?? .black
            defaults.set([c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent].map(Double.init), forKey: "widgetColor")
        }
    }
}
