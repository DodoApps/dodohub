import SwiftUI

@main
struct DodoHubApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .appInfo) {
                Button("Check for updates...") {
                    Task {
                        await CatalogService.shared.fetchCatalog(forceRefresh: true)
                        AppStateManager.shared.checkInstallationStatus(for: CatalogService.shared.apps)
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}
