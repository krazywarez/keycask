import Foundation
import KeycaskCore

enum Output {
    static let mask = "********"

    static func masked(_ entry: Entry, reveal: Bool) -> Entry {
        guard !reveal else { return entry }
        var copy = entry
        copy.password = mask
        return copy
    }

    static func text(_ entry: Entry, reveal: Bool) -> String {
        let e = masked(entry, reveal: reveal)
        var lines = ["id: \(e.id.rawValue)", "name: \(e.name)"]
        if let u = e.username { lines.append("username: \(u)") }
        lines.append("password: \(e.password)")
        if let u = e.url { lines.append("url: \(u)") }
        if !e.tags.isEmpty { lines.append("tags: \(e.tags.joined(separator: ", "))") }
        if let n = e.notes { lines.append("notes: \(n)") }
        lines.append("created: \(iso(e.created))")
        lines.append("updated: \(iso(e.updated))")
        return lines.joined(separator: "\n") + "\n"
    }

    static func table(_ entries: [Entry]) -> String {
        guard !entries.isEmpty else { return "" }
        let rows = entries.map { [$0.id.rawValue, $0.name, $0.username ?? "", $0.url ?? ""] }
        let widths = (0..<3).map { col in rows.map { $0[col].count }.max() ?? 0 }
        return rows.map { row in
            let padded = (0..<3).map {
                row[$0].padding(toLength: widths[$0], withPad: " ", startingAt: 0)
            }
            return (padded + [row[3]]).joined(separator: "  ")
                .trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n") + "\n"
    }

    static func json(_ entries: [Entry], reveal: Bool) throws -> String {
        guard !entries.isEmpty else { return "[]\n" }
        return try encode(entries.map { masked($0, reveal: reveal) })
    }

    static func json(_ entry: Entry, reveal: Bool) throws -> String {
        try encode(masked(entry, reveal: reveal))
    }

    static func field(_ entry: Entry, named name: String) throws -> String {
        switch name {
        case "id": entry.id.rawValue
        case "name": entry.name
        case "username": entry.username ?? ""
        case "password": entry.password
        case "url": entry.url ?? ""
        case "notes": entry.notes ?? ""
        case "tags": entry.tags.joined(separator: ",")
        case "created": iso(entry.created)
        case "updated": iso(entry.updated)
        default: throw KeycaskError.usage("unknown field \(name)")
        }
    }

    private static func encode(_ value: some Encodable) throws -> String {
        let encoder = VaultCodec.makeEncoder()
        encoder.outputFormatting.insert(.prettyPrinted)
        do {
            return String(decoding: try encoder.encode(value), as: UTF8.self) + "\n"
        } catch {
            throw KeycaskError.io("encode json: \(error)")
        }
    }

    private static func iso(_ date: Date) -> String {
        date.formatted(.iso8601)
    }
}
