# MDQuickLook

A macOS QuickLook extension that previews Markdown files with [Typora themes](https://theme.typora.io/). Spacebar in Finder now renders your `.md` files the way Typora would.

## Install

```sh
brew install --cask angusjune/tap/mdquicklook
```

Then launch **MDQuickLook** once (registers the QuickLook extension) and press space on any `.md` or `.markdown` file.

## Themes

The app window is the theme manager:

- **Pick the default theme** — one global theme, used by every preview. Ships with the five Typora built-ins: **Github, Newsprint, Pixyll, Whitey, Night**.
- **Add themes** from any public GitHub repo by typing `author/repo` (a full repo URL works too). Every CSS file in the repo becomes a theme, so `blinkfox/typora-vue-theme` installs *vue* and *vue-dark* together. Re-adding a repo overwrites it.
- **Delete** installed themes with the trash button. Built-ins can't be removed.

Themes render with their assets (fonts, images) fully self-contained — previews never touch the network.

## What gets rendered

GitHub-flavored Markdown: tables, task lists, strikethrough, autolinks, fenced code — plus raw HTML embedded in the document.

Raw HTML is **sanitized**: `<script>` tags, inline event handlers, and script-style URLs are stripped, and nothing executes JavaScript in the preview. That's why KaTeX/Mermaid don't render (yet).

## Notes

- After changing the default theme, already-open previews refresh on the next preview; a stubborn one clears with `killall Finder`.
- If another Markdown QuickLook extension is installed (e.g. QLMarkdown), macOS picks one — disable the other with `pluginkit -e ignore -i <bundle-id>`.
- The extension is ad-hoc signed; install via the tap (Homebrew doesn't quarantine downloads), not by copying the app out of a random download.

## Building from source

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project MDQuickLook.xcodeproj -scheme MDQuickLook -configuration Release build
```

Open the generated `MDQuickLook.xcodeproj` in Xcode, or install your local build straight into `/Applications`:

```sh
xcodebuild -project MDQuickLook.xcodeproj -scheme MDQuickLook -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/MDQuickLook.app /Applications/
```

Headless theme install (also handy for testing):

```sh
/Applications/MDQuickLook.app/Contents/MacOS/MDQuickLook --install author/repo
```

## Design docs

Glossary in [`CONTEXT.md`](CONTEXT.md); decision records in [`docs/adr/`](docs/adr/) — why a data-based QuickLook extension, how themes are installed from `author/repo` zips, and the security stance.
