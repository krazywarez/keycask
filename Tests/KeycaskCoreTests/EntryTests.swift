import Foundation
import Testing

@testable import KeycaskCore

@Suite struct EntryTests {
    @Test func initNormalizesTagsAndTruncatesDates() {
        let now = Date(timeIntervalSince1970: 1_700_000_000.75)
        let e = Entry(
            name: "gh", password: "p", tags: [" work", "Dev", "dev", "", "alpha"], now: now)
        #expect(e.tags == ["alpha", "Dev", "work"])
        #expect(e.created == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(e.updated == e.created)
    }

    @Test func normalizeSortsCaseInsensitivelyAndKeepsFirstSpelling() {
        #expect(Entry.normalize(tags: ["b", "A", "a", "B"]) == ["A", "b"])
        #expect(Entry.normalize(tags: []) == [])
    }

    @Test func hasTagIsCaseInsensitive() {
        let e = Entry(name: "gh", password: "p", tags: ["Dev"])
        #expect(e.hasTag("dev"))
        #expect(e.hasTag("DEV"))
        #expect(!e.hasTag("ops"))
    }

    @Test func matchesSearchesEveryTextFieldExceptPassword() {
        let e = Entry(
            name: "GitHub", username: "cmc", password: "hunter2", url: "https://github.com",
            notes: "downtown office", tags: ["Dev"])
        #expect(e.matches("github"))
        #expect(e.matches("CMC"))
        #expect(e.matches("github.com"))
        #expect(e.matches("downtown"))
        #expect(e.matches("dev"))
        #expect(!e.matches("hunter2"))
        #expect(!e.matches("nothing"))
    }
}
