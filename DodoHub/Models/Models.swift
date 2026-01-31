import Foundation

// MARK: - Catalog Root

struct Catalog: Codable {
    let schemaVersion: String
    let lastUpdated: String
    let publishers: [Publisher]
    let apps: [CatalogApp]
}

// MARK: - Publisher

struct Publisher: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let website: String?
    let github: String
    let icon: String?
    let email: String?
    let sponsorUrl: String?
    let verified: Bool
    let verifiedAt: String
    let joinedAt: String
}

// MARK: - App

struct CatalogApp: Codable, Identifiable {
    let id: String
    let name: String
    let publisherId: String
    let tagline: String
    let description: String
    let category: AppCategory
    let featured: Bool?
    let icon: String
    let screenshots: [String]
    let version: String
    let minMacOS: String
    let downloadUrl: String
    let downloadSize: Int
    let releaseDate: String
    let bundleId: String
    let features: [String]?
    let verification: Verification
    let repoStats: RepoStats

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(downloadSize), countStyle: .file)
    }

    var formattedReleaseDate: String {
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
}

// MARK: - Category

enum AppCategory: String, Codable, CaseIterable {
    case productivity
    case utilities
    case analytics

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .productivity: return "pencil.and.outline"
        case .utilities: return "wrench.and.screwdriver"
        case .analytics: return "chart.bar"
        }
    }
}

// MARK: - Verification

struct Verification: Codable {
    let openSource: Bool
    let repoUrl: String
    let license: String
    let notarized: Bool
    let codeReviewed: Bool
    let sandboxed: Bool
    let noAnalytics: Bool
    let repoCreatedAt: String
    let verifiedAt: String
}

// MARK: - Repo Stats

struct RepoStats: Codable {
    let lastCommitAt: String
    let openIssues: Int
    let stars: Int
    let archived: Bool
    let fetchedAt: String
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
