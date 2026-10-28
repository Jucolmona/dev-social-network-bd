
-- seguridad.sql - Roles y privilegios de CodeF@ctory (Sprint 2)
-- Ejecutar DESPUES de schema.sql, con el rol propietario de las tablas
-- (por ejemplo postgres). Se puede ejecutar varias veces.
-- Principio: minimo privilegio. Nadie tiene acceso por defecto (PUBLIC).


-- 1. Cerrar el acceso por defecto
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;

-- 2. Roles de grupo (sin LOGIN): contienen los privilegios
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['rol_autenticacion','rol_administracion','rol_consultas','rol_analista'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN', r);
    END IF;
  END LOOP;
END $$;

-- 3. Usuarios de conexion (con LOGIN): heredan de un unico rol de grupo.
--    CAMBIAR las contrasenas antes de desplegar y guardarlas como secretos.
DO $$
DECLARE u text; g text;
BEGIN
  FOR u, g IN VALUES ('svc_autenticacion','rol_autenticacion'), ('svc_administracion','rol_administracion'),
                     ('svc_consultas','rol_consultas'), ('usr_analista','rol_analista') LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = u) THEN
      EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE', u, 'CAMBIAR_ANTES_DE_DESPLEGAR');
    END IF;
    EXECUTE format('GRANT %I TO %I', g, u);
  END LOOP;
END $$;

ALTER ROLE svc_autenticacion  CONNECTION LIMIT 10;
ALTER ROLE svc_administracion CONNECTION LIMIT 20;
ALTER ROLE svc_consultas      CONNECTION LIMIT 10;
ALTER ROLE usr_analista       CONNECTION LIMIT 3;
ALTER ROLE usr_analista       SET statement_timeout = '30s';

-- 4. Privilegios por rol (se revoca primero para que el script sea repetible)
GRANT USAGE ON SCHEMA public TO rol_autenticacion, rol_administracion, rol_consultas, rol_analista;

-- rol_autenticacion
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rol_autenticacion;
GRANT SELECT (id, email, username) ON usuarios TO rol_autenticacion;
GRANT SELECT, INSERT, UPDATE ON credenciales TO rol_autenticacion;

-- rol_administracion
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rol_administracion;
GRANT SELECT, INSERT, UPDATE ON usuarios TO rol_administracion;
GRANT SELECT, INSERT, UPDATE ON perfiles_usuario TO rol_administracion;
GRANT SELECT, INSERT, UPDATE, DELETE ON enlaces_externos TO rol_administracion;
GRANT SELECT ON tecnologias TO rol_administracion;
GRANT SELECT, INSERT, DELETE ON habilidades TO rol_administracion;
GRANT SELECT, INSERT, UPDATE, DELETE ON proyectos TO rol_administracion;
GRANT SELECT, INSERT, DELETE ON proyecto_tecnologias TO rol_administracion;
GRANT SELECT, INSERT, UPDATE ON discusiones TO rol_administracion;
GRANT SELECT, INSERT ON interaccion_discusion TO rol_administracion;
GRANT SELECT, INSERT ON interaccion_proyecto TO rol_administracion;
GRANT SELECT, INSERT, DELETE ON seguidores TO rol_administracion;
GRANT SELECT, INSERT, DELETE ON likes_proyecto TO rol_administracion;
GRANT SELECT, INSERT ON conversaciones TO rol_administracion;
GRANT SELECT, INSERT ON mensajes_privados TO rol_administracion;

-- rol_consultas
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rol_consultas;
GRANT SELECT (id, nombre, apellido, username, fecha_registro) ON usuarios TO rol_consultas;
GRANT SELECT ON perfiles_usuario TO rol_consultas;
GRANT SELECT ON enlaces_externos TO rol_consultas;
GRANT SELECT ON tecnologias TO rol_consultas;
GRANT SELECT ON habilidades TO rol_consultas;
GRANT SELECT ON proyectos TO rol_consultas;
GRANT SELECT ON proyecto_tecnologias TO rol_consultas;
GRANT SELECT ON discusiones TO rol_consultas;
GRANT SELECT ON interaccion_discusion TO rol_consultas;
GRANT SELECT ON interaccion_proyecto TO rol_consultas;
GRANT SELECT ON seguidores TO rol_consultas;
GRANT SELECT ON likes_proyecto TO rol_consultas;

-- rol_analista
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rol_analista;
GRANT SELECT (id, username, fecha_registro) ON usuarios TO rol_analista;
GRANT SELECT (usuario_id, intentos_fallidos, bloqueado_hasta) ON credenciales TO rol_analista;
GRANT SELECT ON perfiles_usuario TO rol_analista;
GRANT SELECT ON tecnologias TO rol_analista;
GRANT SELECT ON habilidades TO rol_analista;
GRANT SELECT ON proyectos TO rol_analista;
GRANT SELECT ON proyecto_tecnologias TO rol_analista;
GRANT SELECT ON discusiones TO rol_analista;
GRANT SELECT ON interaccion_discusion TO rol_analista;
GRANT SELECT ON interaccion_proyecto TO rol_analista;
GRANT SELECT ON seguidores TO rol_analista;
GRANT SELECT ON likes_proyecto TO rol_analista;
GRANT SELECT (id, fecha_creacion) ON conversaciones TO rol_analista;
GRANT SELECT (id, id_conversacion, fecha_envio) ON mensajes_privados TO rol_analista;

-- 5. Documentacion en el catalogo
COMMENT ON ROLE rol_autenticacion  IS 'Servicio de autenticacion: credenciales y lectura minima de usuarios';
COMMENT ON ROLE rol_administracion IS 'Servicio de administracion: escritura sobre el negocio; sin acceso a credenciales';
COMMENT ON ROLE rol_consultas      IS 'Servicio de consultas/feed: solo lectura, sin credenciales ni mensajes';
COMMENT ON ROLE rol_analista       IS 'Reportes: solo lectura por columnas, sin hashes ni contenido de mensajes';
