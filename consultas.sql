
-- consultas.sql  -  Sprint 1 y Sprint 2
-- Consultas ejecutables sobre schema.sql.  Cada una indica la pregunta que
-- responde, la HU y el tipo de operacion.  Probadas sobre schema.sql +
-- datos semilla (seed.sql); los valores literales ('LuisDev', 'Java', ...)
-- son parametros de ejemplo.
--   PARTE A  PC01-PC06  preguntas clave del Sprint 1 (README, seccion 2)
--   PARTE B  PC07-PC14  preguntas clave del Sprint 2
--   PARTE C  C01-C27    consultas complementarias por historia de usuario


-- PARTE A - PREGUNTAS CLAVE DEL SPRINT 1  


-- [PC01] HU001 - Sprint 1 - Filtro por fecha + agregación
-- Pregunta: ¿Cuántos usuarios nuevos se registraron por mes en los últimos 6 meses?
SELECT date_trunc('month', fecha_registro)::date AS mes,
       COUNT(*)                                   AS usuarios_nuevos
FROM usuarios
WHERE fecha_registro >= date_trunc('month', now()) - INTERVAL '5 months'
GROUP BY 1
ORDER BY 1;

-- [PC02] HU007 - Sprint 1 - Join + agregación + orden + límite
-- Pregunta: Cuáles son los 10 proyectos con más tecnologías asociadas?
SELECT p.titulo,
       u.username                    AS autor,
       COUNT(pt.id_tecnologia)       AS num_tecnologias
FROM proyectos p
JOIN usuarios u                 ON u.id = p.usuario_id
LEFT JOIN proyecto_tecnologias pt ON pt.id_proyecto = p.id
GROUP BY p.id, p.titulo, u.username
ORDER BY num_tecnologias DESC, p.titulo
LIMIT 10;

-- [PC03] HU002 - Sprint 1 - Join + filtro (misma consulta que C04)
-- Pregunta: Qué usuarios tienen su cuenta bloqueada actualmente (bloqueado_hasta vigente)?
SELECT u.username, c.intentos_fallidos, c.bloqueado_hasta
FROM credenciales c
JOIN usuarios u ON u.id = c.usuario_id
WHERE c.bloqueado_hasta > now()
ORDER BY c.bloqueado_hasta;

-- [PC04] HU011 - Sprint 1 - Join + agregación
-- Pregunta: Cuántas discusiones existen agrupadas por tecnología?
SELECT t.nombre_tecnologia,
       COUNT(d.id) AS discusiones
FROM discusiones d
JOIN tecnologias t ON t.id = d.id_tecnologia
GROUP BY t.id, t.nombre_tecnologia
ORDER BY discusiones DESC, t.nombre_tecnologia;

-- [PC05] HU007 - Sprint 1 - Join + filtro + orden + subconsulta
-- Pregunta: Cuál es el listado de proyectos publicados por un usuario específico, ordenados por fecha de creación?
SELECT p.titulo,
       p.repositorio_url,
       p.fecha_creacion,
       (SELECT string_agg(t.nombre_tecnologia, ', ' ORDER BY t.nombre_tecnologia)
          FROM proyecto_tecnologias pt
          JOIN tecnologias t ON t.id = pt.id_tecnologia
         WHERE pt.id_proyecto = p.id) AS tecnologias
FROM proyectos p
JOIN usuarios u ON u.id = p.usuario_id
WHERE u.username = 'LuisDev'
ORDER BY p.fecha_creacion DESC;

-- [PC06] HU003/HU007 - Sprint 1 - UNION ALL + join + agregación + límite
-- Pregunta: Cuáles son las 5 tecnologías más usadas entre todos los proyectos y perfiles combinados?
SELECT t.nombre_tecnologia,
       COUNT(*)                                       AS usos_totales,
       COUNT(*) FILTER (WHERE x.origen = 'PROYECTO')  AS en_proyectos,
       COUNT(*) FILTER (WHERE x.origen = 'PERFIL')    AS en_perfiles
FROM (SELECT id_tecnologia, 'PROYECTO' AS origen FROM proyecto_tecnologias
      UNION ALL
      SELECT id_tecnologia, 'PERFIL'   AS origen FROM habilidades) x
