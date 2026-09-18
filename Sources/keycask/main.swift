import ArgumentParser
import Foundation
import KeycaskCore

func fail(_ text: String, code: Int32) -> Never {
    FileHandle.standardError.write(Data((text + "\n").utf8))
    exit(code)
}

do {
    var command = try Keycask.parseAsRoot()
    try command.run()
} catch let error as KeycaskError {
    fail(error.message, code: error.exitCode)
} catch {
    let text = Keycask.fullMessage(for: error)
    let code = Keycask.exitCode(for: error)
    if code.isSuccess {
        print(text)
        exit(0)
    }
    fail(text, code: code.rawValue == 64 ? 2 : 1)
}
