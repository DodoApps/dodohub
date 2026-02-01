import SwiftUI

struct AppCardView: View {
    let app: CatalogApp
    let state: AppInstallState

    @State private var isHovering = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Icon and status badges
            HStack(alignment: .top) {
                // App icon with installed indicator
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(url: URL(string: app.icon)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(placeholderGradient)
                            .overlay {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                    // Installed checkmark badge
                    if isInstalled {
                        ZStack {
                            Circle()
                                .fill(Color.accentGreen)
                                .frame(width: 22, height: 22)

                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: 4)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }

                Spacer()

                // Status badges
                VStack(alignment: .trailing, spacing: 6) {
                    if app.featured == true {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow.gradient)
                            Text("Featured")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.yellow.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        .foregroundStyle(colorScheme == .dark ? .yellow : Color(red: 0.7, green: 0.5, blue: 0))
                        .clipShape(Capsule())
                    }

                    if hasUpdate {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Update")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(colorScheme == .dark ? 0.25 : 0.12))
                        .foregroundStyle(colorScheme == .dark ? Color(red: 1.0, green: 0.7, blue: 0.4) : .orange)
                        .clipShape(Capsule())
                    }
                }
            }

            // Name and tagline
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(app.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(primaryTextColor)
                        .lineLimit(1)

                    if isInstalled && !hasUpdate {
                        Text("Installed")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentGreen.opacity(colorScheme == .dark ? 0.25 : 0.12))
                            .foregroundStyle(colorScheme == .dark ? Color(red: 0.4, green: 0.9, blue: 0.5) : .accentGreen)
                            .clipShape(Capsule())
                    }
                }

                Text(app.tagline)
                    .font(.system(size: 14))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)
            }

            Spacer()

            // Stats at bottom
            HStack(spacing: 12) {
                StarsBadge(count: app.stars)

                Text("v\(app.version)")
                    .font(.system(size: 13))
                    .foregroundStyle(tertiaryTextColor)

                Spacer()

                MaintenanceBadge(status: app.maintenanceStatus)
            }
        }
        .padding(24)
        .frame(height: 260)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isInstalled ? Color.accentGreen.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .opacity(isHovering ? 0.9 : 1.0)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    // MARK: - State Helpers

    private var isInstalled: Bool {
        switch state {
        case .installed, .updateAvailable:
            return true
        default:
            return false
        }
    }

    private var hasUpdate: Bool {
        if case .updateAvailable = state {
            return true
        }
        return false
    }

    // MARK: - Theme Colors

    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color(white: 0.12))
        } else {
            return AnyShapeStyle(Color(white: 0.98))
        }
    }

    private var borderColor: Color {
        if colorScheme == .dark {
            return isHovering ? Color.white.opacity(0.15) : Color.white.opacity(0.08)
        } else {
            return isHovering ? Color.black.opacity(0.12) : Color.black.opacity(0.06)
        }
    }

    private var installedBorderColor: Color {
        if isInstalled {
            return Color.accentGreen.opacity(colorScheme == .dark ? 0.5 : 0.3)
        }
        return borderColor
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.12)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(white: 0.1)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.4)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.5) : Color(white: 0.55)
    }

    private var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(white: 0.25), Color(white: 0.2)]
                : [Color(white: 0.92), Color(white: 0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var buttonColor: Color {
        switch state {
        case .notInstalled:
            return .accentGreen
        case .installed:
            return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .updateAvailable:
            return Color(red: 0.95, green: 0.6, blue: 0.2)
        case .downloading, .installing:
            return Color(white: 0.5)
        }
    }
}

// MARK: - Compact Card (for lists)

struct AppCompactRow: View {
    let app: CatalogApp
    let state: AppInstallState
    let onAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isInstalled: Bool {
        switch state {
        case .installed, .updateAvailable:
            return true
        default:
            return false
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: URL(string: app.icon)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                if isInstalled {
                    ZStack {
                        Circle()
                            .fill(Color.accentGreen)
                            .frame(width: 16, height: 16)

                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 3, y: 3)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(app.name)
                        .font(.system(size: 14, weight: .semibold))

                    if isInstalled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.accentGreen)
                    }
                }

                Text(app.tagline)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Button(action: onAction) {
                    Text(state.buttonTitle)
                        .font(.system(size: 12, weight: .medium))
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
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private var buttonColor: Color {
        switch state {
        case .notInstalled:
            return .accentGreen
        case .installed:
            return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .updateAvailable:
            return Color(red: 0.95, green: 0.6, blue: 0.2)
        case .downloading, .installing:
            return Color(white: 0.5)
        }
    }
}
