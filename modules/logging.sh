log() {
  local status="$1"
  shift
  local message="$*"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$status] $message"
}

setup_logging() {
  touch "$LOGFILE"
  exec > >(tee -a "$LOGFILE") 2>&1
  log INFO "Logging initialisiert in $LOGFILE"
}
