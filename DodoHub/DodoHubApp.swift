import SwiftUI
import Sparkle

@main
struct DodoHubApp: App {
    @StateObject private var settings = SettingsManager.shared
    private let updaterController: SPUStandardUpdaterController

    init() {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(settings.colorScheme.colorScheme)
                .onAppear {
                    // Request notification permission on first launch
                    Task {
                        await NotificationManager.shared.requestAuthorization()
                    }
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)

                Divider()

                Button("Refresh catalog") {
                    Task {
                        await CatalogService.shared.fetchCatalog(forceRefresh: true)
                        AppStateManager.shared.checkInstallationStatus(for: CatalogService.shared.apps)
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {
            SettingsView(updater: updaterController.updater)
        }
    }
}

// MARK: - Check for Updates Menu Item

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for updates...") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
