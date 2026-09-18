import ArgumentParser
import KeycaskCore

struct Generate: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Generate a password.")

    @Option(name: .long, help: "Password length (default 24).") var length: Int?
    @Option(name: .long, help: "Passphrase of this many words instead.") var words: Int?
    @Flag(name: .long, help: "Copy to the clipboard instead of printing.") var copy = false

    mutating func validate() throws {
        if length != nil, words != nil {
            throw ValidationError("--length and --words are mutually exclusive")
        }
        if let length, length < 1 { throw ValidationError("--length must be at least 1") }
        if let words, words < 1 { throw ValidationError("--words must be at least 1") }
    }

    func run() throws {
        let secret =
            words.map { Generator.passphrase(words: $0) }
            ?? Generator.password(length: length ?? Generator.defaultLength)
        if copy {
            try Clipboard.copyWithTimeout(secret)
            print("copied; clears in \(Clipboard.timeoutSeconds)s")
            return
        }
        print(secret)
    }
}
