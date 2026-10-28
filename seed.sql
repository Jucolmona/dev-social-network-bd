
-- Datos semilla (SOLO DEMO / PRUEBAS)
-- Requiere haber ejecutado schema.sql. UUID fijos para que las consultas
-- sean reproducibles.  Los password_hash NO son hashes reales: no sirven
-- para iniciar sesion (el registro real se hace por la API).


-- ---- Catalogo de tecnologias (HU003, HU007, HU011) -------------------
-- Nota: el tipo no admite 'HERRAMIENTA'; Docker se registra como FRAMEWORK
-- de forma aproximada porque HU011 habla de "tecnologia o herramienta".
INSERT INTO tecnologias (id, nombre_tecnologia, tipo) VALUES
 ('10000000-0000-0000-0000-000000000001','Backend Developer','ROL'),
 ('10000000-0000-0000-0000-000000000002','Frontend Developer','ROL'),
 ('10000000-0000-0000-0000-000000000003','Full Stack Developer','ROL'),
 ('10000000-0000-0000-0000-000000000004','DevOps Engineer','ROL'),
 ('10000000-0000-0000-0000-000000000005','Java','LENGUAJE'),
 ('10000000-0000-0000-0000-000000000006','Python','LENGUAJE'),
 ('10000000-0000-0000-0000-000000000007','JavaScript','LENGUAJE'),
 ('10000000-0000-0000-0000-000000000008','TypeScript','LENGUAJE'),
 ('10000000-0000-0000-0000-000000000009','SQL','LENGUAJE'),
 ('10000000-0000-0000-0000-000000000010','Spring Boot','FRAMEWORK'),
 ('10000000-0000-0000-0000-000000000011','React','FRAMEWORK'),
 ('10000000-0000-0000-0000-000000000012','Angular','FRAMEWORK'),
 ('10000000-0000-0000-0000-000000000013','Django','FRAMEWORK'),
 ('10000000-0000-0000-0000-000000000014','Docker','FRAMEWORK');

-- ---- Usuarios (HU001) -------------------------------------------------
INSERT INTO usuarios (id, nombre, apellido, username, email, fecha_registro) VALUES
 ('a0000000-0000-0000-0000-000000000001','Luis','Gomez','LuisDev','luis@devmail.com', now() - interval '90 days'),
 ('a0000000-0000-0000-0000-000000000002','Pepito','Perez','PepitoDevPro','pepito@devmail.com', now() - interval '60 days'),
 ('a0000000-0000-0000-0000-000000000003','Ana','Ramirez','AnaCoder','ana@devmail.com', now() - interval '45 days'),
 ('a0000000-0000-0000-0000-000000000004','Maria','Lopez','MariaTech','maria@devmail.com', now() - interval '10 days'),
 ('a0000000-0000-0000-0000-000000000005','Carlos','Diaz','CarlosBack','carlos@devmail.com', now() - interval '2 days');

-- ---- Credenciales (HU001, HU002) --------------------------------------
INSERT INTO credenciales (usuario_id, tipo, password_hash, intentos_fallidos, bloqueado_hasta) VALUES
 ('a0000000-0000-0000-0000-000000000001','LOCAL','HASH_DEMO_NO_VALIDO',0,NULL),
 ('a0000000-0000-0000-0000-000000000002','LOCAL','HASH_DEMO_NO_VALIDO',1,NULL),
 ('a0000000-0000-0000-0000-000000000003','LOCAL','HASH_DEMO_NO_VALIDO',0,NULL),
 ('a0000000-0000-0000-0000-000000000004','LOCAL','HASH_DEMO_NO_VALIDO',3, now() + interval '7 days'),
 ('a0000000-0000-0000-0000-000000000005','LOCAL','HASH_DEMO_NO_VALIDO',0,NULL);

-- ---- Perfiles, enlaces y habilidades (HU003) --------------------------
INSERT INTO perfiles_usuario (id, id_usuario, bio, nivel_completado, enlace_portafolio, anio_inicio_dev, nivel) VALUES
 ('b0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','Backend con Spring Boot',80,'https://luis.dev', EXTRACT(YEAR FROM now())::int - 5,'MID'),
 ('b0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000002','Full stack apasionado',90,'https://pepito.dev', EXTRACT(YEAR FROM now())::int - 12,'SENIOR'),
 ('b0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000003','Frontend con React',60,NULL, EXTRACT(YEAR FROM now())::int - 2,'JUNIOR'),
 ('b0000000-0000-0000-0000-000000000004','a0000000-0000-0000-0000-000000000004',NULL,10,NULL,NULL,'ENTRY'),
 ('b0000000-0000-0000-0000-000000000005','a0000000-0000-0000-0000-000000000005',NULL,0,NULL,NULL,'ENTRY');

