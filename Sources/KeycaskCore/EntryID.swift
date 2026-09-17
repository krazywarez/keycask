public struct EntryID: Hashable, Sendable, CustomStringConvertible {
    public static let alphabet: [Character] = Array("abcdefghijkmnpqrstuvwxyz23456789")
    public static let length = 8

    public let rawValue: String

    public init?(_ raw: String) {
        guard raw.count == Self.length else { return nil }
        let allowed = Set(Self.alphabet)
        guard raw.allSatisfy({ allowed.contains($0) }) else { return nil }
        rawValue = raw
    }

    public static func random() -> EntryID {
        var rng = SystemRandomNumberGenerator()
        return random(using: &rng)
    }

    public static func random(using rng: inout some RandomNumberGenerator) -> EntryID {
        var chars: [Character] = []
        chars.reserveCapacity(length)
        for _ in 0..<length {
            chars.append(alphabet[Int(rng.next(upperBound: UInt32(alphabet.count)))])
        }
        return EntryID(String(chars))!
    }

    public var description: String { rawValue }
}

extension EntryID: Codable {
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let id = EntryID(raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "invalid entry id \(raw)"))
        }
        self = id
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
