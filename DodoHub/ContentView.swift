import SwiftUI

struct ContentView: View {
    @StateObject private var catalogService = CatalogService.shared
    @StateObject private var stateManager = AppStateManager.shared
    @State private var selectedFilter: SidebarFilter = .all
    @State private var selectedApp: CatalogApp?

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedFilter: $selectedFilter,
                catalogService: catalogService,
                stateManager: stateManager
            )
        } detail: {
            detailContent
        }
        .task {
            await catalogService.fetchCatalog()
            stateManager.checkInstallationStatus(for: catalogService.apps)
        }
        .sheet(item: $selectedApp) { app in
            AppDetailView(
                app: app,
                publisher: catalogService.publisher(for: app),
                stateManager: stateManager
            )
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    @ViewBuilder
    private var detailContent: some View {
        if catalogService.isLoading && catalogService.apps.isEmpty {
            loadingView
        } else if let error = catalogService.error, catalogService.apps.isEmpty {
            errorView(error)
        } else {
            contentForFilter
        }
    }

    @ViewBuilder
    private var contentForFilter: some View {
        switch selectedFilter {
        case .all:
            AppGridView(
                apps: catalogService.apps,
                title: "All apps",
                stateManager: stateManager,
                selectedApp: $selectedApp
            )

        case .featured:
            VStack(spacing: 24) {
                if !catalogService.featuredApps.isEmpty {
                    FeaturedSection(
                        apps: catalogService.featuredApps,
                        stateManager: stateManager,
                        selectedApp: $selectedApp
                    )
                }

                AppGridView(
                    apps: catalogService.apps,
                    title: "All apps",
                    stateManager: stateManager,
                    selectedApp: $selectedApp
                )
            }

        case .installed:
            AppGridView(
                apps: stateManager.installedApps(from: catalogService.apps),
                title: "Installed",
                stateManager: stateManager,
                selectedApp: $selectedApp
            )

        case .updates:
            AppGridView(
                apps: stateManager.appsWithUpdates(from: catalogService.apps),
                title: "Updates available",
                stateManager: stateManager,
                selectedApp: $selectedApp
            )

        case .category(let category):
            AppGridView(
                apps: catalogService.apps(for: category),
                title: category.displayName,
                stateManager: stateManager,
                selectedApp: $selectedApp
            )

        case .publisher(let publisherId):
            let publisherApps = catalogService.apps(for: publisherId)
            let publisherName = catalogService.publishers.first { $0.id == publisherId }?.name ?? "Publisher"
            AppGridView(
                apps: publisherApps,
                title: publisherName,
                stateManager: stateManager,
                selectedApp: $selectedApp
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading catalog...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Failed to load catalog")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try again") {
                Task {
                    await catalogService.fetchCatalog(forceRefresh: true)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
