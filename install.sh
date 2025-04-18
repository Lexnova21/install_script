#!/bin/bash

# ==============================================================================
# Hyprland Installationsskript für Arch Linux und CachyOS
# Installiert Hyprland, Abhängigkeiten, Grafiktreiber (AMD/NVIDIA)
# und kopiert Beispielkonfigurationen aus einem 'configs'-Unterordner.
# ==============================================================================

# --- Variablen & Pfade (Hier alle am Anfang) ---

# Pfad zum Skript-Verzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Name des Logfiles
LOGFILE_NAME="hyprland_install_$(date +%Y%m%d_%H%M%S).log"
LOGFILE="$SCRIPT_DIR/$LOGFILE_NAME"

# AUR Helper Informationen (falls yay nicht gefunden wird)
AUR_HELPER_NAME="yay"
AUR_HELPER_REPO_URL="https://aur.archlinux.org/$AUR_HELPER_NAME.git"
AUR_HELPER_BUILD_DIR_NAME="$AUR_HELPER_NAME_build" # Temporärer Build-Ordner

# --- Logging einrichten ---
# Erstelle das Logfile, falls es nicht existiert
touch "$LOGFILE" || { echo "FEHLER: Kann Logfile nicht erstellen: $LOGFILE"; exit 1; }

# Leite stdout und stderr ins Logfile und auf die Konsole
exec > >(tee -a "$LOGFILE") 2>&1

# --- Hilfsfunktion für Logging ---
log() {
    local status="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$status] $message"
}

# --- Hilfsfunktion für Fehlerausgabe und Exit ---
exit_failure() {
    log ERROR "$*"
    log INFO "Das Skript wird beendet."
    exit 1
}

# --- Root-Rechte prüfen ---
log INFO "Prüfe Root-Rechte..."
if [[ $EUID -ne 0 ]]; then
    exit_failure "Dieses Skript muss mit sudo-Rechten ausgeführt werden."
fi
log OK "Root-Rechte vorhanden."

# --- Benutzername korrekt ermitteln (auch bei sudo) ---
# ${SUDO_USER:-$(logname)} ist die sicherste Methode
username="${SUDO_USER:-$(logname)}"
if [ -z "$username" ]; then
    exit_failure "Benutzername konnte nicht ermittelt werden."
fi
log OK "Benutzername ermittelt: $username"

# --- Home-Verzeichnis des Benutzers ermitteln ---
# Muss nach der Ermittlung des Benutzernamens erfolgen
home_dir="/home/$username"
if [ ! -d "$home_dir" ]; then
    # Fallbeispiel: Home-Verzeichnis liegt woanders (selten, aber möglich)
    home_dir=$(eval echo "~$username")
    if [ ! -d "$home_dir" ]; then
         exit_failure "Home-Verzeichnis für Benutzer '$username' konnte nicht gefunden oder ermittelt werden."
    fi
fi
log OK "Home-Verzeichnis ermittelt: $home_dir"

# --- Paketlisten definieren ---
# Pakete, die üblicherweise in den offiziellen Repos sind
pacman_packages_common="hyprland udisks2 wlroots xdg-desktop-portal-hyprland thunar gvfs wofi vim kitty nwg-look gnome-themes-extra materia-gtk-theme power-profiles-daemon"

# Pakete, die nur für Arch spezifisch sind (oft in common, aber zur Sicherheit getrennt)
pacman_packages_arch="" # Beispiel: "wayland" ist oft schon in hyprland als Abhängigkeit

# Pakete, die üblicherweise im AUR sind
aur_packages="hyprland-qt-support hyprpolkitagent"

# --- Grafiktreiber-Auswahl ---
echo ""
echo "-------------------------------------------------"
echo "Grafiktreiber-Auswahl"
echo "-------------------------------------------------"

echo "Welche Grafiktreiber sollen installiert werden?"
echo "1) Nur AMD"
echo "2) Nur NVIDIA"
echo "3) AMD und NVIDIA"
echo "4) Keine"
read -p "Bitte Auswahl (1/2/3/4): " gpu_choice

# --- Grafikpakete dynamisch hinzufügen ---
case "$gpu_choice" in
    1)  # AMD
        log INFO "AMD-Grafiktreiber ausgewählt."
        pacman_packages_common+=" mesa vulkan-radeon libva-mesa-driver libva-utils"
        ;;
    2)  # NVIDIA
        log INFO "NVIDIA-Grafiktreiber ausgewählt."
        # nvidia-open ist der Open Source Treiber, nvidia der proprietäre.
        # Hier nehmen wir mal die verbreitetsten Namen. Prüfe ggf. auf cachyos/arch repos.
        pacman_packages_common+=" nvidia nvidia-utils nvidia-settings"
        ;;
    3)  # AMD + NVIDIA
        log INFO "AMD- und NVIDIA-Grafiktreiber ausgewählt."
        pacman_packages_common+=" mesa vulkan-radeon libva-mesa-driver libva-utils nvidia nvidia-utils nvidia-settings"
        ;;
    4)
        log INFO "Keine zusätzlichen Grafiktreiber werden installiert."
        ;;
    *)
        exit_failure "Ungültige Auswahl '$gpu_choice'. Skript wird beendet."
        ;;
