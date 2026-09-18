import ArgumentParser
import Foundation
import KeycaskCore

enum PasswordInput {
    static func read(prompt: String) throws -> String {
        if Terminal.stdinIsTTY {
            return try Terminal.readSecretLine(prompt: prompt)
        }
        guard let line = Swift.readLine(strippingNewline: true) else {
            throw KeycaskError.usage("no password: pass one on stdin or run on a terminal")
        }
        return line
    }
}

struct PasswordOptions: ParsableArguments {
    @Flag(name: .long, help: "Generate a random password.")
    var generate = false

    @Option(name: .long, help: "Length of the generated password (default 24).")
    var length: Int?

    @Option(name: .long, help: "Generate a passphrase of this many words instead.")
    var words: Int?

    mutating func validate() throws {
        if generate, words != nil {
            throw ValidationError("--generate and --words are mutually exclusive")
        }
        if words != nil, length != nil {
            throw ValidationError("--length and --words are mutually exclusive")
        }
        if let length, length < 1 { throw ValidationError("--length must be at least 1") }
        if let words, words < 1 { throw ValidationError("--words must be at least 1") }
        if length != nil, !generate, words == nil {
            throw ValidationError("--length requires --generate")
        }
    }

    /// nil means the caller must prompt.
    func newPassword() -> String? {
        if let words { return Generator.passphrase(words: words) }
        if generate { return Generator.password(length: length ?? Generator.defaultLength) }
        return nil
    }
}

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Add an entry.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Entry name. Names may repeat; the printed id is unique.") var name: String
    @Option(name: [.short, .customLong("username")], help: "Username.") var username: String?
    @Option(name: .long, help: "URL.") var url: String?
    @Option(name: .long, help: "Notes.") var notes: String?
    @Option(name: .long, help: "Tag. Repeatable.") var tag: [String] = []
    @OptionGroup var password: PasswordOptions

    func run() throws {
        var open = try OpenVault.load(global)
        let secret = try password.newPassword() ?? PasswordInput.read(prompt: "Password: ")
        var entry = Entry(
            name: name, username: username, password: secret, url: url,
            notes: notes, tags: tag)
        while open.vault.entry(id: entry.id) != nil {
            entry = Entry(
                name: name, username: username, password: secret, url: url,
                notes: notes, tags: tag)
        }
        try open.vault.add(entry)
        try open.save()
        print(entry.id.rawValue)
    }
}
