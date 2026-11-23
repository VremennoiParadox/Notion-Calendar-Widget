import Foundation

/// Settings shared by the app and the widget through an App Group (see Support/*.entitlements).
enum Store {
    static let defaults = UserDefaults(suiteName: Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String) ?? .standard

    static var notionToken: String {
        get { defaults.string(forKey: "notionToken") ?? "" }
        set { defaults.set(newValue, forKey: "notionToken") }
    }
}