JOIN tecnologias t ON t.id = x.id_tecnologia
GROUP BY t.id, t.nombre_tecnologia
ORDER BY usos_totales DESC, t.nombre_tecnologia
LIMIT 5;


-- PARTE B · PREGUNTAS CLAVE DEL SPRINT 2 

-- [PC07] HU005 - Sprint 2 - Subconsultas + agregación (misma consulta que C16)
-- Pregunta: Cuántos seguidores y cuántos seguidos tiene cada usuario?
SELECT u.username,
       (SELECT COUNT(*) FROM seguidores f WHERE f.id_seguido   = u.id) AS seguidores,
       (SELECT COUNT(*) FROM seguidores f WHERE f.id_seguidor  = u.id) AS seguidos
FROM usuarios u
ORDER BY seguidores DESC, u.username;

-- [PC08] HU005 - Sprint 2 - UNION ALL + join (misma consulta que C17)
-- Pregunta: Qué actividad (proyectos y discusiones) han publicado los desarrolladores que sigue un usuario? (feed)
SELECT actividad.tipo, actividad.titulo, u.username AS autor, actividad.fecha
FROM (
    SELECT 'PROYECTO'  AS tipo, pr.titulo, pr.usuario_id AS autor_id, pr.fecha_creacion AS fecha FROM proyectos pr
    UNION ALL
    SELECT 'DISCUSION' AS tipo, d.titulo,  d.autor_id,               d.fecha_creacion  AS fecha FROM discusiones d
) actividad
JOIN usuarios u       ON u.id = actividad.autor_id
JOIN seguidores f     ON f.id_seguido = actividad.autor_id
JOIN usuarios yo      ON yo.id = f.id_seguidor
WHERE yo.username = 'LuisDev'
ORDER BY actividad.fecha DESC;

-- [PC09] HU010  Sprint 2  Join externo + agregación + límite
-- Pregunta: Cuáles son los 5 proyectos con más likes?
SELECT p.titulo,
       u.username   AS autor,
       COUNT(l.id_usuario) AS likes
FROM proyectos p
JOIN usuarios u ON u.id = p.usuario_id
LEFT JOIN likes_proyecto l ON l.id_proyecto = p.id
GROUP BY p.id, p.titulo, u.username
ORDER BY likes DESC, p.titulo
LIMIT 5;

-- [PC10] HU010  Sprint 2  Join + filtro (misma consulta que C18)
-- Pregunta: Qué proyectos le han gustado a un usuario (su lista de likes)?
SELECT pr.titulo, l.fecha_creacion AS fecha_like
FROM likes_proyecto l
JOIN proyectos pr ON pr.id = l.id_proyecto
JOIN usuarios u   ON u.id  = l.id_usuario
WHERE u.username = 'AnaCoder'
ORDER BY l.fecha_creacion DESC;

-- [PC11] HU012  Sprint 2  Join + agregación condicional (misma consulta que C20)
-- Pregunta: Cuántas discusiones abiertas y resueltas tiene cada autor?
SELECT u.username,
       COUNT(*) FILTER (WHERE d.estado = 'ABIERTA')   AS abiertas,
       COUNT(*) FILTER (WHERE d.estado = 'RESUELTA')  AS resueltas
FROM discusiones d
JOIN usuarios u ON u.id = d.autor_id
GROUP BY u.username
ORDER BY u.username;

-- [PC12] HU013  Sprint 2  Join externo + agregación (misma consulta que C23)
-- Pregunta: Cuántos comentarios tiene cada proyecto? (incluye proyectos sin comentarios)
SELECT pr.titulo, COUNT(c.id) AS comentarios
FROM proyectos pr
LEFT JOIN interaccion_proyecto c ON c.id_proyecto = pr.id
GROUP BY pr.id, pr.titulo
ORDER BY comentarios DESC, pr.titulo;

