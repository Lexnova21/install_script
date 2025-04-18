install_gpu_drivers() {
  case "$GPU_CHOICE" in
    1) packages="mesa vulkan-radeon libva-mesa-driver libva-utils" ;;
    2) packages="nvidia-open nvidia-utils nvidia-settings" ;;
    3) packages="mesa vulkan-radeon libva-mesa-driver libva-utils nvidia-open nvidia-utils nvidia-settings" ;;
    *) return ;;
  esac

  log "INFO" "Installiere Grafiktreiber: $packages"
  pacman -S --noconfirm $packages || log_error "Fehler bei Treiberinstallation"
}
