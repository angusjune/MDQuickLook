import Cocoa
import Quartz
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let markdown = (try? String(contentsOf: request.fileURL, encoding: .utf8)) ?? ""
        let themeName = ThemeStore.defaultThemeName
        let css = ThemeStore.themeCSS(named: themeName)
        let body = MarkdownRenderer.wrapInDocument(MarkdownRenderer.render(markdown), css: css, raw: markdown)
        // ponytail: M2 witness — theme name + size recorded so the harness can
        // verify theme switching without eyes; remove in M3.
        try? Data("theme=\(themeName) bytes=\(body.count)".utf8)
            .write(to: FileManager.default.temporaryDirectory.appendingPathComponent("mdql-theme.txt"))
        return QLPreviewReply(__dataOfContentType: .html, contentSize: CGSize(width: 700, height: 800)) { _, _ in
            Data(body.utf8)
        }
    }
}
