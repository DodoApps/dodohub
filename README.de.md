<p align="center">
  <img src="icon.png" alt="DodoHub" width="128" height="128">
</p>

<h1 align="center">DodoHub</h1>

<p align="center">
  Ein nativer macOS App Store zum Entdecken, Herunterladen und Verwalten von DodoApps-Anwendungen.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Lizenz-MIT-green" alt="Lizenz">
</p>

<p align="center">
  <a href="README.md">English</a> •
  <b>Deutsch</b> •
  <a href="README.fr.md">Français</a> •
  <a href="README.es.md">Español</a> •
  <a href="README.tr.md">Türkçe</a>
</p>

<p align="center">
  <img width="1315" alt="DodoHub Screenshot" src="https://github.com/user-attachments/assets/cbb71acc-b1e3-41f8-9fca-785c9ca60dfd" />
</p>

<p align="center">
  <img width="1314" alt="DodoHub App-Details" src="https://github.com/user-attachments/assets/7f9bfa21-23cd-41ff-8900-c091ba48b716" />
</p>

## Funktionen

- **App-Katalog** - Durchsuchen Sie alle verfügbaren DodoApps mit Beschreibungen, Screenshots und Funktionen
- **Ein-Klick-Installation** - Laden Sie Apps direkt aus dem Katalog herunter und installieren Sie sie
- **Update-Erkennung** - Sehen Sie, welche installierten Apps Updates verfügbar haben
- **Intelligente Filterung** - Filtern Sie nach Kategorie, Herausgeber oder Installationsstatus
- **Verifizierungsabzeichen** - Sehen Sie, welche Apps Open Source, notariell beglaubigt und datenschutzorientiert sind
- **Wartungsstatus** - Erfahren Sie, ob eine App aktiv gewartet wird

## Anforderungen

- macOS 14.0 (Sonoma) oder höher
- Apple Silicon oder Intel Mac

## Installation

### Homebrew (empfohlen)

```bash
brew tap dodoapps/tap
brew install --cask dodohub
```

### DMG herunterladen

Laden Sie die neueste Version von der [Releases](https://github.com/DodoApps/dodohub/releases)-Seite herunter.

### Aus Quellcode bauen

```bash
git clone https://github.com/DodoApps/dodohub.git
cd dodohub
open DodoHub.xcodeproj
```

In Xcode bauen und ausführen (⌘R).

## Funktionsweise

DodoHub ruft den App-Katalog von [DodoApps/catalog](https://github.com/DodoApps/catalog) ab, der Metadaten für alle verfügbaren Apps enthält. Wenn Sie auf "Installieren" klicken, wird die DMG direkt von GitHub Releases heruntergeladen und geöffnet, damit Sie sie in den Programme-Ordner ziehen können.

## Für Herausgeber

Möchten Sie Ihre App auf DodoHub listen? Siehe das [Catalog-Repository](https://github.com/DodoApps/catalog) für Einreichungsrichtlinien.

Anforderungen:
- Open Source (öffentliches Repository)
- Mindestens 1 Jahr alt
- Code überprüft
- Apple notariell beglaubigt

## Architektur

```
DodoHub/
├── DodoHubApp.swift          # App-Einstiegspunkt
├── ContentView.swift         # Hauptnavigation
├── Models/
│   └── Models.swift          # Datenmodelle (Catalog, App, Publisher)
├── Services/
│   ├── CatalogService.swift  # Ruft Katalog ab und cached ihn
│   ├── AppStateManager.swift # Verfolgt Installationsstatus
│   ├── DownloadManager.swift # Verwaltet Downloads
│   └── Helpers.swift         # Hilfsprogramme und UI-Komponenten
└── Views/
    ├── SidebarView.swift     # Navigations-Seitenleiste
    ├── AppGridView.swift     # App-Rasterlayout
    ├── AppCardView.swift     # Einzelne App-Karten
    └── AppDetailView.swift   # Vollständige App-Details
```

## Lizenz

MIT-Lizenz - siehe [LICENSE](LICENSE) für Details.

## Verwandte Projekte

- [DodoApps Catalog](https://github.com/DodoApps/catalog) - Der App-Katalog
- [DodoShot](https://github.com/DodoApps/dodoshot) - Screenshot-Tool
- [DodoClip](https://github.com/DodoApps/dodoclip) - Zwischenablage-Manager
- [DodoPulse](https://github.com/DodoApps/dodopulse) - Systemüberwachung
- [DodoTidy](https://github.com/DodoApps/dodotidy) - Systembereinigung
- [DodoCount](https://github.com/DodoApps/dodocount) - Analytics-Menüleiste
- [DodoNest](https://github.com/DodoApps/dodonest) - Menüleisten-Organizer
- [DodoPass](https://github.com/DodoApps/dodopass) - Passwort-Manager
