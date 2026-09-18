import Foundation
import KeycaskCore

enum Clipboard {
    struct Handoff: Codable, Equatable {
        var secret: String
    }

    struct Tool: Equatable {
        let copy: [String]
        let paste: [String]
    }

    static let timeoutSeconds = 45

    static func shouldClear(secret: String, current: String?) -> Bool {
        current == secret
    }

    static func findTool(
        path: String = ProcessInfo.processInfo.environment["PATH"] ?? "",
        fileManager: FileManager = .default
    ) -> Tool? {
        #if os(Windows)
            let separator: Character = ";"
            let candidates: [(copy: [String], paste: [String])] = [
                (["clip.exe"], ["powershell.exe", "-NoProfile", "-Command", "Get-Clipboard -Raw"])
            ]
        #elseif os(macOS)
            let separator: Character = ":"
            let candidates: [(copy: [String], paste: [String])] = [(["pbcopy"], ["pbpaste"])]
        #else
            let separator: Character = ":"
            let candidates: [(copy: [String], paste: [String])] = [
                (["wl-copy"], ["wl-paste", "--no-newline"]),
                (
                    ["xclip", "-selection", "clipboard"],
                    ["xclip", "-selection", "clipboard", "-o"]
                ),
            ]
        #endif
        let dirs = path.split(separator: separator).map(String.init)
        func locate(_ name: String) -> String? {
            for dir in dirs {
                let full = URL(fileURLWithPath: dir).appendingPathComponent(name).path
                if fileManager.isExecutableFile(atPath: full) { return full }
            }
            return nil
        }
        for candidate in candidates {
            guard let copy = locate(candidate.copy[0]), let paste = locate(candidate.paste[0])
            else {
                continue
            }
            return Tool(
                copy: [copy] + candidate.copy.dropFirst(),
                paste: [paste] + candidate.paste.dropFirst())
        }
        return nil
    }

    /// Removes exactly one trailing line break, which some paste tools add.
    static func stripTrailingNewline(_ s: String) -> String {
        var scalars = s.unicodeScalars
        guard scalars.last == "\n" else { return s }
        scalars.removeLast()
        if scalars.last == "\r" { scalars.removeLast() }
        return String(scalars)
    }

    static func read() throws -> String {
        let tool = try requireTool()
        let (status, output) = try runTool(tool.paste, input: nil)
        guard status == 0 else { return "" }
        return stripTrailingNewline(output)
    }

    static func write(_ text: String) throws {
        let tool = try requireTool()
        let (status, _) = try runTool(tool.copy, input: text)
        guard status == 0 else { throw KeycaskError.failure("clipboard tool failed") }
    }

    static func copyWithTimeout(_ secret: String, seconds: Int = timeoutSeconds) throws {
        _ = try requireTool()
        let handoff = Handoff(secret: secret)
        try write(secret)
        let process = Process()
        process.executableURL = Bundle.main.executableURL
        process.arguments = ["clipboard-daemon", String(seconds)]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        let input = Pipe()
        process.standardInput = input
        do {
            try process.run()
            input.fileHandleForWriting.write(try JSONEncoder().encode(handoff))
            try input.fileHandleForWriting.close()
        } catch {
            throw KeycaskError.failure("start clipboard daemon: \(error)")
        }
    }

    static func runDaemon(seconds: Int) throws {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        let handoff: Handoff
        do {
            handoff = try JSONDecoder().decode(Handoff.self, from: data)
        } catch {
            throw KeycaskError.failure("bad handoff")
        }
        Thread.sleep(forTimeInterval: TimeInterval(seconds))
        let current = try? read()
        guard shouldClear(secret: handoff.secret, current: current) else { return }
        try write("")
    }

    private static func requireTool() throws -> Tool {
        guard let tool = findTool() else {
            #if os(Windows)
                let hint = "clip.exe and powershell.exe"
            #elseif os(macOS)
                let hint = "pbcopy and pbpaste"
            #else
                let hint = "wl-clipboard or xclip"
            #endif
            throw KeycaskError.failure("no clipboard tool found: install \(hint)")
        }
        return tool
    }

    private static func runTool(_ argv: [String], input: String?) throws -> (Int32, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: argv[0])
        process.arguments = Array(argv.dropFirst())
        let out = Pipe()
        process.standardOutput = out
        process.standardError = FileHandle.nullDevice
        let inPipe = Pipe()
        process.standardInput = inPipe
        do {
            try process.run()
        } catch {
            throw KeycaskError.failure("run \(argv[0]): \(error)")
        }
        if let input { inPipe.fileHandleForWriting.write(Data(input.utf8)) }
        try? inPipe.fileHandleForWriting.close()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
