import SwiftUI

struct AppGridView: View {
    let apps: [CatalogApp]
    let title: String
    @ObservedObject var stateManager: AppStateManager
    @Binding var selectedApp: CatalogApp?
    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
    ]

    var filteredApps: [CatalogApp] {
        if searchText.isEmpty {
            return apps
        }
        let lowercased = searchText.lowercased()
        return apps.filter { app in
            app.name.lowercased().contains(lowercased) ||
            app.tagline.lowercased().contains(lowercased)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(filteredApps.count) apps")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Grid
            ScrollView {
                if filteredApps.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredApps) { app in
                            AppCardView(
                                app: app,
                                state: stateManager.state(for: app.id),
                                onAction: { handleAction(for: app) }
                            )
                            .onTapGesture {
                                selectedApp = app
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search apps...")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.dashed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No apps found")
                .font(.headline)

            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func handleAction(for app: CatalogApp) {
        let state = stateManager.state(for: app.id)

        switch state {
        case .notInstalled, .updateAvailable:
            Task {
                await DownloadManager.shared.download(app)
            }
        case .installed:
            stateManager.openApp(app)
        case .downloading, .installing:
            break
        }
    }
}

// MARK: - Featured Section

struct FeaturedSection: View {
    let apps: [CatalogApp]
    @ObservedObject var stateManager: AppStateManager
    @Binding var selectedApp: CatalogApp?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Featured")
                    .font(.headline)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(apps) { app in
                        FeaturedCard(
                            app: app,
                            state: stateManager.state(for: app.id)
                        )
                        .onTapGesture {
                            selectedApp = app
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct FeaturedCard: View {
    let app: CatalogApp
    let state: AppInstallState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: URL(string: app.icon)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)

                    Text(app.tagline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            if let screenshot = app.screenshots.first, let url = URL(string: screenshot) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
