import SwiftUI

struct AppDetailView: View {
    let app: CatalogApp
    let publisher: Publisher?
    @ObservedObject var stateManager: AppStateManager
    var onBack: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ThemedBackground()

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
                    if !app.features.isEmpty {
                        featuresSection(app.features)
                    }

                    // Verification
                    if app.verification != nil {
                        verificationSection
                    }

                    // Stats
                    if app.repoStats != nil {
                        statsSection
                    }

                    // Publisher
                    if let publisher = publisher {
                        publisherSection(publisher)
                    }
                }
                .padding(24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if let onBack = onBack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 18) {
            CachedAsyncImage(url: URL(string: app.icon)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 108, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(app.name)
                        .font(.system(size: 26, weight: .bold))

                    if app.featured == true {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                    }
                }

                Text(app.tagline)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Text("v\(app.version)")
                    Text("•")
                    Text(app.formattedSize)
                    Text("•")
                    Text("macOS \(app.minMacOS)+")
                }
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                actionButton
                    .frame(width: 130)

                if case .installed = stateManager.state(for: app.id) {
                    Button("Show in Finder") {
                        stateManager.revealInFinder(app)
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 13))
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
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 34)
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
        VStack(alignment: .leading, spacing: 14) {
            Text("Screenshots")
                .font(.system(size: 18, weight: .semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(app.screenshots, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 350, height: 220)
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.system(size: 18, weight: .semibold))

            Text(app.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Features

    private func featuresSection(_ features: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.system(size: 18, weight: .semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentGreen)
                            .font(.system(size: 14))

                        Text(feature)
                            .font(.system(size: 14))

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Verification

    @ViewBuilder
    private var verificationSection: some View {
        if let verification = app.verification {
            VStack(alignment: .leading, spacing: 12) {
                Text("Verification")
                    .font(.system(size: 18, weight: .semibold))

                VerificationBadges(verification: verification)

                HStack(spacing: 18) {
                    if let license = verification.license {
                        Label("License: \(license)", systemImage: "doc.text")
                    }
                    if let verifiedAt = verification.verifiedAt {
                        Label("Verified: \(verifiedAt)", systemImage: "checkmark.seal")
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)

                if let repoUrlString = verification.repoUrl, let repoUrl = URL(string: repoUrlString) {
                    Link(destination: repoUrl) {
                        Label("View source code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .font(.system(size: 14))
                }
            }
        }
    }

    // MARK: - Stats

    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repository stats")
                .font(.system(size: 18, weight: .semibold))

            HStack(spacing: 26) {
                StatItem(icon: "star.fill", value: "\(app.stars)", label: "Stars", color: .yellow)
                StatItem(icon: "exclamationmark.circle", value: "\(app.openIssues)", label: "Open issues", color: .orange)
                MaintenanceBadge(status: app.maintenanceStatus)
            }

            if !app.formattedReleaseDate.isEmpty && app.formattedReleaseDate != "Unknown" {
                Text("Last updated: \(app.formattedReleaseDate)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Publisher

    private func publisherSection(_ publisher: Publisher) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Publisher")
                .font(.system(size: 18, weight: .semibold))

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(String(publisher.name.prefix(1)))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.accentGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(publisher.name)
                            .font(.system(size: 15, weight: .medium))

                        if publisher.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 13))
                        }
                    }

                    if let description = publisher.description {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let github = publisher.github, let githubUrl = URL(string: github) {
                    Link(destination: githubUrl) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(14)
            .background(colorScheme == .dark ? Color(white: 0.12) : Color(white: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}
