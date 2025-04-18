copy_configs() {
  # Hyprland
  if [ -d "$SCRIPT_DIR/configs/hypr" ]; then
    mkdir -p "$home_dir/.config/hypr"
    cp -r "$SCRIPT_DIR/configs/hypr" "$home_dir/.config/"
    chown -R "$username":"$username" "$home_dir/.config/hypr"
    log OK "Hyprland-Konfiguration kopiert"
  fi

  # Sunshine
  if command -v sunshine &> /dev/null && [ -d "$SCRIPT_DIR/configs/sunshine" ]; then
    mkdir -p "$home_dir/.config/sunshine"
    cp -r "$SCRIPT_DIR/configs/sunshine/"* "$home_dir/.config/sunshine/"
    chown -R "$username":"$username" "$home_dir/.config/sunshine"
    log OK "Sunshine-Konfiguration kopiert"
  fi

  # CachyOS-Fish
  if [[ "$os" == "cachyos" ]] && [ -d "$SCRIPT_DIR/configs/fish" ]; then
    mkdir -p "$home_dir/.config/fish"
    cp -r "$SCRIPT_DIR/configs/fish" "$home_dir/.config/"
    chown -R "$username":"$username" "$home_dir/.config/fish"
    log OK "Fish-Konfiguration kopiert"
  fi
}
