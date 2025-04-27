#!/bin/bash

install_base_packages() {
  local common_packages="hyprland udisks2 sudo thunderbird python-pip swaync waybar hypridle wlroots networkmanager xdg-desktop-portal-hyprland hyprland-qt-support hyprpolkitagent thunar gvfs wofi vim kitty nwg-look gnome-themes-extra materia-gtk-theme power-profiles-daemon "
  local arch_only_packages="wayland"

  if [[ "$os" == "arch" ]]; then
    install_packages "$common_packages $arch_only_packages"
  else
    install_packages "$common_packages"
  fi
}

install_packages() {
  local packages="$1"
  log "INFO" "Installiere Pakete: $packages"
  
  if ! pacman -S --needed --noconfirm $packages; then
    log_error "Fehler bei der Installation von $packages"
    return 1
  fi
  
  log "OK" "Pakete erfolgreich installiert: $packages"
}

install_aur_packages() {
  # Waybar IMMER installieren (Hardcoded)
  local required_aur_packages=("")
  local combined_packages=("${required_aur_packages[@]}" "${SELECTED_AUR[@]}")

  [[ ${#combined_packages[@]} -eq 0 ]] && return
  
  log "INFO" "Installiere AUR-Pakete: ${combined_packages[*]}"
  
  for pkg in "${combined_packages[@]}"; do
    # Doppelte entfernen (falls Waybar manuell ausgewählt wurde)
    [[ " ${installed_pkgs[*]} " == *" $pkg "* ]] && continue
    installed_pkgs+=("$pkg")

    if ! sudo -u "$username" yay -S --needed --noconfirm "$pkg"; then
      log_error "Fehler bei der Installation von $pkg"
      continue
    fi
    log "OK" "$pkg erfolgreich installiert"
  done
}


install_yay() {
  if command -v yay &> /dev/null; then
    log "OK" "Yay ist bereits installiert"
    return 0
  fi

  log "INFO" "Installiere Yay..."
  
  if ! install_packages "git base-devel"; then
    log_error "Abhängigkeiten für Yay fehlgeschlagen"
    return 1
  fi

  sudo -u "$username" mkdir -p "$YAY_BUILD_DIR"
  if ! sudo -u "$username" git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR"; then
    log_error "Yay-Repository konnte nicht geklont werden"
    return 1
  fi

  cd "$YAY_BUILD_DIR" || {
    log_error "Verzeichniswechsel fehlgeschlagen"
    return 1
  }

  if ! sudo -u "$username" makepkg -si --noconfirm; then
    log_error "Yay-Kompilierung fehlgeschlagen"
    return 1
  fi

  cd - >/dev/null || return
  log "OK" "Yay erfolgreich installiert"
}
