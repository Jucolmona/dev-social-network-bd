-- verificacion_sprint3.sql - Pruebas de triggers y funciones de HU018, HU019 y votar comentarios (Sprint 3)
-- Requiere schema.sql + seed.sql cargados. Todo se deshace al final (ROLLBACK).
-- Las pruebas marcadas "DEBE FALLAR" muestran un ERROR a proposito: es el resultado esperado.
\set ON_ERROR_STOP off
\set ON_ERROR_ROLLBACK on
\set VERBOSITY terse
BEGIN;

\echo '=== HU018 - mensajes no leidos'
\echo '--- V18: conteo del seed: PepitoDevPro 1 no leido, LuisDev 1 (nunca abrio la conversacion)'
SELECT u.username, n.no_leidos
FROM usuarios u, LATERAL fn_conteo_no_leidos(u.id) n
WHERE u.username IN ('PepitoDevPro','LuisDev') ORDER BY u.username;

\echo '--- V19: marcar leida deja 0 no leidos a PepitoDevPro'
SELECT fn_marcar_conversacion_leida('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002') IS NOT NULL AS marcada;
SELECT no_leidos FROM fn_conteo_no_leidos('a0000000-0000-0000-0000-000000000002');

\echo '--- V20: marcar leida por primera vez (LuisDev, sin fila) crea la fila y deja 0'
SELECT fn_marcar_conversacion_leida('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001') IS NOT NULL AS marcada;
SELECT no_leidos FROM fn_conteo_no_leidos('a0000000-0000-0000-0000-000000000001');

\echo '--- V21: la marca no retrocede (trg_lectura_no_retrocede): fecha antigua conserva la actual -> debe dar true'
SELECT fn_marcar_conversacion_leida('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001', now() - interval '10 days')
       >= now() - interval '1 minute' AS conserva_la_mas_reciente;

\echo '--- V22: usuario que no participa no puede tener estado de lectura (trg_lectura_participante) DEBE FALLAR'
SELECT fn_marcar_conversacion_leida('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000004');

\echo '--- V23: conversacion inexistente DEBE FALLAR (CONVERSATION_NOT_FOUND)'
SELECT fn_marcar_conversacion_leida(gen_random_uuid(),'a0000000-0000-0000-0000-000000000001');

\echo '--- V24: no se puede cambiar el usuario de un estado de lectura DEBE FALLAR'
UPDATE conversation_read_states SET id_usuario = 'a0000000-0000-0000-0000-000000000004'
WHERE id_conversacion = 'e0000000-0000-0000-0000-000000000001' AND id_usuario = 'a0000000-0000-0000-0000-000000000001';

\echo '=== HU019 - bloquear usuario'
\echo '--- V25: hay bloqueo en ambos sentidos (Ana bloqueo a Carlos): true, true, false'
SELECT fn_hay_bloqueo('a0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000005') AS ana_carlos,
       fn_hay_bloqueo('a0000000-0000-0000-0000-000000000005','a0000000-0000-0000-0000-000000000003') AS carlos_ana,
       fn_hay_bloqueo('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002') AS luis_pepito;

\echo '--- V26: con bloqueo, Carlos no puede escribirle a Ana (trg_mensaje_sin_bloqueo) DEBE FALLAR'
INSERT INTO mensajes_privados (id_conversacion, remitente_id, destinatario_id, contenido)
VALUES ('e0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000005','a0000000-0000-0000-0000-000000000003','hola?');

\echo '--- V27: tampoco Ana a Carlos (la restriccion es mutua) DEBE FALLAR'
INSERT INTO mensajes_privados (id_conversacion, remitente_id, destinatario_id, contenido)
VALUES ('e0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000005','hola');

\echo '--- V28: sin bloqueo el mensaje se envia (Luis a Pepito)'
INSERT INTO mensajes_privados (id_conversacion, remitente_id, destinatario_id, contenido)
VALUES ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','Nos vemos manana');
SELECT count(*) AS mensajes_luis_pepito FROM mensajes_privados WHERE id_conversacion = 'e0000000-0000-0000-0000-000000000001';

