import Foundation
import SwiftUI

@MainActor
class CatalogService: ObservableObject {
    static let shared = CatalogService()

    private let catalogURL = URL(string: "https://raw.githubusercontent.com/DodoApps/catalog/main/apps.json")!
    private let cacheKey = "cached_catalog"
    private let cacheTimestampKey = "cached_catalog_timestamp"
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
            let decoded = try JSONDecoder().decode(Catalog.self, from: data)

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

    // MARK: - Cache

    private func loadFromCache() -> Catalog? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }

        return try? JSONDecoder().decode(Catalog.self, from: data)
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
