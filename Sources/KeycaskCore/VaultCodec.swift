import Foundation

public enum VaultCodec {
    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public static func encode(_ vault: Vault) throws -> Data {
        do {
            return try makeEncoder().encode(vault)
        } catch {
            throw KeycaskError.io("encode vault: \(error)")
        }
    }

    public static func decode(_ data: Data) throws -> Vault {
        do {
            return try makeDecoder().decode(Vault.self, from: data)
        } catch {
            throw KeycaskError.corrupt("\(error)")
        }
    }
}
