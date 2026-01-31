import SwiftUI

struct AppCardView: View {
    let app: CatalogApp
    let state: AppInstallState
    let onAction: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and status
            HStack(alignment: .top) {
                CachedAsyncImage(url: URL(string: app.icon)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                Spacer()

                if app.featured == true {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }

            // Name and tagline
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(app.tagline)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(height: 32, alignment: .top)
            }

            // Stats
            HStack(spacing: 12) {
                StarsBadge(count: app.repoStats.stars)

                Text("v\(app.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                MaintenanceBadge(status: app.maintenanceStatus)
            }

            Spacer()

            // Action button
            Button(action: onAction) {
                HStack {
                    if case .downloading(let progress) = state {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                    } else {
                        Text(state.buttonTitle)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 28)
            }
            .buttonStyle(.borderedProminent)
            .tint(buttonColor)
            .disabled(!state.isActionable)
        }
        .padding(16)
        .frame(height: 220)
        .background(isHovering ? Color(nsColor: .controlBackgroundColor).opacity(0.8) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovering ? 0.15 : 0.08), radius: isHovering ? 8 : 4, x: 0, y: isHovering ? 4 : 2)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var buttonColor: Color {
        switch state {
        case .notInstalled:
            return .accentGreen
        case .installed:
            return .blue
        case .updateAvailable:
            return .orange
        case .downloading, .installing:
            return .gray
        }
    }
}

// MARK: - Compact Card (for lists)

struct AppCompactRow: View {
    let app: CatalogApp
    let state: AppInstallState
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: app.icon)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.headline)

                Text(app.tagline)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Button(action: onAction) {
                    Text(state.buttonTitle)
                        .frame(width: 80)
                }
                .buttonStyle(.borderedProminent)
                .tint(buttonColor)
                .controlSize(.small)
                .disabled(!state.isActionable)

                Text("v\(app.version) • \(app.formattedSize)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var buttonColor: Color {
        switch state {
        case .notInstalled:
            return .accentGreen
        case .installed:
            return .blue
        case .updateAvailable:
            return .orange
        case .downloading, .installing:
            return .gray
        }
    }
}
