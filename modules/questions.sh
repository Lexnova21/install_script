ask_questions() {
    echo ""
    echo "-------------------------------------------------"
    echo " Installationsassistent für Hyprland"
    echo "-------------------------------------------------"
    
    # Grafiktreiber
    while true; do
        echo "1) Grafiktreiber:"
        echo "   (1) AMD (mesa, vulkan)"
        echo "   (2) NVIDIA (open-source)"
        echo "   (3) AMD + NVIDIA"
        echo "   (4) Keine"
        read -p "   Auswahl (1-4): " GPU_CHOICE
        
        [[ "$GPU_CHOICE" =~ ^[1-4]$ ]] && break
        echo "Ungültige Eingabe!"
    done

    # Netzwerk
    read -p "2) Soll eine statische IP konfiguriert werden? (j/n): " NETWORK_CHOICE
    if [[ "$NETWORK_CHOICE" =~ ^[jJ] ]]; then
        read -p "   IP-Adresse/CIDR (z.B. 192.168.1.10/24): " IP_ADDRESS
        read -p "   Gateway (z.B. 192.168.1.1): " GATEWAY
        read -p "   DNS-Server (z.B. 8.8.8.8): " DNS_SERVER
    fi

    # AUR-Pakete
    echo "3) AUR-Pakete:"
    declare -a AUR_PACKAGES=(
        "visual-studio-code-bin"
        "google-chrome"
        "sunshine"
        "tradingview"
    )
    SELECTED_AUR=()
    for pkg in "${AUR_PACKAGES[@]}"; do
        read -p "   $pkg installieren? (j/n): " choice
        [[ "$choice" =~ ^[jJ] ]] && SELECTED_AUR+=("$pkg")
    done

    # Autologin
    read -p "4) Autologin für aktuellen Benutzer aktivieren? (j/n): " AUTOLOGIN_CHOICE

    # Bestätigung
    echo ""
    echo "Zusammenfassung der Konfiguration:"
    echo "Grafiktreiber: Option $GPU_CHOICE"
    [[ "$NETWORK_CHOICE" == "j" ]] && echo "Netzwerk: $IP_ADDRESS | $GATEWAY | $DNS_SERVER"
    echo "AUR-Pakete: ${SELECTED_AUR[*]}"
    echo "Autologin: $AUTOLOGIN_CHOICE"
    
    read -p "Installation starten? (j/n): " START_INSTALL
    [[ "$START_INSTALL" =~ ^[jJ] ]] || exit 0
}
