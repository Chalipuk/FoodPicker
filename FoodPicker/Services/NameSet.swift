import Foundation

enum NameSet {
    static func decode(_ raw: String) -> Set<String> {
        Set(raw.split(separator: "|").map(String.init))
    }

    static func toggle(_ name: String, in raw: String) -> String {
        var set = decode(raw)
        if set.contains(name) { set.remove(name) } else { set.insert(name) }
        return set.sorted().joined(separator: "|")
    }
}
