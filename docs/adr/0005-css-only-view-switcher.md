# CSS-only View Switcher

The Preview/Raw View Switcher is built from two hidden radio inputs and `:checked ~ sibling` rules — no script, no extension-side UI — because document JavaScript never runs in the preview (ADR-0002) and the extension hosts no view of its own (ADR-0001). Its stylesheet is emitted after the theme's, and the Raw pane lives outside `<div id="write">`, so Typora themes (which scope themselves to `#write`) cannot restyle the chrome or the source text. The control is styled as a macOS segmented control — translucent track, raised selected segment, system font, `prefers-color-scheme` aware — and a spacer element keeps the last line of a document clear of it.

Consequences: the switcher works in QuickLook's scriptless web view and costs one extra copy of the Markdown source (HTML-escaped) in the reply payload. The chosen view is not persisted, and it resets to Preview each time a preview opens — there is no store to write it to from a scriptless document.
