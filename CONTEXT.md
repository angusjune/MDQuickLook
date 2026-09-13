# MDQuickLook

A macOS QuickLook app that previews Markdown files rendered with Typora themes. Distributed via Homebrew cask.

## Language

### Pieces

**Preview Extension**:
The passive QuickLook app extension that renders a Markdown file's preview. Has no UI of its own; renders whatever the Default Theme dictates.
_Avoid_: plugin, qlgenerator, QLGenerator

**Theme Manager**:
The containing app. One window: lists installed Themes, adds Themes from a Theme Repo, removes Themes, and selects the Default Theme.
_Avoid_: settings app, preferences, main app

### Themes

**Theme**:
One Typora CSS file together with its assets (fonts, images) referenced by relative path. The unit a preview loads and the unit the Theme Manager lists. One repo may contain several Themes (e.g. `vue` and `vue-dark`).
_Avoid_: skin, style, css file (as a synonym for Theme)

**Built-in Theme**:
One of the five Themes shipped inside the app bundle: Github, Newsprint, Pixyll, Whitey, Night. Cannot be removed.
_Avoid_: default theme (as a synonym for Built-in Theme)

**Installed Theme**:
A Theme added by the user from a Theme Repo. Removable.
_Avoid_: downloaded theme, custom theme

**Theme Repo**:
A public GitHub repository identified as `author/repo` that contains one or more Themes in Typora's layout.
_Avoid_: theme source, package

**Default Theme**:
The single global Theme every preview uses, chosen in the Theme Manager. Applies to all Markdown files; there is no per-file selection.
_Avoid_: active theme, current theme
