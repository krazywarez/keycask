import ArgumentParser
import KeycaskCore

struct Rm: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Remove an entry.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Entry id or name.") var ref: String
    @Flag(name: .long, help: "Do not ask for confirmation.") var yes = false

    func run() throws {
        var open = try OpenVault.load(global)
        let target = try open.vault.resolve(ref)
        if !yes {
            guard Terminal.stdinIsTTY else {
                throw KeycaskError.usage("refusing to remove without --yes when not on a terminal")
            }
            guard Terminal.confirm("remove \(target.name) (\(target.id.rawValue))?") else {
                throw KeycaskError.failure("aborted")
            }
        }
        try open.vault.remove(id: target.id)
        try open.save()
    }
}
