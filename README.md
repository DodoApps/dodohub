# DodoHub

A native macOS app store for discovering, downloading, and managing MaOS applications.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)


<img width="1315" height="854" alt="image" src="https://github.com/user-attachments/assets/cbb71acc-b1e3-41f8-9fca-785c9ca60dfd" />

<p>

<img width="1314" height="851" alt="image" src="https://github.com/user-attachments/assets/7f9bfa21-23cd-41ff-8900-c091ba48b716" />

</p>
## Features

- **App catalog** - Browse all available DodoApps with descriptions, screenshots, and features
- **One-click install** - Download and install apps directly from the catalog
- **Update detection** - See which installed apps have updates available
- **Smart filtering** - Filter by category, publisher, or installation status
- **Verification badges** - See which apps are open source, notarized, and privacy-focused
- **Maintenance status** - Know if an app is actively maintained



## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## Installation

### Download

Download the latest release from the [Releases](https://github.com/DodoApps/dodohub/releases) page.

### Build from source

```bash
git clone https://github.com/DodoApps/dodohub.git
cd dodohub
open DodoHub.xcodeproj
```

Build and run in Xcode (⌘R).

## How it works

DodoHub fetches the app catalog from [DodoApps/catalog](https://github.com/DodoApps/catalog), which contains metadata for all available apps. When you click "Install", it downloads the DMG directly from GitHub releases and opens it for you to drag to Applications.

## For publishers

Want to list your app on DodoHub? See the [catalog repository](https://github.com/DodoApps/catalog) for submission guidelines.

Requirements:
- Open source (public repository)
- At least 1 year old
- Code reviewed
- Apple notarized

## Architecture

```
DodoHub/
├── DodoHubApp.swift          # App entry point
├── ContentView.swift         # Main navigation
├── Models/
│   └── Models.swift          # Data models (Catalog, App, Publisher)
├── Services/
│   ├── CatalogService.swift  # Fetches and caches catalog
│   ├── AppStateManager.swift # Tracks installation status
│   ├── DownloadManager.swift # Handles downloads
│   └── Helpers.swift         # Utilities and UI components
└── Views/
    ├── SidebarView.swift     # Navigation sidebar
    ├── AppGridView.swift     # App grid layout
    ├── AppCardView.swift     # Individual app cards
    └── AppDetailView.swift   # Full app details
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related

- [DodoApps Catalog](https://github.com/DodoApps/catalog) - The app catalog
- [DodoShot](https://github.com/DodoApps/dodoshot) - Screenshot tool
- [DodoClip](https://github.com/DodoApps/dodoclip) - Clipboard manager
- [DodoPulse](https://github.com/DodoApps/dodopulse) - System monitoring
- [DodoTidy](https://github.com/DodoApps/dodotidy) - System cleaner
- [DodoCount](https://github.com/DodoApps/dodocount) - Analytics menubar
- [DodoNest](https://github.com/DodoApps/dodonest) - Menu bar organizer
