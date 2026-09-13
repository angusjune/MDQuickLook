import Cocoa
import Quartz
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        // ponytail: throwaway spike witness, delete in M1
        try? Data("spike".utf8).write(to: FileManager.default.temporaryDirectory.appendingPathComponent("mdql-spike-marker"))
        let html = """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"><style>
          body { font: 15px -apple-system, Helvetica, sans-serif; margin: 2em auto; max-width: 42em; color: #222; }
          h1 { border-bottom: 1px solid #ddd; }
        </style></head>
        <body>
          <h1>MDQuickLook spike</h1>
          <p>If you can read this, the ad-hoc-signed data-based preview extension loads and renders.</p>
        </body>
        </html>
        """
        return QLPreviewReply(__dataOfContentType: .html, contentSize: CGSize(width: 700, height: 800)) { _, _ in
            Data(html.utf8)
        }
    }
}
