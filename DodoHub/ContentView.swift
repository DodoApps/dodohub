import SwiftUI

struct ContentView: View {
    @StateObject private var catalogService = CatalogService.shared
    @StateObject private var stateManager = AppStateManager.shared
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var selectedFilter: SidebarFilter = .all
    @State private var selectedApp: CatalogApp?
    @State private var isInitialLoading = true
    @State private var showDownloadError = false

    var body: some View {
        Group {
            if isInitialLoading {
                LoadingView()
            } else {
                mainContent
            }
        }
        .task {
            await catalogService.fetchCatalog()
            stateManager.checkInstallationStatus(for: catalogService.apps)

            // Small delay for smooth transition
            try? await Task.sleep(nanoseconds: 500_000_000)

            withAnimation(.easeOut(duration: 0.3)) {
                isInitialLoading = false
            }
        }
        .onChange(of: downloadManager.lastError?.appName) { _, newValue in
            if newValue != nil {
                showDownloadError = true
            }
        }
        .alert("Download failed", isPresented: $showDownloadError) {
            Button("Try again") {
                if let errorInfo = downloadManager.lastError,
                   let app = catalogService.apps.first(where: { $0.name == errorInfo.appName }) {
                    Task {
                        await downloadManager.retry(app)
                    }
                }
                downloadManager.clearError()
            }
            Button("OK", role: .cancel) {
                downloadManager.clearError()
            }
        } message: {
            if let errorInfo = downloadManager.lastError {
                Text("\(errorInfo.appName): \(errorInfo.error.localizedDescription)\n\n\(errorInfo.error.recoverySuggestion ?? "")")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private var mainContent: some View {
        NavigationSplitView {
            SidebarView(
                selectedFilter: $selectedFilter,
                catalogService: catalogService,
                stateManager: stateManager
            )
        } detail: {
            NavigationStack {
                if let app = selectedApp {
                    AppDetailView(
                        app: app,
                        publisher: catalogService.publisher(for: app),
                        stateManager: stateManager,
                        onBack: { selectedApp = nil }
                    )
                } else {
                    detailContent
                }
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if catalogService.isLoading && catalogService.apps.isEmpty {
            LoadingView()
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
            ZStack {
                ThemedBackground()

                ScrollView {
                    VStack(spacing: 28) {
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
                    .padding(.top, 20)
                }
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

    @Environment(\.colorScheme) private var colorScheme

    private func errorView(_ error: Error) -> some View {
        ZStack {
            ThemedBackground()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange.gradient)
                }

                VStack(spacing: 8) {
                    Text("Failed to load catalog")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.1))

                    Text(error.localizedDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.5))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }

                Button(action: {
                    Task {
                        await catalogService.fetchCatalog(forceRefresh: true)
                    }
                }) {
                    Text("Try again")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentGreen)
            }
            .padding(40)
        }
    }
}

#Preview {
    ContentView()
}
