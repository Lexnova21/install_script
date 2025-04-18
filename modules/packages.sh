install_packages() {
  local packages="$1"
  log INFO "Installiere Pakete: $packages"
  if pacman -S --needed --noconfirm $packages; then
    log OK "Pakete erfolgreich installiert: $packages"
  else
    log ERROR "Fehler bei der Installation: $packages"
    exit 1
  fi
}

install_yay() {
  if ! command -v yay &> /dev/null; then
    log INFO "Yay wird installiert..."
    install_packages "git base-devel"
    sudo -u "$username" rm -rf "$YAY_BUILD_DIR"
    sudo -u "$username" git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR"
    cd "$YAY_BUILD_DIR"
    sudo -u "$username" makepkg -si --noconfirm
    cd /
    sudo -u "$username" rm -rf "$YAY_BUILD_DIR"
    log OK "Yay erfolgreich installiert"
  else
    log OK "Yay ist bereits installiert"
  fi
}
