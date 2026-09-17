import Foundation

public struct Vault: Codable, Equatable, Sendable {
    public var entries: [Entry]

    public init(entries: [Entry] = []) {
        self.entries = entries
    }

    public func entry(id: EntryID) -> Entry? {
        entries.first { $0.id == id }
    }

    public mutating func add(_ entry: Entry) throws {
        guard self.entry(id: entry.id) == nil else { throw KeycaskError.duplicateID(entry.id) }
        var normalized = entry
        normalized.tags = Entry.normalize(tags: entry.tags)
        entries.append(normalized)
    }

    public mutating func remove(id: EntryID) throws {
        guard let index = entries.firstIndex(where: { $0.id == id }) else {
            throw KeycaskError.notFound(id.rawValue)
        }
        entries.remove(at: index)
    }

    public mutating func update(
        id: EntryID, now: Date = .now, _ change: (inout Entry) -> Void
    ) throws {
        guard let index = entries.firstIndex(where: { $0.id == id }) else {
            throw KeycaskError.notFound(id.rawValue)
        }
        change(&entries[index])
        entries[index].tags = Entry.normalize(tags: entries[index].tags)
        entries[index].updated = Entry.truncateToSeconds(now)
    }

    public func resolve(_ ref: String) throws -> Entry {
        if let id = EntryID(ref), let hit = entry(id: id) {
            return hit
        }
        let byName = entries.filter { $0.name == ref }
        switch byName.count {
        case 0: throw KeycaskError.notFound(ref)
        case 1: return byName[0]
        default: throw KeycaskError.ambiguous(name: ref, candidates: byName)
        }
    }

    public func filter(tag: String) -> [Entry] {
        sortedEntries.filter { $0.hasTag(tag) }
    }

    public func search(_ query: String) -> [Entry] {
        sortedEntries.filter { $0.matches(query) }
    }

    public var sortedEntries: [Entry] {
        entries.sorted { a, b in
            let (la, lb) = (a.name.lowercased(), b.name.lowercased())
            return la == lb ? a.id.rawValue < b.id.rawValue : la < lb
        }
    }
}
