# Sanitized raw HTML: scripts stripped, local assets only

Markdown files are untrusted input. The preview renders raw HTML embedded in Markdown (Typora parity) but sanitizes it: `<script>` elements, `on*` event-handler attributes, and inline JavaScript URLs are stripped. The generated HTML references only local resources (theme CSS, fonts, images delivered as `cid:` attachments to `QLPreviewReply`); no network requests, no remote assets. JavaScript never runs in the preview.

Consequences: HTML-heavy documents render faithfully minus anything scriptable; math (KaTeX) and diagrams (Mermaid) are deferred until a trusted, bundled JS pipeline is added on purpose — content-supplied scripts are never an acceptable way to get them.