esac

# --- Funktion: Pakete mit pacman installieren ---
install_pacman_packages() {
    local packages="$1"
    if [ -z "$packages" ]; then
        log INFO "Keine pacman-Pakete zu installieren."
        return 0
    fi
    log INFO "Installiere Pakete mit pacman: $packages"
    if pacman -S --needed --noconfirm $packages; then
        log OK "Pakete erfolgreich installiert: $packages"
        return 0
    else
        exit_failure "Fehler bei der Installation der Pakete: $packages"
    fi
}

# --- Funktion: Pakete mit AUR Helper installieren ---
install_aur_packages() {
    local packages="$1"
     if [ -z "$packages" ]; then
        log INFO "Keine AUR-Pakete zu installieren."
        return 0
    fi
    log INFO "Installiere Pakete mit $AUR_HELPER_NAME: $packages"
    # Führe den AUR-Befehl als der normale Benutzer aus!
    if sudo -u "$username" $AUR_HELPER_NAME -S --needed --noconfirm $packages; then
        log OK "AUR-Pakete erfolgreich installiert: $packages"
        return 0
    else
        exit_failure "Fehler bei der Installation der AUR-Pakete: $packages"
    fi
}


# --- Betriebssystem erkennen ---
log INFO "Erkenne Betriebssystem..."
os="unknown"
if grep -q "Arch Linux" /etc/os-release; then
    os="arch"
    log OK "Erkanntes Betriebssystem: Arch Linux"
elif grep -q "CachyOS" /etc/os-release; then
    os="cachyos"
    log OK "Erkanntes Betriebssystem: CachyOS"
else
    log WARN "Betriebssystem nicht erkannt. Einige Schritte könnten fehlschlagen oder unnötig sein."
fi

# --- Pakete aus offiziellen Repos installieren ---
log INFO "Beginne Installation der offiziellen Pakete..."
if [[ "$os" == "arch" ]]; then
    install_pacman_packages "$pacman_packages_common $pacman_packages_arch"
else
    install_pacman_packages "$pacman_packages_common" # CachyOS hat oft arch_only Pakete im Repo
fi
log OK "Offizielle Paketinstallation abgeschlossen."

# --- Installation von Yay (AUR Helper) ---
echo ""
echo "-------------------------------------------------"
echo "Installation von $AUR_HELPER_NAME"
echo "-------------------------------------------------"

log INFO "Prüfe, ob $AUR_HELPER_NAME bereits installiert ist..."
if ! command -v $AUR_HELPER_NAME &> /dev/null; then
    log INFO "$AUR_HELPER_NAME wird installiert..."
    # Benötigte Pakete für AUR-Builds
    install_pacman_packages "git base-devel"

    AUR_BUILD_DIR="$home_dir/$AUR_HELPER_BUILD_DIR_NAME"

    # Temporäres Build-Verzeichnis aufräumen (falls Reste vorhanden sind)
    log INFO "Räume temporäres AUR Build-Verzeichnis auf: $AUR_BUILD_DIR"
    sudo -u "$username" rm -rf "$AUR_BUILD_DIR"

    # Klonen des AUR Helper Repos als normaler Benutzer
    log INFO "Klone $AUR_HELPER_NAME Repository von $AUR_HELPER_REPO_URL nach $AUR_BUILD_DIR"
    if sudo -u "$username" git clone "$AUR_HELPER_REPO_URL" "$AUR_BUILD_DIR"; then
        log OK "$AUR_HELPER_NAME Repository geklont."
    else
        exit_failure "Fehler beim Klonen des $AUR_HELPER_NAME Repositorys."
    fi

    # Wechsel ins Build-Verzeichnis und Bauen/Installieren als normaler Benutzer
    log INFO "Wechsle ins Build-Verzeichnis und baue $AUR_HELPER_NAME..."
    cd "$AUR_BUILD_DIR" || exit_failure "Konnte nicht ins Verzeichnis '$AUR_BUILD_DIR' wechseln."

    if sudo -u "$username" makepkg -si --noconfirm; then
        log OK "$AUR_HELPER_NAME erfolgreich installiert."
    else
        cd "$SCRIPT_DIR" # Zurückwechseln, bevor wir abbrechen
        exit_failure "Fehler bei der $AUR_HELPER_NAME Installation mit makepkg."
    fi

    # Zurückwechseln ins Skript-Verzeichnis
    cd "$SCRIPT_DIR" || log WARN "Konnte nicht zurück ins Skript-Verzeichnis '$SCRIPT_DIR' wechseln."

    # Temporäres Build-Verzeichnis aufräumen
    log INFO "Entferne temporäres AUR Build-Verzeichnis: $AUR_BUILD_DIR"
    sudo -u "$username" rm -rf "$AUR_BUILD_DIR" || log WARN "Konnte temporäres Verzeichnis '$AUR_BUILD_DIR' nicht vollständig entfernen."

