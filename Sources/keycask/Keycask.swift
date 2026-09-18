import ArgumentParser

struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Path to the vault file.")
    var vault: String?
}

struct Keycask: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "keycask",
        abstract: "Command-line password manager. One passphrase-encrypted vault file.",
        subcommands: [
            Init.self, Add.self, Show.self, Ls.self, Find.self, Edit.self, Rm.self, Generate.self,
            Clip.self, ClipboardDaemon.self,
        ]
    )

    @OptionGroup var global: GlobalOptions
}
