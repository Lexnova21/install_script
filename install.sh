#!/bin/bash

username="${SUDO_USER:-$(logname)}"
home_dir="/home/$username"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/hyprland_install_$(date +%Y%m%d_%H%M%S).log"
YAY_BUILD_DIR="$home_dir/yay"
common_packages="hyprland udisks2 wlroots networkmanager xdg-desktop-portal-hyprland hyprland-qt-support hyprpolkitagent thunar gvfs wofi vim kitty nwg-look gnome-themes-extra materia-gtk-theme power-profiles-daemon"
arch_only_packages="wayland"

# Module laden
source "$SCRIPT_DIR/modules/logging.sh"
source "$SCRIPT_DIR/modules/system_check.sh"
source "$SCRIPT_DIR/modules/drivers.sh"
source "$SCRIPT_DIR/modules/network.sh"  # NEU
source "$SCRIPT_DIR/modules/packages.sh"
source "$SCRIPT_DIR/modules/aur.sh"
source "$SCRIPT_DIR/modules/configs.sh"
source "$SCRIPT_DIR/modules/autologin.sh"

setup_logging
check_root
detect_os

choose_gpu_driver
configure_network  # NEU

if [[ "$os" == "arch" ]]; then
  install_packages "$common_packages $arch_only_packages"
else
  install_packages "$common_packages"
fi

install_yay
install_aur_packages
copy_configs
setup_autologin

echo ""
echo "-------------------------------------------------"
echo "System wird jetzt neu gestartet, um Autologin zu aktivieren!"
echo "Das Logfile findest du unter: $LOGFILE"
echo "-------------------------------------------------"
sleep 5
reboot
