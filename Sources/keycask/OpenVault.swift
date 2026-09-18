import Foundation
import KeycaskCore

struct OpenVault {
    var vault: Vault
    let kdf: Envelope.KDFParams
    let url: URL
    let passphrase: String

    static func load(_ options: GlobalOptions) throws -> OpenVault {
        let url = Paths.vaultURL(override: options.vault)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            throw KeycaskError.noVault(url.path)
        } catch {
            if !FileManager.default.fileExists(atPath: url.path) {
                throw KeycaskError.noVault(url.path)
            }
            throw KeycaskError.io("read \(url.path): \(error)")
        }
        let envelope = try Envelope(parsing: data)
        let passphrase = try Passphrase.obtain(confirm: false)
        let plaintext = try envelope.open(passphrase: passphrase)
        let vault = try VaultCodec.decode(plaintext)
        return OpenVault(vault: vault, kdf: envelope.kdf, url: url, passphrase: passphrase)
    }

    static func create(_ options: GlobalOptions) throws -> URL {
        let url = Paths.vaultURL(override: options.vault)
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw KeycaskError.vaultExists(url.path)
        }
        let passphrase = try Passphrase.obtain(confirm: true)
        let fresh = OpenVault(vault: Vault(), kdf: .fresh(), url: url, passphrase: passphrase)
        try fresh.save()
        return url
    }

    func save() throws {
        let plaintext = try VaultCodec.encode(vault)
        let envelope = try Envelope.seal(plaintext, passphrase: passphrase, kdf: kdf)
        try AtomicFile.write(try envelope.encoded(), to: url)
    }
}
