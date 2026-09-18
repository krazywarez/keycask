import ArgumentParser
import KeycaskCore

struct Edit: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Change an entry.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Entry id or name.") var ref: String
    @Option(name: .long, help: "New name.") var name: String?
    @Option(name: [.short, .customLong("username")], help: "New username.") var username: String?
    @Option(name: .long, help: "New URL.") var url: String?
    @Option(name: .long, help: "New notes.") var notes: String?
    @Option(name: .long, help: "Add a tag. Repeatable.") var tag: [String] = []
    @Option(name: .long, help: "Remove a tag. Repeatable.") var untag: [String] = []
    @Flag(name: .long, help: "Prompt for a new password.") var password = false
    @OptionGroup var generated: PasswordOptions

    mutating func validate() throws {
        let changes =
            [name, username, url, notes].contains { $0 != nil }
            || !tag.isEmpty || !untag.isEmpty || password || generated.generate
            || generated.words != nil
        guard changes else { throw ValidationError("nothing to change") }
        if password, generated.newPassword() != nil {
            throw ValidationError("--password cannot be combined with --generate or --words")
        }
    }

    func run() throws {
        var open = try OpenVault.load(global)
        let target = try open.vault.resolve(ref)
        let newSecret: String? =
            password ? try PasswordInput.read(prompt: "New password: ") : generated.newPassword()
        try open.vault.update(id: target.id) { e in
            if let name { e.name = name }
            if let username { e.username = username }
            if let url { e.url = url }
            if let notes { e.notes = notes }
            if let newSecret { e.password = newSecret }
            let drop = Set(untag.map { $0.lowercased() })
            e.tags = e.tags.filter { !drop.contains($0.lowercased()) } + tag
        }
        try open.save()
    }
}
