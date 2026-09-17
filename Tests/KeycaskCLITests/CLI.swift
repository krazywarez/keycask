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

@Test func binaryIsBuilt() {
    #expect(FileManager.default.isExecutableFile(atPath: Binary.url.path))
}
