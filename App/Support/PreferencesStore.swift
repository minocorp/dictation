import Core
import Foundation
import Synchronization

internal final class PreferencesStore: Sendable {
    private static let key = "preferences"

    private let current: Mutex<Preferences>

    init(fallback: Preferences) {
        current = Mutex(Self.stored() ?? fallback)
    }

    func read() -> Preferences {
        current.withLock { $0 }
    }

    func write(_ preferences: Preferences) {
        current.withLock { $0 = preferences }
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(preferences), forKey: Self.key)
        } catch {
            AppLog.failure("save preferences", error)
        }
    }

    private static func stored() -> Preferences? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(Preferences.self, from: data)
        } catch {
            AppLog.failure("read preferences", error)
            return nil
        }
    }
}
