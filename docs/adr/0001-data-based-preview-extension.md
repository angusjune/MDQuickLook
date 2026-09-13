# Data-based QuickLook preview extension

We preview Markdown with a `com.apple.quicklook.preview` app extension using the **data-based** path: a `QLPreviewProvider` returning `QLPreviewReply` HTML (`QLIsDataBasedKey = true`), available macOS 12+; deployment target is macOS 13. We do not use a legacy `.qlgenerator` (deprecated in the macOS 12 SDK) and we do not host our own WKWebView inside the extension (undocumented, with community reports of blank rendering). The rendered document is wrapped in a `<div id="write">` container because Typora themes target that element.

Consequences: rendering happens in QuickLook's own web view; features that require document JavaScript (KaTeX, Mermaid) are out of scope until a deliberate trusted-JS pipeline exists (see ADR-0002).