-- [PC13] HU017  Sprint 2  Join + subconsultas (misma consulta que C24)
-- Pregunta: Qué mensajes contiene la conversación entre dos usuarios, en orden de envío?
SELECT r.username AS remitente, m.contenido, m.fecha_envio
FROM mensajes_privados m
JOIN conversaciones cv ON cv.id = m.id_conversacion
JOIN usuarios r        ON r.id  = m.remitente_id
WHERE cv.id_participante_uno = LEAST   ((SELECT id FROM usuarios WHERE username = 'LuisDev'),
                                        (SELECT id FROM usuarios WHERE username = 'PepitoDevPro'))
  AND cv.id_participante_dos = GREATEST((SELECT id FROM usuarios WHERE username = 'LuisDev'),
                                        (SELECT id FROM usuarios WHERE username = 'PepitoDevPro'))
ORDER BY m.fecha_envio;

-- [PC14] HU017  Sprint 2  Join + agregación (misma consulta que C26)
-- Pregunta: Cuáles son las conversaciones de un usuario, con su último mensaje y el total de mensajes?
SELECT otro.username AS conversacion_con,
       COUNT(m.id)            AS total_mensajes,
       MAX(m.fecha_envio)     AS ultimo_mensaje
FROM conversaciones cv
JOIN usuarios yo   ON yo.id IN (cv.id_participante_uno, cv.id_participante_dos)
JOIN usuarios otro ON otro.id IN (cv.id_participante_uno, cv.id_participante_dos)
                  AND otro.id <> yo.id
LEFT JOIN mensajes_privados m ON m.id_conversacion = cv.id
WHERE yo.username = 'LuisDev'
GROUP BY otro.username
ORDER BY ultimo_mensaje DESC;


-- PARTE C · CONSULTAS COMPLEMENTARIAS POR HU (SPRINT 1) 

-- [C01] HU001  Sprint 1  Filtro + agregación
-- Pregunta: Ya existe una cuenta registrada con este correo? (validación de correo duplicado, sin distinguir mayúsculas)
SELECT COUNT(*) AS cuentas_con_ese_correo
FROM usuarios
WHERE lower(email) = lower('pepito@devmail.com');

-- [C02] HU001  Sprint 1  Agregación
-- Pregunta: Cuántos usuarios se registraron cada mes?
SELECT date_trunc('month', fecha_registro)::date AS mes,
       COUNT(*)                                   AS usuarios_registrados
FROM usuarios
GROUP BY 1
ORDER BY 1;

-- [C03] HU001  Sprint 1  Join externo (anti-join)
-- Pregunta: Qué usuarios tienen cuenta pero aún no tienen credencial? (control de integridad del registro)
SELECT u.id, u.username, u.email
FROM usuarios u
LEFT JOIN credenciales c ON c.usuario_id = u.id
WHERE c.id IS NULL;

-- [C04] HU002  Sprint 1  Join + filtro
-- Pregunta: Qué cuentas están bloqueadas en este momento y hasta cuándo?
SELECT u.username, c.intentos_fallidos, c.bloqueado_hasta
FROM credenciales c
JOIN usuarios u ON u.id = c.usuario_id
WHERE c.bloqueado_hasta > now()
ORDER BY c.bloqueado_hasta;

-- [C05] HU002  Sprint 1  Join + filtro + expresión
-- Pregunta: Qué cuentas tienen intentos fallidos acumulados y cuántos les faltan para el bloqueo (límite 3)?
SELECT u.username,
       c.intentos_fallidos,
       GREATEST(3 - c.intentos_fallidos, 0) AS intentos_restantes
FROM credenciales c
JOIN usuarios u ON u.id = c.usuario_id
WHERE c.intentos_fallidos > 0
ORDER BY c.intentos_fallidos DESC;

-- [C06] HU003  Sprint 1  Join + subconsultas
-- Pregunta: Cuál es el perfil técnico completo de un usuario (nivel, bio, enlaces y habilidades)?
SELECT u.nombre || ' ' || u.apellido AS nombre_completo,
       u.email,
       p.nivel,
       p.bio,
       (SELECT string_agg(e.nombre_enlace || ': ' || e.url_enlace, ' | ' ORDER BY e.nombre_enlace)
          FROM enlaces_externos e WHERE e.id_perfil = p.id)   AS enlaces,
       (SELECT string_agg(t.nombre_tecnologia, ', ' ORDER BY t.nombre_tecnologia)
          FROM habilidades h
          JOIN tecnologias t ON t.id = h.id_tecnologia
         WHERE h.id_perfil = p.id)                            AS habilidades
