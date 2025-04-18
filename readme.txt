# Hyprland-Installationsskript für Arch Linux und CachyOS

Dieses Skript automatisiert die Installation und Grundkonfiguration einer modernen Hyprland-Desktopumgebung auf Arch Linux und CachyOS. Es richtet alle wichtigen Pakete, Treiber, Autologin sowie den automatischen Start von Hyprland ein und kopiert auf Wunsch deine Konfigurationsdateien.

---

## Inhalt

- [Funktionen](#funktionen)
- [Voraussetzungen](#voraussetzungen)
- [Vorbereitung](#vorbereitung)
- [Nutzung](#nutzung)
- [Was wird installiert?](#was-wird-installiert)
- [Was wird konfiguriert?](#was-wird-konfiguriert)
- [Eigene Konfigurationen](#eigene-konfigurationen)
- [Nach der Installation](#nach-der-installation)
- [Troubleshooting](#troubleshooting)

---

## Funktionen

- Erkennung von Arch Linux und CachyOS
- Installation aller notwendigen Pakete für Hyprland und Wayland
- Automatische Installation von AMD- und NVIDIA-Grafiktreibern (Open Source)
- Automatische Installation von Yay (AUR-Helfer)
- Installation empfohlener Software (Google Chrome, Visual Studio Code, Sunshine)
- Einrichtung von Autologin auf TTY1
- Automatischer Start von Hyprland auf TTY1 (Bash, Zsh, Fish)
- Kopieren eigener Hyprland- und Fish-Konfigurationen

---

## Voraussetzungen

- Frische Installation von Arch Linux **oder** CachyOS
- Internetverbindung
- Root-Zugriff (über `sudo`)
- Optional: Eigene Konfigurationen im Ordner `configs/` (siehe unten)

---

## Vorbereitung

1. **Repository klonen oder Skript herunterladen**
2. **(Optional) Eigene Konfigurationen bereitstellen**
   - `configs/hypr/` → Hyprland-Konfiguration
   - `configs/fish/` → Fish-Konfiguration (nur für CachyOS empfohlen)

---

## Nutzung

chmod +x install_hyprland.sh
sudo ./install_hyprland.sh

text

**Hinweis:** Das Skript muss mit Root-Rechten ausgeführt werden!

---

## Was wird installiert?

- **Hyprland & Wayland-Basispakete:**  
  `hyprland`, `wlroots`, `xdg-desktop-portal-hyprland`, `hyprland-qt-support`, `hyprpolkitagent`
- **Dateimanager & Tools:**  
  `thunar`, `gvfs`, `wofi`, `vim`, `kitty`, `nwg-look`
- **Themes:**  
  `gnome-themes-extra`, `materia-gtk-theme`
- **Leistungsoptimierung:**  
  `power-profiles-daemon`
- **Grafiktreiber:**  
  - AMD: `mesa`, `vulkan-radeon`, `libva-mesa-driver`, `libva-utils`
  - NVIDIA (Open Source): `nvidia-open`, `nvidia-utils`, `nvidia-settings`
- **AUR-Software (via Yay):**  
  `google-chrome`, `visual-studio-code-bin`, `sunshine`

---

## Was wird konfiguriert?

- **Autologin auf TTY1:**  
  Erstellt und aktiviert einen systemd-Service, der automatisch den Benutzer auf TTY1 einloggt.
- **Automatischer Start von Hyprland:**  
  Fügt in `.bash_profile`, `.zprofile` und (bei Bedarf) `config.fish` einen Autostart für Hyprland ein, sofern auf TTY1 eingeloggt.
- **Kopieren von Konfigurationsdateien:**  
  Kopiert deine eigenen Hyprland- und Fish-Konfigurationen (sofern im `configs/`-Ordner vorhanden) ins Home-Verzeichnis.

---

## Eigene Konfigurationen

Lege im selben Verzeichnis wie das Skript folgende Ordner an, um deine eigenen Einstellungen zu übernehmen:

- `configs/hypr/` – für Hyprland (wird immer kopiert)
- `configs/fish/` – für Fish (wird nur bei CachyOS kopiert)

Beispielstruktur:
.
├── install_hyprland.sh
└── configs
├── hypr
│ └── hyprland.conf
└── fish
└── config.fish

text

---

## Nach der Installation

1. **Neustart durchführen:**  
   Damit alle Dienste und Einstellungen greifen.
2. **Theme anpassen (optional):**  
   Mit `nwg-look` kannst du das GTK-Theme setzen.
3. **Leistungsprofil einstellen (optional):**  
powerprofilesctl set balanced

text

---

## Troubleshooting

- **Yay funktioniert nicht:**  
Stelle sicher, dass der Benutzer im System existiert und Zugriff auf `/tmp` hat.
- **Hyprland startet nicht automatisch:**  
Prüfe, ob die Zeilen in `.bash_profile`, `.zprofile` oder `config.fish` korrekt eingefügt wurden.
- **NVIDIA-Probleme:**  
Füge ggf. `nvidia-drm.modeset=1` zu deiner Kernel-Commandline hinzu.
- **Wayland/Xorg-Konflikte:**  
Deinstalliere ggf. den Xorg-Server, falls du nur Wayland nutzen möchtest.
- **Konfigurationsdateien fehlen:**  
Lege die entsprechenden Ordner und Dateien unter `configs/` an.

---

## Lizenz

Dieses Skript steht unter der MIT-Lizenz. Nutzung auf eigene Gefahr.

---

**Viel Erfolg mit deinem neuen Hyprland-Setup!**