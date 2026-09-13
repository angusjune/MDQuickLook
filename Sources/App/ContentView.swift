import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var model = ThemeModel()

    var body: some View {
        HSplitView {
            themeList
                .frame(minWidth: 260, maxWidth: 340)
            ThemePreviewPane(themeName: model.selected ?? "github")
                .frame(minWidth: 360)
        }
        .frame(minWidth: 760, minHeight: 480)
        .onAppear { model.refresh() }
        .navigationTitle("MDQuickLook")
    }

    private var themeList: some View {
        VStack(spacing: 0) {
            List {
                Section("Default Theme") {
                    ForEach(model.themes) { theme in
                        themeRow(theme)
                    }
                }
            }
            .listStyle(.sidebar)
            addBar.padding(8)
            Text(model.status)
                .font(.caption)
                .foregroundStyle(model.isError ? .red : .secondary)
                .lineLimit(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
        }
    }

    private func themeRow(_ theme: Theme) -> some View {
        HStack {
            Image(systemName: model.selected == theme.name ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(Color.accentColor)
            Text(theme.name)
            Spacer()
            if !ThemeStore.isInstalled(theme) {
                Text("Built-in").font(.caption2).foregroundStyle(.secondary)
            } else {
                Button {
                    model.delete(theme)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete theme")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { model.pick(theme.name) }
    }

    private var addBar: some View {
        HStack {
            TextField("author/repo", text: $model.entry)
                .textFieldStyle(.roundedBorder)
                .onSubmit { Task { await model.add() } }
            Button("Add") { Task { await model.add() } }
                .disabled(model.entry.isEmpty || model.isBusy)
        }
    }
}

struct ThemePreviewPane: NSViewRepresentable {
    let themeName: String

    func makeNSView(context: Context) -> WKWebView { WKWebView() }

    func updateNSView(_ view: WKWebView, context: Context) {
        let html = ThemeStore.themeCSS(named: themeName)
        let body = MarkdownRenderer.wrapInDocument(MarkdownRenderer.render(SampleDoc.markdown), css: html)
        view.loadHTMLString(body, baseURL: nil)
    }
}

@MainActor
final class ThemeModel: ObservableObject {
    @Published var themes: [Theme] = []
    @Published var selected: String?
    @Published var entry = ""
    @Published var status = ""
    @Published var isError = false
    @Published var isBusy = false

    func refresh() {
        themes = ThemeStore.allThemes
        selected = ThemeStore.defaultThemeName
    }

    func pick(_ name: String) {
        var settings = ThemeStore.loadSettings()
        settings.defaultTheme = name
        ThemeStore.saveSettings(settings)
        selected = name
        status = "Default theme set to “\(name)”. New previews will use it."
        isError = false
    }

    func add() async {
        guard !entry.isEmpty, !isBusy else { return }
        isBusy = true
        status = "Installing \(entry)…"
        isError = false
        defer { isBusy = false }
        do {
            let added = try await ThemeInstaller.install(entry)
            refresh()
            status = added.isEmpty ? "No themes found." : "Installed: \(added.joined(separator: ", "))"
        } catch {
            isError = true
            status = error.localizedDescription
        }
    }

    func delete(_ theme: Theme) {
        try? ThemeStore.delete(theme)
        refresh()
        if selected == theme.name { pick(ThemeStore.fallbackThemeName) }
    }
}
