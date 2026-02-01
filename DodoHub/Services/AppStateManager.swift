import Foundation
import AppKit

@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    @Published private(set) var appStates: [String: AppInstallState] = [:]

    private init() {}

    // MARK: - Check Installation Status

    func checkInstallationStatus(for apps: [CatalogApp]) {
        for app in apps {
            appStates[app.id] = getInstallState(for: app)
        }
    }

    func getInstallState(for app: CatalogApp) -> AppInstallState {
        // Check if currently downloading
        if let currentState = appStates[app.id] {
            switch currentState {
            case .downloading, .installing:
                return currentState
            default:
                break
            }
        }

        // Check if app is installed
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) else {
            return .notInstalled
        }

        // Get installed version
        guard let bundle = Bundle(url: appURL),
              let installedVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return .installed(version: "Unknown")
        }

        // Compare versions
        if compareVersions(installedVersion, app.version) == .orderedAscending {
            return .updateAvailable(installed: installedVersion, available: app.version)
        }

        return .installed(version: installedVersion)
    }

    func state(for appId: String) -> AppInstallState {
        appStates[appId] ?? .notInstalled
    }

    func updateState(for appId: String, to state: AppInstallState) {
        appStates[appId] = state
    }

    // MARK: - Actions

    func openApp(_ app: CatalogApp) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) else {
            return
        }

        NSWorkspace.shared.openApplication(at: appURL, configuration: .init()) { runningApp, error in
            if let error = error {
                print("Failed to open app: \(error.localizedDescription)")
            }
        }
    }

    func revealInFinder(_ app: CatalogApp) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) else {
            return
        }

        NSWorkspace.shared.selectFile(appURL.path, inFileViewerRootedAtPath: "")
    }

    // MARK: - Version Comparison

    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(components1.count, components2.count)

        for i in 0..<maxLength {
            let c1 = i < components1.count ? components1[i] : 0
            let c2 = i < components2.count ? components2[i] : 0

            if c1 < c2 {
                return .orderedAscending
            } else if c1 > c2 {
                return .orderedDescending
            }
        }

        return .orderedSame
    }

    // MARK: - Installed Apps

    func installedApps(from catalog: [CatalogApp]) -> [CatalogApp] {
        catalog.filter { app in
            switch state(for: app.id) {
            case .installed, .updateAvailable:
                return true
            default:
                return false
            }
        }
    }

    func appsWithUpdates(from catalog: [CatalogApp]) -> [CatalogApp] {
        catalog.filter { app in
            if case .updateAvailable = state(for: app.id) {
                return true
            }
            return false
        }
    }
}
