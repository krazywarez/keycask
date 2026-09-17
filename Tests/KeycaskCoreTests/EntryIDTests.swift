import Foundation
import Testing

@testable import KeycaskCore

@Suite struct EntryIDTests {
    @Test func randomIDsHaveLengthEightFromTheAlphabet() {
        let allowed = Set(EntryID.alphabet)
        for _ in 0..<200 {
            let id = EntryID.random()
            #expect(id.rawValue.count == 8)
            #expect(id.rawValue.allSatisfy { allowed.contains($0) })
        }
    }

    @Test func alphabetExcludesAmbiguousCharacters() {
        let alphabet = Set(EntryID.alphabet)
        #expect(alphabet.count == 32)
        for bad in ["l", "o", "0", "1"] {
            #expect(!alphabet.contains(Character(bad)))
        }
    }

    @Test func parsingValidatesLengthAndAlphabet() {
        #expect(EntryID("abcd2345") != nil)
        #expect(EntryID("abcd234") == nil)
        #expect(EntryID("abcd23456") == nil)
        #expect(EntryID("abcd234l") == nil)
        #expect(EntryID("ABCD2345") == nil)
    }

    @Test func codableIsABareString() throws {
        let id = EntryID("abcd2345")!
        let data = try JSONEncoder().encode([id])
        #expect(String(decoding: data, as: UTF8.self) == "[\"abcd2345\"]")
        let back = try JSONDecoder().decode([EntryID].self, from: data)
        #expect(back == [id])
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([EntryID].self, from: Data("[\"bad\"]".utf8))
        }
    }

    @Test func seededGeneratorIsDeterministic() {
        struct Counter: RandomNumberGenerator {
            var n: UInt64 = 0
            mutating func next() -> UInt64 {
                n += 1
                return n
            }
        }
        var a = Counter()
        var b = Counter()
        #expect(EntryID.random(using: &a) == EntryID.random(using: &b))
    }
}
