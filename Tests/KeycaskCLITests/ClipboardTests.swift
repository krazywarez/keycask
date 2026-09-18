import Foundation
import Testing

@testable import keycask

@Suite struct ClipboardTests {
    @Test func clearsOnlyWhenClipboardStillHoldsTheSecret() {
        #expect(Clipboard.shouldClear(secret: "s", current: "s"))
        #expect(!Clipboard.shouldClear(secret: "s", current: "user pasted"))
        #expect(!Clipboard.shouldClear(secret: "s", current: nil))
    }

    @Test func handoffRoundTrips() throws {
        let h = Clipboard.Handoff(secret: "s3cret")
        let data = try JSONEncoder().encode(h)
        #expect(try JSONDecoder().decode(Clipboard.Handoff.self, from: data) == h)
    }

    @Test func stripsOneTrailingNewline() {
        #expect(Clipboard.stripTrailingNewline("s\r\n") == "s")
        #expect(Clipboard.stripTrailingNewline("s\n") == "s")
        #expect(Clipboard.stripTrailingNewline("s") == "s")
        #expect(Clipboard.stripTrailingNewline("s\n\n") == "s\n")
    }

    @Test func findToolScansPathInOrder() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("keycask-clip-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        #expect(Clipboard.findTool(path: dir.path) == nil)

        #if os(macOS)
            let names = ["pbcopy", "pbpaste"]
        #elseif os(Windows)
            let names = ["clip.exe", "powershell.exe"]
        #else
            let names = ["xclip"]
        #endif
        for n in names {
            let f = dir.appendingPathComponent(n)
            try Data("#!/bin/sh\n".utf8).write(to: f)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: f.path)
        }
        let tool = Clipboard.findTool(path: dir.path)
        #expect(tool != nil)
        #expect(tool?.copy.first?.hasPrefix(dir.path) == true)
    }

    @Test func daemonWithoutHandoffFails() throws {
        let cli = try CLI()
        let r = try cli.run(["clipboard-daemon", "1"], stdin: "not json", passphrase: nil)
        #expect(r.status == 1)
    }

    @Test func daemonIsHiddenFromHelp() throws {
        let cli = try CLI()
        let r = try cli.run(["--help"], passphrase: nil)
        #expect(!r.stdout.contains("clipboard-daemon"))
        #expect(r.stdout.contains("clip"))
    }

    @Test func clipOfMissingEntryIsNotFoundBeforeTouchingClipboard() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["clip", "nope"])
        #expect(r.status == 3)
    }

    #if !os(Windows)
        /// A temp directory of clipboard tools backed by a file, so tests never
        /// touch the real clipboard.
        struct Stub {
            let dir: URL

            var file: URL { dir.appendingPathComponent("clip.txt") }
            var environment: [String: String] { ["PATH": "\(dir.path):/bin:/usr/bin"] }

            init() throws {
                dir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("keycask-clip-stub-\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                #if os(macOS)
                    try install("pbcopy", "#!/bin/sh\ncat > \"$(dirname \"$0\")/clip.txt\"\n")
                    try install(
                        "pbpaste", "#!/bin/sh\ncat \"$(dirname \"$0\")/clip.txt\" 2>/dev/null\n")
                #else
                    try install(
                        "xclip",
                        """
                        #!/bin/sh
                        for a in "$@"; do
                            if [ "$a" = "-o" ]; then
                                cat "$(dirname "$0")/clip.txt" 2>/dev/null
                                exit 0
                            fi
                        done
                        cat > "$(dirname "$0")/clip.txt"

                        """)
                #endif
            }

            func contents() -> String {
                (try? String(contentsOf: file, encoding: .utf8)) ?? ""
            }

            func set(_ text: String) throws {
                try Data(text.utf8).write(to: file)
            }

            private func install(_ name: String, _ script: String) throws {
                let url = dir.appendingPathComponent(name)
                try Data(script.utf8).write(to: url)
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o755], ofItemAtPath: url.path)
            }
        }

        @Test func clipCopiesTheFieldThroughTheTool() throws {
            let cli = try CLI.initialized()
            let stub = try Stub()
            try cli.run(["add", "t", "--generate"])
            let expected = try cli.run(["show", "t", "--field", "password"]).stdout
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let start = Date()
            let r = try cli.run(["clip", "t"], extraEnvironment: stub.environment)
            let elapsed = Date().timeIntervalSince(start)

            #expect(r.status == 0)
            #expect(r.stdout.contains("copied password of t"))
            #expect(stub.contents() == expected)
            #expect(elapsed < 5)
        }

        @Test func generateCopyWritesTheTool() throws {
            let cli = try CLI()
            let stub = try Stub()
            let r = try cli.run(
                ["generate", "--copy"], passphrase: nil, extraEnvironment: stub.environment)
            #expect(r.status == 0)
            let copied = stub.contents()
            #expect(copied.count == 24)
            #expect(!r.stdout.contains(copied))
        }

        @Test func daemonClearsWhenClipboardStillHoldsSecret() throws {
            let cli = try CLI()
            let stub = try Stub()
            try stub.set("probe")
            let r = try cli.run(
                ["clipboard-daemon", "1"], stdin: #"{"secret":"probe"}"#, passphrase: nil,
                extraEnvironment: stub.environment)
            #expect(r.status == 0)
            #expect(stub.contents() == "")
        }

        @Test func daemonLeavesForeignContentAlone() throws {
            let cli = try CLI()
            let stub = try Stub()
            try stub.set("other")
            let r = try cli.run(
                ["clipboard-daemon", "1"], stdin: #"{"secret":"probe"}"#, passphrase: nil,
                extraEnvironment: stub.environment)
            #expect(r.status == 0)
            #expect(stub.contents() == "other")
        }
    #endif
}
