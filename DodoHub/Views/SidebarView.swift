import SwiftUI

struct SidebarView: View {
    @Binding var selectedFilter: SidebarFilter
    @ObservedObject var catalogService: CatalogService
    @ObservedObject var stateManager: AppStateManager

    var body: some View {
        List(selection: $selectedFilter) {
            Section("Browse") {
                NavigationLink(value: SidebarFilter.all) {
                    Label("All apps", systemImage: "square.grid.2x2")
                }

                NavigationLink(value: SidebarFilter.featured) {
                    Label("Featured", systemImage: "star")
                }
            }

            Section("Library") {
                NavigationLink(value: SidebarFilter.installed) {
                    Label {
                        HStack {
                            Text("Installed")
                            Spacer()
                            Text("\(installedCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "checkmark.circle")
                    }
                }

                NavigationLink(value: SidebarFilter.updates) {
                    Label {
                        HStack {
                            Text("Updates")
                            Spacer()
                            if updatesCount > 0 {
                                Text("\(updatesCount)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentGreen)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: "arrow.down.circle")
                    }
                }
            }

            Section("Categories") {
                ForEach(AppCategory.allCases, id: \.self) { category in
                    NavigationLink(value: SidebarFilter.category(category)) {
                        Label {
                            HStack {
                                Text(category.displayName)
                                Spacer()
                                Text("\(appsCount(for: category))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: category.icon)
                        }
                    }
                }
            }

            if !catalogService.publishers.isEmpty {
                Section("Publishers") {
                    ForEach(catalogService.publishers) { publisher in
                        NavigationLink(value: SidebarFilter.publisher(publisher.id)) {
                            Label {
                                HStack {
                                    Text(publisher.name)
                                    Spacer()
                                    if publisher.verified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                            } icon: {
                                Image(systemName: "person.circle")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }

    private var installedCount: Int {
        stateManager.installedApps(from: catalogService.apps).count
    }

    private var updatesCount: Int {
        stateManager.appsWithUpdates(from: catalogService.apps).count
    }

    private func appsCount(for category: AppCategory) -> Int {
        catalogService.apps(for: category).count
    }
}
