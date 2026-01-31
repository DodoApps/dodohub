import Foundation
import AppKit

@MainActor
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadTask] = [:]

    private var urlSession: URLSession!
    private var downloadTasks: [URLSessionDownloadTask: String] = [:]

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
    }

    struct DownloadTask {
        let appId: String
        let appName: String
        var progress: Double
        var downloadedBytes: Int64
        var totalBytes: Int64
        var task: URLSessionDownloadTask?
    }

    // MARK: - Download

    func download(_ app: CatalogApp) async {
        guard let url = URL(string: app.downloadUrl) else { return }

        // Update state
        AppStateManager.shared.updateState(for: app.id, to: .downloading(progress: 0))

        activeDownloads[app.id] = DownloadTask(
            appId: app.id,
            appName: app.name,
            progress: 0,
            downloadedBytes: 0,
            totalBytes: Int64(app.downloadSize),
            task: nil
        )

        do {
            let (tempURL, _) = try await downloadWithProgress(url: url, appId: app.id)

            // Move to Downloads folder
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let destinationURL = downloadsURL.appendingPathComponent("\(app.name)-\(app.version).dmg")

            // Remove existing file if present
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)

            // Update state
            activeDownloads.removeValue(forKey: app.id)
            AppStateManager.shared.updateState(for: app.id, to: .installing)

            // Open DMG
            NSWorkspace.shared.open(destinationURL)

            // After a delay, refresh the install state
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            let newState = AppStateManager.shared.getInstallState(for: app)
            AppStateManager.shared.updateState(for: app.id, to: newState)

        } catch {
            print("Download failed: \(error)")
            activeDownloads.removeValue(forKey: app.id)
            AppStateManager.shared.updateState(for: app.id, to: .notInstalled)
        }
    }

    private func downloadWithProgress(url: URL, appId: String) async throws -> (URL, URLResponse) {
        let request = URLRequest(url: url)

        return try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.downloadTask(with: request) { [weak self] tempURL, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let tempURL = tempURL, let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                // Move to a persistent temp location
                let persistentTemp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".dmg")
                do {
                    try FileManager.default.moveItem(at: tempURL, to: persistentTemp)
                    continuation.resume(returning: (persistentTemp, response))
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            downloadTasks[task] = appId

            // Observe progress
            let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                Task { @MainActor in
                    self?.updateProgress(appId: appId, progress: progress.fractionCompleted)
                }
            }

            // Store observation to prevent deallocation
            objc_setAssociatedObject(task, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)

            task.resume()
        }
    }

    private func updateProgress(appId: String, progress: Double) {
        if var download = activeDownloads[appId] {
            download.progress = progress
            activeDownloads[appId] = download
            AppStateManager.shared.updateState(for: appId, to: .downloading(progress: progress))
        }
    }

    // MARK: - Cancel

    func cancelDownload(appId: String) {
        if let download = activeDownloads[appId] {
            download.task?.cancel()
            activeDownloads.removeValue(forKey: appId)
            AppStateManager.shared.updateState(for: appId, to: .notInstalled)
        }
    }
}
