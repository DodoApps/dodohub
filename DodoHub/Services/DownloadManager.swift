import Foundation
import AppKit
import Network

@MainActor
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadTask] = [:]
    @Published var lastError: (appName: String, error: DownloadError)?

    private var urlSession: URLSession!
    private var downloadTasks: [URLSessionDownloadTask: String] = [:]
    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = true

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: .main)

        // Monitor network availability
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    struct DownloadTask {
        let appId: String
        let appName: String
        var progress: Double
        var downloadedBytes: Int64
        var totalBytes: Int64
        var task: URLSessionDownloadTask?
    }

    // MARK: - URL Validation

    func validateURL(_ urlString: String) async -> Result<URL, DownloadError> {
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }

        guard isNetworkAvailable else {
            return .failure(.networkUnavailable)
        }

        // Check if URL is reachable with HEAD request
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.serverError(statusCode: 0))
            }

            switch httpResponse.statusCode {
            case 200...299:
                return .success(url)
            case 404:
                return .failure(.fileNotFound)
            default:
                return .failure(.serverError(statusCode: httpResponse.statusCode))
            }
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                return .failure(.networkUnavailable)
            }
            return .failure(.downloadFailed(underlying: error))
        } catch {
            return .failure(.downloadFailed(underlying: error))
        }
    }

    // MARK: - Download

    func download(_ app: CatalogApp) async {
        // Validate URL first
        let validationResult = await validateURL(app.downloadUrl)

        switch validationResult {
        case .failure(let error):
            handleError(error, for: app)
            return
        case .success(let url):
            await performDownload(app: app, url: url)
        }
    }

    private func performDownload(app: CatalogApp, url: URL) async {
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
            let (tempURL, response) = try await downloadWithProgress(url: url, appId: app.id)

            // Verify we got a valid response
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw DownloadError.serverError(statusCode: httpResponse.statusCode)
                }
            }

            // Move to Downloads folder
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let destinationURL = downloadsURL.appendingPathComponent("\(app.name)-\(app.version).dmg")

            // Remove existing file if present
            try? FileManager.default.removeItem(at: destinationURL)

            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            } catch {
                throw DownloadError.fileSystemError(underlying: error)
            }

            // Verify file exists and has content
            let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
            guard let fileSize = attributes[.size] as? Int64, fileSize > 0 else {
                try? FileManager.default.removeItem(at: destinationURL)
                throw DownloadError.downloadFailed(underlying: NSError(domain: "DownloadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is empty"]))
            }

            // Update state
            activeDownloads.removeValue(forKey: app.id)
            AppStateManager.shared.updateState(for: app.id, to: .installing)

            // Open DMG
            NSWorkspace.shared.open(destinationURL)

            // After a delay, refresh the install state
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            let newState = AppStateManager.shared.getInstallState(for: app)
            AppStateManager.shared.updateState(for: app.id, to: newState)

        } catch let error as DownloadError {
            handleError(error, for: app)
        } catch let error as URLError {
            if error.code == .cancelled {
                handleError(.cancelled, for: app)
            } else if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                handleError(.networkUnavailable, for: app)
            } else {
                handleError(.downloadFailed(underlying: error), for: app)
            }
        } catch {
            handleError(.downloadFailed(underlying: error), for: app)
        }
    }

    private func handleError(_ error: DownloadError, for app: CatalogApp) {
        activeDownloads.removeValue(forKey: app.id)

        // Don't show error for cancelled downloads
        if case .cancelled = error {
            AppStateManager.shared.updateState(for: app.id, to: .notInstalled)
            return
        }

        // Update state with error
        AppStateManager.shared.updateState(for: app.id, to: .failed(error: error.localizedDescription))

        // Store error for alert
        lastError = (appName: app.name, error: error)

        print("⚠️ Download failed for \(app.name): \(error.localizedDescription)")
    }

    func clearError() {
        lastError = nil
    }

    private func downloadWithProgress(url: URL, appId: String) async throws -> (URL, URLResponse) {
        let request = URLRequest(url: url)

        return try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.downloadTask(with: request) { tempURL, response, error in
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

            // Store task reference
            if var download = activeDownloads[appId] {
                download.task = task
                activeDownloads[appId] = download
            }

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

    // MARK: - Retry

    func retry(_ app: CatalogApp) async {
        // Clear the error state first
        AppStateManager.shared.updateState(for: app.id, to: .notInstalled)
        lastError = nil

        // Try downloading again
        await download(app)
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
