<p align="center">
  <img src="icon.png" alt="DodoHub" width="128" height="128">
</p>

<h1 align="center">DodoHub</h1>

<p align="center">
  DodoApps uygulamalarını keşfetmek, indirmek ve yönetmek için yerel bir macOS uygulama mağazası.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Lisans-MIT-green" alt="Lisans">
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README.de.md">Deutsch</a> •
  <a href="README.fr.md">Français</a> •
  <a href="README.es.md">Español</a> •
  <b>Türkçe</b>
</p>

<p align="center">
  <img width="1315" alt="DodoHub Ekran Görüntüsü" src="https://github.com/user-attachments/assets/cbb71acc-b1e3-41f8-9fca-785c9ca60dfd" />
</p>

<p align="center">
  <img width="1314" alt="DodoHub Uygulama Detayı" src="https://github.com/user-attachments/assets/7f9bfa21-23cd-41ff-8900-c091ba48b716" />
</p>

## Özellikler

- **Uygulama kataloğu** - Tüm DodoApps uygulamalarını açıklamalar, ekran görüntüleri ve özelliklerle birlikte inceleyin
- **Tek tıkla kurulum** - Uygulamaları doğrudan katalogdan indirin ve kurun
- **Güncelleme algılama** - Hangi kurulu uygulamaların güncellemesi olduğunu görün
- **Akıllı filtreleme** - Kategori, yayıncı veya kurulum durumuna göre filtreleyin
- **Doğrulama rozetleri** - Hangi uygulamaların açık kaynak, noter onaylı ve gizlilik odaklı olduğunu görün
- **Bakım durumu** - Bir uygulamanın aktif olarak bakımının yapılıp yapılmadığını bilin

## Gereksinimler

- macOS 14.0 (Sonoma) veya üstü
- Apple Silicon veya Intel Mac

## Kurulum

### Homebrew (önerilen)

```bash
brew tap dodoapps/tap
brew install --cask dodohub
```

### DMG İndir

En son sürümü [Releases](https://github.com/DodoApps/dodohub/releases) sayfasından indirin.

### Kaynak koddan derleme

```bash
git clone https://github.com/DodoApps/dodohub.git
cd dodohub
open DodoHub.xcodeproj
```

Xcode'da derleyin ve çalıştırın (⌘R).

## Nasıl çalışır

DodoHub, tüm mevcut uygulamalar için meta verileri içeren [DodoApps/catalog](https://github.com/DodoApps/catalog) deposundan uygulama kataloğunu çeker. "Kur" düğmesine tıkladığınızda, DMG'yi doğrudan GitHub sürümlerinden indirir ve Uygulamalar klasörüne sürüklemeniz için açar.

## Yayıncılar için

Uygulamanızı DodoHub'da listelemek mi istiyorsunuz? Gönderim kuralları için [catalog deposuna](https://github.com/DodoApps/catalog) bakın.

Gereksinimler:
- Açık kaynak (herkese açık depo)
- En az 1 yıllık
- Kod incelemesi yapılmış
- Apple noter onaylı

## Mimari

```
DodoHub/
├── DodoHubApp.swift          # Uygulama giriş noktası
├── ContentView.swift         # Ana navigasyon
├── Models/
│   └── Models.swift          # Veri modelleri (Catalog, App, Publisher)
├── Services/
│   ├── CatalogService.swift  # Kataloğu çeker ve önbelleğe alır
│   ├── AppStateManager.swift # Kurulum durumunu takip eder
│   ├── DownloadManager.swift # İndirmeleri yönetir
│   └── Helpers.swift         # Yardımcı araçlar ve UI bileşenleri
└── Views/
    ├── SidebarView.swift     # Navigasyon kenar çubuğu
    ├── AppGridView.swift     # Uygulama ızgara düzeni
    ├── AppCardView.swift     # Bireysel uygulama kartları
    └── AppDetailView.swift   # Tam uygulama detayları
```

## Lisans

MIT Lisansı - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## İlgili Projeler

- [DodoApps Catalog](https://github.com/DodoApps/catalog) - Uygulama kataloğu
- [DodoShot](https://github.com/DodoApps/dodoshot) - Ekran görüntüsü aracı
- [DodoClip](https://github.com/DodoApps/dodoclip) - Pano yöneticisi
- [DodoPulse](https://github.com/DodoApps/dodopulse) - Sistem izleme
- [DodoTidy](https://github.com/DodoApps/dodotidy) - Sistem temizleyici
- [DodoCount](https://github.com/DodoApps/dodocount) - Analitik menü çubuğu
- [DodoNest](https://github.com/DodoApps/dodonest) - Menü çubuğu düzenleyici
- [DodoPass](https://github.com/DodoApps/dodopass) - Şifre yöneticisi
