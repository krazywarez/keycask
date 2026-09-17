import Crypto
import Foundation
import _CryptoExtras

public struct Envelope: Codable, Equatable, Sendable {
    public struct KDFParams: Codable, Equatable, Sendable {
        public var name: String
        public var iterations: Int
        public var salt: Data

        public init(name: String, iterations: Int, salt: Data) {
            self.name = name
            self.iterations = iterations
            self.salt = salt
        }

        public static func fresh(iterations: Int = Envelope.defaultIterations) -> KDFParams {
            var rng = SystemRandomNumberGenerator()
            let salt = Data(
                (0..<Envelope.saltLength).map { _ in UInt8.random(in: .min ... .max, using: &rng) })
            return KDFParams(name: Envelope.kdfName, iterations: iterations, salt: salt)
        }
    }

    public static let currentFormat = 1
    public static let defaultIterations = 600_000
    public static let kdfName = "pbkdf2-hmac-sha256"
    public static let saltLength = 16
    static let keyLength = 32
    static let minimumBoxLength = 12 + 16

    public var format: Int
    public var kdf: KDFParams
    public var box: Data

    public static func seal(_ plaintext: Data, passphrase: String, kdf: KDFParams) throws
        -> Envelope
    {
        let key = try deriveKey(passphrase: passphrase, kdf: kdf)
        do {
            let sealed = try ChaChaPoly.seal(plaintext, using: key)
            return Envelope(format: currentFormat, kdf: kdf, box: sealed.combined)
        } catch {
            throw KeycaskError.failure("encrypt: \(error)")
        }
    }

    public func open(passphrase: String) throws -> Data {
        guard format == Self.currentFormat else {
            throw KeycaskError.corrupt("unsupported format \(format)")
        }
        guard kdf.name == Self.kdfName else {
            throw KeycaskError.corrupt("unsupported kdf \(kdf.name)")
        }
        guard box.count >= Self.minimumBoxLength else {
            throw KeycaskError.corrupt("box too short")
        }
        let key = try Self.deriveKey(passphrase: passphrase, kdf: kdf)
        let sealed: ChaChaPoly.SealedBox
        do {
            sealed = try ChaChaPoly.SealedBox(combined: box)
        } catch {
            throw KeycaskError.corrupt("box is malformed")
        }
        do {
            return try ChaChaPoly.open(sealed, using: key)
        } catch {
            throw KeycaskError.cannotDecrypt
        }
    }

    public init(parsing data: Data) throws {
        do {
            self = try JSONDecoder().decode(Envelope.self, from: data)
        } catch {
            throw KeycaskError.corrupt("not a keycask vault: \(error)")
        }
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        do {
            return try encoder.encode(self)
        } catch {
            throw KeycaskError.io("encode envelope: \(error)")
        }
    }

    init(format: Int, kdf: KDFParams, box: Data) {
        self.format = format
        self.kdf = kdf
        self.box = box
    }

    static func deriveKey(passphrase: String, kdf: KDFParams) throws -> SymmetricKey {
        guard (1...Int(UInt32.max)).contains(kdf.iterations) else {
            throw KeycaskError.corrupt("bad iteration count \(kdf.iterations)")
        }
        let normalized = Array(passphrase.precomposedStringWithCanonicalMapping.utf8)
        do {
            return try KDF.Insecure.PBKDF2.deriveKey(
                from: normalized, salt: kdf.salt, using: .sha256,
                outputByteCount: keyLength, unsafeUncheckedRounds: kdf.iterations)
        } catch {
            throw KeycaskError.failure("derive key: \(error)")
        }
    }
}
