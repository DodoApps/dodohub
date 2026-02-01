import SwiftUI

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("colorScheme") var colorScheme: ColorSchemePreference = .system
    @AppStorage("refreshOnLaunch") var refreshOnLaunch: Bool = true
    @AppStorage("showNotifications") var showNotifications: Bool = true
    @AppStorage("defaultSortOrder") var defaultSortOrder: SortOrder = .featured
    @AppStorage("compactCards") var compactCards: Bool = false
    @AppStorage("downloadLocation") var downloadLocation: String = "~/Downloads"

    private init() {}
}

enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case featured = "Featured first"
    case nameAsc = "A to Z"
    case nameDesc = "Z to A"
    case stars = "Most stars"
    case recentlyUpdated = "Recently updated"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .nameAsc: return "arrow.up"
        case .nameDesc: return "arrow.down"
        case .stars: return "star"
        case .recentlyUpdated: return "clock"
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            appearanceSettings
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        Form {
            Section {
                Toggle("Refresh catalog on launch", isOn: $settings.refreshOnLaunch)

                Toggle("Show download notifications", isOn: $settings.showNotifications)

                Picker("Default sorting", selection: $settings.defaultSortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Label(order.rawValue, systemImage: order.icon)
                            .tag(order)
                    }
                }
            }

            Section {
                HStack {
                    Text("Download location")
                    Spacer()
                    Text(settings.downloadLocation)
                        .foregroundStyle(.secondary)
                    Button("Change...") {
                        selectDownloadLocation()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Appearance Settings

    private var appearanceSettings: some View {
        Form {
            Section {
                Picker("Appearance", selection: $settings.colorScheme) {
                    ForEach(ColorSchemePreference.allCases) { preference in
                        Text(preference.rawValue).tag(preference)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Use compact cards", isOn: $settings.compactCards)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About View

    private var aboutView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.075, green: 0.443, blue: 0.357), Color(red: 0.075, green: 0.443, blue: 0.357).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(red: 0.075, green: 0.443, blue: 0.357).opacity(0.4), radius: 15, x: 0, y: 8)

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("DodoHub")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("Version 1.0.0")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Text("Discover and install quality macOS apps")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                Link(destination: URL(string: "https://github.com/DodoApps/DodoHub")!) {
                    Label("GitHub", systemImage: "link")
                }

                Link(destination: URL(string: "https://github.com/DodoApps/DodoHub/issues")!) {
                    Label("Report issue", systemImage: "exclamationmark.bubble")
                }
            }
            .font(.system(size: 13))

            Spacer()

            Text("© 2026 DodoApps. All rights reserved.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    private func selectDownloadLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            settings.downloadLocation = url.path
        }
    }
}

#Preview {
    SettingsView()
}
