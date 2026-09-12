#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${POSTGRES_CONTAINER:-willay-postgres}"
DB="${POSTGRES_DB:-willay}"
USER="${POSTGRES_USER:-willay}"
OUT_DIR="${BACKUP_DIR:-./backups}"

mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
FILE="$OUT_DIR/${DB}_${STAMP}.dump"

docker exec "$CONTAINER" pg_dump \
  -U "$USER" \
  -d "$DB" \
  -Fc \
  --no-owner \
  --no-privileges \
  > "$FILE"

echo "Backup creado: $FILE"
