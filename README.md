# Infraestructura local de Willariq

Este repositorio reúne los servicios que utiliza la API de Willariq en desarrollo.

| Servicio                   | Carpeta     | Función                                                                        |
| -------------------------- | ----------- | ------------------------------------------------------------------------------ |
| PostgreSQL 18 con pgvector | `postgres/` | Datos de la aplicación y vectores de conocimiento                              |
| Redis 7                    | `redis/`    | Colas y trabajos de BullMQ                                                     |
| RustFS                     | `rustfs/`   | Almacenamiento privado compatible con S3 para evidencias y documentos Markdown |

Cada servicio tiene su propio Compose, archivo de variables y volumen persistente. Los comandos siguientes se ejecutan desde la raíz de este repositorio. Crea el archivo `.env` de cada servicio a partir de su ejemplo si aún no existe y configura las credenciales antes de arrancarlo.

Crea la red Docker compartida una vez en cada host antes de iniciar los servicios. Si ya existe, reutilízala.

```bash
docker network create willariq-backend
```

## 1. PostgreSQL

```bash
(cd postgres && docker compose up -d)
(cd postgres && docker compose ps)
```

Configura `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` y `POSTGRES_PORT` en `postgres/.env`. La API, cuando se ejecuta en el mismo equipo, se conecta a `127.0.0.1` y al puerto publicado en `POSTGRES_PORT`. Usa esos datos en `DATABASE_URL` de la API.

La imagen incluye pgvector y la migración inicial de la API activa la extensión `vector`. El archivo `postgres/init/001_extensions.sql` es una referencia para activación manual. El Compose actual no monta ese archivo como script de inicialización.

Desde el repositorio `willariq-api`, aplica las migraciones existentes:

```bash
pnpm exec prisma migrate deploy --config prisma7.config.ts
pnpm exec prisma generate --config prisma7.config.ts
```

Para verificar la extensión después de migrar, ejecuta en la base de Willariq:

```sql
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
```

## 2. Redis para BullMQ

```bash
(cd redis && docker compose up -d)
(cd redis && docker compose ps)
(cd redis && docker compose exec redis redis-cli --askpass PING)
```

Usa la contraseña de `redis/.env`. La prueba debe responder `PONG`. La API usa `REDIS_HOST=127.0.0.1` si corre en el mismo equipo, el puerto publicado mediante `REDIS_PORT` y la misma `REDIS_PASSWORD`. Compose habilita persistencia AOF y la política `noeviction` para las colas.

## 3. RustFS

```bash
(cd rustfs && docker compose up -d)
(cd rustfs && docker compose ps)
```

Con los puertos predeterminados, el endpoint S3 es `http://127.0.0.1:9000` y la consola es `http://127.0.0.1:9001`. Ambos puertos se publican solo en la interfaz local. Si modificas `RUSTFS_PORT` o `RUSTFS_CONSOLE_PORT`, usa el puerto correspondiente.

1. Entra a la consola con `RUSTFS_ACCESS_KEY` y `RUSTFS_SECRET_KEY`.
2. Crea el bucket privado `incident-evidence` para las fotos de incidencias.
3. Si vas a usar conocimiento y chatbot, crea otro bucket privado llamado `municipal-knowledge` para los Markdown. Usa en la API los nombres exactos de los buckets que creaste.

La API usa RustFS mediante el SDK de AWS para S3.

| Configuración                | API fuera de Docker               | API dentro de Docker          |
| ---------------------------- | --------------------------------- | ----------------------------- |
| PostgreSQL en `DATABASE_URL` | `127.0.0.1` y el puerto publicado | `willariq-postgres:5432`      |
| Redis                        | `127.0.0.1` y el puerto publicado | `willariq-redis:6379`         |
| `RUSTFS_ENDPOINT`            | `http://127.0.0.1:9000`           | `http://willariq-rustfs:9000` |

Configura `RUSTFS_ENABLED=true`, `RUSTFS_ACCESS_KEY`, `RUSTFS_SECRET_KEY`, `RUSTFS_REGION` y `RUSTFS_EVIDENCE_BUCKET`. Agrega `RUSTFS_KNOWLEDGE_BUCKET` si habilitas conocimiento. Si eliges otro nombre para la red, define `WILLARIQ_BACKEND_NETWORK` con el mismo valor en los Compose que se conectan entre sí.

La app móvil y el panel acceden a los archivos a través de la API. Las credenciales y el endpoint S3 se configuran en el servidor de la API.

## Comprobación final

Revisa el estado de los tres servicios con `docker compose ps` desde sus carpetas. Arranca la API con la configuración correspondiente y comprueba que conecta a PostgreSQL y verifica los buckets privados. Prueba una carga de evidencia y, si habilitaste conocimiento, el procesamiento de un Markdown para comprobar también el worker de BullMQ.

Los volúmenes conservan los datos al detener los contenedores. `docker compose down -v` elimina los volúmenes del servicio.
