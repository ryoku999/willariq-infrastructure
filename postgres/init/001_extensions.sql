-- Se ejecuta al inicializar por primera vez el volumen de PostgreSQL.
-- Las extensiones se habilitan POR BASE DE DATOS.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verificación
SELECT PostGIS_Full_Version();

SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('postgis', 'vector', 'pgcrypto')
ORDER BY extname;
