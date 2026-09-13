import Foundation

/// Installs Themes from `author/repo` Theme Repos (ADR-0003).
/// App-only: relies on being unsandboxed (writes into the extension's container).
enum ThemeInstaller {
    struct Repo: Equatable {
        let author: String
        let name: String
    }

    static func parse(_ input: String) -> Repo? {
        var s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: #"^https?://(www\.)?github\.com/"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\.git$"#, with: "", options: .regularExpression)
        let parts = s.split(separator: "/")
        guard parts.count == 2 else { return nil }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_")
        for p in parts where p.rangeOfCharacter(from: allowed.inverted) != nil { return nil }
        return Repo(author: String(parts[0]), name: String(parts[1]))
    }

    /// Downloads the repo zip, extracts it, and copies every `*.css` found at
    /// depth 0–1 (with sibling assets) into `<author>-<repo>/` under the
    /// installed-themes dir. Returns the names of the newly available Themes.
    static func install(_ input: String) async throws -> [String] {
        guard let repo = parse(input) else {
            throw InstallError.badInput(input)
        }
        let zipURL = URL(string: "https://codeload.github.com/\(repo.author)/\(repo.name)/zip/HEAD")!
        let (zipData, resp) = try await URLSession.shared.data(from: zipURL)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw InstallError.repoNotFound(repo.author + "/" + repo.name)
        }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdql-install-\(UUID().uuidString)", isDirectory: true)
        let zipFile = tmp.appendingPathComponent("theme.zip")
        let extractDir = tmp.appendingPathComponent("x", isDirectory: true)
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        try zipData.write(to: zipFile)

        let ditto = Process()
        ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        ditto.arguments = ["-x", "-k", zipFile.path, extractDir.path]
        try ditto.run()
        ditto.waitUntilExit()
        guard ditto.terminationStatus == 0 else { throw InstallError.extractFailed }

        // Candidate css files at depth 0–1 inside the extracted tree.
        var cssParents = Set<URL>()
        var cssFiles: [URL] = []
        let root = extractDir.appendingPathComponent(extractDirChildren(extractDir).first ?? "")
        for dir in [extractDir, root] {
            for url in (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
                where url.pathExtension.lowercased() == "css" {
                cssFiles.append(url)
                cssParents.insert(url.deletingLastPathComponent())
            }
        }
        guard !cssFiles.isEmpty else { throw InstallError.noThemesFound }

        let dest = ThemeStore.installedThemesDir.appendingPathComponent("\(repo.author)-\(repo.name)", isDirectory: true)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        // Copy everything that lives next to the css files (assets, licenses…).
        for parent in cssParents {
            for item in (try? FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil)) ?? [] {
                let target = dest.appendingPathComponent(item.lastPathComponent)
                try? FileManager.default.removeItem(at: target)
                try FileManager.default.copyItem(at: item, to: target)
            }
        }
        return ThemeStore.themes(in: dest).map(\.name)
    }

    enum InstallError: LocalizedError {
        case badInput(String)
        case repoNotFound(String)
        case extractFailed
        case noThemesFound

        var errorDescription: String? {
            switch self {
            case .badInput(let s): return "\"\(s)\" is not an author/repo pair."
            case .repoNotFound(let s): return "GitHub repo \"\(s)\" not found (or private)."
            case .extractFailed: return "Downloaded theme zip could not be extracted."
            case .noThemesFound: return "No CSS themes found in the repo (looked at depth 0–1)."
            }
        }
    }
}

private func extractDirChildren(_ dir: URL) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
        .map(\.lastPathComponent)
}
