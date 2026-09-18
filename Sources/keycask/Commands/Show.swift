import ArgumentParser
import KeycaskCore

struct Show: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Show an entry.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Entry id or name.") var ref: String
    @Flag(name: .long, help: "Show the password.") var reveal = false
    @Option(name: .long, help: "Print one field, unmasked.") var field: String?
    @Flag(name: .long, help: "JSON output.") var json = false

    func run() throws {
        let open = try OpenVault.load(global)
        let entry = try open.vault.resolve(ref)
        if let field {
            print(try Output.field(entry, named: field))
        } else if json {
            print(try Output.json(entry, reveal: reveal), terminator: "")
        } else {
            print(Output.text(entry, reveal: reveal), terminator: "")
        }
    }
}
