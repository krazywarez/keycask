import Foundation
import KeycaskCore

enum Passphrase {
    static let variable = "KEYCASK_PASSPHRASE"

    static func obtain(
        confirm: Bool, environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> String {
        if let fromEnv = environment[variable] {
            return try validated(fromEnv)
        }
        guard Terminal.stdinIsTTY else {
            throw KeycaskError.usage("no passphrase: set \(variable) or run on a terminal")
        }
        let first = try Terminal.readSecretLine(prompt: "Passphrase: ")
        if confirm {
            let second = try Terminal.readSecretLine(prompt: "Confirm passphrase: ")
            guard first == second else { throw KeycaskError.failure("passphrases do not match") }
        }
        return try validated(first)
    }

    private static func validated(_ passphrase: String) throws -> String {
        guard !passphrase.isEmpty else { throw KeycaskError.failure("passphrase is empty") }
        return passphrase
    }
}