FROM usuarios u
JOIN perfiles_usuario p ON p.id_usuario = u.id
WHERE u.username = 'LuisDev';

-- [C07] HU003  Sprint 1  Agregación
-- Pregunta: Cuántos usuarios hay por nivel de experiencia y cuál es el promedio de años de experiencia de cada nivel?
SELECT p.nivel,
       COUNT(*) AS usuarios,
       ROUND(AVG(EXTRACT(YEAR FROM now()) - p.anio_inicio_dev), 1) AS anios_experiencia_promedio
FROM perfiles_usuario p
GROUP BY p.nivel
ORDER BY CASE p.nivel WHEN 'ENTRY' THEN 1 WHEN 'JUNIOR' THEN 2 WHEN 'MID' THEN 3 ELSE 4 END;

-- [C08] HU003  Sprint 1  Join de 4 tablas + filtro
-- Pregunta: Qué desarrolladores dominan una tecnología dada (por ejemplo Java)?
SELECT u.username, p.nivel
FROM tecnologias t
JOIN habilidades h        ON h.id_tecnologia = t.id
JOIN perfiles_usuario p   ON p.id = h.id_perfil
JOIN usuarios u           ON u.id = p.id_usuario
WHERE t.nombre_tecnologia = 'Java'
ORDER BY u.username;

-- [C09] HU003  Sprint 1 Subconsultas NOT EXISTS
-- Pregunta: Qué usuarios tienen el perfil vacío (sin bio, sin enlaces ni habilidades), como un usuario recién registrado?
SELECT u.username
FROM usuarios u
JOIN perfiles_usuario p ON p.id_usuario = u.id
WHERE p.bio IS NULL
  AND NOT EXISTS (SELECT 1 FROM enlaces_externos e WHERE e.id_perfil = p.id)
  AND NOT EXISTS (SELECT 1 FROM habilidades h       WHERE h.id_perfil = p.id);

-- [C10] HU007  Sprint 1  Join de 4 tablas + agregación
-- Pregunta: Qué proyectos están publicados, quién es su autor y con qué tecnologías?
SELECT pr.titulo,
       u.username AS autor,
       pr.repositorio_url,
       string_agg(t.nombre_tecnologia, ', ' ORDER BY t.nombre_tecnologia) AS tecnologias
FROM proyectos pr
JOIN usuarios u                ON u.id = pr.usuario_id
JOIN proyecto_tecnologias pt   ON pt.id_proyecto = pr.id
JOIN tecnologias t             ON t.id = pt.id_tecnologia
GROUP BY pr.id, pr.titulo, u.username, pr.repositorio_url
ORDER BY pr.titulo;

-- [C11] HU007  Sprint 1  Join + agregación
-- Pregunta: Cuáles son las tecnologías más usadas en los proyectos publicados?
SELECT t.nombre_tecnologia, t.tipo, COUNT(*) AS proyectos
FROM proyecto_tecnologias pt
JOIN tecnologias t ON t.id = pt.id_tecnologia
GROUP BY t.id, t.nombre_tecnologia, t.tipo
ORDER BY proyectos DESC, t.nombre_tecnologia;

-- [C12] HU007  Sprint 1  Subconsulta NOT EXISTS
-- Pregunta: ¿Hay proyectos publicados sin ninguna tecnología? (regla: al menos una tecnología)
SELECT pr.id, pr.titulo
FROM proyectos pr
WHERE NOT EXISTS (SELECT 1 FROM proyecto_tecnologias pt WHERE pt.id_proyecto = pr.id);

-- [C13] HU011  Sprint 1  Join + agregación condicional
-- Pregunta: Cuántas discusiones hay por tecnología y cuántas siguen abiertas?
SELECT t.nombre_tecnologia,
       COUNT(*)                                       AS discusiones,
       COUNT(*) FILTER (WHERE d.estado = 'ABIERTA')   AS abiertas
FROM discusiones d
JOIN tecnologias t ON t.id = d.id_tecnologia
GROUP BY t.nombre_tecnologia
ORDER BY discusiones DESC, t.nombre_tecnologia;

