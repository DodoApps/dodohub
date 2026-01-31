<p align="center">
  <img src="icon.png" alt="DodoHub" width="128" height="128">
</p>

<h1 align="center">DodoHub</h1>

<p align="center">
  Una tienda de aplicaciones nativa de macOS para descubrir, descargar y gestionar aplicaciones DodoApps.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Licencia-MIT-green" alt="Licencia">
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README.de.md">Deutsch</a> •
  <a href="README.fr.md">Français</a> •
  <b>Español</b> •
  <a href="README.tr.md">Türkçe</a>
</p>

<p align="center">
  <img width="1315" alt="Captura de pantalla de DodoHub" src="https://github.com/user-attachments/assets/cbb71acc-b1e3-41f8-9fca-785c9ca60dfd" />
</p>

<p align="center">
  <img width="1314" alt="Detalles de la aplicación DodoHub" src="https://github.com/user-attachments/assets/7f9bfa21-23cd-41ff-8900-c091ba48b716" />
</p>

## Características

- **Catálogo de aplicaciones** - Explora todas las aplicaciones DodoApps disponibles con descripciones, capturas de pantalla y características
- **Instalación con un clic** - Descarga e instala aplicaciones directamente desde el catálogo
- **Detección de actualizaciones** - Ve qué aplicaciones instaladas tienen actualizaciones disponibles
- **Filtrado inteligente** - Filtra por categoría, editor o estado de instalación
- **Insignias de verificación** - Ve qué aplicaciones son de código abierto, notarizadas y enfocadas en la privacidad
- **Estado de mantenimiento** - Sabe si una aplicación se mantiene activamente

## Requisitos

- macOS 14.0 (Sonoma) o posterior
- Mac con Apple Silicon o Intel

## Instalación

### Homebrew (recomendado)

```bash
brew tap dodoapps/tap
brew install --cask dodohub
```

### Descargar DMG

Descarga la última versión desde la página de [Releases](https://github.com/DodoApps/dodohub/releases).

### Compilar desde el código fuente

```bash
git clone https://github.com/DodoApps/dodohub.git
cd dodohub
open DodoHub.xcodeproj
```

Compila y ejecuta en Xcode (⌘R).

## Cómo funciona

DodoHub obtiene el catálogo de aplicaciones desde [DodoApps/catalog](https://github.com/DodoApps/catalog), que contiene metadatos de todas las aplicaciones disponibles. Cuando haces clic en "Instalar", descarga el DMG directamente desde los releases de GitHub y lo abre para que puedas arrastrarlo a Aplicaciones.

## Para editores

¿Quieres listar tu aplicación en DodoHub? Consulta el [repositorio catalog](https://github.com/DodoApps/catalog) para las directrices de envío.

Requisitos:
- Código abierto (repositorio público)
- Al menos 1 año de antigüedad
- Código revisado
- Notarizado por Apple

## Arquitectura

```
DodoHub/
├── DodoHubApp.swift          # Punto de entrada de la aplicación
├── ContentView.swift         # Navegación principal
├── Models/
│   └── Models.swift          # Modelos de datos (Catalog, App, Publisher)
├── Services/
│   ├── CatalogService.swift  # Obtiene y almacena en caché el catálogo
│   ├── AppStateManager.swift # Rastrea el estado de instalación
│   ├── DownloadManager.swift # Gestiona las descargas
│   └── Helpers.swift         # Utilidades y componentes de UI
└── Views/
    ├── SidebarView.swift     # Barra lateral de navegación
    ├── AppGridView.swift     # Diseño de cuadrícula de aplicaciones
    ├── AppCardView.swift     # Tarjetas de aplicaciones individuales
    └── AppDetailView.swift   # Detalles completos de la aplicación
```

## Licencia

Licencia MIT - ver [LICENSE](LICENSE) para más detalles.

## Proyectos relacionados

- [DodoApps Catalog](https://github.com/DodoApps/catalog) - El catálogo de aplicaciones
- [DodoShot](https://github.com/DodoApps/dodoshot) - Herramienta de capturas de pantalla
- [DodoClip](https://github.com/DodoApps/dodoclip) - Gestor de portapapeles
- [DodoPulse](https://github.com/DodoApps/dodopulse) - Monitorización del sistema
- [DodoTidy](https://github.com/DodoApps/dodotidy) - Limpiador del sistema
- [DodoCount](https://github.com/DodoApps/dodocount) - Analytics en la barra de menús
- [DodoNest](https://github.com/DodoApps/dodonest) - Organizador de barra de menús
- [DodoPass](https://github.com/DodoApps/dodopass) - Gestor de contraseñas
