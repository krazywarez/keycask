public enum KeycaskError: Error, Equatable, Sendable {
    case notFound(String)
    case ambiguous(name: String, candidates: [Entry])
    case cannotDecrypt
    case corrupt(String)
    case vaultExists(String)
    case noVault(String)
    case duplicateID(EntryID)
    case io(String)
    case usage(String)
    case failure(String)

    public var exitCode: Int32 {
        switch self {
        case .failure, .io, .corrupt, .vaultExists, .duplicateID: 1
        case .usage: 2
        case .notFound, .noVault: 3
        case .cannotDecrypt: 4
        case .ambiguous: 5
        }
    }

    public var message: String {
        switch self {
        case .notFound(let what): "\(what): not found"
        case .ambiguous(let name, let candidates):
            (["\(name): ambiguous, use an id:"]
                + candidates.map { "  \($0.id.rawValue)  \($0.username ?? "")  \($0.url ?? "")" })
                .joined(separator: "\n")
        case .cannotDecrypt: "cannot decrypt: wrong passphrase or damaged vault"
        case .corrupt(let why): "vault is corrupt: \(why)"
        case .vaultExists(let path): "vault \(path) already exists"
        case .noVault(let path): "vault \(path) not found (run `keycask init`)"
        case .duplicateID(let id): "duplicate id \(id.rawValue)"
        case .io(let why): why
        case .usage(let why): why
        case .failure(let why): why
        }
    }
}
