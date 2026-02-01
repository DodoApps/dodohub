import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {
        Task {
            await checkAuthorization()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Download Notifications

    func sendDownloadCompleteNotification(appName: String) {
        guard SettingsManager.shared.showNotifications else { return }
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Download complete"
        content.body = "\(appName) has been downloaded and is ready to install."
        content.sound = .default
        content.categoryIdentifier = "DOWNLOAD_COMPLETE"

        let request = UNNotificationRequest(
            identifier: "download-\(appName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    func sendDownloadFailedNotification(appName: String, error: String) {
        guard SettingsManager.shared.showNotifications else { return }
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Download failed"
        content.body = "\(appName): \(error)"
        content.sound = .default
        content.categoryIdentifier = "DOWNLOAD_FAILED"

        let request = UNNotificationRequest(
            identifier: "download-failed-\(appName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    func sendUpdateAvailableNotification(appName: String, newVersion: String) {
        guard SettingsManager.shared.showNotifications else { return }
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Update available"
        content.body = "\(appName) \(newVersion) is now available."
        content.sound = .default
        content.categoryIdentifier = "UPDATE_AVAILABLE"

        let request = UNNotificationRequest(
            identifier: "update-\(appName)-\(newVersion)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    func sendDodoHubUpdateNotification(newVersion: String) {
        guard SettingsManager.shared.showNotifications else { return }
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "DodoHub update available"
        content.body = "Version \(newVersion) is now available. Click to update."
        content.sound = .default
        content.categoryIdentifier = "DODOHUB_UPDATE"

        let request = UNNotificationRequest(
            identifier: "dodohub-update-\(newVersion)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}
