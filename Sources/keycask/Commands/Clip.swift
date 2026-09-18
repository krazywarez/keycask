import ArgumentParser
import KeycaskCore

struct Clip: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Copy a field to the clipboard. Clears after \(Clipboard.timeoutSeconds) seconds."
    )

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Entry id or name.") var ref: String
    @Option(name: .long, help: "Field to copy (default password).") var field = "password"

    func run() throws {
        let open = try OpenVault.load(global)
        let entry = try open.vault.resolve(ref)
        let value = try Output.field(entry, named: field)
        try Clipboard.copyWithTimeout(value)
        print("copied \(field) of \(entry.name); clears in \(Clipboard.timeoutSeconds)s")
    }
}
