#!/usr/bin/env bash

set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin"

START_TIME=$(date +%s)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$REPO_DIR/update_logs"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/$(date '+%Y_%m_%d').log"

exec > >(tee -a "$LOGFILE") 2>&1
log() { printf '%s %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S')" "$*"; }
trap 'log "Script finished with status $?"' EXIT

command -v docker &>/dev/null || { log "ERROR: Docker not found."; exit 1; }
docker info &>/dev/null || { log "ERROR: Docker daemon not running."; exit 1; }

cd "$REPO_DIR" || { log "ERROR: cannot change to $REPO_DIR"; exit 1; }

log "Pulling latest Docker images..."
docker compose pull

log "Bringing stack up (rebuild as needed)..."
docker compose up -d --build

STACK_IMAGES=$(docker compose config --images)
for img in $STACK_IMAGES; do
  log "Pruning unused images for $img ..."
  docker image prune -f --filter "reference=$img"
done

log "Checking for dangling images..."
STACK_IMAGES=$(docker compose config --images)
for img in $STACK_IMAGES; do
  log "Removing unused images for $img ..."
  UNUSED_IMAGES=$(docker images --quiet --filter=reference="$img" --filter=dangling=true)
  if [ -n "$UNUSED_IMAGES" ]; then
    docker image rm -f $UNUSED_IMAGES
  else
    log "No unused images found for $img."
  fi
done

log "Container status after update:"
docker compose ps

ELAPSED=$(( $(date +%s) - START_TIME ))
log "Elapsed time: ${ELAPSED}s"
