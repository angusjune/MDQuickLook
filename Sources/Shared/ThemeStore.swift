import Foundation

struct Theme: Identifiable, Equatable {
    /// Theme name = CSS file basename (Typora convention): "github", "night", …
    let name: String
    let url: URL
    var id: String { name }
}

enum ThemeStore {
    static let fallbackThemeName = "github"
    static let extensionContainerID = "com.angusjune.MDQuickLookPreview"

    /// Shared store lives in the preview extension's sandbox container: the
    /// extension can read it (own container), and the unsandboxed app writes it
    /// (no app-group entitlement possible under ad-hoc signing — pkd also
    /// hard-requires sandboxed QL plug-ins).
    static var sharedStoreDir: URL {
        if let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MDQuickLook", isDirectory: true),
            FileManager.default.fileExists(atPath: dir.path) || sandboxed {
            return dir
        }
        // Unsandboxed (the app): target the extension's container directly.
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/")
            .appendingPathComponent(extensionContainerID)
            .appendingPathComponent("Data/Library/Application Support/MDQuickLook")
    }

    private static var sandboxed: Bool {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path
            .contains("Containers/") == true
    }

    static var installedThemesDir: URL {
        sharedStoreDir.appendingPathComponent("Themes", isDirectory: true)
    }

    static var themesDir: URL {
        Bundle.main.resourceURL!.appendingPathComponent("Themes", isDirectory: true)
    }

    static var builtInThemes: [Theme] {
        themes(in: themesDir)
    }

    static var allThemes: [Theme] {
        var seen = Set<String>()
        var out: [Theme] = []
        // Installed themes live flat or in one `<author>-<repo>/` subdir each.
        let installedDirs = [installedThemesDir]
            + subdirs(of: installedThemesDir)
        for dir in installedDirs + [themesDir] {
            for theme in themes(in: dir) where !seen.contains(theme.name) {
                seen.insert(theme.name)
                out.append(theme)
            }
        }
        return out
    }

    static func isInstalled(_ theme: Theme) -> Bool {
        !theme.url.path.hasPrefix(themesDir.path)
    }

    static func delete(_ theme: Theme) throws {
        try FileManager.default.removeItem(at: theme.url)
    }

    private static func subdirs(of dir: URL) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey])) ?? [])
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
    }

    static func themes(in dir: URL) -> [Theme] {
        (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "css" }
            .map { Theme(name: $0.deletingPathExtension().lastPathComponent, url: $0) }
            .sorted { $0.name < $1.name }
            ?? []
    }

    struct Settings: Codable {
        var defaultTheme: String?
    }

    static var settingsURL: URL { sharedStoreDir.appendingPathComponent("settings.json") }

    static func loadSettings() -> Settings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(Settings.self, from: data) else { return .init() }
        return settings
    }

    static func saveSettings(_ settings: Settings) {
        try? FileManager.default.createDirectory(at: sharedStoreDir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: settingsURL, options: .atomic)
        }
    }

    static var defaultThemeName: String {
        let stored = loadSettings().defaultTheme
        guard let stored, allThemes.contains(where: { $0.name == stored }) else {
            return fallbackThemeName
        }
        return stored
    }

    /// Full CSS for a theme with url(...) asset references inlined as data URIs,
    /// so the document is self-contained (no attachments, no relative fetches).
    static func themeCSS(named name: String) -> String {
        guard let theme = allThemes.first(where: { $0.name == name }) else { return "" }
        let css = (try? String(contentsOf: theme.url, encoding: .utf8)) ?? ""
        return inlineAssets(css, baseURL: theme.url.deletingLastPathComponent())
    }

    private static func inlineAssets(_ css: String, baseURL: URL) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"url\(\s*['"]?([^'")]+)['"]?\s*\)"#) else { return css }
        let range = NSRange(css.startIndex..., in: css)
        var replacements: [(NSRange, String)] = []
        regex.enumerateMatches(in: css, range: range) { match, _, _ in
            guard let match, match.numberOfRanges == 2,
                  let full = Range(match.range, in: css),
                  let pathRange = Range(match.range(at: 1), in: css) else { return }
            let rawPath = String(css[pathRange])
            guard !rawPath.hasPrefix("data:"), !rawPath.hasPrefix("http"), !rawPath.hasPrefix("/") else { return }
            let fileURL = baseURL.appendingPathComponent(rawPath)
            guard let data = try? Data(contentsOf: fileURL),
                  let mime = mimeTypes[fileURL.pathExtension.lowercased()] else { return }
            let dataURI = "data:\(mime);base64,\(data.base64EncodedString())"
            replacements.append((match.range(at: 1), dataURI))
        }
        var out = css
        for (range, value) in replacements.reversed() {
            if let r = Range(range, in: out) { out.replaceSubrange(r, with: value) }
        }
        return out
    }

    private static let mimeTypes: [String: String] = [
        "woff": "font/woff", "woff2": "font/woff2", "ttf": "font/ttf", "otf": "font/otf",
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif",
        "svg": "image/svg+xml", "webp": "image/webp", "eot": "application/vnd.ms-fontobject",
    ]
}