\echo '--- V29: bloquear devuelve el id del bloqueo (Luis bloquea a Maria)'
SELECT fn_bloquear_usuario('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000004') IS NOT NULL AS bloqueado;

\echo '--- V30: bloquear dos veces DEBE FALLAR (BLOQUEO_DUPLICADO)'
SELECT fn_bloquear_usuario('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000004');

\echo '--- V31: bloquearse a si mismo DEBE FALLAR (AUTO_BLOQUEO)'
SELECT fn_bloquear_usuario('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001');

\echo '--- V32: bloquear un usuario inexistente DEBE FALLAR (USUARIO_NO_EXISTE)'
SELECT fn_bloquear_usuario('a0000000-0000-0000-0000-000000000001', gen_random_uuid());

\echo '--- V33: el CHECK de la tabla tambien impide el auto bloqueo (insercion directa) DEBE FALLAR'
INSERT INTO usuarios_bloqueados (blocker_id, blocked_id) VALUES ('a0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000002');

\echo '--- V34: desbloquear (Ana a Carlos) y volver a escribir: la conversacion queda libre -> hay_bloqueo = false'
SELECT fn_desbloquear_usuario('a0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000005');
SELECT fn_hay_bloqueo('a0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000005') AS hay_bloqueo;
INSERT INTO mensajes_privados (id_conversacion, remitente_id, destinatario_id, contenido)
VALUES ('e0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000005','a0000000-0000-0000-0000-000000000003','gracias por desbloquear');

\echo '--- V35: desbloquear sin bloqueo previo DEBE FALLAR (BLOQUEO_NO_ENCONTRADO)'
SELECT fn_desbloquear_usuario('a0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000005');

\echo '=== Votar comentarios'
\echo '--- V36: votos del seed en el proyecto 1: "Muy buen proyecto" = 3 y los otros dos comentarios 0'
SELECT c.comentario, v.total_votos
FROM fn_conteo_votos_proyecto('c0000000-0000-0000-0000-000000000001') v
JOIN interaccion_proyecto c ON c.id = v.id_comentario ORDER BY v.total_votos DESC, c.comentario;

\echo '--- V37: LuisDev vota "Muy buen proyecto": votado = true, total = 4'
SELECT * FROM fn_alternar_voto_comentario('c0000000-0000-0000-0000-000000000001',
   (SELECT id FROM interaccion_proyecto WHERE comentario='Muy buen proyecto'), 'a0000000-0000-0000-0000-000000000001');

\echo '--- V38: volver a votar retira el voto: votado = false, total = 3'
SELECT * FROM fn_alternar_voto_comentario('c0000000-0000-0000-0000-000000000001',
   (SELECT id FROM interaccion_proyecto WHERE comentario='Muy buen proyecto'), 'a0000000-0000-0000-0000-000000000001');

\echo '--- V39: comentario de otro proyecto DEBE FALLAR (COMMENT_NOT_IN_PROJECT)'
SELECT * FROM fn_alternar_voto_comentario('c0000000-0000-0000-0000-000000000002',
   (SELECT id FROM interaccion_proyecto WHERE comentario='Muy buen proyecto'), 'a0000000-0000-0000-0000-000000000001');

\echo '--- V40: proyecto inexistente DEBE FALLAR (PROJECT_NOT_FOUND)'
SELECT * FROM fn_alternar_voto_comentario(gen_random_uuid(), gen_random_uuid(), 'a0000000-0000-0000-0000-000000000001');

\echo '--- V41: comentario inexistente DEBE FALLAR (COMMENT_NOT_FOUND)'
SELECT * FROM fn_alternar_voto_comentario('c0000000-0000-0000-0000-000000000001', gen_random_uuid(), 'a0000000-0000-0000-0000-000000000001');

ROLLBACK;
