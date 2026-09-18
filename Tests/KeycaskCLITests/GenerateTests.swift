import Foundation
import Testing

@Suite struct GenerateTests {
    @Test func defaultIs24Characters() throws {
        let cli = try CLI()
        let r = try cli.run(["generate"], passphrase: nil)
        #expect(r.status == 0)
        #expect(r.stdout.count == 25)
    }

    @Test func lengthAndWords() throws {
        let cli = try CLI()
        let lenResult = try cli.run(["generate", "--length", "12"], passphrase: nil)
        #expect(lenResult.stdout.count == 13)
        let wordsOutput = try cli.run(["generate", "--words", "6"], passphrase: nil).stdout
        let w = wordsOutput.trimmingCharacters(in: .newlines).split(separator: "-")
        #expect(w.count == 6)
    }

    @Test func doesNotNeedAVault() throws {
        let cli = try CLI()
        #expect(!FileManager.default.fileExists(atPath: cli.vault.path))
        #expect(try cli.run(["generate"], passphrase: nil).status == 0)
    }

    @Test func lengthAndWordsTogetherIsUsageError() throws {
        let cli = try CLI()
        #expect(
            try cli.run(["generate", "--length", "3", "--words", "3"], passphrase: nil).status == 2)
    }
}
