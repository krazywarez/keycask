import Foundation

enum Paths {
    static let variable = "KEYCASK_VAULT"

    static func vaultURL(
        override: String?, environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL {
        if let override { return URL(fileURLWithPath: override) }
        if let env = environment[variable], !env.isEmpty { return URL(fileURLWithPath: env) }
        return defaultDirectory(environment: environment)
            .appendingPathComponent("keycask").appendingPathComponent("vault.kc")
    }

    private static func defaultDirectory(environment: [String: String]) -> URL {
        #if os(Windows)
            let base = environment["LOCALAPPDATA"] ?? environment["USERPROFILE"] ?? "."
            return URL(fileURLWithPath: base)
        #else
            if let xdg = environment["XDG_DATA_HOME"], !xdg.isEmpty {
                return URL(fileURLWithPath: xdg)
            }
            let home = environment["HOME"] ?? "."
            return URL(fileURLWithPath: home).appendingPathComponent(".local/share")
        #endif
    }
}
