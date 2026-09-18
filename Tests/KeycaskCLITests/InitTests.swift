import Foundation
import Testing

@Suite struct InitTests {
    @Test func initCreatesVaultAndPrintsPath() throws {
        let cli = try CLI()
        let r = try cli.run(["init"])
        #expect(r.status == 0)
        #expect(r.stdout.contains(cli.vault.path))
        #expect(FileManager.default.fileExists(atPath: cli.vault.path))
        let text = try String(contentsOf: cli.vault, encoding: .utf8)
        #expect(text.contains("\"format\" : 1"))
        #expect(text.contains("pbkdf2-hmac-sha256"))
        #expect(!text.contains("entries"))
    }

    @Test func initRefusesExistingVault() throws {
        let cli = try CLI.initialized()
        let r = try cli.run(["init"])
        #expect(r.status == 1)
        #expect(r.stderr.contains("already exists"))
    }

    @Test func initWithoutPassphraseOrTTYIsUsageError() throws {
        let cli = try CLI()
        let r = try cli.run(["init"], passphrase: nil)
        #expect(r.status == 2)
        #expect(r.stderr.contains("KEYCASK_PASSPHRASE"))
    }

    @Test func emptyPassphraseIsRejected() throws {
        let cli = try CLI()
        let r = try cli.run(["init"], passphrase: "")
        #expect(r.status == 1)
        #expect(r.stderr.contains("empty"))
    }

    @Test func vaultFlagBeatsEnvironment() throws {
        let cli = try CLI()
        let other = cli.dir.appendingPathComponent("elsewhere.kc")
        let r = try cli.run(["--vault", other.path, "init"])
        #expect(r.status == 0)
        #expect(FileManager.default.fileExists(atPath: other.path))
        #expect(!FileManager.default.fileExists(atPath: cli.vault.path))
    }

    @Test func unknownSubcommandIsUsageError() throws {
        let cli = try CLI()
        let r = try cli.run(["frobnicate"])
        #expect(r.status == 2)
        #expect(r.stderr.contains("Usage"))
    }

    @Test func helpExitsZero() throws {
        let cli = try CLI()
        let r = try cli.run(["--help"])
        #expect(r.status == 0)
        #expect(r.stdout.contains("init"))
    }

    #if !os(Windows)
        @Test func vaultIsPrivateOnUnix() throws {
            let cli = try CLI.initialized()
            let attrs = try FileManager.default.attributesOfItem(atPath: cli.vault.path)
            let mode = (attrs[.posixPermissions] as! NSNumber).intValue & 0o777
            #expect(mode == 0o600)
        }

        @Test func preExistingTempFileDoesNotWeakenPermissions() throws {
            let cli = try CLI()
            let temp = cli.dir.appendingPathComponent("vault.kc.tmp")
            FileManager.default.createFile(
                atPath: temp.path, contents: Data(), attributes: [.posixPermissions: 0o644])

            let r = try cli.run(["init"])
            #expect(r.status == 0)
            let attrs = try FileManager.default.attributesOfItem(atPath: cli.vault.path)
            let mode = (attrs[.posixPermissions] as! NSNumber).intValue & 0o777
            #expect(mode == 0o600)
            #expect(!FileManager.default.fileExists(atPath: temp.path))
        }

        @Test func symlinkedTempFileIsNotFollowed() throws {
            let cli = try CLI()
            let victim = cli.dir.appendingPathComponent("victim.txt")
            FileManager.default.createFile(atPath: victim.path, contents: Data())
            let temp = cli.dir.appendingPathComponent("vault.kc.tmp")
            try FileManager.default.createSymbolicLink(at: temp, withDestinationURL: victim)

            let r = try cli.run(["init"])
            #expect(r.status == 0)
            let victimAttrs = try FileManager.default.attributesOfItem(atPath: victim.path)
            #expect((victimAttrs[.size] as! NSNumber).intValue == 0)
            let attrs = try FileManager.default.attributesOfItem(atPath: cli.vault.path)
            #expect(attrs[.type] as? FileAttributeType == .typeRegular)
            #expect((attrs[.posixPermissions] as! NSNumber).intValue & 0o777 == 0o600)
        }
    #endif

    @Test func noTempFileLeftBehind() throws {
        let cli = try CLI.initialized()
        let names = try FileManager.default.contentsOfDirectory(atPath: cli.dir.path)
        #expect(names == ["vault.kc"])
    }
}
