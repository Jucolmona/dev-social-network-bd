-- =====================================================================
-- verificacion.sql
-- Consultas de verificacion de schema.sql (ejecutar DESPUES de schema.sql).
-- =====================================================================

-- [V1] ¿Cuantas tablas se crearon?  (15)
SELECT COUNT(*) AS tablas
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- [V2] Resumen por tabla: columnas, PK, FK, UNIQUE, CHECK e indices
SELECT c.relname AS tabla,
       (SELECT count(*) FROM pg_attribute a
         WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped)          AS columnas,
       (SELECT count(*) FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'p') AS pk,
       (SELECT count(*) FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'f') AS fk,
       (SELECT count(*) FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'u') AS uq,
       (SELECT count(*) FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'c') AS chk,
       (SELECT count(*) FROM pg_index i WHERE i.indrelid = c.oid)                          AS indices
FROM pg_class c
WHERE c.relnamespace = 'public'::regnamespace AND c.relkind = 'r'
ORDER BY c.relname;

-- [V3] Claves foraneas y su regla ON DELETE  (23 filas)
SELECT conrelid::regclass AS tabla,
       conname            AS restriccion,
       pg_get_constraintdef(oid) AS definicion
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype = 'f'
ORDER BY 1, 2;

-- [V4] Restricciones CHECK  (19 filas)
SELECT conrelid::regclass AS tabla,
       conname            AS restriccion,
       pg_get_constraintdef(oid) AS regla
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype = 'c'
ORDER BY 1, 2;

-- [V5] Indices creados explicitamente con CREATE INDEX  (13 filas)
SELECT i.tablename AS tabla, i.indexname AS indice, i.indexdef AS definicion
FROM pg_indexes i
WHERE i.schemaname = 'public'
  AND NOT EXISTS (SELECT 1 FROM pg_constraint k
                  WHERE k.conindid = (quote_ident(i.schemaname) || '.' || quote_ident(i.indexname))::regclass)
ORDER BY 1, 2;
