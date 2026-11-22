-- verificacion_hu014.sql - Pruebas de la tabla respuestas_comentario (HU014)
-- Requiere schema.sql + seed.sql cargados (el seed ya trae 2 respuestas al comentario 'Muy buen proyecto'). Todo se deshace al final (ROLLBACK).
\set ON_ERROR_STOP off
-- Un error esperado no aborta el resto de la transaccion de pruebas:
\set ON_ERROR_ROLLBACK on
BEGIN;

\echo '--- V1: insertar una respuesta valida (Escenario 1)'
INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta)
SELECT c.id, u.id, 'Estoy de acuerdo con tu propuesta'
FROM interaccion_proyecto c, usuarios u
WHERE c.comentario = 'Muy buen proyecto' AND u.username = 'LuisDev';

\echo '--- V2: el comentario tiene 3 respuestas (2 del seed + la de V1)'
SELECT COUNT(*) AS total_respuestas FROM respuestas_comentario
WHERE id_comentario = (SELECT id FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto');

\echo '--- V3: respuesta vacia o en blanco debe fallar (Escenario 4)'
INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta)
SELECT c.id, u.id, '   ' FROM interaccion_proyecto c, usuarios u
WHERE c.comentario = 'Muy buen proyecto' AND u.username = 'LuisDev';

\echo '--- V4: 1001 caracteres debe fallar (Escenario 5)'
INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta)
SELECT c.id, u.id, repeat('a', 1001) FROM interaccion_proyecto c, usuarios u
WHERE c.comentario = 'Muy buen proyecto' AND u.username = 'LuisDev';

\echo '--- V5: exactamente 1000 caracteres debe pasar (Escenario 6)'
INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta)
SELECT c.id, u.id, repeat('a', 1000) FROM interaccion_proyecto c, usuarios u
WHERE c.comentario = 'Muy buen proyecto' AND u.username = 'LuisDev';

\echo '--- V6: comentario inexistente debe fallar por la FK (Escenario 8)'
INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta)
SELECT gen_random_uuid(), u.id, 'Buen aporte' FROM usuarios u WHERE u.username = 'LuisDev';

\echo '--- V7: al borrar el comentario se borran sus respuestas (ON DELETE CASCADE): debe quedar 0'
DELETE FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto';
SELECT COUNT(*) AS respuestas_restantes FROM respuestas_comentario;

ROLLBACK;

