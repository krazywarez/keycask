import Foundation
import Testing

@testable import KeycaskCore

@Suite struct VaultCodecTests {
    @Test func roundTripsAndIsDeterministic() throws {
        var v = Vault()
        try v.add(
            Entry(
                id: EntryID("aaaa2222")!, name: "gh", username: "cmc", password: "p",
                url: "https://github.com", notes: "n", tags: ["dev"],
                now: Date(timeIntervalSince1970: 1_700_000_000)))
        let a = try VaultCodec.encode(v)
        let b = try VaultCodec.encode(v)
        #expect(a == b)
        #expect(try VaultCodec.decode(a) == v)
    }

    @Test func datesAreISO8601WholeSeconds() throws {
        var v = Vault()
        try v.add(
            Entry(
                id: EntryID("aaaa2222")!, name: "gh", password: "p",
                now: Date(timeIntervalSince1970: 1_700_000_000)))
        let text = String(decoding: try VaultCodec.encode(v), as: UTF8.self)
        #expect(text.contains("\"created\":\"2023-11-14T22:13:20Z\""))
    }

    @Test func keysAreSorted() throws {
        var v = Vault()
        try v.add(Entry(id: EntryID("aaaa2222")!, name: "gh", password: "p"))
        let text = String(decoding: try VaultCodec.encode(v), as: UTF8.self)
        let created = text.range(of: "\"created\"")!.lowerBound
        let id = text.range(of: "\"id\"")!.lowerBound
        let updated = text.range(of: "\"updated\"")!.lowerBound
        #expect(created < id && id < updated)
    }

    @Test func garbageIsCorrupt() {
        #expect(throws: KeycaskError.self) { try VaultCodec.decode(Data("nope".utf8)) }
        do {
            _ = try VaultCodec.decode(Data("{\"entries\":[{\"id\":1}]}".utf8))
            Issue.record("expected corrupt")
        } catch let e as KeycaskError {
            #expect(e.exitCode == 1)
            #expect(e.message.hasPrefix("vault is corrupt:"))
        } catch {
            Issue.record("wrong error \(error)")
        }
    }
}
