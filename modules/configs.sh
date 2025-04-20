copy_configs() {
    local configs_ok=0
    local configs_failed=0

    # Hyprland-Konfig mit Script-Berechtigungen
    if [ -d "$SCRIPT_DIR/configs/hypr" ]; then
        log "INFO" "Kopiere Hyprland-Konfiguration..."
        if mkdir -p "$home_dir/.config/hypr" && \
           cp -r "$SCRIPT_DIR/configs/hypr" "$home_dir/.config/" && \
           chown -R "$username":"$username" "$home_dir/.config/hypr"; then
            
            # Setze Berechtigungen für alle .sh-Dateien im Script-Ordner
            local script_dir="$home_dir/.config/hypr/scripts"
            if [ -d "$script_dir" ]; then
                find "$script_dir" -type f -name "*.sh" -exec chmod +x {} +
                log "DEBUG" "Ausführungsrechte für alle Scripts in $script_dir gesetzt"
            else
                log "WARN" "Script-Ordner nicht gefunden: $script_dir"
            fi
            
            log "OK" "Hyprland-Konfiguration erfolgreich kopiert"
            ((configs_ok++))
        else
            log_error "Fehler beim Kopieren der Hyprland-Konfiguration"
            ((configs_failed++))
        fi
    else
        log "WARN" "Hyprland-Konfigurationsordner nicht gefunden"
    fi

    # Sunshine-Konfig (unverändert)
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

    # Fish-Konfig (unverändert)
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

    # Waybar-Konfig (unverändert)
    if [ -d "$SCRIPT_DIR/configs/waybar" ]; then
        log "INFO" "Kopiere Waybar-Konfiguration..."
        if mkdir -p "$home_dir/.config/waybar" && \
           cp -r "$SCRIPT_DIR/configs/waybar" "$home_dir/.config/" && \
           chown -R "$username":"$username" "$home_dir/.config/waybar"; then
            log "OK" "Waybar-Konfiguration erfolgreich kopiert"
            ((configs_ok++))
        else
            log_error "Fehler beim Kopieren der Waybar-Konfiguration"
            ((configs_failed++))
        fi
    else
        log "WARN" "Waybar-Konfigurationsordner nicht gefunden"
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