-- [C14] HU011  Sprint 1 Join + filtro + orden
-- Pregunta: Cuáles son las discusiones más recientes de una tecnología, con su autor?
SELECT d.titulo, u.username AS autor, d.estado, d.fecha_creacion
FROM discusiones d
JOIN usuarios u     ON u.id = d.autor_id
JOIN tecnologias t  ON t.id = d.id_tecnologia
WHERE t.nombre_tecnologia = 'Spring Boot'
ORDER BY d.fecha_creacion DESC
LIMIT 10;


-- PARTE C · CONSULTAS COMPLEMENTARIAS POR HU (SPRINT 2) 

-- [C15] HU005 Sprint 2  Join (auto-relación)
-- Pregunta: A qué desarrolladores sigue un usuario (su lista de seguidos)?
SELECT s.username AS seguido, f.fecha_creacion AS desde
FROM seguidores f
JOIN usuarios yo ON yo.id = f.id_seguidor
JOIN usuarios s  ON s.id  = f.id_seguido
WHERE yo.username = 'LuisDev'
ORDER BY s.username;

-- [C16] HU005  Sprint 2  Subconsultas + agregación
-- Pregunta: Cuántos seguidores y cuántos seguidos tiene cada usuario?
SELECT u.username,
       (SELECT COUNT(*) FROM seguidores f WHERE f.id_seguido   = u.id) AS seguidores,
       (SELECT COUNT(*) FROM seguidores f WHERE f.id_seguidor  = u.id) AS seguidos
FROM usuarios u
ORDER BY seguidores DESC, u.username;

-- [C17] HU005  Sprint 2  UNION ALL + join de 4 tablas
-- Pregunta: Qué actividad (proyectos y discusiones) han publicado los desarrolladores que sigue un usuario? (feed)
SELECT actividad.tipo, actividad.titulo, u.username AS autor, actividad.fecha
FROM (
    SELECT 'PROYECTO'  AS tipo, pr.titulo, pr.usuario_id AS autor_id, pr.fecha_creacion AS fecha FROM proyectos pr
    UNION ALL
    SELECT 'DISCUSION' AS tipo, d.titulo,  d.autor_id,               d.fecha_creacion  AS fecha FROM discusiones d
) actividad
JOIN usuarios u       ON u.id = actividad.autor_id
JOIN seguidores f     ON f.id_seguido = actividad.autor_id
JOIN usuarios yo      ON yo.id = f.id_seguidor
WHERE yo.username = 'LuisDev'
ORDER BY actividad.fecha DESC;

-- [C18] HU010  Sprint 2  Join + filtro
-- Pregunta: Qué proyectos le han gustado a un usuario (su lista de likes)?
SELECT pr.titulo, l.fecha_creacion AS fecha_like
FROM likes_proyecto l
JOIN proyectos pr ON pr.id = l.id_proyecto
JOIN usuarios u   ON u.id  = l.id_usuario
WHERE u.username = 'AnaCoder'
ORDER BY l.fecha_creacion DESC;

-- [C19] HU010  Sprint 2  Join externo + agregación
-- Pregunta: Cuántos likes tiene cada proyecto? (ranking, incluye proyectos sin likes)
SELECT pr.titulo, COUNT(l.id_usuario) AS likes
FROM proyectos pr
LEFT JOIN likes_proyecto l ON l.id_proyecto = pr.id
GROUP BY pr.id, pr.titulo
ORDER BY likes DESC, pr.titulo;

-- [C20] HU012  Sprint 2  Join + agregación condicional
-- Pregunta: Cuántas discusiones abiertas y resueltas tiene cada autor?
SELECT u.username,
       COUNT(*) FILTER (WHERE d.estado = 'ABIERTA')   AS abiertas,
       COUNT(*) FILTER (WHERE d.estado = 'RESUELTA')  AS resueltas
FROM discusiones d
JOIN usuarios u ON u.id = d.autor_id
GROUP BY u.username
ORDER BY u.username;

-- [C21] HU012  Sprint 2 Producto cruzado controlado + expresiones
-- Pregunta: Puede un usuario marcar como resuelta una discusión? (existe, es abierta y es el autor)
SELECT d.titulo,
       d.estado,
       (d.autor_id = u.id)                    AS es_autor,
       (d.estado = 'ABIERTA' AND d.autor_id = u.id) AS puede_resolver
