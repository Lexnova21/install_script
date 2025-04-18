source /usr/share/cachyos-fish-config/cachyos-config.fish
if test -z "$WAYLAND_DISPLAY" -a (tty) = /dev/tty1
	exec Hyprland
end
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
