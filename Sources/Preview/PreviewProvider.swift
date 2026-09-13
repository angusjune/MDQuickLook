import Cocoa
import Quartz
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let markdown = (try? String(contentsOf: request.fileURL, encoding: .utf8)) ?? ""
        let document = MarkdownRenderer.wrapInDocument(MarkdownRenderer.render(markdown))
        // ponytail: M1 witness — write rendered HTML to the container so the test
        // harness can verify content without eyes; remove in M2.
        try? Data(document.utf8).write(to: FileManager.default.temporaryDirectory.appendingPathComponent("mdql-render.html"))
        return QLPreviewReply(__dataOfContentType: .html, contentSize: CGSize(width: 700, height: 800)) { _, _ in
            Data(document.utf8)
        }
    }
}
