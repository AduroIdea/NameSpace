import Foundation

final class SpaceNamesStore: ObservableObject {
    private let key = "spaceNames"
    private let defaults = UserDefaults.standard
    private var cache: [String: String]?

    private func loadedCache() -> [String: String] {
        if let c = cache { return c }
        let c = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        cache = c
        return c
    }

    // Returns the stored name for spaceID, or a default "Desktop N" label.
    func getName(for id: Int, defaultIndex: Int) -> String {
        loadedCache()[String(id)] ?? "Desktop \(defaultIndex)"
    }

    func setName(_ name: String, for id: Int) {
        var stored = loadedCache()
        stored[String(id)] = name
        cache = stored
        defaults.set(stored, forKey: key)
        objectWillChange.send()
    }

    func removeName(for id: Int) {
        var stored = loadedCache()
        stored.removeValue(forKey: String(id))
        cache = stored
        defaults.set(stored, forKey: key)
    }
}
