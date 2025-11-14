#!/usr/bin/env bash

set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin"

START_TIME=$(date +%s)
REPO_DIR="$(pwd)"
LOG_DIR="$REPO_DIR/update_logs"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/$(date '+%Y_%m_%d').log"

exec > >(tee -a "$LOGFILE") 2>&1
log() { printf '%s %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S')" "$*"; }

trap 'log "Script finished with status $?"' EXIT
log "=== mediastack update started ==="

if ! command -v docker &>/dev/null; then
    log "ERROR: Docker command not found."
    exit 1
fi

if ! docker info &>/dev/null; then
    log "ERROR: Docker daemon not running."
    exit 1
fi

cd "$REPO_DIR" || { log "ERROR: cannot change to $REPO_DIR"; exit 1; }

log "Pulling latest Docker images..."
docker compose pull

log "Bringing stack up (rebuild as needed)..."
docker compose up -d --build

log "Pruning unused images for mediastack…"
docker image prune -f --filter "label=mediastack"

log "Container status after update:"
docker compose ps

ELAPSED=$(( $(date +%s) - START_TIME ))
log "Elapsed time: ${ELAPSED}s"
log "=== mediastack update completed successfully ==="
