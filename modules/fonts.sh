install_nerd_fonts() {
    log "INFO" "Installiere Nerd Fonts..."

    local font_dir="$home_dir/.local/share/fonts"
    local zip_file="JetBrainsMono.zip"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$zip_file"

    # Erstelle Font-Verzeichnis
    if ! mkdir -p "$font_dir"; then
        log_error "Fehler beim Erstellen des Font-Verzeichnisses: $font_dir"
        return 1
    fi

    # Wechsel ins Font-Verzeichnis
    cd "$font_dir" || {
        log_error "Fehler beim Wechseln in das Font-Verzeichnis: $font_dir"
        return 1
    }

    # Download der Nerd Font ZIP-Datei
    if ! curl -fLO "$download_url"; then
        log_error "Fehler beim Herunterladen der Nerd Fonts von: $download_url"
        return 1
    fi

    # Entpacken der ZIP-Datei
    if ! unzip "$zip_file"; then
        log_error "Fehler beim Entpacken der ZIP-Datei: $zip_file"
        return 1
    fi

    # Aktualisiere Font-Cache
    if ! fc-cache -fv; then
        log_error "Fehler beim Aktualisieren des Font-Caches"
        return 1
    fi

    log "OK" "Nerd Fonts erfolgreich installiert!"
    return 0
}
