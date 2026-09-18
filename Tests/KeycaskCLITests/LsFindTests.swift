import Foundation
import Testing

@Suite struct LsFindTests {
    func seeded() throws -> CLI {
        let cli = try CLI.initialized()
        try cli.run([
            "add", "github", "-u", "cmc", "--url", "https://github.com", "--tag", "Dev",
            "--generate",
        ])
        try cli.run([
            "add", "bank", "--url", "https://bank.example", "--notes", "downtown branch",
            "--generate",
        ])
        try cli.run(["add", "Alpha", "--tag", "dev", "--generate"])
        return cli
    }

    @Test func lsSortsByNameAndShowsColumns() throws {
        let cli = try seeded()
        let r = try cli.run(["ls"])
        #expect(r.status == 0)
        let names = r.lines.map {
            String($0.split(separator: " ", omittingEmptySubsequences: true)[1])
        }
        #expect(names == ["Alpha", "bank", "github"])
        #expect(r.stdout.contains("cmc"))
        #expect(r.stdout.contains("https://github.com"))
    }

    @Test func lsTagFilterIsCaseInsensitive() throws {
        let cli = try seeded()
        let r = try cli.run(["ls", "--tag", "DEV"])
        #expect(r.lines.count == 2)
        #expect(!r.stdout.contains("bank"))
    }

    @Test func lsJsonIsAnArrayWithMaskedPasswords() throws {
        let cli = try seeded()
        let r = try cli.run(["ls", "--json"])
        let arr = try JSONSerialization.jsonObject(with: Data(r.stdout.utf8)) as! [[String: Any]]
        #expect(arr.count == 3)
        #expect(arr.allSatisfy { $0["password"] as? String == "********" })
    }

    @Test func emptyVaultListsNothing() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["ls"])
        #expect(r.status == 0)
        #expect(r.stdout == "")
        let j = try cli.run(["ls", "--json"])
        #expect(j.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "[]")
    }

    @Test func findMatchesNotesURLTagsCaseInsensitively() throws {
        let cli = try seeded()
        #expect(try cli.run(["find", "DOWNTOWN"]).lines.count == 1)
        #expect(try cli.run(["find", "github.com"]).lines.count == 1)
        #expect(try cli.run(["find", "dev"]).lines.count == 2)
        let none = try cli.run(["find", "zzz"])
        #expect(none.status == 0)
        #expect(none.stdout == "")
    }

    @Test func findJson() throws {
        let cli = try seeded()
        let r = try cli.run(["find", "bank", "--json"])
        let arr = try JSONSerialization.jsonObject(with: Data(r.stdout.utf8)) as! [[String: Any]]
        #expect(arr.count == 1)
        #expect(arr[0]["name"] as? String == "bank")
    }
}
