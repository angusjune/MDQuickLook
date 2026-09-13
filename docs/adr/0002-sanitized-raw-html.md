# Sanitized raw HTML: scripts stripped, local assets only

Markdown files are untrusted input. The preview renders raw HTML embedded in Markdown (Typora parity) but sanitizes it: `<script>` elements, `on*` event-handler attributes, and inline JavaScript URLs are stripped. The generated document is fully self-contained — theme CSS is inlined in a `<style>` element with `url(...)` asset references rewritten to `data:` URIs — so nothing is fetched and no network requests occur. JavaScript never runs in the preview.

Consequences: HTML-heavy documents render faithfully minus anything scriptable; math (KaTeX) and diagrams (Mermaid) are deferred until a trusted, bundled JS pipeline is added on purpose — content-supplied scripts are never an acceptable way to get them.
