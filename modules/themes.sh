copy_themes() {
    local source_dir="$SCRIPT_DIR/configs/themes"
    local target_dir="$home_dir/.themes"

    if [ ! -d "$source_dir" ]; then
        log_error "Quellverzeichnis für Themes nicht gefunden: $source_dir"
        return 1
    fi

    # Zielverzeichnis anlegen, falls nicht vorhanden
    if mkdir -p "$target_dir"; then
        # Inhalte rekursiv kopieren (inklusive versteckter Dateien und Rechte)
        cp -a "$source_dir/." "$target_dir/"
        chown -R "$username":"$username" "$target_dir"
        log "OK" "Themes erfolgreich nach $target_dir kopiert."
        return 0
    else
        log_error "Konnte Zielverzeichnis $target_dir nicht erstellen."
        return 1
    fi
}
