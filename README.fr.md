<p align="center">
  <img src="icon.png" alt="DodoHub" width="128" height="128">
</p>

<h1 align="center">DodoHub</h1>

<p align="center">
  Une boutique d'applications macOS native pour découvrir, télécharger et gérer les applications DodoApps.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Licence-MIT-green" alt="Licence">
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README.de.md">Deutsch</a> •
  <b>Français</b> •
  <a href="README.es.md">Español</a> •
  <a href="README.tr.md">Türkçe</a>
</p>

<p align="center">
  <img width="1315" alt="Capture d'écran DodoHub" src="https://github.com/user-attachments/assets/cbb71acc-b1e3-41f8-9fca-785c9ca60dfd" />
</p>

<p align="center">
  <img width="1314" alt="Détails de l'application DodoHub" src="https://github.com/user-attachments/assets/7f9bfa21-23cd-41ff-8900-c091ba48b716" />
</p>

## Fonctionnalités

- **Catalogue d'applications** - Parcourez toutes les applications DodoApps disponibles avec descriptions, captures d'écran et fonctionnalités
- **Installation en un clic** - Téléchargez et installez des applications directement depuis le catalogue
- **Détection des mises à jour** - Voyez quelles applications installées ont des mises à jour disponibles
- **Filtrage intelligent** - Filtrez par catégorie, éditeur ou statut d'installation
- **Badges de vérification** - Voyez quelles applications sont open source, notariées et respectueuses de la vie privée
- **Statut de maintenance** - Sachez si une application est activement maintenue

## Configuration requise

- macOS 14.0 (Sonoma) ou ultérieur
- Mac Apple Silicon ou Intel

## Installation

### Homebrew (recommandé)

```bash
brew tap dodoapps/tap
brew install --cask dodohub
```

### Télécharger le DMG

Téléchargez la dernière version depuis la page [Releases](https://github.com/DodoApps/dodohub/releases).

### Compiler depuis les sources

```bash
git clone https://github.com/DodoApps/dodohub.git
cd dodohub
open DodoHub.xcodeproj
```

Compilez et exécutez dans Xcode (⌘R).

## Comment ça fonctionne

DodoHub récupère le catalogue d'applications depuis [DodoApps/catalog](https://github.com/DodoApps/catalog), qui contient les métadonnées de toutes les applications disponibles. Lorsque vous cliquez sur "Installer", il télécharge le DMG directement depuis les releases GitHub et l'ouvre pour que vous puissiez le glisser dans Applications.

## Pour les éditeurs

Vous souhaitez lister votre application sur DodoHub ? Consultez le [dépôt catalog](https://github.com/DodoApps/catalog) pour les directives de soumission.

Exigences :
- Open source (dépôt public)
- Au moins 1 an d'existence
- Code examiné
- Notarié par Apple

## Architecture

```
DodoHub/
├── DodoHubApp.swift          # Point d'entrée de l'application
├── ContentView.swift         # Navigation principale
├── Models/
│   └── Models.swift          # Modèles de données (Catalog, App, Publisher)
├── Services/
│   ├── CatalogService.swift  # Récupère et met en cache le catalogue
│   ├── AppStateManager.swift # Suit le statut d'installation
│   ├── DownloadManager.swift # Gère les téléchargements
│   └── Helpers.swift         # Utilitaires et composants UI
└── Views/
    ├── SidebarView.swift     # Barre latérale de navigation
    ├── AppGridView.swift     # Disposition en grille des applications
    ├── AppCardView.swift     # Cartes d'applications individuelles
    └── AppDetailView.swift   # Détails complets de l'application
```

## Licence

Licence MIT - voir [LICENSE](LICENSE) pour plus de détails.

## Projets connexes

- [DodoApps Catalog](https://github.com/DodoApps/catalog) - Le catalogue d'applications
- [DodoShot](https://github.com/DodoApps/dodoshot) - Outil de capture d'écran
- [DodoClip](https://github.com/DodoApps/dodoclip) - Gestionnaire de presse-papiers
- [DodoPulse](https://github.com/DodoApps/dodopulse) - Surveillance système
- [DodoTidy](https://github.com/DodoApps/dodotidy) - Nettoyeur système
- [DodoCount](https://github.com/DodoApps/dodocount) - Analytics dans la barre de menus
- [DodoNest](https://github.com/DodoApps/dodonest) - Organisateur de barre de menus
- [DodoPass](https://github.com/DodoApps/dodopass) - Gestionnaire de mots de passe
