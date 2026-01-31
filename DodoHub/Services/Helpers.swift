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

// MARK: - Maintenance Status Badge

struct MaintenanceBadge: View {
    let status: MaintenanceStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .active: return .green.opacity(0.15)
        case .maintained: return .blue.opacity(0.15)
        case .stale: return .orange.opacity(0.15)
        case .abandoned: return .red.opacity(0.15)
        case .unknown: return .gray.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .active: return .green
        case .maintained: return .blue
        case .stale: return .orange
        case .abandoned: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Verification Badges

struct VerificationBadges: View {
    let verification: Verification

    var body: some View {
        HStack(spacing: 8) {
            if verification.openSource {
                Badge(icon: "lock.open", text: "Open source", color: .green)
            }
            if verification.notarized {
                Badge(icon: "checkmark.seal", text: "Notarized", color: .blue)
            }
            if verification.noAnalytics {
                Badge(icon: "eye.slash", text: "No tracking", color: .purple)
            }
            if verification.sandboxed {
                Badge(icon: "shield", text: "Sandboxed", color: .orange)
            }
        }
    }
}

struct Badge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

// MARK: - Stars Badge

struct StarsBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("\(count)")
        }
        .font(.caption)
    }
}
