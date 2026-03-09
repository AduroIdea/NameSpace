import Foundation

final class SpaceNamesStore: ObservableObject {
    private let key = "spaceNames"
    private let defaults = UserDefaults.standard

    // Returns the stored name for spaceID, or a default "Desktop N" label.
    func getName(for id: Int, defaultIndex: Int) -> String {
        let stored = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        return stored[String(id)] ?? "Desktop \(defaultIndex)"
    }

    func setName(_ name: String, for id: Int) {
        var stored = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        stored[String(id)] = name
        defaults.set(stored, forKey: key)
        objectWillChange.send()
    }

    func removeName(for id: Int) {
        var stored = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        stored.removeValue(forKey: String(id))
        defaults.set(stored, forKey: key)
    }
}
