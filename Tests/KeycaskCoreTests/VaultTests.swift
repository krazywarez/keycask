import Foundation
import Testing

@testable import KeycaskCore

@Suite struct VaultTests {
    func idA() -> EntryID { EntryID("aaaa2222")! }
    func idB() -> EntryID { EntryID("bbbb3333")! }

    @Test func addRejectsDuplicateID() throws {
        var v = Vault()
        try v.add(Entry(id: idA(), name: "gh", password: "p"))
        #expect(throws: KeycaskError.duplicateID(idA())) {
            try v.add(Entry(id: idA(), name: "other", password: "p"))
        }
        #expect(v.entries.count == 1)
    }

    @Test func removeUnknownIsNotFound() {
        var v = Vault()
        #expect(throws: KeycaskError.notFound("aaaa2222")) { try v.remove(id: idA()) }
    }

    @Test func updateSetsUpdatedAndNormalizesTags() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let t1 = Date(timeIntervalSince1970: 2_000.9)
        var v = Vault()
        try v.add(Entry(id: idA(), name: "gh", password: "p", now: t0))
        try v.update(id: idA(), now: t1) { e in
            e.tags = ["z", "A", "a"]
            e.password = "q"
        }
        let e = v.entry(id: idA())!
        #expect(e.password == "q")
        #expect(e.tags == ["A", "z"])
        #expect(e.created == t0)
        #expect(e.updated == Date(timeIntervalSince1970: 2_000))
    }

    @Test func resolvePrefersIDThenUniqueName() throws {
        var v = Vault()
        try v.add(Entry(id: idA(), name: "gh", password: "p"))
        try v.add(Entry(id: idB(), name: "aaaa2222", password: "p"))
        #expect(try v.resolve("aaaa2222").id == idA())
        #expect(try v.resolve("gh").id == idA())
        #expect(try v.resolve("bbbb3333").id == idB())
    }

    @Test func resolveReportsAmbiguousWithAllCandidates() throws {
        var v = Vault()
        let a = Entry(id: idA(), name: "gh", password: "p")
        let b = Entry(id: idB(), name: "gh", password: "p")
        try v.add(a)
        try v.add(b)
        #expect(throws: KeycaskError.ambiguous(name: "gh", candidates: [a, b])) {
            try v.resolve("gh")
        }
    }

    @Test func resolveUnknownIsNotFound() {
        #expect(throws: KeycaskError.notFound("nope")) { try Vault().resolve("nope") }
    }

    @Test func filterAndSearch() throws {
        var v = Vault()
        try v.add(Entry(id: idA(), name: "GitHub", password: "p", tags: ["dev"]))
        try v.add(Entry(id: idB(), name: "bank", password: "p", url: "https://bank.example"))
        #expect(v.filter(tag: "DEV").map(\.id) == [idA()])
        #expect(v.search("example").map(\.id) == [idB()])
        #expect(v.search("zzz").isEmpty)
    }

    @Test func sortedEntriesOrderByNameThenID() throws {
        var v = Vault()
        try v.add(Entry(id: idB(), name: "gh", password: "p"))
        try v.add(Entry(id: idA(), name: "gh", password: "p"))
        try v.add(Entry(id: EntryID("cccc4444")!, name: "Alpha", password: "p"))
        #expect(v.sortedEntries.map(\.id.rawValue) == ["cccc4444", "aaaa2222", "bbbb3333"])
    }

    @Test func addNormalizesTagsSetAfterInit() throws {
        var e = Entry(id: idA(), name: "gh", password: "p")
        e.tags = ["z", "A", "a", " b "]
        var v = Vault()
        try v.add(e)
        #expect(v.entry(id: idA())!.tags == ["A", "b", "z"])
    }
}