FROM discusiones d
CROSS JOIN usuarios u
WHERE u.username = 'LuisDev'
ORDER BY d.titulo;

-- [C22] HU013  Sprint 2  Join + filtro + orden
-- Pregunta: Qué comentarios tiene un proyecto, con su autor y fecha de publicación?
SELECT u.username AS autor, c.comentario, c.fecha_creacion
FROM interaccion_proyecto c
JOIN usuarios u   ON u.id = c.id_usuario
JOIN proyectos pr ON pr.id = c.id_proyecto
WHERE pr.titulo = 'DevConnect'
ORDER BY c.fecha_creacion;

-- [C23] HU013  Sprint 2  Join externo + agregación
-- Pregunta: Cuántos comentarios tiene cada proyecto? (incluye proyectos sin comentarios)
SELECT pr.titulo, COUNT(c.id) AS comentarios
FROM proyectos pr
LEFT JOIN interaccion_proyecto c ON c.id_proyecto = pr.id
GROUP BY pr.id, pr.titulo
ORDER BY comentarios DESC, pr.titulo;

-- [C24] HU017  Sprint 2  Join + subconsultas
-- Pregunta: Qué mensajes contiene la conversación entre dos usuarios, en orden de envío?
SELECT r.username AS remitente, m.contenido, m.fecha_envio
FROM mensajes_privados m
JOIN conversaciones cv ON cv.id = m.id_conversacion
JOIN usuarios r        ON r.id  = m.remitente_id
WHERE cv.id_participante_uno = LEAST   ((SELECT id FROM usuarios WHERE username = 'LuisDev'),
                                        (SELECT id FROM usuarios WHERE username = 'PepitoDevPro'))
  AND cv.id_participante_dos = GREATEST((SELECT id FROM usuarios WHERE username = 'LuisDev'),
                                        (SELECT id FROM usuarios WHERE username = 'PepitoDevPro'))
ORDER BY m.fecha_envio;

-- [C25] HU017  Sprint 2  Join + filtro (control de acceso)
-- Pregunta: Tiene un usuario acceso a la conversación entre otros dos? (0 filas = 'No tienes acceso a esta conversación')
SELECT cv.id
FROM conversaciones cv
JOIN usuarios u ON u.id IN (cv.id_participante_uno, cv.id_participante_dos)
WHERE u.username = 'AnaCoder'
  AND cv.id = 'e0000000-0000-0000-0000-000000000001';

-- [C26] HU017  Sprint 2  Join + agregación
-- Pregunta: Cuáles son las conversaciones de un usuario, con su último mensaje y el total de mensajes?
SELECT otro.username AS conversacion_con,
       COUNT(m.id)            AS total_mensajes,
       MAX(m.fecha_envio)     AS ultimo_mensaje
FROM conversaciones cv
JOIN usuarios yo   ON yo.id IN (cv.id_participante_uno, cv.id_participante_dos)
JOIN usuarios otro ON otro.id IN (cv.id_participante_uno, cv.id_participante_dos)
                  AND otro.id <> yo.id
LEFT JOIN mensajes_privados m ON m.id_conversacion = cv.id
WHERE yo.username = 'LuisDev'
GROUP BY otro.username
ORDER BY ultimo_mensaje DESC;

-- [C27] Transversal  Sprint 2  Subconsultas correlacionadas
-- Pregunta: Cuánta actividad tiene cada usuario? (proyectos, discusiones, comentarios, likes dados y seguidores)
SELECT u.username,
       (SELECT COUNT(*) FROM proyectos p              WHERE p.usuario_id = u.id)  AS proyectos,
       (SELECT COUNT(*) FROM discusiones d            WHERE d.autor_id   = u.id)  AS discusiones,
       (SELECT COUNT(*) FROM interaccion_proyecto c   WHERE c.id_usuario = u.id)  AS comentarios,
       (SELECT COUNT(*) FROM likes_proyecto l         WHERE l.id_usuario = u.id)  AS likes_dados,
       (SELECT COUNT(*) FROM seguidores f             WHERE f.id_seguido = u.id)  AS seguidores
FROM usuarios u
ORDER BY proyectos DESC, u.username;
