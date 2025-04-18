setup_autologin() {
  local dropin_dir="/etc/systemd/system/getty@tty1.service.d"
  mkdir -p "$dropin_dir"
  
  cat > "$dropin_dir/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $username --noclear %I \$TERM
EOF

  systemctl daemon-reload
  systemctl enable getty@tty1.service
  log OK "Autologin für $username eingerichtet"
}
