#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Uso: $0 backups/archivo.dump"
  exit 1
fi

CONTAINER="${POSTGRES_CONTAINER:-willay-postgres}"
DB="${POSTGRES_DB:-willay}"
USER="${POSTGRES_USER:-willay}"
FILE="$1"

cat "$FILE" | docker exec -i "$CONTAINER" pg_restore \
  -U "$USER" \
  -d "$DB" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges

echo "Restauración finalizada desde: $FILE"
