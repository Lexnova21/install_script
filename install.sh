#!/bin/bash

# ==========================
# Hyprland Installationsskript für Arch Linux und CachyOS
# ==========================

# --- Variablen am Anfang setzen ---
username="${SUDO_USER:-$(logname)}"
home_dir="/home/$username"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/hyprland_install_$(date +%Y%m%d_%H%M%S).log"
YAY_BUILD_DIR="$home_dir/yay"

# --- Logfile festlegen ---
touch "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

log() {
  local status="$1"
  shift
  local message="$*"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$status] $message"
}

# --- Root-Rechte prüfen ---
if [[ $EUID -ne 0 ]]; then
  echo "Dieses Skript muss mit sudo-Rechten ausgeführt werden."
  exit 1
fi

# --- Betriebssystem erkennen ---
if grep -q "Arch Linux" /etc/os-release; then
  os="arch"
  log OK "Erkanntes Betriebssystem: Arch Linux"
elif grep -q "CachyOS" /etc/os-release; then
  os="cachyos"
  log OK "Erkanntes Betriebssystem: CachyOS"
else
  log WARN "Betriebssystem nicht erkannt. Einige Schritte könnten fehlschlagen."
  os="unknown"
fi

# --- Paketlisten definieren ---
common_packages="hyprland udisks2 wlroots xdg-desktop-portal-hyprland hyprland-qt-support hyprpolkitagent thunar gvfs wofi vim kitty nwg-look gnome-themes-extra materia-gtk-theme power-profiles-daemon"
arch_only_packages="wayland"

# --- Grafiktreiber-Auswahl ---
echo ""
echo "-------------------------------------------------"
echo "Grafiktreiber-Auswahl"
echo "-------------------------------------------------"
echo "Welche Grafiktreiber sollen installiert werden?"
echo "1) Nur AMD"
echo "2) Nur NVIDIA"
echo "3) AMD und NVIDIA"
echo "4) Keine"
read -p "Bitte Auswahl (1/2/3/4): " gpu_choice

case "$gpu_choice" in
  1)  # AMD
    common_packages+=" mesa vulkan-radeon libva-mesa-driver libva-utils"
    ;;
  2)  # NVIDIA
    common_packages+=" nvidia-open nvidia-utils nvidia-settings"
    ;;
  3)  # AMD + NVIDIA
    common_packages+=" mesa vulkan-radeon libva-mesa-driver libva-utils nvidia-open nvidia-utils nvidia-settings"
    ;;
  4)
    log INFO "Keine Grafiktreiber werden installiert."
    ;;
  *)
    log ERROR "Ungültige Auswahl. Skript wird beendet."
    exit 1
    ;;
esac

# --- Funktion: Pakete installieren ---
install_packages() {
  local packages="$1"
  log INFO "Installiere Pakete: $packages"
  if pacman -S --needed --noconfirm $packages; then
    log OK "Pakete erfolgreich installiert: $packages"
  else
    log ERROR "Fehler bei der Installation: $packages"
  fi
}

# --- Pakete installieren ---
if [[ "$os" == "arch" ]]; then
  install_packages "$common_packages $arch_only_packages"
else
  install_packages "$common_packages"
fi

echo ""
echo "-------------------------------------------------"
echo "Installation von Yay"
echo "-------------------------------------------------"

if ! command -v yay &> /dev/null; then
  log INFO "Yay wird installiert..."
  install_packages "git base-devel"
  sudo -u "$username" rm -rf "$YAY_BUILD_DIR"
  sudo -u "$username" git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR" && log OK "yay-Repository geklont." || log ERROR "Fehler beim Klonen von yay."
  cd "$YAY_BUILD_DIR"
  if sudo -u "$username" makepkg -si --noconfirm; then
    log OK "Yay erfolgreich installiert."
  else
    log ERROR "Fehler bei der Yay-Installation."
  fi
  cd /
  sudo -u "$username" rm -rf "$YAY_BUILD_DIR"
else
  log OK "Yay ist bereits installiert."
fi

echo ""
echo "-------------------------------------------------"
echo "Kopieren von Konfigurationsdateien"
echo "-------------------------------------------------"

if [ -d "$SCRIPT_DIR/configs/hypr" ]; then
  log INFO "Kopiere configs/hypr nach $home_dir/.config/hypr"
  mkdir -p "$home_dir/.config"
  cp -r "$SCRIPT_DIR/configs/hypr" "$home_dir/.config/"
  chown -R "$username":"$username" "$home_dir/.config/hypr"
  log OK "Hyprland-Konfiguration kopiert."
else
  log WARN "Ordner 'configs/hypr' nicht gefunden."
fi

if [[ "$os" == "cachyos" ]]; then
  if [ -d "$SCRIPT_DIR/configs/fish" ]; then
    log INFO "Kopiere configs/fish nach $home_dir/.config/fish"
    mkdir -p "$home_dir/.config"
    cp -r "$SCRIPT_DIR/configs/fish" "$home_dir/.config/"
    chown -R "$username":"$username" "$home_dir/.config/fish"
    log OK "Fish-Konfiguration kopiert."
  else
    log WARN "Ordner 'configs/fish' nicht gefunden."
  fi
fi

echo ""
echo "-------------------------------------------------"
echo "Fertig!"
echo "Bitte starte deinen Computer neu, um alle Änderungen zu übernehmen."
echo "Das Logfile findest du unter: $LOGFILE"
echo "-------------------------------------------------"
