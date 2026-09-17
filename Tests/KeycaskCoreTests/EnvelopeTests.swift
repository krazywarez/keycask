import Crypto
import Foundation
import Testing

@testable import KeycaskCore

@Suite struct EnvelopeTests {
    // Low iteration count keeps the suite fast. Production uses Envelope.defaultIterations.
    let kdf = Envelope.KDFParams(
        name: Envelope.kdfName, iterations: 1_000, salt: Data(repeating: 7, count: 16))

    func hex(_ key: SymmetricKey) -> String {
        key.withUnsafeBytes { $0.map { String(format: "%02x", $0) }.joined() }
    }

    @Test func pbkdf2MatchesPublishedVectors() throws {
        let one = Envelope.KDFParams(name: Envelope.kdfName, iterations: 1, salt: Data("salt".utf8))
        #expect(
            hex(try Envelope.deriveKey(passphrase: "password", kdf: one))
                == "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b")
        let many = Envelope.KDFParams(
            name: Envelope.kdfName, iterations: 4096, salt: Data("salt".utf8))
        #expect(
            hex(try Envelope.deriveKey(passphrase: "password", kdf: many))
                == "c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a")
    }

    @Test func sealThenOpenRoundTrips() throws {
        let env = try Envelope.seal(Data("hello vault".utf8), passphrase: "pw", kdf: kdf)
        #expect(env.format == 1)
        #expect(env.kdf == kdf)
        #expect(try env.open(passphrase: "pw") == Data("hello vault".utf8))
    }

    @Test func wrongPassphraseCannotDecrypt() throws {
        let env = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        #expect(throws: KeycaskError.cannotDecrypt) { try env.open(passphrase: "PW") }
    }

    @Test func tamperedBoxCannotDecrypt() throws {
        var env = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        env.box[env.box.count - 1] ^= 0x01
        #expect(throws: KeycaskError.cannotDecrypt) { try env.open(passphrase: "pw") }
    }

    @Test func nonceIsFreshAndSaltIsKept() throws {
        let a = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        let b = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        #expect(a.box != b.box)
        #expect(a.kdf.salt == b.kdf.salt)
    }

    @Test func freshParamsUseDefaults() {
        let p = Envelope.KDFParams.fresh()
        #expect(p.name == "pbkdf2-hmac-sha256")
        #expect(p.iterations == 600_000)
        #expect(p.salt.count == 16)
        #expect(p.salt != Envelope.KDFParams.fresh().salt)
    }

    @Test func encodedShapeMatchesTheSpec() throws {
        let env = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        let json = try JSONSerialization.jsonObject(with: env.encoded()) as! [String: Any]
        #expect(json["format"] as? Int == 1)
        let k = json["kdf"] as! [String: Any]
        #expect(k["name"] as? String == "pbkdf2-hmac-sha256")
        #expect(k["iterations"] as? Int == 1_000)
        #expect(Data(base64Encoded: k["salt"] as! String) == kdf.salt)
        #expect(Data(base64Encoded: json["box"] as! String) == env.box)
        #expect(try Envelope(parsing: env.encoded()) == env)
    }

    @Test func malformedInputsAreCorrupt() throws {
        #expect(throws: KeycaskError.self) { try Envelope(parsing: Data("not json".utf8)) }
        #expect(throws: KeycaskError.self) { try Envelope(parsing: Data("{\"format\":1}".utf8)) }

        var wrongFormat = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        wrongFormat.format = 2
        #expect(throws: KeycaskError.corrupt("unsupported format 2")) {
            try wrongFormat.open(passphrase: "pw")
        }

        var wrongKDF = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        wrongKDF.kdf.name = "argon2id"
        #expect(throws: KeycaskError.corrupt("unsupported kdf argon2id")) {
            try wrongKDF.open(passphrase: "pw")
        }

        var shortBox = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        shortBox.box = Data([1, 2, 3])
        #expect(throws: KeycaskError.corrupt("box too short")) {
            try shortBox.open(passphrase: "pw")
        }
    }

    @Test func outOfRangeIterationsAreCorrupt() throws {
        var env = try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: kdf)
        env.kdf.iterations = -1
        #expect(throws: KeycaskError.corrupt("bad iteration count -1")) {
            try env.open(passphrase: "pw")
        }
        env.kdf.iterations = 0
        #expect(throws: KeycaskError.corrupt("bad iteration count 0")) {
            try env.open(passphrase: "pw")
        }
        let tooMany = Envelope.KDFParams(
            name: Envelope.kdfName, iterations: Int(UInt32.max) + 1, salt: kdf.salt)
        #expect(throws: KeycaskError.corrupt("bad iteration count \(Int(UInt32.max) + 1)")) {
            try Envelope.seal(Data("x".utf8), passphrase: "pw", kdf: tooMany)
        }
    }

    @Test func passphraseIsNFCNormalized() throws {
        let composed = "caf\u{00E9}"
        let decomposed = "cafe\u{0301}"
        let env = try Envelope.seal(Data("x".utf8), passphrase: composed, kdf: kdf)
        #expect(try env.open(passphrase: decomposed) == Data("x".utf8))
    }
}
