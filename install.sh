#!/bin/bash

username="${SUDO_USER:-$(logname)}"
home_dir="/home/$username"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/hyprland_install_$(date +%Y%m%d_%H%M%S).log"
YAY_BUILD_DIR="$home_dir/yay"

# --- Logging Funktion ---
log() {
  local status="$1"
  shift
  local message="$*"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$status] $message"
}

# --- Logfile festlegen ---
touch "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

# --- Root-Rechte prüfen ---
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Dieses Skript muss mit sudo-Rechten ausgeführt werden."
    exit 1
  fi
}

# --- Betriebssystem erkennen ---
detect_os() {
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
}

# --- Grafiktreiber-Auswahl ---
choose_gpu_driver() {
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
}

# --- Pakete installieren ---
install_packages() {
  local packages="$1"
  log INFO "Installiere Pakete: $packages"
  if pacman -S --needed --noconfirm $packages; then
    log OK "Pakete erfolgreich installiert: $packages"
  else
    log ERROR "Fehler bei der Installation: $packages"
  fi
}

# --- Yay installieren ---
install_yay() {
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
}

# --- AUR-Pakete installieren ---
install_aur_packages() {
  echo ""
  echo "-------------------------------------------------"
  echo "Optional: AUR-Paketinstallation"
  echo "-------------------------------------------------"
  
  declare -a packages=(
    "visual-studio-code-bin"
    "google-chrome"
    "sunshine"
    "tradingview"
  )
  
  for pkg in "${packages[@]}"; do
    read -p "$pkg installieren? (j/n): " choice
    if [[ "$choice" =~ ^[jJ] ]]; then
      log INFO "Installiere $pkg..."
      sudo -u "$username" yay -S --noconfirm "$pkg" && log OK "$pkg installiert" || log ERROR "Fehler bei $pkg"
    fi
  done
}

# --- Konfigurationsdateien kopieren ---
copy_configs() {
  echo ""
  echo "-------------------------------------------------"
  echo "Kopieren von Konfigurationsdateien"
  echo "-------------------------------------------------"

  # Hyprland-Konfiguration
  if [ -d "$SCRIPT_DIR/configs/hypr" ]; then
    log INFO "Kopiere configs/hypr nach $home_dir/.config/hypr"
    mkdir -p "$home_dir/.config"
    cp -r "$SCRIPT_DIR/configs/hypr" "$home_dir/.config/"
    chown -R "$username":"$username" "$home_dir/.config/hypr"
    log OK "Hyprland-Konfiguration kopiert."
  else
    log WARN "Ordner 'configs/hypr' nicht gefunden."
  fi

  # Sunshine-Konfiguration
  if [ -d "$SCRIPT_DIR/configs/sunshine" ]; then
    log INFO "Kopiere configs/sunshine nach $home_dir/.config/sunshine"
    mkdir -p "$home_dir/.config/sunshine"
    cp -r "$SCRIPT_DIR/configs/sunshine/"* "$home_dir/.config/sunshine/"
    chown -R "$username":"$username" "$home_dir/.config/sunshine"
    log OK "Sunshine-Konfiguration kopiert."
    
    # Sunshine-Dienst neustarten falls installiert
    if command -v sunshine &> /dev/null; then
      if systemctl is-active --quiet sunshine; then
        systemctl restart sunshine && log OK "Sunshine-Dienst neu gestartet" || log WARN "Konnte Sunshine-Dienst nicht neustarten"
      else
        systemctl enable --now sunshine && log OK "Sunshine-Dienst aktiviert" || log WARN "Konnte Sunshine-Dienst nicht aktivieren"
      fi
    fi
  else
    log WARN "Ordner 'configs/sunshine' nicht gefunden."
  fi

  # CachyOS-spezifische Konfiguration
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
}

# --- Autologin per systemd Drop-In einrichten ---
setup_autologin() {
  local dropin_dir="/etc/systemd/system/getty@tty1.service.d"
  local dropin_file="$dropin_dir/autologin.conf"
  local autologin_user="$username"

  log INFO "Richte Autologin für Benutzer '$autologin_user' auf tty1 per systemd-Drop-In ein..."

  mkdir -p "$dropin_dir"
  cat > "$dropin_file" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $autologin_user --noclear %I \$TERM
EOF

  chmod 644 "$dropin_file"
  log OK "Autologin-Drop-In erstellt: $dropin_file"

  systemctl daemon-reload
  systemctl enable getty@tty1.service

  log OK "Autologin für tty1 aktiviert."
}

# --- Hauptprogramm ---

check_root
detect_os

common_packages="hyprland udisks2 wlroots xdg-desktop-portal-hyprland hyprland-qt-support hyprpolkitagent thunar gvfs wofi vim kitty nwg-look gnome-themes-extra materia-gtk-theme power-profiles-daemon"
arch_only_packages="wayland"

choose_gpu_driver

if [[ "$os" == "arch" ]]; then
  install_packages "$common_packages $arch_only_packages"
else
  install_packages "$common_packages"
fi

install_yay
install_aur_packages
copy_configs
setup_autologin

# --- Abschluss & Neustart ---
echo ""
echo "-------------------------------------------------"
echo "System wird jetzt neu gestartet, um Autologin zu aktivieren!"
echo "Das Logfile findest du unter: $LOGFILE"
echo "-------------------------------------------------"
sleep 5
reboot
