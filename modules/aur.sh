install_aur_packages() {
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
      sudo -u "$username" yay -S --noconfirm "$pkg" && \
        log OK "$pkg installiert" || \
        log ERROR "Fehler bei $pkg"
    fi
  done
}
