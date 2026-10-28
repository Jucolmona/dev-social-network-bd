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
