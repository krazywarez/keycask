import Foundation
import KeycaskCore

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif os(Windows)
    import CRT
    import WinSDK
#endif

enum Terminal {
    static var stdinIsTTY: Bool {
        #if os(Windows)
            return _isatty(_fileno(stdin)) != 0
        #else
            return isatty(STDIN_FILENO) != 0
        #endif
    }

    static func write(_ text: String) {
        FileHandle.standardError.write(Data(text.utf8))
    }

    static func readLine(prompt: String) -> String? {
        write(prompt)
        return Swift.readLine(strippingNewline: true)
    }

    static func confirm(_ question: String) -> Bool {
        guard let answer = readLine(prompt: question + " [y/N] ") else { return false }
        return answer.lowercased().hasPrefix("y")
    }

    static func readSecretLine(prompt: String) throws -> String {
        write(prompt)
        defer { write("\n") }
        return try withEchoDisabled { Swift.readLine(strippingNewline: true) ?? "" }
    }

    #if os(Windows)
        private static func withEchoDisabled<T>(_ body: () throws -> T) throws -> T {
            let handle = GetStdHandle(DWORD(bitPattern: -10))
            var mode: DWORD = 0
            guard GetConsoleMode(handle, &mode).boolValue else {
                throw KeycaskError.io("GetConsoleMode failed")
            }
            SetConsoleMode(handle, mode & ~DWORD(ENABLE_ECHO_INPUT))
            defer { SetConsoleMode(handle, mode) }
            return try body()
        }
    #else
        private static func withEchoDisabled<T>(_ body: () throws -> T) throws -> T {
            var original = termios()
            guard tcgetattr(STDIN_FILENO, &original) == 0 else {
                throw KeycaskError.io("tcgetattr failed")
            }
            var quiet = original
            quiet.c_lflag &= ~tcflag_t(ECHO)
            tcsetattr(STDIN_FILENO, TCSANOW, &quiet)
            defer { tcsetattr(STDIN_FILENO, TCSANOW, &original) }
            return try body()
        }
    #endif
}
