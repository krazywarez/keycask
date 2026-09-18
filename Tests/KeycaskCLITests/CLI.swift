import Foundation
import Testing

enum Binary {
    static let url: URL = {
        #if os(macOS)
            if let index = CommandLine.arguments.firstIndex(of: "--test-bundle-path"),
                CommandLine.arguments.count > index + 1
            {
                return URL(fileURLWithPath: CommandLine.arguments[index + 1])
                    .deletingLastPathComponent()  // MacOS
                    .deletingLastPathComponent()  // Contents
                    .deletingLastPathComponent()  // *.xctest
                    .deletingLastPathComponent()  // Products/Debug
                    .appendingPathComponent("keycask")
            }
            for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
                return bundle.bundleURL.deletingLastPathComponent().appendingPathComponent(
                    "keycask")
            }
            fatalError("test bundle not found")
        #elseif os(Windows)
            return Bundle.main.bundleURL.appendingPathComponent("keycask.exe")
        #else
            return Bundle.main.bundleURL.appendingPathComponent("keycask")
        #endif
    }()
}

struct CLI {
    struct Result {
        let status: Int32
        let stdout: String
        let stderr: String
        var lines: [String] { stdout.split(separator: "\n").map(String.init) }
    }

    static let passphrase = "correct horse battery"

    let dir: URL
    let vault: URL

    init() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("keycask-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        vault = dir.appendingPathComponent("vault.kc")
    }

    @discardableResult
    func run(
        _ args: [String],
        stdin: String? = nil,
        passphrase: String? = CLI.passphrase,
        extraEnvironment: [String: String] = [:]
    ) throws -> Result {
        let process = Process()
        process.executableURL = Binary.url
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["KEYCASK_VAULT"] = vault.path
        env.removeValue(forKey: "KEYCASK_PASSPHRASE")
        if let passphrase { env["KEYCASK_PASSPHRASE"] = passphrase }
        for (k, v) in extraEnvironment { env[k] = v }
        process.environment = env

        let out = Pipe()
        let err = Pipe()
        let input = Pipe()
        process.standardOutput = out
        process.standardError = err
        process.standardInput = input
        try process.run()
        if let stdin {
            input.fileHandleForWriting.write(Data(stdin.utf8))
        }
        try input.fileHandleForWriting.close()
        let outData = out.fileHandleForReading.readDataToEndOfFile()
        let errData = err.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Result(
            status: process.terminationStatus,
            stdout: String(decoding: outData, as: UTF8.self),
            stderr: String(decoding: errData, as: UTF8.self))
    }

    /// Runs `init` and returns the harness, for tests that need a vault.
    static func initialized() throws -> CLI {
        let cli = try CLI()
        let r = try cli.run(["init"])
        precondition(r.status == 0, "init failed: \(r.stderr)")
        return cli
    }
}
