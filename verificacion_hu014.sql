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

\echo '--- V8: TRIGGER trg_respuesta_normaliza: los espacios de los extremos no se guardan (debe devolver: [hola], 4)'
INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta)
SELECT c.id, u.id, '   hola   ' FROM interaccion_proyecto c, usuarios u
WHERE c.comentario = 'Muy buen proyecto' AND u.username = 'LuisDev'
RETURNING '[' || respuesta || ']' AS guardada, char_length(respuesta) AS largo;

\echo '--- V9: TRIGGER trg_respuesta_inmutable: no se puede mover una respuesta a otro comentario (debe fallar)'
UPDATE respuestas_comentario SET id_comentario = (SELECT id FROM interaccion_proyecto WHERE comentario <> 'Muy buen proyecto' LIMIT 1)
WHERE id = (SELECT id FROM respuestas_comentario ORDER BY fecha_creacion LIMIT 1);

\echo '--- V10: TRIGGER trg_respuesta_inmutable: no se puede cambiar el autor (debe fallar)'
UPDATE respuestas_comentario SET id_usuario = (SELECT id FROM usuarios WHERE username = 'Pepito')
WHERE id = (SELECT id FROM respuestas_comentario ORDER BY fecha_creacion LIMIT 1);

\echo '--- V11: FUNCION fn_publicar_respuesta: respuesta valida (devuelve id y el nuevo total del hilo: 6)'
SELECT total_respuestas, id_respuesta IS NOT NULL AS tiene_id
FROM fn_publicar_respuesta(
    (SELECT id_proyecto FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'),
    (SELECT id FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'),
    (SELECT id FROM usuarios WHERE username = 'LuisDev'),
    'Respuesta publicada con la funcion');

\echo '--- V12: FUNCION fn_publicar_respuesta: proyecto inexistente (debe fallar: PROJECT_NOT_FOUND)'
SELECT * FROM fn_publicar_respuesta(gen_random_uuid(),
    (SELECT id FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'),
    (SELECT id FROM usuarios WHERE username = 'LuisDev'), 'x');

\echo '--- V13: FUNCION fn_publicar_respuesta: comentario inexistente (debe fallar: COMMENT_NOT_FOUND)'
SELECT * FROM fn_publicar_respuesta(
    (SELECT id_proyecto FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'),
    gen_random_uuid(), (SELECT id FROM usuarios WHERE username = 'LuisDev'), 'x');

\echo '--- V14: FUNCION fn_publicar_respuesta: comentario de otro proyecto (debe fallar: COMMENT_NOT_IN_PROJECT)'
SELECT * FROM fn_publicar_respuesta(
    (SELECT id FROM proyectos WHERE id <> (SELECT id_proyecto FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto') LIMIT 1),
    (SELECT id FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'),
    (SELECT id FROM usuarios WHERE username = 'LuisDev'), 'x');

\echo '--- V15: FUNCION fn_listar_respuestas: devuelve las 6 respuestas en orden cronologico'
SELECT count(*) AS respuestas, min(fecha_creacion) <= max(fecha_creacion) AS en_orden
FROM fn_listar_respuestas((SELECT id FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'));

\echo '--- V16: FUNCION fn_conteo_respuestas_proyecto: un renglon por comentario del proyecto, con ceros'
SELECT c.comentario, f.total_respuestas
FROM fn_conteo_respuestas_proyecto((SELECT id_proyecto FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto')) f
JOIN interaccion_proyecto c ON c.id = f.id_comentario ORDER BY c.fecha_creacion;

\echo '--- V17: al borrar el comentario se borran sus respuestas (ON DELETE CASCADE): debe quedar 0'
DELETE FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto';
SELECT COUNT(*) AS respuestas_restantes FROM respuestas_comentario;

ROLLBACK;

