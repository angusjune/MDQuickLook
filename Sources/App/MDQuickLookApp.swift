import SwiftUI

@main
struct MDQuickLookApp: App {
    init() {
        // Headless install for scripting/tests: MDQuickLook --install author/repo
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--install"), i + 1 < args.count {
            let input = args[i + 1]
            let sem = DispatchSemaphore(value: 0)
            Task.detached {
                do {
                    let added = try await ThemeInstaller.install(input)
                    print("installed: \(added.joined(separator: ", "))")
                } catch {
                    print("error: \(error.localizedDescription)")
                    fflush(stdout)
                    exit(1)
                }
                sem.signal()
            }
            sem.wait()
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup("MDQuickLook") {
            ContentView()
        }
    }
}
