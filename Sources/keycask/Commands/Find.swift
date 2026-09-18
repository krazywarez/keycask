import ArgumentParser
import KeycaskCore

struct Find: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Search entries.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Case-insensitive substring.") var query: String
    @Flag(name: .long, help: "JSON output.") var json = false

    func run() throws {
        let open = try OpenVault.load(global)
        let entries = open.vault.search(query)
        if json {
            print(try Output.json(entries, reveal: false), terminator: "")
        } else {
            print(Output.table(entries), terminator: "")
        }
    }
}
