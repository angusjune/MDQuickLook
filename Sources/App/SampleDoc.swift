import Foundation

enum SampleDoc {
    static let markdown = """
    ---
    title: MDQuickLook Sample
    theme: github
    ---

    # Typora Themes

    **MDQuickLook** renders Markdown with *Typora* themes. This is a ~~sample~~ document.

    ## Feature checklist

    - [x] GFM tables
    - [x] Task lists
    - [x] Syntax highlighting
    - [ ] KaTeX (not yet)

    ## Table

    | Theme     | Style | Dark  |
    |-----------|-------|-------|
    | Github    | clean | no    |
    | Newsprint | serif | no    |
    | Night     | dark  | yes   |

    ## Quote

    > Simplify, then add lightness.

    ## Code

    ```swift
    let themes = try ThemeInstaller.install("blinkfox/typora-vue-theme")
    print(themes) // ["vue", "vue-dark"]
    ```

    Raw HTML: <b>bold</b> and <em>italic</em>. [Links](https://theme.typora.io) work too.
    """
}
