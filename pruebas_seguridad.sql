\set VERBOSITY terse
\echo [P1] autenticacion lee credenciales
SET ROLE svc_autenticacion; SELECT count(*) AS credenciales_visibles FROM credenciales; RESET ROLE;
\echo [P2] autenticacion NO lee perfiles
SET ROLE svc_autenticacion; SELECT count(*) FROM perfiles_usuario; RESET ROLE;
\echo [P3] autenticacion NO lee usuarios.nombre (solo id, email, username)
SET ROLE svc_autenticacion; SELECT nombre FROM usuarios LIMIT 1; RESET ROLE;
\echo [P4] administracion NO lee credenciales
SET ROLE svc_administracion; SELECT password_hash FROM credenciales LIMIT 1; RESET ROLE;
\echo [P5] administracion NO puede borrar mensajes
SET ROLE svc_administracion; DELETE FROM mensajes_privados; RESET ROLE;
\echo [P6] administracion NO puede modificar mensajes
SET ROLE svc_administracion; UPDATE mensajes_privados SET contenido='x'; RESET ROLE;
\echo [P7] administracion SI lee mensajes
SET ROLE svc_administracion; SELECT count(*) AS mensajes FROM mensajes_privados; RESET ROLE;
\echo [P8] consultas SI lee proyectos
SET ROLE svc_consultas; SELECT count(*) AS proyectos FROM proyectos; RESET ROLE;
\echo [P9] consultas NO escribe
SET ROLE svc_consultas; INSERT INTO tecnologias(nombre_tecnologia,tipo) VALUES ('X','ROL'); RESET ROLE;
\echo [P10] consultas NO lee mensajes
SET ROLE svc_consultas; SELECT count(*) FROM mensajes_privados; RESET ROLE;
\echo [P11] analista NO lee el hash
SET ROLE usr_analista; SELECT password_hash FROM credenciales; RESET ROLE;
\echo [P12] analista SI lee bloqueos (columnas permitidas)
SET ROLE usr_analista; SELECT count(*) AS bloqueados FROM credenciales WHERE bloqueado_hasta > now(); RESET ROLE;
\echo [P13] analista NO lee el contenido de los mensajes
SET ROLE usr_analista; SELECT contenido FROM mensajes_privados LIMIT 1; RESET ROLE;
\echo [P14] analista NO lee email
SET ROLE usr_analista; SELECT email FROM usuarios; RESET ROLE;
\echo [P15] el borrado en cascada sigue funcionando (lo ejecuta el propietario)
BEGIN; DELETE FROM usuarios WHERE id=(SELECT id FROM usuarios ORDER BY email LIMIT 1); SELECT 'ok' AS cascada; ROLLBACK;

\echo [P16] administracion SI inserta respuestas a comentarios (HU014)
BEGIN; SET ROLE svc_administracion; INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta) SELECT c.id, c.id_usuario, 'prueba P16' FROM interaccion_proyecto c LIMIT 1; RESET ROLE; ROLLBACK;
\echo [P17] administracion NO borra respuestas
SET ROLE svc_administracion; DELETE FROM respuestas_comentario; RESET ROLE;
\echo [P18] consultas SI lee respuestas
SET ROLE svc_consultas; SELECT count(*) AS respuestas FROM respuestas_comentario; RESET ROLE;
\echo [P19] consultas NO inserta respuestas
SET ROLE svc_consultas; INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta) SELECT id, id_usuario, 'x' FROM interaccion_proyecto LIMIT 1; RESET ROLE;
\echo [P20] autenticacion NO lee respuestas
SET ROLE svc_autenticacion; SELECT count(*) FROM respuestas_comentario; RESET ROLE;

\echo [P21] autenticacion NO ejecuta fn_publicar_respuesta (EXECUTE solo para administracion)
SET ROLE svc_autenticacion; SELECT * FROM fn_publicar_respuesta(gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 'x'); RESET ROLE;
\echo [P22] consultas NO ejecuta fn_publicar_respuesta (solo lectura)
SET ROLE svc_consultas; SELECT * FROM fn_publicar_respuesta(gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 'x'); RESET ROLE;
\echo [P23] consultas SI ejecuta fn_listar_respuestas
SET ROLE svc_consultas; SELECT count(*) AS respuestas FROM fn_listar_respuestas((SELECT id FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto')); RESET ROLE;
\echo [P24] administracion SI ejecuta fn_publicar_respuesta (se deshace con ROLLBACK)
BEGIN; SET ROLE svc_administracion; SELECT total_respuestas FROM fn_publicar_respuesta((SELECT id_proyecto FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'), (SELECT id FROM interaccion_proyecto WHERE comentario = 'Muy buen proyecto'), (SELECT id FROM usuarios WHERE username = 'LuisDev'), 'prueba P24'); RESET ROLE; ROLLBACK;
\echo [P25] analista NO ejecuta fn_conteo_respuestas_proyecto
SET ROLE usr_analista; SELECT * FROM fn_conteo_respuestas_proyecto(gen_random_uuid()); RESET ROLE;
