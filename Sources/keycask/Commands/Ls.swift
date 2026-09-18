import ArgumentParser
import KeycaskCore

struct Ls: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "List entries.")

    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Only entries with this tag.") var tag: String?
    @Flag(name: .long, help: "JSON output.") var json = false

    func run() throws {
        let open = try OpenVault.load(global)
        let entries = tag.map { open.vault.filter(tag: $0) } ?? open.vault.sortedEntries
        if json {
            print(try Output.json(entries, reveal: false), terminator: "")
        } else {
            print(Output.table(entries), terminator: "")
        }
    }
}
