import SwiftUI

struct AppGridView: View {
    let apps: [CatalogApp]
    let title: String
    @ObservedObject var stateManager: AppStateManager
    @Binding var selectedApp: CatalogApp?
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = SettingsManager.shared.defaultSortOrder
    @Environment(\.colorScheme) private var colorScheme

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 20)
    ]

    var filteredAndSortedApps: [CatalogApp] {
        var result = apps

        // Filter by search
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            result = result.filter { app in
                app.name.lowercased().contains(lowercased) ||
                app.tagline.lowercased().contains(lowercased)
            }
        }

        // Sort
        switch sortOrder {
        case .featured:
            result.sort { ($0.featured == true ? 0 : 1) < ($1.featured == true ? 0 : 1) }
        case .nameAsc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .stars:
            result.sort { $0.stars > $1.stars }
        case .recentlyUpdated:
            result.sort { $0.releaseDate > $1.releaseDate }
        }

        return result
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.1))

                    Spacer()

                    // Sort picker
                    Menu {
                        ForEach(SortOrder.allCases) { order in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    sortOrder = order
                                }
                            } label: {
                                Label(order.rawValue, systemImage: order.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 12, weight: .medium))
                            Text(sortOrder.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Text("\(filteredAndSortedApps.count) apps")
                        .font(.system(size: 15))
                        .foregroundStyle(colorScheme == .dark ? Color(white: 0.5) : Color(white: 0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Grid
                ScrollView {
                    if filteredAndSortedApps.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredAndSortedApps) { app in
                                AppCardView(
                                    app: app,
                                    state: stateManager.state(for: app.id)
                                )
                                .onTapGesture {
                                    selectedApp = app
                                }
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search apps...")
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                    .frame(width: 100, height: 100)

                Image(systemName: "app.dashed")
                    .font(.system(size: 40))
                    .foregroundStyle(colorScheme == .dark ? Color(white: 0.4) : Color(white: 0.6))
            }

            VStack(spacing: 8) {
                Text("No apps found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.2))

                if !searchText.isEmpty {
                    Text("Try a different search term")
                        .font(.system(size: 14))
                        .foregroundStyle(colorScheme == .dark ? Color(white: 0.5) : Color(white: 0.5))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(60)
    }

}

// MARK: - Featured Section

struct FeaturedSection: View {
    let apps: [CatalogApp]
    @ObservedObject var stateManager: AppStateManager
    @Binding var selectedApp: CatalogApp?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow.gradient)
                Text("Featured")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.1))
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
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
                .padding(.horizontal, 24)
            }
        }
    }
}

struct FeaturedCard: View {
    let app: CatalogApp
    let state: AppInstallState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                CachedAsyncImage(url: URL(string: app.icon)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {
                    Text(app.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.1))

                    Text(app.tagline)
                        .font(.system(size: 14))
                        .foregroundStyle(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.45))
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
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(22)
        .frame(width: 340)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(isHovering ? 0.9 : 1.0)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color(white: 0.12))
        } else {
            return AnyShapeStyle(Color(white: 0.98))
        }
    }
}
