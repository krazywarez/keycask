import Testing

@testable import KeycaskCore

@Suite struct GeneratorTests {
    struct Counter: RandomNumberGenerator {
        var n: UInt64 = 0
        mutating func next() -> UInt64 {
            n &+= 0x9E37_79B9_7F4A_7C15
            return n
        }
    }

    @Test func wordlistHas7776UniqueWords() {
        #expect(Wordlist.words.count == 7776)
        #expect(Set(Wordlist.words).count == 7776)
        #expect(Wordlist.words.first == "abacus")
        #expect(Wordlist.words.allSatisfy { !$0.isEmpty && !$0.contains(" ") })
    }

    @Test func passwordHasRequestedLengthFromTheAlphabet() {
        let allowed = Set(Generator.alphabet)
        for length in [1, 8, 24, 64] {
            let p = Generator.password(length: length)
            #expect(p.count == length)
            #expect(p.allSatisfy { allowed.contains($0) })
        }
        #expect(Generator.password(length: 0) == "")
    }

    @Test func alphabetCoversAllClasses() {
        let s = String(Generator.alphabet)
        #expect(s.contains("A") && s.contains("z") && s.contains("7") && s.contains("!"))
        #expect(Set(Generator.alphabet).count == Generator.alphabet.count)
    }

    @Test func passphraseUsesWordsFromTheList() {
        var a = Counter()
        var b = Counter()
        let produced = Generator.passphrase(words: 5, using: &a)
        let count = UInt32(Wordlist.words.count)
        let expected = (0..<5).map { _ in Wordlist.words[Int(b.next(upperBound: count))] }
            .joined(separator: Generator.wordSeparator)
        #expect(produced == expected)
        #expect(Generator.passphrase(words: 0) == "")
        #expect(!Generator.passphrase(words: 3).isEmpty)
    }

    @Test func seededOutputIsReproducible() {
        var a = Counter()
        var b = Counter()
        #expect(
            Generator.password(length: 16, using: &a) == Generator.password(length: 16, using: &b))
        #expect(
            Generator.passphrase(words: 3, using: &a) == Generator.passphrase(words: 3, using: &b))
    }
}
