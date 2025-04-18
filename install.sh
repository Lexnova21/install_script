#!/bin/bash

# ==========================
# Hyprland Installationsskript für Arch Linux und CachyOS
# ==========================

# --- Logfile festlegen ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/hyprland_install_$(date +%Y%m%d_%H%M%S).log"
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
  log ERROR "Dieses Skript muss mit sudo-Rechten ausgeführt werden."
  exit 1
fi

# --- Benutzername korrekt ermitteln (auch bei sudo) ---
username="${SUDO_USER:-$(logname)}"

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

# --- Paketlisten definieren ---
common_packages="hyprland udisks2 wlroots xdg-desktop-portal-hyprland hyprland-qt-support hyprpolkitagent thunar gvfs wofi vim kitty nwg-look gnome-themes-extra materia-gtk-theme power-profiles-daemon"
arch_only_packages="wayland"

# --- Grafikpakete dynamisch hinzufügen ---
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
  YAY_BUILD_DIR="/home/$username/yay"
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

# echo ""
# echo "-------------------------------------------------"
# echo "Installation zusätzlicher Software via Yay"
# echo "-------------------------------------------------"

# if command -v yay &> /dev/null; then
#   if sudo -u "$username" yay -S --needed --noconfirm google-chrome visual-studio-code-bin sunshine; then
#     log OK "AUR-Programme erfolgreich installiert."
#   else
#     log ERROR "Fehler bei der Installation von AUR-Programmen."
#   fi
# else
#   log ERROR "Yay ist nicht installiert. Überspringe die Installation von Google Chrome, VS Code und Sunshine."
# fi

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


echo "-------------------------------------------------"
echo "Konfiguration des Autologins"
echo "-------------------------------------------------"

# --- Deaktiviere andere Getty-Instanzen ---
# systemctl disable getty@tty2.service 2>/dev/null
# systemctl disable getty@tty3.service 2>/dev/null
# systemctl disable getty@tty4.service 2>/dev/null
# systemctl disable getty@tty5.service 2>/dev/null
# systemctl disable getty@tty6.service 2>/dev/null

autologin_service_content="[Unit]
Description=Autologin für %I
After=systemd-user-sessions.service plymouth-quit-wait.service
Before=getty.target
ConditionPathExists=/dev/tty1

[Service]
ExecStart=-/sbin/agetty --autologin $username --noclear %I
Type=idle
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
"

autologin_service_path="/etc/systemd/system/autologin@tty1.service"

log INFO "Erstelle die Autologin Service Datei: $autologin_service_path"
echo "$autologin_service_content" > "$autologin_service_path"

# log INFO "Aktiviere und starte den Autologin Dienst..."
# systemctl daemon-reload
# systemctl enable autologin@tty1.service
# systemctl start autologin@tty1.service

echo ""
echo "-------------------------------------------------"
echo "Konfiguration des automatischen Hyprland Starts"
echo "-------------------------------------------------"

home_dir="/home/$username"
bash_profile_path="$home_dir/.bash_profile"
zprofile_path="$home_dir/.zprofile"
fish_config_path="$home_dir/.config/fish/config.fish"

# # --- Hyprland Autostart für Bash ---
# log INFO "Konfiguriere automatischen Hyprland Start in $bash_profile_path..."
# if ! grep -q "exec Hyprland" "$bash_profile_path" 2>/dev/null; then
#   {
#     echo ""
#     echo "# Auto-start Hyprland on TTY1"
#     echo 'if [[ -z $WAYLAND_DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then'
#     echo '  exec Hyprland'
#     echo 'fi'
#   } >> "$bash_profile_path"
#   log OK "Hyprland Autostart in .bash_profile konfiguriert."
# fi
# chown "$username":"$username" "$bash_profile_path"

# # --- Hyprland Autostart für Zsh ---
# log INFO "Konfiguriere automatischen Hyprland Start in $zprofile_path..."
# if ! grep -q "exec Hyprland" "$zprofile_path" 2>/dev/null; then
#   {
#     echo ""
#     echo "# Auto-start Hyprland on TTY1"
#     echo 'if [[ -z $WAYLAND_DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then'
#     echo '  exec Hyprland'
#     echo 'fi'
#   } >> "$zprofile_path"
#   log OK "Hyprland Autostart in .zprofile konfiguriert."
# fi
# chown "$username":"$username" "$zprofile_path"

# # --- Hyprland Autostart für Fish ---
# log INFO "Konfiguriere automatischen Hyprland Start in $fish_config_path..."
# mkdir -p "$(dirname "$fish_config_path")"
# if ! grep -q "exec Hyprland" "$fish_config_path" 2>/dev/null; then
#   {
#     echo ""
#     echo "# Auto-start Hyprland on TTY1"
#     echo 'if test -z "$WAYLAND_DISPLAY" -a (tty) = /dev/tty1'
#     echo '  exec Hyprland'
#     echo 'end'
#   } >> "$fish_config_path"
#   log OK "Hyprland Autostart in config.fish konfiguriert."
# fi
# chown -R "$username":"$username" "$(dirname "$fish_config_path")"



echo ""
echo "-------------------------------------------------"
echo "Fertig!"
echo "Bitte starte deinen Computer neu, um alle Änderungen zu übernehmen."
echo "Das Logfile findest du unter: $LOGFILE"
echo "-------------------------------------------------"
systemctl daemon-reload
systemctl enable autologin@tty1.service
systemctl start autologin@tty1.service