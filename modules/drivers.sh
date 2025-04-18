choose_gpu_driver() {
  echo ""
  echo "-------------------------------------------------"
  echo "Grafiktreiber-Auswahl"
  echo "-------------------------------------------------"
  echo "1) Nur AMD"
  echo "2) Nur NVIDIA"
  echo "3) AMD und NVIDIA"
  echo "4) Keine"
  read -p "Bitte Auswahl (1/2/3/4): " gpu_choice

  case "$gpu_choice" in
    1)  common_packages+=" mesa vulkan-radeon libva-mesa-driver libva-utils"
        log OK "AMD-Treiber ausgewählt" ;;
    2)  common_packages+=" nvidia-open nvidia-utils nvidia-settings"
        log OK "NVIDIA-Treiber ausgewählt" ;;
    3)  common_packages+=" mesa vulkan-radeon libva-mesa-driver libva-utils nvidia-open nvidia-utils nvidia-settings"
        log OK "AMD + NVIDIA ausgewählt" ;;
    4)  log INFO "Keine Grafiktreiber werden installiert" ;;
    *)  log ERROR "Ungültige Auswahl"; exit 1 ;;
  esac
}
