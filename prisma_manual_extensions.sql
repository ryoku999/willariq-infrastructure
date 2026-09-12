--  PostGIS + pgvector + índices/trigger

-- Después de que Prisma haya creado la tabla incidents:
CREATE INDEX IF NOT EXISTS incidents_location_gist_idx
ON incidents USING GIST (location);

CREATE OR REPLACE FUNCTION set_incident_location()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.location :=
    ST_SetSRID(
      ST_MakePoint(
        NEW.longitude::double precision,
        NEW.latitude::double precision
      ),
      4326
    )::geography;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_incident_location ON incidents;

CREATE TRIGGER trg_set_incident_location
BEFORE INSERT OR UPDATE OF latitude, longitude
ON incidents
FOR EACH ROW
EXECUTE FUNCTION set_incident_location();

-- pgvector:
-- NO fijes N hasta elegir definitivamente tu único modelo de embeddings.
--
-- Cuando sepas la dimensión, por ejemplo N=1024:
--
-- ALTER TABLE knowledge_chunks
--   ALTER COLUMN embedding TYPE vector(1024);
--
-- CREATE INDEX IF NOT EXISTS knowledge_chunks_embedding_hnsw_idx
-- ON knowledge_chunks
-- USING hnsw (embedding vector_cosine_ops);
