import Foundation

/// The weekly-digest opt-in flag. Lives in the App Group defaults so any
/// process that writes expenses can (eventually) consult it; default off —
/// notifications are strictly opt-in.
enum DigestPreferences {
    private static let enabledKey = "digestEnabled"

    /// Swappable for tests (ephemeral suite); App Group suite in production.
    nonisolated(unsafe) static var userDefaults: UserDefaults =
        UserDefaults(suiteName: SpendthriftContainer.appGroupID) ?? .standard

    static var isEnabled: Bool {
        get { userDefaults.bool(forKey: enabledKey) }
        set { userDefaults.set(newValue, forKey: enabledKey) }
    }
}
