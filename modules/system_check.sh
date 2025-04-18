check_root() {
  if [[ $EUID -ne 0 ]]; then
    log ERROR "Dieses Skript muss mit sudo-Rechten ausgeführt werden."
    exit 1
  fi
  log OK "Root-Rechte bestätigt"
}

detect_os() {
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
}
