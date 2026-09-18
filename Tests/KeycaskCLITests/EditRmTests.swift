import Foundation
import Testing

@Suite struct EditRmTests {
    @Test func editChangesFieldsAndBumpsUpdated() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "gh", "--tag", "a", "--generate"])
        let before =
            try JSONSerialization.jsonObject(
                with: Data(try cli.run(["show", "gh", "--json"]).stdout.utf8)) as! [String: Any]
        let r = try cli.run([
            "edit", "gh", "--name", "github", "-u", "cmc", "--url", "https://x", "--notes", "n",
            "--tag", "b", "--untag", "a",
        ])
        #expect(r.status == 0)
        let after =
            try JSONSerialization.jsonObject(
                with: Data(try cli.run(["show", "github", "--json"]).stdout.utf8)) as! [String: Any]
        #expect(after["name"] as? String == "github")
        #expect(after["username"] as? String == "cmc")
        #expect(after["url"] as? String == "https://x")
        #expect(after["notes"] as? String == "n")
        #expect(after["tags"] as? [String] == ["b"])
        #expect(after["created"] as? String == before["created"] as? String)
        #expect(after["id"] as? String == before["id"] as? String)
    }

    @Test func editPasswordFromStdinAndGenerate() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "gh", "--generate"])
        try cli.run(["edit", "gh", "--password"], stdin: "newpass\n")
        #expect(try cli.run(["show", "gh", "--field", "password"]).stdout == "newpass\n")
        try cli.run(["edit", "gh", "--generate", "--length", "30"])
        #expect(try cli.run(["show", "gh", "--field", "password"]).stdout.count == 31)
    }

    @Test func editWithNoChangesIsUsageError() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "gh", "--generate"])
        let r = try cli.run(["edit", "gh"])
        #expect(r.status == 2)
    }

    @Test func editUnknownIsNotFound() throws {
        let cli = try CLI.initialized()
        #expect(try cli.run(["edit", "nope", "--url", "x"]).status == 3)
    }

    @Test func rmWithYesRemoves() throws {
        let cli = try CLI.initialized()
        let id = try cli.run(["add", "gh", "--generate"]).stdout.trimmingCharacters(in: .newlines)
        let r = try cli.run(["rm", id, "--yes"])
        #expect(r.status == 0)
        #expect(try cli.run(["show", id]).status == 3)
        #expect(try cli.run(["ls"]).stdout == "")
    }

    @Test func rmWithoutYesAndWithoutTTYIsUsageError() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "gh", "--generate"])
        let r = try cli.run(["rm", "gh"], stdin: "y\n")
        #expect(r.status == 2)
        #expect(r.stderr.contains("--yes"))
        #expect(try cli.run(["ls"]).lines.count == 1)
    }

    @Test func rmAmbiguousNameLists() throws {
        let cli = try CLI.initialized()
        try cli.run(["add", "gh", "--generate"])
        try cli.run(["add", "gh", "--generate"])
        let r = try cli.run(["rm", "gh", "--yes"])
        #expect(r.status == 5)
        #expect(try cli.run(["ls"]).lines.count == 2)
    }
}
