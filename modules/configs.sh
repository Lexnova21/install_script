copy_configs() {
    local configs_ok=0
    local configs_failed=0

    # Hyprland-Konfig (unverändert)
    if [ -d "$SCRIPT_DIR/configs/hypr" ]; then
        log "INFO" "Kopiere Hyprland-Konfiguration..."
        if mkdir -p "$home_dir/.config/hypr" && \
           cp -r "$SCRIPT_DIR/configs/hypr" "$home_dir/.config/" && \
           chown -R "$username":"$username" "$home_dir/.config/hypr"; then
            log "OK" "Hyprland-Konfiguration erfolgreich kopiert"
            ((configs_ok++))
        else
            log_error "Fehler beim Kopieren der Hyprland-Konfiguration"
            ((configs_failed++))
        fi
    else
        log "WARN" "Hyprland-Konfigurationsordner nicht gefunden"
    fi

    # Sunshine-Konfig (ALWAYS kopieren)
    if [ -d "$SCRIPT_DIR/configs/sunshine" ]; then
        log "INFO" "Kopiere Sunshine-Konfiguration..."
        if mkdir -p "$home_dir/.config/sunshine" && \
           cp -r "$SCRIPT_DIR/configs/sunshine/"* "$home_dir/.config/sunshine/" && \
           chown -R "$username":"$username" "$home_dir/.config/sunshine"; then
            log "OK" "Sunshine-Konfiguration erfolgreich kopiert"
            ((configs_ok++))
        else
            log_error "Fehler beim Kopieren der Sunshine-Konfiguration"
            ((configs_failed++))
        fi
    else
        log "WARN" "Sunshine-Konfigurationsordner nicht gefunden"
    fi

    # Fish-Konfig (ALWAYS kopieren)
    if [ -d "$SCRIPT_DIR/configs/fish" ]; then
        log "INFO" "Kopiere Fish-Konfiguration..."
        if mkdir -p "$home_dir/.config/fish" && \
           cp -r "$SCRIPT_DIR/configs/fish" "$home_dir/.config/" && \
           chown -R "$username":"$username" "$home_dir/.config/fish"; then
            log "OK" "Fish-Konfiguration erfolgreich kopiert"
            ((configs_ok++))
        else
            log_error "Fehler beim Kopieren der Fish-Konfiguration"
            ((configs_failed++))
        fi
    else
        log "WARN" "Fish-Konfigurationsordner nicht gefunden"
    fi

    # Zusammenfassung
    echo ""
    log "INFO" "Konfigurations-Zusammenfassung:"
    log "OK" "Erfolgreich kopiert: $configs_ok Konfigurationen"
    if [ $configs_failed -gt 0 ]; then
        log_error "Fehlgeschlagen: $configs_failed Konfigurationen"
        return 1
    fi
    return 0
}
