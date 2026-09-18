import Foundation
import Testing

@Suite struct AddShowTests {
    @Test func addReadsPasswordFromStdinAndPrintsID() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(
            ["add", "github", "-u", "cmc", "--url", "https://github.com", "--tag", "dev"],
            stdin: "hunter2\n")
        #expect(r.status == 0)
        let id = r.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(id.count == 8)

        let shown = try cli.run(["show", id])
        #expect(shown.status == 0)
        #expect(shown.stdout.contains("name: github"))
        #expect(shown.stdout.contains("username: cmc"))
        #expect(shown.stdout.contains("password: ********"))
        #expect(shown.stdout.contains("tags: dev"))
        #expect(!shown.stdout.contains("hunter2"))
    }

    @Test func showByNameRevealAndField() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "github"], stdin: "hunter2\n")
        let revealed = try cli.run(["show", "github", "--reveal"])
        #expect(revealed.stdout.contains("password: hunter2"))
        let field = try cli.run(["show", "github", "--field", "password"])
        #expect(field.stdout == "hunter2\n")
        let missing = try cli.run(["show", "github", "--field", "url"])
        #expect(missing.status == 0)
        #expect(missing.stdout == "\n")
        let unknown = try cli.run(["show", "github", "--field", "nope"])
        #expect(unknown.status == 2)
    }

    @Test func jsonMasksUnlessReveal() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "github", "-u", "cmc"], stdin: "hunter2\n")
        let masked = try cli.run(["show", "github", "--json"])
        let obj = try JSONSerialization.jsonObject(with: Data(masked.stdout.utf8)) as! [String: Any]
        #expect(obj["name"] as? String == "github")
        #expect(obj["username"] as? String == "cmc")
        #expect(obj["password"] as? String == "********")
        #expect((obj["id"] as? String)?.count == 8)
        #expect((obj["created"] as? String)?.hasSuffix("Z") == true)
        let revealed = try cli.run(["show", "github", "--json", "--reveal"])
        let obj2 =
            try JSONSerialization.jsonObject(with: Data(revealed.stdout.utf8)) as! [String: Any]
        #expect(obj2["password"] as? String == "hunter2")
    }

    @Test func addGenerateAndWords() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "a", "--generate"])
        try cli.run(["add", "b", "--generate", "--length", "40"])
        try cli.run(["add", "c", "--words", "4"])
        #expect(try cli.run(["show", "a", "--field", "password"]).stdout.count == 25)
        #expect(try cli.run(["show", "b", "--field", "password"]).stdout.count == 41)
        let words = try cli.run(["show", "c", "--field", "password"]).stdout
            .trimmingCharacters(in: .newlines).split(separator: "-")
        #expect(words.count == 4)
    }

    @Test func generateAndWordsTogetherIsUsageError() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["add", "a", "--generate", "--words", "3"])
        #expect(r.status == 2)
    }

    @Test func duplicateNamesAreAllowedAndAmbiguousOnShow() throws {
        let cli = try CLI.initialized()
        let a = try cli.run(["add", "gh", "-u", "one", "--generate"]).stdout.trimmingCharacters(
            in: .newlines)
        let b = try cli.run(["add", "gh", "-u", "two", "--generate"]).stdout.trimmingCharacters(
            in: .newlines)
        let r = try cli.run(["show", "gh"])
        #expect(r.status == 5)
        #expect(r.stderr.contains(a) && r.stderr.contains(b))
        #expect(try cli.run(["show", a]).stdout.contains("username: one"))
    }

    @Test func missingEntryIsNotFound() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["show", "nope"])
        #expect(r.status == 3)
        #expect(r.stderr == "nope: not found\n")
    }

    @Test func wrongPassphraseCannotDecrypt() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["show", "x"], passphrase: "wrong")
        #expect(r.status == 4)
        #expect(r.stderr.contains("cannot decrypt"))
    }

    @Test func missingVaultIsNotFound() throws {
        let cli = try CLI()
        let r = try cli.run(["show", "x"])
        #expect(r.status == 3)
        #expect(r.stderr.contains("keycask init"))
    }

    @Test func lengthWithWordsIsUsageError() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["add", "a", "--words", "4", "--length", "30"])
        #expect(r.status == 2)
    }

    @Test func addWithoutPasswordSourceIsUsageError() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["add", "x"], stdin: "")
        #expect(r.status == 2)
        #expect(r.stderr.contains("no password"))
    }

    @Test func corruptVaultIsFailure() throws {
        let cli = try CLI.initialized()
        try Data("{}".utf8).write(to: cli.vault)
        let r = try cli.run(["show", "x"])
        #expect(r.status == 1)
        #expect(r.stderr.hasPrefix("vault is corrupt"))
    }
}
