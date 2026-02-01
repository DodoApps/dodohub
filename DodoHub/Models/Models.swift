import Foundation

// MARK: - Catalog Root

struct Catalog: Codable {
    let schemaVersion: String?
    let lastUpdated: String?
    let publishers: [Publisher]
    let apps: [CatalogApp]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        schemaVersion = try container.decodeIfPresent(String.self, forKey: .schemaVersion)
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)

        // Decode publishers, skipping invalid ones
        publishers = (try? container.decodeIfPresent([SafeDecodable<Publisher>].self, forKey: .publishers))?
            .compactMap { $0.value } ?? []

        // Decode apps, skipping invalid ones
        apps = (try? container.decodeIfPresent([SafeDecodable<CatalogApp>].self, forKey: .apps))?
            .compactMap { $0.value } ?? []
    }
}

// MARK: - Safe Decodable Wrapper

/// Wraps a Decodable type to allow graceful failure - if decoding fails, value is nil instead of throwing
struct SafeDecodable<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            value = try container.decode(T.self)
        } catch {
            // Log the error for debugging but don't fail
            print("⚠️ Failed to decode \(T.self): \(error.localizedDescription)")
            value = nil
        }
    }
}

// MARK: - Publisher

struct Publisher: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let website: String?
    let github: String?
    let email: String?
    let sponsorUrl: String?
    let verified: Bool
    let verifiedAt: String?
    let joinedAt: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        // Optional fields with defaults
        description = try container.decodeIfPresent(String.self, forKey: .description)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        github = try container.decodeIfPresent(String.self, forKey: .github)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        sponsorUrl = try container.decodeIfPresent(String.self, forKey: .sponsorUrl)
        verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
        verifiedAt = try container.decodeIfPresent(String.self, forKey: .verifiedAt)
        joinedAt = try container.decodeIfPresent(String.self, forKey: .joinedAt)
    }
}

// MARK: - App

struct CatalogApp: Codable, Identifiable {
    let id: String
    let name: String
    let publisherId: String
    let tagline: String
    let description: String
    let category: AppCategory
    let featured: Bool
    let icon: String
    let screenshots: [String]
    let version: String
    let minMacOS: String
    let downloadUrl: String
    let downloadSize: Int
    let releaseDate: String
    let bundleId: String
    let features: [String]
    let verification: Verification?
    let repoStats: RepoStats?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields - app must have these to be valid
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        downloadUrl = try container.decode(String.self, forKey: .downloadUrl)

        // Optional fields with sensible defaults
        publisherId = try container.decodeIfPresent(String.self, forKey: .publisherId) ?? "unknown"
        tagline = try container.decodeIfPresent(String.self, forKey: .tagline) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try container.decodeIfPresent(AppCategory.self, forKey: .category) ?? .utilities
        featured = try container.decodeIfPresent(Bool.self, forKey: .featured) ?? false
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? ""
        screenshots = try container.decodeIfPresent([String].self, forKey: .screenshots) ?? []
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0.0"
        minMacOS = try container.decodeIfPresent(String.self, forKey: .minMacOS) ?? "14.0"
        downloadSize = try container.decodeIfPresent(Int.self, forKey: .downloadSize) ?? 0
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate) ?? ""
        bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId) ?? ""
        features = try container.decodeIfPresent([String].self, forKey: .features) ?? []
        verification = try container.decodeIfPresent(Verification.self, forKey: .verification)
        repoStats = try container.decodeIfPresent(RepoStats.self, forKey: .repoStats)
    }

    var formattedSize: String {
        guard downloadSize > 0 else { return "Unknown size" }
        return ByteCountFormatter.string(fromByteCount: Int64(downloadSize), countStyle: .file)
    }

    var formattedReleaseDate: String {
        guard !releaseDate.isEmpty else { return "Unknown" }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: releaseDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: releaseDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }

        return releaseDate
    }

    var maintenanceStatus: MaintenanceStatus {
        guard let repoStats = repoStats, !repoStats.lastCommitAt.isEmpty else {
            return .unknown
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let lastCommit = formatter.date(from: repoStats.lastCommitAt) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: repoStats.lastCommitAt)
        }() else {
            return .unknown
        }

        if repoStats.archived {
            return .abandoned
        }

        let daysSinceCommit = Calendar.current.dateComponents([.day], from: lastCommit, to: Date()).day ?? 0

        switch daysSinceCommit {
        case 0...90:
            return .active
        case 91...180:
            return .maintained
        case 181...365:
            return .stale
        default:
            return .abandoned
        }
    }

    // MARK: - Convenience accessors for verification

    var isOpenSource: Bool {
        verification?.openSource ?? false
    }

    var isNotarized: Bool {
        verification?.notarized ?? false
    }

    var isPrivacyFocused: Bool {
        verification?.noAnalytics ?? false
    }

    var isSandboxed: Bool {
        verification?.sandboxed ?? false
    }

    var repoUrl: String? {
        verification?.repoUrl
    }

    var license: String? {
        verification?.license
    }

    var stars: Int {
        repoStats?.stars ?? 0
    }

    var openIssues: Int {
        repoStats?.openIssues ?? 0
    }
}

