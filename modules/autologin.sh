setup_autologin() {
    local dropin_dir="/etc/systemd/system/getty@tty1.service.d"
    local config_file="$dropin_dir/autologin.conf"
    local backup_file="$dropin_dir/autologin.conf.bak"

    # Backup vorhandener Konfiguration
    if [ -f "$config_file" ]; then
        log "INFO" "Erstelle Backup der bestehenden Autologin-Konfiguration"
        cp "$config_file" "$backup_file" || {
            log_error "Backup der Autologin-Konfiguration fehlgeschlagen"
            return 1
        }
    fi

    # Verzeichnis erstellen
    log "INFO" "Erstelle Systemd-Drop-in-Verzeichnis"
    if ! mkdir -p "$dropin_dir"; then
        log_error "Verzeichnis $dropin_dir konnte nicht erstellt werden"
        return 1
    fi

    # Konfigurationsdatei erstellen
    log "INFO" "Erstelle Autologin-Konfiguration für $username"
    if ! cat > "$config_file" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $username --noclear %I \$TERM
EOF
    then
        log_error "Erstellung der Autologin-Konfiguration fehlgeschlagen"
        return 1
    fi

    # Systemd reload
    log "INFO" "Lade Systemd-Daemon neu"
    if ! systemctl daemon-reload; then
        log_error "Systemd-Daemon-Reload fehlgeschlagen"
        return 1
    fi

    # Service aktivieren
    log "INFO" "Aktiviere getty-Service"
    if ! systemctl enable getty@tty1.service; then
        log_error "Aktivierung des getty-Services fehlgeschlagen"
        return 1
    fi

    log "OK" "Autologin für $username erfolgreich eingerichtet"
    return 0
}
