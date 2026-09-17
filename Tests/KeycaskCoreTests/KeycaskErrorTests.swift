import Testing

@testable import KeycaskCore

@Suite struct KeycaskErrorTests {
    @Test func exitCodesFollowTheSpec() {
        #expect(KeycaskError.failure("x").exitCode == 1)
        #expect(KeycaskError.io("x").exitCode == 1)
        #expect(KeycaskError.corrupt("x").exitCode == 1)
        #expect(KeycaskError.vaultExists("x").exitCode == 1)
        #expect(KeycaskError.duplicateID(EntryID("abcd2345")!).exitCode == 1)
        #expect(KeycaskError.usage("x").exitCode == 2)
        #expect(KeycaskError.notFound("x").exitCode == 3)
        #expect(KeycaskError.noVault("/p").exitCode == 3)
        #expect(KeycaskError.cannotDecrypt.exitCode == 4)
        #expect(KeycaskError.ambiguous(name: "gh", candidates: []).exitCode == 5)
    }

    @Test func messagesNameTheSubject() {
        #expect(KeycaskError.notFound("gh").message == "gh: not found")
        #expect(KeycaskError.noVault("/v").message == "vault /v not found (run `keycask init`)")
        #expect(KeycaskError.vaultExists("/v").message == "vault /v already exists")
        #expect(
            KeycaskError.cannotDecrypt.message
                == "cannot decrypt: wrong passphrase or damaged vault")
        #expect(KeycaskError.corrupt("bad json").message == "vault is corrupt: bad json")
    }

    @Test func ambiguousListsCandidateIDs() {
        let a = Entry(id: EntryID("aaaa2222")!, name: "gh", username: "one", password: "p")
        let b = Entry(id: EntryID("bbbb3333")!, name: "gh", password: "p", url: "https://x")
        let m = KeycaskError.ambiguous(name: "gh", candidates: [a, b]).message
        #expect(m.hasPrefix("gh: ambiguous, use an id:\n"))
        #expect(m.contains("aaaa2222"))
        #expect(m.contains("bbbb3333"))
        #expect(m.contains("https://x"))
    }
}
