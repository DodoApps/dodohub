import Foundation
import SwiftUI

// MARK: - Async Image with Caching

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: NSImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(nsImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }
        isLoading = true

        // Check cache
        if let cached = ImageCache.shared.get(for: url) {
            self.image = cached
            isLoading = false
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let nsImage = NSImage(data: data) {
                    ImageCache.shared.set(nsImage, for: url)
                    await MainActor.run {
                        self.image = nsImage
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Image Cache

class ImageCache {
    static let shared = ImageCache()

    private var cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 100
    }

    func get(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Color Extensions

extension Color {
    static let accentGreen = Color(red: 0.075, green: 0.443, blue: 0.357) // #13715B
}

// MARK: - Theme-Aware Background

struct ThemedBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.05, green: 0.05, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.96, blue: 0.98),
                        Color(red: 0.92, green: 0.92, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ThemedBackground()

            VStack(spacing: 24) {
                // Animated logo placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentGreen, Color.accentGreen.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.accentGreen.opacity(0.4), radius: 20, x: 0, y: 10)

                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)

                VStack(spacing: 8) {
                    Text("DodoHub")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.15))

                    Text("Loading app catalog...")
                        .font(.system(size: 14))
                        .foregroundStyle(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.5))
                }

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color.accentGreen)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Maintenance Status Badge

struct MaintenanceBadge: View {
    let status: MaintenanceStatus
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.icon)
                .font(.system(size: 11, weight: .semibold))
            Text(status.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        let opacity = colorScheme == .dark ? 0.25 : 0.12
        switch status {
        case .active: return .green.opacity(opacity)
        case .maintained: return .blue.opacity(opacity)
        case .stale: return .orange.opacity(opacity)
        case .abandoned: return .red.opacity(opacity)
        case .unknown: return .gray.opacity(opacity)
        }
    }

    private var foregroundColor: Color {
        let darkAdjustment = colorScheme == .dark
        switch status {
        case .active: return darkAdjustment ? Color(red: 0.4, green: 0.9, blue: 0.5) : .green
        case .maintained: return darkAdjustment ? Color(red: 0.5, green: 0.7, blue: 1.0) : .blue
        case .stale: return darkAdjustment ? Color(red: 1.0, green: 0.7, blue: 0.4) : .orange
        case .abandoned: return darkAdjustment ? Color(red: 1.0, green: 0.5, blue: 0.5) : .red
        case .unknown: return darkAdjustment ? Color(white: 0.6) : .gray
        }
    }
}

// MARK: - Verification Badges

struct VerificationBadges: View {
    let verification: Verification
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if verification.openSource {
                Badge(icon: "lock.open.fill", text: "Open source", color: .green)
            }
            if verification.notarized {
                Badge(icon: "checkmark.seal.fill", text: "Notarized", color: .blue)
            }
            if verification.noAnalytics {
                Badge(icon: "eye.slash.fill", text: "No tracking", color: .purple)
            }
            if verification.sandboxed {
                Badge(icon: "shield.fill", text: "Sandboxed", color: .orange)
            }
        }
    }
}

struct Badge: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(colorScheme == .dark ? 0.25 : 0.12))
        .foregroundColor(colorScheme == .dark ? color.opacity(0.9) : color)
        .clipShape(Capsule())
    }
}

// MARK: - Stars Badge

struct StarsBadge: View {
    let count: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow.gradient)
                .font(.system(size: 13))
            Text("\(count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? Color(white: 0.8) : Color(white: 0.3))
        }
    }
}
