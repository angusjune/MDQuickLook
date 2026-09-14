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

    /// Wraps a rendered fragment in a self-contained document. Passing `raw`
    /// (the Markdown source) adds the Preview/Raw switcher; omitting it yields
    /// the preview pane alone.
    static func wrapInDocument(_ fragment: String, css: String = "", raw: String? = nil) -> String {
        let inputs = raw == nil ? "" : """
        <input type="radio" name="mdql-view" id="mdql-view-preview" class="mdql-view-input" checked>
        <input type="radio" name="mdql-view" id="mdql-view-raw" class="mdql-view-input">
        """
        let rawPane = raw.map { "<pre class=\"mdql-raw\">\(escapeHTML($0))</pre>" } ?? ""
        let switcher = raw == nil ? "" : """
        <div class="mdql-spacer"></div>
        <div class="mdql-view-switcher" aria-label="View">\
        <label for="mdql-view-preview">Preview</label>\
        <label for="mdql-view-raw">Raw</label>\
        </div>
        """
        return """
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
        </style><style>\(css)</style><style>\(raw == nil ? "" : viewSwitcherCSS)</style></head>
        <body>\(inputs)<div id="write">\(fragment)</div>\(rawPane)\(switcher)</body>
        </html>
        """
    }

    /// Preview/Raw switcher: a macOS-style segmented control pinned bottom-right.
    /// Pure CSS — two radios whose `:checked` state drives the sibling panes —
    /// because document JavaScript never runs in the preview (ADR-0002). Emitted
    /// after the theme's `<style>` so theme rules can't outrank the chrome; the
    /// raw pane sits outside `#write`, which Typora themes scope themselves to.
    private static let viewSwitcherCSS = """
      .mdql-view-input { position: fixed; top: 0; left: 0; width: 1px; height: 1px; margin: 0; opacity: 0; pointer-events: none; }
      #mdql-view-raw:checked ~ #write { display: none; }
      #mdql-view-preview:checked ~ pre.mdql-raw { display: none; }
      pre.mdql-raw {
        max-width: 46em; margin: 0 auto; padding: 2em 1.2em 0; border: 0; border-radius: 0; background: none;
        font: 12px/1.55 ui-monospace, "SF Mono", Menlo, monospace; color: inherit;
        white-space: pre-wrap; word-wrap: break-word; -webkit-user-select: text; user-select: text;
      }
      .mdql-spacer { height: 3.4em; }
      .mdql-view-switcher {
        position: fixed; right: 14px; bottom: 14px; z-index: 2147483647;
        display: flex; gap: 1px; padding: 2px; border-radius: 8px;
        background: rgba(246, 246, 246, .82);
        -webkit-backdrop-filter: saturate(180%) blur(20px); backdrop-filter: saturate(180%) blur(20px);
        box-shadow: inset 0 0 0 .5px rgba(0, 0, 0, .16), 0 1px 3px rgba(0, 0, 0, .18);
        -webkit-user-select: none; user-select: none;
      }
      .mdql-view-switcher label {
        display: block; margin: 0; padding: 3px 10px 4px; border-radius: 6px; background: none;
        font: 500 11px/1.35 -apple-system, "SF Pro Text", "Helvetica Neue", sans-serif;
        color: rgba(0, 0, 0, .85); white-space: nowrap; cursor: default; text-transform: none; letter-spacing: 0;
        transition: background-color 120ms ease, box-shadow 120ms ease;
      }
      #mdql-view-preview:checked ~ .mdql-view-switcher label[for="mdql-view-preview"],
      #mdql-view-raw:checked ~ .mdql-view-switcher label[for="mdql-view-raw"] {
        background: #fff; box-shadow: 0 0 0 .5px rgba(0, 0, 0, .10), 0 1px 2px rgba(0, 0, 0, .20);
      }
      #mdql-view-preview:focus-visible ~ .mdql-view-switcher label[for="mdql-view-preview"],
      #mdql-view-raw:focus-visible ~ .mdql-view-switcher label[for="mdql-view-raw"] {
        box-shadow: 0 0 0 3px rgba(0, 122, 255, .45);
      }
      @media (prefers-color-scheme: dark) {
        .mdql-view-switcher {
          background: rgba(54, 54, 56, .82);
          box-shadow: inset 0 0 0 .5px rgba(255, 255, 255, .14), 0 1px 3px rgba(0, 0, 0, .44);
        }
        .mdql-view-switcher label { color: rgba(255, 255, 255, .88); }
        #mdql-view-preview:checked ~ .mdql-view-switcher label[for="mdql-view-preview"],
        #mdql-view-raw:checked ~ .mdql-view-switcher label[for="mdql-view-raw"] {
          background: rgba(122, 122, 126, .70); box-shadow: 0 0 0 .5px rgba(0, 0, 0, .24), 0 1px 2px rgba(0, 0, 0, .36);
        }
      }
      @media print { .mdql-view-switcher, .mdql-spacer { display: none; } }
    """

    static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

private extension String {
    func replacing(_ pattern: String, regex template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return self }
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }
}