INSERT INTO enlaces_externos (id_perfil, nombre_enlace, url_enlace) VALUES
 ('b0000000-0000-0000-0000-000000000001','GITHUB','https://github.com/luisdev'),
 ('b0000000-0000-0000-0000-000000000001','LINKEDIN','https://www.linkedin.com/in/luisdev/'),
 ('b0000000-0000-0000-0000-000000000002','GITHUB','https://github.com/pepitodevpro'),
 ('b0000000-0000-0000-0000-000000000003','GITHUB','https://github.com/anacoder');

INSERT INTO habilidades (id_perfil, id_tecnologia) VALUES
 ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001'),
 ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000005'),
 ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000010'),
 ('b0000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003'),
 ('b0000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000005'),
 ('b0000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000011'),
 ('b0000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002'),
 ('b0000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000007'),
 ('b0000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000011');

-- ---- Proyectos y sus tecnologias (HU007) -------------------------------
INSERT INTO proyectos (id, usuario_id, titulo, descripcion, repositorio_url, fecha_creacion) VALUES
 ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','DevConnect','Red social para desarrolladores con arquitectura hexagonal','https://github.com/luisdev/devconnect', now() - interval '30 days'),
 ('c0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000002','TaskFlow','Gestor de tareas con React y Spring Boot','https://gitlab.com/pepito/taskflow', now() - interval '20 days'),
 ('c0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000003','Portafolio Ana','Sitio personal con React','https://bitbucket.org/ana/portafolio', now() - interval '5 days');

INSERT INTO proyecto_tecnologias (id_proyecto, id_tecnologia) VALUES
 ('c0000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000005'),
 ('c0000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000010'),
 ('c0000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000005'),
 ('c0000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000010'),
 ('c0000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000011'),
 ('c0000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000011');

-- ---- Discusiones (HU011, HU012) ---------------------------------------
INSERT INTO discusiones (id, titulo, autor_id, contenido, estado, fecha_creacion, id_tecnologia) VALUES
 ('d0000000-0000-0000-0000-000000000001','¿Cómo configurar CORS en Spring?','a0000000-0000-0000-0000-000000000001','Necesito permitir el origen del frontend en Spring Boot.','ABIERTA', now() - interval '3 days','10000000-0000-0000-0000-000000000010'),
 ('d0000000-0000-0000-0000-000000000002','Error en Docker Compose','a0000000-0000-0000-0000-000000000002','El servicio no levanta con depends_on.','ABIERTA', now() - interval '2 days','10000000-0000-0000-0000-000000000014'),
 ('d0000000-0000-0000-0000-000000000003','¿Hooks o clases en React?','a0000000-0000-0000-0000-000000000003','Dudas sobre el estado en componentes.','RESUELTA', now() - interval '8 days','10000000-0000-0000-0000-000000000011');

INSERT INTO interaccion_discusion (id_discusion, id_usuario, comentario) VALUES
 ('d0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000002','Usa hooks, son el estándar actual.'),
 ('d0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','Revisa WebMvcConfigurer.addCorsMappings.');

-- ---- Comentarios en proyectos (HU013): DevConnect con 3 comentarios ---
INSERT INTO interaccion_proyecto (id_proyecto, id_usuario, comentario, fecha_creacion) VALUES
 ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','Muy buen proyecto', now() - interval '25 days'),
 ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000003','Me gustó la estructura de paquetes', now() - interval '24 days'),
 ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000004','¿Piensas agregar tests de integración?', now() - interval '20 days'),
 ('c0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001','Buen uso de React', now() - interval '10 days');

-- ---- Seguidores (HU005) -----------------------------------------------
INSERT INTO seguidores (id_seguidor, id_seguido) VALUES
 ('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002'),
 ('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000003'),
 ('a0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000002'),
 ('a0000000-0000-0000-0000-000000000004','a0000000-0000-0000-0000-000000000001');

-- ---- Likes (HU010) -----------------------------------------------------
INSERT INTO likes_proyecto (id_proyecto, id_usuario) VALUES
 ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002'),
 ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000003'),
 ('c0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001'),
 ('c0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000003');

-- ---- Mensajeria privada (HU017) ---------------------------------------
-- Conversacion Luis(...01) - Pepito(...02): participante_uno - participante_dos
INSERT INTO conversaciones (id, id_participante_uno, id_participante_dos) VALUES
 ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002');

INSERT INTO mensajes_privados (id_conversacion, remitente_id, destinatario_id, contenido, fecha_envio) VALUES
 ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','Hola', now() - interval '2 hours'),
 ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001','¿Colaboramos en el módulo de pagos?', now() - interval '1 hour'),
 ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','Claro, ¿tienes tiempo esta semana?', now() - interval '30 minutes');
