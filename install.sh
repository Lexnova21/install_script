#!/bin/bash

# --- Konfiguration ---
username="${SUDO_USER:-$(logname)}"
home_dir="/home/$username"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/hyprland_install_$(date +%Y%m%d_%H%M%S).log"
YAY_BUILD_DIR="$home_dir/yay"
declare -a ERROR_LOG

# --- Module laden ---
source "$SCRIPT_DIR/modules/logging.sh"
source "$SCRIPT_DIR/modules/system_check.sh"
source "$SCRIPT_DIR/modules/questions.sh"
source "$SCRIPT_DIR/modules/drivers.sh"
source "$SCRIPT_DIR/modules/network.sh"
source "$SCRIPT_DIR/modules/packages.sh"
source "$SCRIPT_DIR/modules/fonts.sh"
source "$SCRIPT_DIR/modules/configs.sh"
source "$SCRIPT_DIR/modules/autologin.sh"
# source "$SCRIPT_DIR/modules/themes.sh"

# --- Initialisierung ---
setup_logging
check_root
detect_os

# --- Alle Fragen am Anfang ---
ask_questions

# --- Installation durchführen ---
set +e # Fehler nicht abbrechen
install_base_packages
install_gpu_drivers
install_yay
install_aur_packages
configure_network
install_nerd_fonts
copy_configs
# copy_themes
setup_autologin

# --- Abschlussbericht ---
echo ""
echo "-------------------------------------------------"
echo " Installationszusammenfassung"
echo "-------------------------------------------------"

if [ ${#ERROR_LOG[@]} -eq 0 ]; then
  echo "✅ Alle Komponenten erfolgreich installiert!"
  echo ""
  read -p "Neustart jetzt durchführen? (y/n): " reboot_choice
  if [[ "$reboot_choice" =~ ^[yY] ]]; then
    reboot
  fi
else
  echo "❌ Folgende Fehler traten auf:"
  printf " - %s\n" "${ERROR_LOG[@]}"
  echo ""
  echo "Logfile: $LOGFILE"
fi