else
    log OK "$AUR_HELPER_NAME ist bereits installiert."
fi

# --- Installation von AUR Paketen ---
if [ -n "$aur_packages" ]; then
    echo ""
    echo "-------------------------------------------------"
    echo "Installation von AUR Paketen"
    echo "-------------------------------------------------"
    install_aur_packages "$aur_packages"
    log OK "AUR Paketinstallation abgeschlossen."
else
    log INFO "Keine AUR Pakete in der Liste zur Installation."
fi

# --- Kopieren von Konfigurationsdateien ---
echo ""
echo "-------------------------------------------------"
echo "Kopieren von Konfigurationsdateien"
echo "-------------------------------------------------"

# Hyprland Konfiguration kopieren
SOURCE_HYPR_CONFIG="$SCRIPT_DIR/configs/hypr"
DEST_HYPR_CONFIG="$home_dir/.config/hypr"
if [ -d "$SOURCE_HYPR_CONFIG" ]; then
    log INFO "Kopiere Konfiguration von '$SOURCE_HYPR_CONFIG' nach '$DEST_HYPR_CONFIG'"
    mkdir -p "$(dirname "$DEST_HYPR_CONFIG")" || exit_failure "Konnte Zielverzeichnis für Hyprland Konfig nicht erstellen."
    if cp -r "$SOURCE_HYPR_CONFIG" "$home_dir/.config/"; then
        log OK "Hyprland-Konfiguration kopiert."
        # Stelle sicher, dass der Benutzer der Besitzer der kopierten Dateien ist
        chown -R "$username":"$username" "$DEST_HYPR_CONFIG" || log WARN "Konnte Besitzrechte für '$DEST_HYPR_CONFIG' nicht ändern."
    else
        log WARN "Fehler beim Kopieren der Hyprland-Konfiguration."
    fi
else
    log WARN "Quellordner für Hyprland-Konfiguration nicht gefunden: '$SOURCE_HYPR_CONFIG'. Konfiguration wird nicht kopiert."
fi

# Fish Konfiguration kopieren (spezifisch für CachyOS, falls gewünscht)
if [[ "$os" == "cachyos" ]]; then
    SOURCE_FISH_CONFIG="$SCRIPT_DIR/configs/fish"
    DEST_FISH_CONFIG="$home_dir/.config/fish"
    if [ -d "$SOURCE_FISH_CONFIG" ]; then
        log INFO "Kopiere Konfiguration von '$SOURCE_FISH_CONFIG' nach '$DEST_FISH_CONFIG'"
        mkdir -p "$(dirname "$DEST_FISH_CONFIG")" || log WARN "Konnte Zielverzeichnis für Fish Konfig nicht erstellen."
        if cp -r "$SOURCE_FISH_CONFIG" "$home_dir/.config/"; then
             log OK "Fish-Konfiguration kopiert."
             # Stelle sicher, dass der Benutzer der Besitzer der kopierten Dateien ist
            chown -R "$username":"$username" "$DEST_FISH_CONFIG" || log WARN "Konnte Besitzrechte für '$DEST_FISH_CONFIG' nicht ändern."
        else
            log WARN "Fehler beim Kopieren der Fish-Konfiguration."
        fi
    else
        log WARN "Quellordner für Fish-Konfiguration nicht gefunden: '$SOURCE_FISH_CONFIG'. Konfiguration wird nicht kopiert."
    fi
fi


# --- Abschließende Hinweise ---
echo ""
echo "-------------------------------------------------"
echo "Installation abgeschlossen!"
echo "-------------------------------------------------"
echo "Einige Dienste (z.B. udisks2, power-profiles-daemon) müssen eventuell noch"
echo "manuell aktiviert werden (systemctl enable --now <dienst>)."
echo ""
echo "Um Hyprland zu starten, kannst du:"
echo "1. Einen Login Manager (wie SDDM) verwenden und Hyprland auswählen."
echo "2. In deiner Shell-Konfiguration (z.B. ~/.bash_profile, ~/.zprofile)"
echo "   nach dem Login prüfen, ob im TTY bist (tty -s), und dann 'exec Hyprland' aufrufen."
echo ""
echo "Bitte starte deinen Computer neu, um alle Änderungen und Kernelmodule zu übernehmen."
echo "Das Logfile dieser Installation findest du unter: $LOGFILE"
echo "-------------------------------------------------"

exit 0 # Skript erfolgreich beendet