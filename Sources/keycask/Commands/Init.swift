import ArgumentParser

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Create an empty vault.")

    @OptionGroup var global: GlobalOptions

    func run() throws {
        let url = try OpenVault.create(global)
        print("created \(url.path)")
    }
}
