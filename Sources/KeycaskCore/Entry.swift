import Foundation

public struct Entry: Codable, Equatable, Sendable {
    public let id: EntryID
    public var name: String
    public var username: String?
    public var password: String
    public var url: String?
    public var notes: String?
    public var tags: [String]
    public let created: Date
    public var updated: Date

    public init(
        id: EntryID = .random(),
        name: String,
        username: String? = nil,
        password: String,
        url: String? = nil,
        notes: String? = nil,
        tags: [String] = [],
        now: Date = .now
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.url = url
        self.notes = notes
        self.tags = Self.normalize(tags: tags)
        let stamp = Self.truncateToSeconds(now)
        created = stamp
        updated = stamp
    }

    public static func normalize(tags: [String]) -> [String] {
        var seen: Set<String> = []
        var out: [String] = []
        for raw in tags {
            let tag = raw.trimmingCharacters(in: .whitespaces)
            guard !tag.isEmpty, seen.insert(tag.lowercased()).inserted else { continue }
            out.append(tag)
        }
        return out.sorted { a, b in
            let (la, lb) = (a.lowercased(), b.lowercased())
            return la == lb ? a < b : la < lb
        }
    }

    public static func truncateToSeconds(_ date: Date) -> Date {
        Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down))
    }

    public func hasTag(_ tag: String) -> Bool {
        let needle = tag.lowercased()
        return tags.contains { $0.lowercased() == needle }
    }

    public func matches(_ query: String) -> Bool {
        let needle = query.lowercased()
        guard !needle.isEmpty else { return false }
        let haystacks = [name, username ?? "", url ?? "", notes ?? ""] + tags
        return haystacks.contains { $0.lowercased().contains(needle) }
    }
}
