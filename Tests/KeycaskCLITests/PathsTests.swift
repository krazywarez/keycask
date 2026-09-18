import Foundation
import Testing

@testable import keycask

@Suite struct PathsTests {
    @Test func overrideWinsOverEverything() {
        let url = Paths.vaultURL(
            override: "/x/v.kc", environment: ["KEYCASK_VAULT": "/y", "HOME": "/h"])
        #expect(url.path == "/x/v.kc")
    }

    @Test func environmentVariableWinsOverDefaults() {
        let url = Paths.vaultURL(
            override: nil, environment: ["KEYCASK_VAULT": "/y/v.kc", "HOME": "/h"])
        #expect(url.path == "/y/v.kc")
    }

    #if os(Windows)
        @Test func windowsUsesLocalAppData() {
            let url = Paths.vaultURL(
                override: nil, environment: ["LOCALAPPDATA": "C:\\Users\\u\\AppData\\Local"])
            #expect(
                url.path.hasSuffix("keycask/vault.kc") || url.path.hasSuffix("keycask\\vault.kc"))
        }
    #else
        @Test func xdgDataHomeIsUsedWhenSet() {
            let url = Paths.vaultURL(
                override: nil, environment: ["XDG_DATA_HOME": "/d", "HOME": "/h"])
            #expect(url.path == "/d/keycask/vault.kc")
        }

        @Test func homeFallback() {
            let url = Paths.vaultURL(override: nil, environment: ["HOME": "/h"])
            #expect(url.path == "/h/.local/share/keycask/vault.kc")
        }
    #endif
}
