#!/bin/bash

configure_network() {
    # Frühe Fehlererkennung
    if ! command -v nmcli &> /dev/null; then
        log "ERROR" "NetworkManager nicht installiert!"
        install_packages "networkmanager" || {
            log_error "NetworkManager konnte nicht installiert werden"
            return 1
        }
    fi

    if [[ "$NETWORK_CHOICE" != "j" ]]; then
        log "INFO" "Behalte DHCP-Konfiguration bei"
        return 0
    fi

    # Interface-Auswahl
    interfaces=($(nmcli device status | awk '$2=="ethernet" {print $1}'))
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        log_error "Keine Netzwerk-Interfaces gefunden!"
        return 1
    fi

    # Automatische Auswahl wenn nur 1 Interface
    if [[ ${#interfaces[@]} -eq 1 ]]; then
        selected_iface="${interfaces[0]}"
    else
        echo "Verfügbare Netzwerk-Interfaces:"
        for i in "${!interfaces[@]}"; do
            echo "$((i+1))) ${interfaces[$i]}"
        done
        
        read -p "Interface auswählen (1-${#interfaces[@]}): " iface_num
        selected_iface="${interfaces[$((iface_num-1))]}"
    fi

    # Konfiguration anwenden
    log "INFO" "Erstelle Netzwerk-Konfiguration für $selected_iface"
    
    nmcli con delete "$selected_iface" 2>/dev/null
    
    if ! nmcli con add con-name "$selected_iface" \
        ifname "$selected_iface" \
        type ethernet \
        ipv4.method manual \
        ipv4.addresses "$IP_ADDRESS" \
        ipv4.gateway "$GATEWAY" \
        ipv4.dns "$DNS_SERVER"; then
        log_error "Fehler bei der Netzwerkkonfiguration"
        return 1
    fi

    nmcli con up "$selected_iface" || {
        log_error "Aktivierung der Verbindung fehlgeschlagen"
        return 1
    }

    # Systemd-Dienste deaktivieren
    systemctl disable --now systemd-networkd systemd-resolved 2>/dev/null
    log "OK" "Systemd-Netzwerkdienste deaktiviert"

    # DNS sperren
    echo "nameserver $DNS_SERVER" > /etc/resolv.conf
    chattr +i /etc/resolv.conf 2>/dev/null
    log "OK" "DNS-Einstellungen gesperrt"
}
