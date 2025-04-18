install_aur_packages() {
  [[ ${#SELECTED_AUR[@]} -eq 0 ]] && return
  
  log "INFO" "Installiere AUR-Pakete: ${SELECTED_AUR[*]}"
  
  for pkg in "${SELECTED_AUR[@]}"; do
    if ! sudo -u "$username" yay -S --needed --noconfirm "$pkg"; then
      log_error "Fehler bei der Installation von $pkg"
      continue
    fi
    log "OK" "$pkg erfolgreich installiert"
  done
}