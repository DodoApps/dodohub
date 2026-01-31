import SwiftUI

struct AppDetailView: View {
    let app: CatalogApp
    let publisher: Publisher?
    @ObservedObject var stateManager: AppStateManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                Divider()

                // Screenshots
                if !app.screenshots.isEmpty {
                    screenshotsSection
                }

                // Description
                descriptionSection

                // Features
                if let features = app.features, !features.isEmpty {
                    featuresSection(features)
                }

                // Verification
                verificationSection

                // Stats
                statsSection

                // Publisher
                if let publisher = publisher {
                    publisherSection(publisher)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 500, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(url: URL(string: app.icon)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(app.name)
                        .font(.title)
                        .fontWeight(.bold)

                    if app.featured == true {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }

                Text(app.tagline)
                    .font(.title3)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Text("v\(app.version)")
                    Text("•")
                    Text(app.formattedSize)
                    Text("•")
                    Text("macOS \(app.minMacOS)+")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                actionButton
                    .frame(width: 120)

                if case .installed = stateManager.state(for: app.id) {
                    Button("Show in Finder") {
                        stateManager.revealInFinder(app)
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
        }
    }

    private var actionButton: some View {
        let state = stateManager.state(for: app.id)

        return Button(action: handleAction) {
            HStack {
                if case .downloading(let progress) = state {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                } else {
                    Text(state.buttonTitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 32)
        }
        .buttonStyle(.borderedProminent)
        .tint(buttonColor)
        .disabled(!state.isActionable)
    }

    private var buttonColor: Color {
        switch stateManager.state(for: app.id) {
        case .notInstalled: return .accentGreen
        case .installed: return .blue
        case .updateAvailable: return .orange
        case .downloading, .installing: return .gray
        }
    }

    private func handleAction() {
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

    // MARK: - Screenshots

    private var screenshotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screenshots")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(app.screenshots, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 300, height: 200)
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)

            Text(app.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Features

    private func featuresSection(_ features: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentGreen)

                        Text(feature)
                            .font(.subheadline)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Verification

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification")
                .font(.headline)

            VerificationBadges(verification: app.verification)

            HStack(spacing: 16) {
                Label("License: \(app.verification.license)", systemImage: "doc.text")
                Label("Verified: \(app.verification.verifiedAt)", systemImage: "checkmark.seal")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if let repoUrl = URL(string: app.verification.repoUrl) {
                Link(destination: repoUrl) {
                    Label("View source code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repository stats")
                .font(.headline)

            HStack(spacing: 24) {
                StatItem(icon: "star.fill", value: "\(app.repoStats.stars)", label: "Stars", color: .yellow)
                StatItem(icon: "exclamationmark.circle", value: "\(app.repoStats.openIssues)", label: "Open issues", color: .orange)
                MaintenanceBadge(status: app.maintenanceStatus)
            }

            Text("Last updated: \(app.formattedReleaseDate)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Publisher

    private func publisherSection(_ publisher: Publisher) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Publisher")
                .font(.headline)

            HStack(spacing: 12) {
                CachedAsyncImage(url: URL(string: publisher.icon ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(publisher.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if publisher.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }

                    if let description = publisher.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let githubUrl = URL(string: publisher.github) {
                    Link(destination: githubUrl) {
                        Image(systemName: "arrow.up.right.square")
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
