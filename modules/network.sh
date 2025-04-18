#!/bin/bash

configure_network() {
    echo ""
    echo "-------------------------------------------------"
    echo "Netzwerk-Konfiguration (Arch Linux + Hyprland)"
    echo "-------------------------------------------------"
    
    read -p "Fix-IP vergeben? (j/n): " static_ip_choice
    
    if [[ "$static_ip_choice" =~ ^[jJ] ]]; then
        interfaces=($(nmcli device status | awk '$2=="ethernet" {print $1}'))
        
        if [[ ${#interfaces[@]} -eq 0 ]]; then
            log ERROR "Keine Netzwerk-Interfaces gefunden!"
            return 1
        fi
        
        echo "Verfügbare Netzwerk-Interfaces:"
        for i in "${!interfaces[@]}"; do
            echo "$((i+1))) ${interfaces[$i]}"
        done
        
        read -p "Interface auswählen (1-${#interfaces[@]}): " iface_num
        selected_iface="${interfaces[$((iface_num-1))]}"
        
        read -p "IP-Adresse (z.B. 192.168.1.100/24): " ip_address
        read -p "Gateway (z.B. 192.168.1.1): " gateway
        read -p "DNS-Server (z.B. 8.8.8.8): " dns_server
        
        echo ""
        echo "Zusammenfassung:"
        echo "Interface: $selected_iface"
        echo "IP: $ip_address"
        echo "Gateway: $gateway"
        echo "DNS: $dns_server"
        echo ""
        
        read -p "Konfiguration übernehmen? (j/n): " confirm
        
        if [[ "$confirm" =~ ^[jJ] ]]; then
            log INFO "Erstelle Netzwerk-Konfiguration für $selected_iface"
            
            if command -v nmcli &> /dev/null; then
                nmcli con delete "$selected_iface" 2>/dev/null
                
                nmcli con add con-name "$selected_iface" \
                ifname "$selected_iface" \
                type ethernet \
                ipv4.method manual \
                ipv4.addresses "$ip_address" \
                ipv4.gateway "$gateway" \
                ipv4.dns "$dns_server"
                
                nmcli con up "$selected_iface"
                log OK "NetworkManager-Konfiguration angewendet"
                
                if systemctl is-active --quiet systemd-networkd; then
                    systemctl disable --now systemd-networkd
                    log OK "systemd-networkd deaktiviert"
                fi
                
                if systemctl is-active --quiet systemd-resolved; then
                    systemctl disable --now systemd-resolved
                    log OK "systemd-resolved deaktiviert"
                fi
                
                echo "nameserver $dns_server" > /etc/resolv.conf
                chattr +i /etc/resolv.conf 2>/dev/null
                log OK "DNS-Konfiguration gesperrt"
                
            else
                log ERROR "NetworkManager nicht installiert!"
                echo "Installation mit: sudo pacman -S networkmanager"
                return 1
            fi
        else
            log INFO "Konfiguration abgebrochen"
        fi
    else
        log INFO "DHCP-Konfiguration beibehalten"
    fi
}