// MARK: - Category

enum AppCategory: String, Codable, CaseIterable {
    case productivity
    case utilities
    case analytics
    case security
    case developer
    case media
    case social
    case finance
    case education
    case other

    // Handle unknown categories gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = AppCategory(rawValue: rawValue.lowercased()) ?? .other
    }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .productivity: return "pencil.and.outline"
        case .utilities: return "wrench.and.screwdriver"
        case .analytics: return "chart.bar"
        case .security: return "lock.shield"
        case .developer: return "hammer"
        case .media: return "play.rectangle"
        case .social: return "bubble.left.and.bubble.right"
        case .finance: return "dollarsign.circle"
        case .education: return "book"
        case .other: return "square.grid.2x2"
        }
    }
}

// MARK: - Verification

struct Verification: Codable {
    let openSource: Bool
    let repoUrl: String?
    let license: String?
    let notarized: Bool
    let codeReviewed: Bool
    let sandboxed: Bool
    let noAnalytics: Bool
    let repoCreatedAt: String?
    let verifiedAt: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        openSource = try container.decodeIfPresent(Bool.self, forKey: .openSource) ?? false
        repoUrl = try container.decodeIfPresent(String.self, forKey: .repoUrl)
        license = try container.decodeIfPresent(String.self, forKey: .license)
        notarized = try container.decodeIfPresent(Bool.self, forKey: .notarized) ?? false
        codeReviewed = try container.decodeIfPresent(Bool.self, forKey: .codeReviewed) ?? false
        sandboxed = try container.decodeIfPresent(Bool.self, forKey: .sandboxed) ?? false
        noAnalytics = try container.decodeIfPresent(Bool.self, forKey: .noAnalytics) ?? false
        repoCreatedAt = try container.decodeIfPresent(String.self, forKey: .repoCreatedAt)
        verifiedAt = try container.decodeIfPresent(String.self, forKey: .verifiedAt)
    }
}

// MARK: - Repo Stats

struct RepoStats: Codable {
    let lastCommitAt: String
    let openIssues: Int
    let stars: Int
    let archived: Bool
    let fetchedAt: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        lastCommitAt = try container.decodeIfPresent(String.self, forKey: .lastCommitAt) ?? ""
        openIssues = try container.decodeIfPresent(Int.self, forKey: .openIssues) ?? 0
        stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
        fetchedAt = try container.decodeIfPresent(String.self, forKey: .fetchedAt)
    }
}

// MARK: - Maintenance Status

enum MaintenanceStatus: String {
    case active = "Active"
    case maintained = "Maintained"
    case stale = "Stale"
    case abandoned = "Abandoned"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .active: return "green"
        case .maintained: return "blue"
        case .stale: return "orange"
        case .abandoned: return "red"
        case .unknown: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .maintained: return "checkmark.circle"
        case .stale: return "exclamationmark.triangle"
        case .abandoned: return "xmark.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - App Installation State

enum AppInstallState: Equatable {
    case notInstalled
    case installed(version: String)
    case updateAvailable(installed: String, available: String)
    case downloading(progress: Double)
    case installing
    case failed(error: String)

    var buttonTitle: String {
        switch self {
        case .notInstalled:
            return "Install"
        case .installed:
            return "Open"
        case .updateAvailable:
            return "Update"
        case .downloading(let progress):
            return "Downloading \(Int(progress * 100))%"
        case .installing:
            return "Installing..."
        case .failed:
            return "Retry"
        }
    }

    var isActionable: Bool {
        switch self {
        case .downloading, .installing:
            return false
        default:
            return true
        }
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Download Error

enum DownloadError: Error, LocalizedError {
    case invalidURL
    case networkUnavailable
    case serverError(statusCode: Int)
    case fileNotFound
    case downloadFailed(underlying: Error)
    case fileSystemError(underlying: Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .networkUnavailable:
            return "No internet connection"
        case .serverError(let code):
            return "Server error (HTTP \(code))"
        case .fileNotFound:
            return "File not found on server"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "Could not save file: \(error.localizedDescription)"
        case .cancelled:
            return "Download cancelled"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "The app's download link may be outdated. Try refreshing the catalog."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .serverError:
            return "The server may be temporarily unavailable. Try again later."
        case .fileNotFound:
            return "The download file may have been moved or deleted. Try refreshing the catalog."
        case .downloadFailed:
            return "Check your internet connection and try again."
        case .fileSystemError:
            return "Check that you have enough disk space and try again."
        case .cancelled:
            return nil
        }
    }
}

// MARK: - Sidebar Filter

enum SidebarFilter: Hashable {
    case all
    case featured
    case installed
    case updates
    case category(AppCategory)
    case publisher(String)

    var title: String {
        switch self {
        case .all: return "All apps"
        case .featured: return "Featured"
        case .installed: return "Installed"
        case .updates: return "Updates"
        case .category(let cat): return cat.displayName
        case .publisher(let name): return name
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .featured: return "star"
        case .installed: return "checkmark.circle"
        case .updates: return "arrow.down.circle"
        case .category(let cat): return cat.icon
        case .publisher: return "person.circle"
        }
    }
}
