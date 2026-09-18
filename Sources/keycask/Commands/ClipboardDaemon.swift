import ArgumentParser

struct ClipboardDaemon: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clipboard-daemon", shouldDisplay: false)

    @Argument var seconds: Int

    func run() throws {
        try Clipboard.runDaemon(seconds: seconds)
    }
}
