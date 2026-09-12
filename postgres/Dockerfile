# PostgreSQL con PostGIS instalado + pgvector compilado.
# Fija versiones en producción y prueba la imagen antes de actualizar.
FROM postgis/postgis:17-3.5

ARG PGVECTOR_VERSION=0.8.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       ca-certificates \
       git \
       postgresql-server-dev-17 \
    && git clone --branch v${PGVECTOR_VERSION} --depth 1 \
       https://github.com/pgvector/pgvector.git /tmp/pgvector \
    && make -C /tmp/pgvector \
    && make -C /tmp/pgvector install \
    && rm -rf /tmp/pgvector \
    && apt-get purge -y --auto-remove \
       build-essential git postgresql-server-dev-17 \
    && rm -rf /var/lib/apt/lists/*
