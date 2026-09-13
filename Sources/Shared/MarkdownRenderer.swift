import Foundation
import cmark_gfm
import cmark_gfm_extensions

enum MarkdownRenderer {
    /// Renders GFM markdown to an HTML fragment: tables, task lists, strikethrough,
    /// autolinks; raw HTML passes through (sanitized below) per ADR-0002.
    static func render(_ markdown: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()
        let parser = cmark_parser_new(CMARK_OPT_DEFAULT)
        defer { cmark_parser_free(parser) }
        for name in ["table", "strikethrough", "tasklist", "autolink"] {
            if let ext = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }
        markdown.withCString { cString in
            cmark_parser_feed(parser, cString, markdown.utf8.count)
        }
        guard let doc = cmark_parser_finish(parser) else { return "" }
        defer { cmark_node_free(doc) }
        guard let html = cmark_render_html(doc, CMARK_OPT_DEFAULT, nil) else { return "" }
        defer { free(html) }
        return sanitize(String(cString: html))
    }

    /// ponytail: regex sanitization, not a DOM allowlist — covers script blocks,
    /// inline event handlers, and script-ish URL schemes, which is the realistic
    /// surface for a viewer without JS. Upgrade to a real HTML parser sanitizer
    /// if someone needs attribute-level fidelity.
    static func sanitize(_ html: String) -> String {
        var out = html
        let patterns: [(String, String)] = [
            (#"<script\b[^>]*>[\s\S]*?</script\s*>"#, ""),           // script blocks
            (#"<script\b[^>]*/?\s*>"#, ""),                        // stray open script
            (#"\son\w+\s*=\s*(".*?"|'.*?'|[^\s>]+)"#, ""),           // inline event handlers
            (#"(href|src|action|formaction|xlink:href)\s*=\s*("|')\s*(javascript|vbscript|data):[^"']*\2"#, #"$1=$2#$2"#),
        ]
        for (pattern, template) in patterns {
            out = out.replacing(pattern, regex: template)
        }
        return out
    }

    static func wrapInDocument(_ fragment: String, css: String = "") -> String {
        """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"><style>
          body { font: 15px/1.6 -apple-system, Helvetica, sans-serif; max-width: 42em; margin: 0 auto; padding: 2em 1em; color: #222; background: #fff; }
          h1, h2 { border-bottom: 1px solid #e2e2e2; padding-bottom: .3em; }
          table { border-collapse: collapse; }
          th, td { border: 1px solid #d0d7de; padding: 6px 13px; }
          code { background: #f6f8fa; padding: .2em .4em; border-radius: 3px; font-family: ui-monospace, Menlo, monospace; font-size: .9em; }
          pre { background: #f6f8fa; padding: 1em; border-radius: 6px; overflow: auto; }
          pre code { background: none; padding: 0; }
          blockquote { border-left: 4px solid #d0d7de; margin: 0; padding: 0 1em; color: #57606a; }
        </style><style>\(css)</style></head>
        <body><div id="write">\(fragment)</div></body>
        </html>
        """
    }
}

private extension String {
    func replacing(_ pattern: String, regex template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return self }
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }
}
