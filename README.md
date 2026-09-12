# Willay - Infraestructura local separada

## 1. PostgreSQL + PostGIS + pgvector + pgAdmin

```bash
cd postgres
cp .env.example .env
docker compose up -d --build
```

pgAdmin:

- URL: http://localhost:5050
- Host de PostgreSQL dentro de pgAdmin: `postgres`
- Port: `5432`
- Database: `willay`
- Username: el `POSTGRES_USER` `willay`
- Password: el `POSTGRES_PASSWORD` `3322`

Verificar PostGIS:

```sql
SELECT PostGIS_Full_Version();
```

Verificar extensiones:

```sql
SELECT extname, extversion FROM pg_extension WHERE extname IN ('postgis','vector','pgcrypto');
```

## 2. Redis / BullMQ

```bash
cd redis
cp .env.example .env
docker compose up -d
```

Prueba:

```bash
docker exec -it willay-redis redis-cli --askpass PING
```

Debe responder `PONG`.

## 3. MinIO

```bash
cd minio
cp .env.example .env
docker compose up -d
```

- API S3: http://localhost:9000
- Console: http://localhost:9001

Crear buckets:

- incident-evidence
- knowledge-base
- avatars

## 4. Prisma: migraciones manuales para extensiones

Prisma recomienda migraciones personalizadas para extensiones que introducen
tipos no soportados nativamente, como `vector`.

### Primera migración

1. Asegura que PostgreSQL esté levantado.
2. Las extensiones ya deberían estar activadas por `init/001_extensions.sql`.
3. Verifica con `pg_extension`.
4. Genera una migración sin aplicarla:

```bash
pnpx prisma migrate dev --name init --create-only
```

5. Abre:

```text
prisma/migrations/<timestamp>_init/migration.sql
```

6. Al COMIENZO agrega:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

7. Revisa el SQL generado. Para `Unsupported("geography(Point,4326)")`
   y `Unsupported("vector")`, Prisma puede requerir que manejes el SQL manualmente.
8. Aplica:

```bash
pnpx prisma migrate dev
```

9. Agrega en una migración posterior el índice GIST y trigger de `location`:

```bash
pnpx prisma migrate dev --name add_geo_indexes --create-only
```

10. Reemplaza el contenido correspondiente con lo de
    `../prisma_manual_extensions.sql` y aplica:

```bash
pnpx prisma migrate dev
```

### pgvector

No crees todavía un HNSW definitivo hasta elegir un único modelo de embedding.
Cuando conozcas su dimensión exacta N:

```bash
npx prisma migrate dev --name fix_embedding_dimension --create-only
```

Y en `migration.sql`:

```sql
ALTER TABLE knowledge_chunks
ALTER COLUMN embedding TYPE vector(N);

CREATE INDEX knowledge_chunks_embedding_hnsw_idx
ON knowledge_chunks
USING hnsw (embedding vector_cosine_ops);
```

Luego:

```bash
npx prisma migrate dev
```

## 5. Auth actual

Campos obligatorios:

- firstName
- dni
- phone
- password (solo DTO; en DB se guarda `passwordHash`)

Opcionales:

- lastName
- email

No hay verificación de correo obligatoria.
`emailVerifiedAt` se conserva nullable para implementar esa función más adelante.

## 6. Backups

### Manual con pgAdmin

pgAdmin usa `pg_dump`/`pg_restore` internamente.

1. Abre pgAdmin.
2. Servers > PostgreSQL > Databases.
3. Click derecho en `willay`.
4. Backup...
5. Formato recomendado: Custom.
6. Guarda el backup.
7. Para restaurar: click derecho en la base > Restore...

Para una copia completa reproducible y automatizable, es preferible `pg_dump`
por script.

### Script local

Desde la raíz:

```bash
./backup-postgres.sh
```

Restaura:

```bash
./restore-postgres.sh backups/willay_YYYYMMDD_HHMMSS.dump
```

### Producción

No confíes solo en pgAdmin. Programa `pg_dump` (cron) y copia el resultado
FUERA del VPS: otro servidor, bucket S3 compatible, etc.
Una copia que vive en el mismo disco/VPS no protege contra pérdida total del servidor.
