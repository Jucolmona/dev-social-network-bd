-- =====================================================================
-- verificacion.sql
-- Consultas de verificacion de schema.sql (ejecutar DESPUES de schema.sql).
-- =====================================================================

-- [V1] ¿Cuantas tablas se crearon?  (19)
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

-- [V3] Claves foraneas y su regla ON DELETE  (31 filas)
SELECT conrelid::regclass AS tabla,
       conname            AS restriccion,
       pg_get_constraintdef(oid) AS definicion
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype = 'f'
ORDER BY 1, 2;

-- [V4] Restricciones CHECK  (21 filas)
SELECT conrelid::regclass AS tabla,
       conname            AS restriccion,
       pg_get_constraintdef(oid) AS regla
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype = 'c'
ORDER BY 1, 2;

-- [V5] Indices creados explicitamente con CREATE INDEX  (17 filas)
SELECT i.tablename AS tabla, i.indexname AS indice, i.indexdef AS definicion
FROM pg_indexes i
WHERE i.schemaname = 'public'
  AND NOT EXISTS (SELECT 1 FROM pg_constraint k
                  WHERE k.conindid = (quote_ident(i.schemaname) || '.' || quote_ident(i.indexname))::regclass)
ORDER BY 1, 2;

-- [V6] Triggers creados (5): 2 de HU014 (respuestas), 2 de HU018 (lectura) y 1 de HU019 (bloqueo de mensajes)
SELECT t.tgrelid::regclass AS tabla, t.tgname AS trigger,
       CASE WHEN t.tgtype & 2 = 2 THEN 'BEFORE' ELSE 'AFTER' END AS momento,
       concat_ws(' / ', CASE WHEN t.tgtype & 4  = 4  THEN 'INSERT' END,
                        CASE WHEN t.tgtype & 8  = 8  THEN 'DELETE' END,
                        CASE WHEN t.tgtype & 16 = 16 THEN 'UPDATE' END) AS evento,
       t.tgfoid::regproc AS funcion
FROM pg_trigger t
WHERE NOT t.tgisinternal AND t.tgrelid::regclass::text IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public')
ORDER BY 1, 2;

-- [V7] Funciones de las HU (15): 10 de negocio (3 de HU014, 5 de HU018 y HU019, 2 de votar comentarios) y 5 de trigger
SELECT p.proname AS funcion, pg_get_function_identity_arguments(p.oid) AS parametros,
       pg_get_function_result(p.oid) AS resultado
FROM pg_proc p
WHERE p.pronamespace = 'public'::regnamespace AND p.proname LIKE 'fn\_%'
ORDER BY 1;
