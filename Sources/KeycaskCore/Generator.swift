public enum Generator {
    public static let alphabet: [Character] = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{};:,.<>?"
    )
    public static let defaultLength = 24
    public static let wordSeparator = "-"

    public static func password(length: Int) -> String {
        var rng = SystemRandomNumberGenerator()
        return password(length: length, using: &rng)
    }

    public static func password(length: Int, using rng: inout some RandomNumberGenerator) -> String
    {
        var chars: [Character] = []
        chars.reserveCapacity(max(length, 0))
        for _ in 0..<max(length, 0) {
            chars.append(alphabet[Int(rng.next(upperBound: UInt32(alphabet.count)))])
        }
        return String(chars)
    }

    public static func passphrase(words: Int) -> String {
        var rng = SystemRandomNumberGenerator()
        return passphrase(words: words, using: &rng)
    }

    public static func passphrase(words: Int, using rng: inout some RandomNumberGenerator) -> String
    {
        let list = Wordlist.words
        var picked: [String] = []
        for _ in 0..<max(words, 0) {
            picked.append(list[Int(rng.next(upperBound: UInt32(list.count)))])
        }
        return picked.joined(separator: wordSeparator)
    }
}
