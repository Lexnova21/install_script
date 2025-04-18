log() {
  local status="$1"
  shift
  local message="$*"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$status] $message"
}

log_error() {
  ERROR_LOG+=("$1")
  log "ERROR" "$1"
}

setup_logging() {
  touch "$LOGFILE"
  exec > >(tee -a "$LOGFILE") 2>&1
}
