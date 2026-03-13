import Foundation
import SwiftUI

@MainActor
class CatalogService: ObservableObject {
    static let shared = CatalogService()

    private let catalogURL = URL(string: "https://raw.githubusercontent.com/DodoApps/catalog/main/apps.json")!
    private let cacheKey = "cached_catalog"
    private let cacheTimestampKey = "cached_catalog_timestamp"
    private let releaseCacheKey = "cached_releases"
    private let releaseCacheTimestampKey = "cached_releases_timestamp"
    private let cacheDuration: TimeInterval = 3600 // 1 hour

    @Published var catalog: Catalog?
    @Published var isLoading = false
    @Published var error: Error?

    var apps: [CatalogApp] {
        catalog?.apps ?? []
    }

    var publishers: [Publisher] {
        catalog?.publishers ?? []
    }

    var featuredApps: [CatalogApp] {
        apps.filter { $0.featured == true }
    }

    func publisher(for app: CatalogApp) -> Publisher? {
        publishers.first { $0.id == app.publisherId }
    }

    func apps(for category: AppCategory) -> [CatalogApp] {
        apps.filter { $0.category == category }
    }

    func apps(for publisherId: String) -> [CatalogApp] {
        apps.filter { $0.publisherId == publisherId }
    }

    // MARK: - Fetch

    func fetchCatalog(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil

        // Check cache first
        if !forceRefresh, let cached = loadFromCache() {
            catalog = cached
            isLoading = false

            // Refresh in background if cache is old
            if shouldRefreshCache() {
                Task {
                    await fetchFromNetwork()
                }
            }
            return
        }

        await fetchFromNetwork()
    }

    private func fetchFromNetwork() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: catalogURL)
            var decoded = try JSONDecoder().decode(Catalog.self, from: data)

            // Enrich apps with latest GitHub release data
            decoded.apps = await enrichAppsWithReleaseData(decoded.apps)

            catalog = decoded
            saveToCache(data)
            error = nil
        } catch {
            self.error = error
            // If network fails, try loading from cache anyway
            if let cached = loadFromCache() {
                catalog = cached
            }
        }

        isLoading = false
    }

    // MARK: - GitHub Release Enrichment

    private func enrichAppsWithReleaseData(_ apps: [CatalogApp]) async -> [CatalogApp] {
        // Load cached releases as fallback
        let cachedReleases = loadReleasesFromCache()

        // Fetch all releases concurrently
        var enrichedApps = apps
        var freshReleases: [String: GitHubRelease] = [:]

        await withTaskGroup(of: (Int, GitHubRelease?).self) { group in
            for (index, app) in apps.enumerated() {
                guard !app.repoSlug.isEmpty else { continue }

                group.addTask {
                    let release = await self.fetchLatestRelease(for: app.repoSlug)
                    return (index, release)
                }
            }

            for await (index, release) in group {
                let app = apps[index]
                if let release = release {
                    freshReleases[app.repoSlug] = release
                    enrichedApps[index] = Self.applyRelease(release, to: app)
                } else if let cached = cachedReleases[app.repoSlug] {
                    // Fall back to cached release data
                    enrichedApps[index] = Self.applyRelease(cached, to: app)
                }
            }
        }

        // Cache the fresh releases
        if !freshReleases.isEmpty {
            var allReleases = cachedReleases
            allReleases.merge(freshReleases) { _, new in new }
            saveReleasesToCache(allReleases)
        }

        return enrichedApps
    }

    private static func applyRelease(_ release: GitHubRelease, to app: CatalogApp) -> CatalogApp {
        var updated = app
        updated.version = release.version

        if let dmg = release.dmgAsset {
            updated.downloadUrl = dmg.browserDownloadUrl
            updated.downloadSize = dmg.size
        }

        if let publishedAt = release.publishedAt {
            updated.releaseDate = publishedAt
        }

        return updated
    }

    private nonisolated func fetchLatestRelease(for repoSlug: String) async -> GitHubRelease? {
        guard let url = URL(string: "https://api.github.com/repos/\(repoSlug)/releases/latest") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            return try JSONDecoder().decode(GitHubRelease.self, from: data)
        } catch {
            print("⚠️ Failed to fetch release for \(repoSlug): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Release Cache

    private func loadReleasesFromCache() -> [String: GitHubRelease] {
        guard let data = UserDefaults.standard.data(forKey: releaseCacheKey) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: GitHubRelease].self, from: data)) ?? [:]
    }

    private func saveReleasesToCache(_ releases: [String: GitHubRelease]) {
        if let data = try? JSONEncoder().encode(releases) {
            UserDefaults.standard.set(data, forKey: releaseCacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: releaseCacheTimestampKey)
        }
    }

    // MARK: - Catalog Cache

    private func loadFromCache() -> Catalog? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }

        guard var catalog = try? JSONDecoder().decode(Catalog.self, from: data) else {
            return nil
        }

        // Apply cached release data to catalog apps
        let cachedReleases = loadReleasesFromCache()
        if !cachedReleases.isEmpty {
            catalog.apps = catalog.apps.map { app in
                guard !app.repoSlug.isEmpty, let release = cachedReleases[app.repoSlug] else {
                    return app
                }
                return Self.applyRelease(release, to: app)
            }
        }

        return catalog
    }

    private func saveToCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
    }

    private func shouldRefreshCache() -> Bool {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        guard timestamp > 0 else { return true }

        let cacheDate = Date(timeIntervalSince1970: timestamp)
        return Date().timeIntervalSince(cacheDate) > cacheDuration
    }

    // MARK: - Search

    func search(_ query: String) -> [CatalogApp] {
        guard !query.isEmpty else { return apps }

        let lowercased = query.lowercased()
        return apps.filter { app in
            app.name.lowercased().contains(lowercased) ||
            app.tagline.lowercased().contains(lowercased) ||
            app.description.lowercased().contains(lowercased) ||
            app.features.contains { $0.lowercased().contains(lowercased) }
        }
    }
}
