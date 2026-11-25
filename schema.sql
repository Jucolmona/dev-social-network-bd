
-- schema.sql -  Sprint 2
-- Script de estructuras (sin datos semilla).
-- Motor: PostgreSQL 14+.  Ejecutable sobre una BD vacia.
-- Orden: tablas padre -> tablas hijas (dependencias de claves foraneas).
--
-- Cambios frente al Sprint 1 (ver README, seccion "Cambios del Sprint 2"):
--   [+] Tablas nuevas: seguidores (HU005), likes_proyecto (HU010),
--       conversaciones y mensajes_privados (HU017).
--   [+] CHECK que trasladan a la BD reglas de los criterios de aceptacion
--       (HU007, HU011, HU013, HU017, HU005).
--   [+] Indices sobre claves foraneas usadas en joins (habilidades,
--       proyecto_tecnologias, seguidores, likes, mensajes).
--   [-] Se retiran idx_usuarios_email e idx_credenciales_usuario_id:
--       eran redundantes (UNIQUE ya crea un indice equivalente).
--
-- Cambios del Sprint 3 (ver README, "Cambios respecto al Sprint 2"):
--   [+] Tablas nuevas: votos_comentario (votar comentarios), respuestas_comentario (HU014),
--       conversation_read_states (HU018) y usuarios_bloqueados (HU019).
--   [+] Triggers y funciones por historia de usuario: secciones 20 (HU014) y 21 (HU018, HU019, votar comentarios).


CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()



-- 1. USUARIOS  (HU001)

CREATE TABLE usuarios (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          VARCHAR(100),
    apellido        VARCHAR(100),
    username        VARCHAR(50)  UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    fecha_registro  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_usuario_email CHECK (btrim(email) <> '')
);
COMMENT ON TABLE usuarios IS 'Cuenta de usuario/desarrollador de la plataforma (HU001).';




-- 2. CREDENCIALES  (HU001, HU002: intentos fallidos y bloqueo)

CREATE TABLE credenciales (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id            UUID NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo                  VARCHAR(30)  NOT NULL DEFAULT 'LOCAL',
    password_hash         VARCHAR(255),
    proveedor_id_externo  VARCHAR(255),
    intentos_fallidos     INT NOT NULL DEFAULT 0,
    bloqueado_hasta       TIMESTAMP WITH TIME ZONE,

    CONSTRAINT chk_credencial_tipo      CHECK (tipo = 'LOCAL' OR tipo LIKE 'OAUTH\_%'),
    CONSTRAINT chk_credencial_intentos  CHECK (intentos_fallidos >= 0),
    CONSTRAINT chk_credencial_local     CHECK (tipo <> 'LOCAL' OR password_hash IS NOT NULL)
);
COMMENT ON COLUMN credenciales.bloqueado_hasta IS 'HU002: 3 intentos fallidos bloquean la cuenta 5 minutos.';



-- 3. PERFILES DE USUARIO  (HU003)

CREATE TABLE perfiles_usuario (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario          UUID NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_creacion      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    bio                 VARCHAR(500),
    nivel_completado    NUMERIC(5,2) DEFAULT 0,
    enlace_portafolio   VARCHAR(255),
    anio_inicio_dev     INT,
    nivel               VARCHAR(20) NOT NULL DEFAULT 'ENTRY',

    CONSTRAINT chk_perfil_nivel      CHECK (nivel IN ('ENTRY', 'JUNIOR', 'MID', 'SENIOR')),
    CONSTRAINT chk_perfil_completado CHECK (nivel_completado BETWEEN 0 AND 100)
);
COMMENT ON COLUMN perfiles_usuario.anio_inicio_dev IS 'Anio en que inicio como desarrollador; los anios de experiencia (0-20, HU003) se derivan.';



-- 4. ENLACES EXTERNOS  (HU003: GitHub, LinkedIn, portafolio)

CREATE TABLE enlaces_externos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_perfil       UUID NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    nombre_enlace   VARCHAR(50)  NOT NULL,
    url_enlace      VARCHAR(255) NOT NULL
);
CREATE INDEX idx_enlaces_perfil ON enlaces_externos(id_perfil);



-- 5. TECNOLOGIAS  (catalogo global de roles, lenguajes y frameworks)

CREATE TABLE tecnologias (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_tecnologia   VARCHAR(100) NOT NULL UNIQUE,
    tipo                VARCHAR(20)  NOT NULL,

    CONSTRAINT chk_tecnologia_tipo CHECK (tipo IN ('ROL', 'LENGUAJE', 'FRAMEWORK'))
);
COMMENT ON TABLE tecnologias IS 'Catalogo global validado por HU003 (habilidades), HU007 (proyectos) y HU011 (discusiones).';




-- 6. HABILIDADES  (N:M perfil <-> tecnologia)  (HU003)

CREATE TABLE habilidades (
    id_perfil       UUID NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    id_tecnologia   UUID NOT NULL REFERENCES tecnologias(id)      ON DELETE CASCADE,

    PRIMARY KEY (id_perfil, id_tecnologia)
);
CREATE INDEX idx_habilidades_tecnologia ON habilidades(id_tecnologia);



-- 7. PROYECTOS  (HU007)

CREATE TABLE proyectos (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id            UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    titulo                VARCHAR(50)  NOT NULL,
    descripcion           VARCHAR(250) NOT NULL,
    repositorio_url       VARCHAR(255),
    fecha_creacion        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultima_actualizacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_proyecto_titulo      CHECK (btrim(titulo) <> ''),
    CONSTRAINT chk_proyecto_descripcion CHECK (btrim(descripcion) <> ''),
    CONSTRAINT chk_proyecto_repositorio CHECK (
        repositorio_url IS NULL
        OR repositorio_url ~* '^https?://(www\.)?(github\.com|gitlab\.com|bitbucket\.org)/.+'
    )
);
CREATE INDEX idx_proyectos_usuario ON proyectos(usuario_id);
COMMENT ON COLUMN proyectos.repositorio_url IS 'HU007: dominio permitido GitHub, GitLab o Bitbucket.';



-- 8. PROYECTO_TECNOLOGIAS  (N:M proyecto <-> tecnologia)  (HU007)

CREATE TABLE proyecto_tecnologias (
    id_proyecto     UUID NOT NULL REFERENCES proyectos(id)   ON DELETE CASCADE,
    id_tecnologia   UUID NOT NULL REFERENCES tecnologias(id) ON DELETE CASCADE,

    PRIMARY KEY (id_proyecto, id_tecnologia)
);
CREATE INDEX idx_proyecto_tecnologias_tecnologia ON proyecto_tecnologias(id_tecnologia);



-- 9. DISCUSIONES  (HU011, HU012)

CREATE TABLE discusiones (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo                VARCHAR(150) NOT NULL,
    autor_id              UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    contenido             TEXT NOT NULL,
    estado                VARCHAR(20) NOT NULL DEFAULT 'ABIERTA',
    fecha_creacion        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultima_actualizacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_tecnologia         UUID NOT NULL REFERENCES tecnologias(id),

    CONSTRAINT chk_discusion_estado    CHECK (estado IN ('ABIERTA', 'RESUELTA')),
    CONSTRAINT chk_discusion_titulo    CHECK (btrim(titulo) <> ''),
    CONSTRAINT chk_discusion_contenido CHECK (btrim(contenido) <> '')
);
CREATE INDEX idx_discusiones_autor      ON discusiones(autor_id);
CREATE INDEX idx_discusiones_tecnologia ON discusiones(id_tecnologia);



-- 10. INTERACCION_DISCUSION  (comentarios en discusiones)

CREATE TABLE interaccion_discusion (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_discusion    UUID NOT NULL REFERENCES discusiones(id) ON DELETE CASCADE,
    id_usuario      UUID NOT NULL REFERENCES usuarios(id)    ON DELETE CASCADE,
    comentario      TEXT NOT NULL,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_interaccion_disc_comentario CHECK (btrim(comentario) <> '')
);
CREATE INDEX idx_interaccion_discusion ON interaccion_discusion(id_discusion);


-- 11. INTERACCION_PROYECTO  (HU013: comentarios en proyectos)

CREATE TABLE interaccion_proyecto (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_proyecto     UUID NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    id_usuario      UUID NOT NULL REFERENCES usuarios(id)  ON DELETE CASCADE,
    comentario      TEXT NOT NULL,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_interaccion_proy_comentario CHECK (
        btrim(comentario) <> '' AND char_length(comentario) <= 1000
    )
);
CREATE INDEX idx_interaccion_proyecto ON interaccion_proyecto(id_proyecto);
COMMENT ON COLUMN interaccion_proyecto.comentario IS 'HU013: no vacio y maximo 1000 caracteres.';

-- 12. SEGUIDORES  (HU005)  [NUEVA EN SPRINT 2]
--     Relacion N:M reflexiva usuarios <-> usuarios.

CREATE TABLE seguidores (
    id_seguidor     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    id_seguido      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_seguidor, id_seguido),                       -- no seguir dos veces
    CONSTRAINT chk_seguidores_no_a_si_mismo CHECK (id_seguidor <> id_seguido)
);
CREATE INDEX idx_seguidores_seguido ON seguidores(id_seguido);   -- "quienes me siguen" y feed


-- 13. LIKES_PROYECTO  (HU010)  [NUEVA EN SPRINT 2]

CREATE TABLE likes_proyecto (
    id_proyecto     UUID NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    id_usuario      UUID NOT NULL REFERENCES usuarios(id)  ON DELETE CASCADE,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_proyecto, id_usuario)                        -- un like por usuario y proyecto
);
CREATE INDEX idx_likes_proyecto_usuario ON likes_proyecto(id_usuario);   -- "mi lista de likes"


-- 14. CONVERSACIONES  (HU017)  [NUEVA EN SPRINT 2]
--     Una sola conversacion por pareja: los participantes se guardan
--     ordenados (uno < dos), asi (A,B) y (B,A) son la misma fila.

CREATE TABLE conversaciones (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_participante_uno   UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    id_participante_dos   UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_creacion        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_conversacion_participantes UNIQUE (id_participante_uno, id_participante_dos),
    CONSTRAINT chk_conversacion_orden        CHECK (id_participante_uno < id_participante_dos)
);
CREATE INDEX idx_conversaciones_participante_dos ON conversaciones(id_participante_dos);


-- 15. MENSAJES_PRIVADOS  (HU017)  [NUEVA EN SPRINT 2]

CREATE TABLE mensajes_privados (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_conversacion  UUID NOT NULL REFERENCES conversaciones(id) ON DELETE CASCADE,
    remitente_id     UUID NOT NULL REFERENCES usuarios(id)       ON DELETE CASCADE,
    destinatario_id  UUID NOT NULL REFERENCES usuarios(id)       ON DELETE CASCADE,
    contenido        VARCHAR(2000) NOT NULL,
    fecha_envio      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_mensaje_contenido     CHECK (btrim(contenido) <> ''),
    CONSTRAINT chk_mensaje_no_a_si_mismo CHECK (remitente_id <> destinatario_id)
);
CREATE INDEX idx_mensajes_conversacion ON mensajes_privados(id_conversacion, fecha_envio);
CREATE INDEX idx_mensajes_destinatario ON mensajes_privados(destinatario_id);
COMMENT ON COLUMN mensajes_privados.contenido IS 'HU017: no vacio y maximo 2000 caracteres.';


-- 16. VOTOS_COMENTARIO  (HU: votar comentarios)  [NUEVA EN SPRINT 3]
--     Un voto positivo por usuario y comentario de proyecto.

CREATE TABLE votos_comentario (
    id_comentario   UUID NOT NULL REFERENCES interaccion_proyecto(id) ON DELETE CASCADE,
    id_usuario      UUID NOT NULL REFERENCES usuarios(id)             ON DELETE CASCADE,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_comentario, id_usuario)
);
CREATE INDEX idx_votos_comentario_usuario ON votos_comentario(id_usuario);
COMMENT ON TABLE votos_comentario IS 'Voto positivo de un usuario a un comentario de proyecto; la clave primaria impide votar dos veces.';


-- 17. RESPUESTAS_COMENTARIO  (HU014: respuestas a un comentario, en hilo)  [NUEVA EN SPRINT 3]
--      Un comentario de proyecto tiene 0..N respuestas; cada respuesta es de un usuario.
--      Tabla aparte (no una columna padre en interaccion_proyecto): asi el listado de
--      comentarios de HU013 no cambia y el conteo de respuestas es una consulta directa.

CREATE TABLE respuestas_comentario (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_comentario   UUID NOT NULL REFERENCES interaccion_proyecto(id) ON DELETE CASCADE,
    id_usuario      UUID NOT NULL REFERENCES usuarios(id)             ON DELETE CASCADE,
    respuesta       TEXT NOT NULL,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_respuesta_comentario CHECK (
        btrim(respuesta) <> '' AND char_length(respuesta) <= 1000
    )
);
-- Cubre "respuestas de un comentario en orden cronologico" y el conteo por comentario.
CREATE INDEX idx_respuestas_comentario ON respuestas_comentario(id_comentario, fecha_creacion);
COMMENT ON TABLE respuestas_comentario IS 'HU014: respuesta de un usuario a un comentario de proyecto.';
COMMENT ON COLUMN respuestas_comentario.respuesta IS 'HU014: no vacia y maximo 1000 caracteres.';

-- 18. CONVERSATION_READ_STATES  (HU018: mensajes no leidos)  [NUEVA EN SPRINT 3]
--     Hasta que momento leyo cada participante cada conversacion. Un mensaje recibido
--     es "no leido" si es posterior a fecha_ultima_lectura (o si no hay fila).
--     Nombres de tabla y columnas iguales a los que ya mapea el backend (ConversationReadStateEntity).

CREATE TABLE conversation_read_states (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_conversacion       UUID NOT NULL REFERENCES conversaciones(id) ON DELETE CASCADE,
    id_usuario            UUID NOT NULL REFERENCES usuarios(id)       ON DELETE CASCADE,
    fecha_ultima_lectura  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_read_state_conversation_user UNIQUE (id_conversacion, id_usuario)
);
CREATE INDEX idx_read_states_usuario ON conversation_read_states(id_usuario);
COMMENT ON TABLE conversation_read_states IS 'HU018: ultimo momento de lectura de un usuario en una conversacion; base del conteo de mensajes no leidos.';


-- 19. USUARIOS_BLOQUEADOS  (HU019: bloquear usuario)  [NUEVA EN SPRINT 3]
--     Bloqueo direccional (blocker_id bloquea a blocked_id); la restriccion de
--     mensajes es mutua: se aplica si cualquiera de los dos bloqueo al otro.
--     Nombres iguales a los de UsuarioBloqueadoEntity del backend.

CREATE TABLE usuarios_bloqueados (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    blocked_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_bloqueo  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_bloqueo_par             UNIQUE (blocker_id, blocked_id),
    CONSTRAINT chk_bloqueo_no_a_si_mismo  CHECK (blocker_id <> blocked_id)
);
-- uq_bloqueo_par cubre la busqueda por blocker_id; este cubre la inversa (quien me bloqueo).
CREATE INDEX idx_bloqueos_bloqueado ON usuarios_bloqueados(blocked_id);
COMMENT ON TABLE usuarios_bloqueados IS 'HU019: bloqueo direccional entre usuarios; impide mensajes en ambos sentidos.';


-- ---------------------------------------------------------------------
-- 20. TRIGGERS Y PROCEDIMIENTOS (HU014 - Sprint 3)
-- Cada objeto indica la HU que atiende. Documentacion y ejemplos en el README
-- (apartado "Triggers y procedimientos").
-- ---------------------------------------------------------------------

-- TRIGGER 1 (HU014, escenarios 4 y 5): normaliza el texto de la respuesta.
-- BEFORE INSERT: quita los espacios al inicio y al final antes de validar. Como el CHECK
-- chk_respuesta_comentario se evalua despues, una respuesta en blanco queda vacia y se rechaza,
-- y el limite de 1000 caracteres se cuenta sobre el texto ya recortado.
CREATE OR REPLACE FUNCTION fn_trg_respuesta_normaliza() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.respuesta := btrim(NEW.respuesta);
    RETURN NEW;
END $$;

CREATE TRIGGER trg_respuesta_normaliza
    BEFORE INSERT ON respuestas_comentario
    FOR EACH ROW EXECUTE FUNCTION fn_trg_respuesta_normaliza();

-- TRIGGER 2 (HU014, integridad del hilo): una respuesta no se puede mover a otro comentario, ni cambiar de autor o de fecha.
-- BEFORE UPDATE de esas columnas: protege la integridad del hilo.
CREATE OR REPLACE FUNCTION fn_trg_respuesta_inmutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Una respuesta no puede cambiar de comentario, de autor ni de fecha de creacion'
        USING ERRCODE = 'integrity_constraint_violation';
END $$;

CREATE TRIGGER trg_respuesta_inmutable
    BEFORE UPDATE OF id_comentario, id_usuario, fecha_creacion ON respuestas_comentario
    FOR EACH ROW
    WHEN (OLD.id_comentario IS DISTINCT FROM NEW.id_comentario
       OR OLD.id_usuario    IS DISTINCT FROM NEW.id_usuario
       OR OLD.fecha_creacion IS DISTINCT FROM NEW.fecha_creacion)
    EXECUTE FUNCTION fn_trg_respuesta_inmutable();

-- FUNCION 1 (HU014, escenarios 1, 3 y 8): publica una respuesta y devuelve el total del hilo.
-- Valida lo que la tabla no puede garantizar sola: que el proyecto exista y que el comentario
-- pertenezca a ese proyecto (respuestas_comentario no tiene id_proyecto). Mismos codigos que la API.
CREATE OR REPLACE FUNCTION fn_publicar_respuesta(
    p_id_proyecto   UUID,
    p_id_comentario UUID,
    p_id_usuario    UUID,
    p_respuesta     TEXT
) RETURNS TABLE (id_respuesta UUID, total_respuestas BIGINT)
LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_proyecto_del_comentario UUID;
    v_nueva                   UUID;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM proyectos p WHERE p.id = p_id_proyecto) THEN
        RAISE EXCEPTION 'PROJECT_NOT_FOUND: El proyecto no existe' USING ERRCODE = 'P0002';
    END IF;

    SELECT c.id_proyecto INTO v_proyecto_del_comentario
    FROM interaccion_proyecto c WHERE c.id = p_id_comentario;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'COMMENT_NOT_FOUND: El comentario no existe' USING ERRCODE = 'P0002';
    END IF;
    IF v_proyecto_del_comentario <> p_id_proyecto THEN
        RAISE EXCEPTION 'COMMENT_NOT_IN_PROJECT: El comentario no pertenece a este proyecto' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO respuestas_comentario (id_comentario, id_usuario, respuesta)
    VALUES (p_id_comentario, p_id_usuario, p_respuesta)
    RETURNING id INTO v_nueva;

    RETURN QUERY
    SELECT v_nueva, (SELECT count(*) FROM respuestas_comentario r WHERE r.id_comentario = p_id_comentario);
END $$;

-- FUNCION 2 (HU014, ver el hilo): respuestas de un comentario, de la mas antigua a la mas reciente.
CREATE OR REPLACE FUNCTION fn_listar_respuestas(p_id_comentario UUID)
RETURNS TABLE (id UUID, id_usuario UUID, username VARCHAR, respuesta TEXT, fecha_creacion TIMESTAMP WITH TIME ZONE)
LANGUAGE sql STABLE
SET search_path = public AS $$
    SELECT r.id, r.id_usuario, u.username, r.respuesta, r.fecha_creacion
    FROM respuestas_comentario r
    JOIN usuarios u ON u.id = r.id_usuario
    WHERE r.id_comentario = p_id_comentario
    ORDER BY r.fecha_creacion, r.id;
$$;

-- FUNCION 3 (HU014, conteo de respuestas): total de respuestas de cada comentario de un proyecto (incluye los de 0).
CREATE OR REPLACE FUNCTION fn_conteo_respuestas_proyecto(p_id_proyecto UUID)
RETURNS TABLE (id_comentario UUID, total_respuestas BIGINT)
LANGUAGE sql STABLE
SET search_path = public AS $$
    SELECT c.id, count(r.id)
    FROM interaccion_proyecto c
    LEFT JOIN respuestas_comentario r ON r.id_comentario = c.id
    WHERE c.id_proyecto = p_id_proyecto
    GROUP BY c.id, c.fecha_creacion
    ORDER BY c.fecha_creacion, c.id;
$$;

COMMENT ON FUNCTION fn_publicar_respuesta(UUID, UUID, UUID, TEXT) IS 'HU014: publica una respuesta validando proyecto y comentario; devuelve id y total del hilo.';
COMMENT ON FUNCTION fn_listar_respuestas(UUID) IS 'HU014: respuestas de un comentario en orden cronologico.';
COMMENT ON FUNCTION fn_conteo_respuestas_proyecto(UUID) IS 'HU014: total de respuestas por comentario de un proyecto (con ceros).';

-- Por defecto PostgreSQL da EXECUTE a PUBLIC: se quita. Los permisos por rol estan en seguridad.sql.
REVOKE ALL ON FUNCTION fn_publicar_respuesta(UUID, UUID, UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_listar_respuestas(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_conteo_respuestas_proyecto(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_trg_respuesta_normaliza() FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_trg_respuesta_inmutable() FROM PUBLIC;

-- ---------------------------------------------------------------------
-- 21. TRIGGERS Y PROCEDIMIENTOS (HU018, HU019 y votar comentarios - Sprint 3)
-- Cada objeto indica la HU que atiende. Documentacion y ejemplos en el README.
-- ---------------------------------------------------------------------

-- FUNCION AUXILIAR (HU019): hay bloqueo entre dos usuarios en cualquiera de los dos sentidos.
CREATE OR REPLACE FUNCTION fn_hay_bloqueo(p_usuario_a UUID, p_usuario_b UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE
SET search_path = public AS $$
    SELECT EXISTS (
        SELECT 1 FROM usuarios_bloqueados b
        WHERE (b.blocker_id = p_usuario_a AND b.blocked_id = p_usuario_b)
           OR (b.blocker_id = p_usuario_b AND b.blocked_id = p_usuario_a)
    );
$$;

-- TRIGGER 3 (HU019): no se puede enviar un mensaje privado si hay bloqueo entre remitente y destinatario.
-- BEFORE INSERT en mensajes_privados. Misma regla que el backend (ENVIO_BLOQUEADO), ahora tambien en la base.
CREATE OR REPLACE FUNCTION fn_trg_mensaje_sin_bloqueo() RETURNS trigger
LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF fn_hay_bloqueo(NEW.remitente_id, NEW.destinatario_id) THEN
        RAISE EXCEPTION 'ENVIO_BLOQUEADO: No es posible enviar mensajes a este usuario'
            USING ERRCODE = 'integrity_constraint_violation';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_mensaje_sin_bloqueo
    BEFORE INSERT ON mensajes_privados
    FOR EACH ROW EXECUTE FUNCTION fn_trg_mensaje_sin_bloqueo();

-- TRIGGER 4 (HU018): solo los dos participantes de una conversacion pueden tener estado de lectura en ella.
-- BEFORE INSERT en conversation_read_states.
CREATE OR REPLACE FUNCTION fn_trg_lectura_participante() RETURNS trigger
LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM conversaciones c
                   WHERE c.id = NEW.id_conversacion
                     AND NEW.id_usuario IN (c.id_participante_uno, c.id_participante_dos)) THEN
        RAISE EXCEPTION 'El usuario no participa en la conversacion'
            USING ERRCODE = 'integrity_constraint_violation';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_lectura_participante
    BEFORE INSERT ON conversation_read_states
    FOR EACH ROW EXECUTE FUNCTION fn_trg_lectura_participante();

-- TRIGGER 5 (HU018): la marca de lectura solo avanza. Un UPDATE con fecha anterior conserva la actual
-- (equivale a advanceTo del backend) y no se puede cambiar la conversacion ni el usuario de la fila.
-- BEFORE UPDATE en conversation_read_states.
CREATE OR REPLACE FUNCTION fn_trg_lectura_no_retrocede() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.id_conversacion IS DISTINCT FROM OLD.id_conversacion
       OR NEW.id_usuario IS DISTINCT FROM OLD.id_usuario THEN
        RAISE EXCEPTION 'El estado de lectura no puede cambiar de conversacion ni de usuario'
            USING ERRCODE = 'integrity_constraint_violation';
    END IF;
    NEW.fecha_ultima_lectura := GREATEST(OLD.fecha_ultima_lectura, NEW.fecha_ultima_lectura);
    RETURN NEW;
END $$;

CREATE TRIGGER trg_lectura_no_retrocede
    BEFORE UPDATE ON conversation_read_states
    FOR EACH ROW EXECUTE FUNCTION fn_trg_lectura_no_retrocede();

-- FUNCION 4 (HU018): marca una conversacion como leida hasta p_fecha (por omision, ahora).
-- Crea la fila si no existe; si existe, la marca solo avanza (lo garantiza el trigger 5).
CREATE OR REPLACE FUNCTION fn_marcar_conversacion_leida(
    p_id_conversacion UUID,
    p_id_usuario      UUID,
    p_fecha           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_fecha TIMESTAMP WITH TIME ZONE;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM conversaciones c WHERE c.id = p_id_conversacion) THEN
        RAISE EXCEPTION 'CONVERSATION_NOT_FOUND: La conversacion no existe' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO conversation_read_states (id_conversacion, id_usuario, fecha_ultima_lectura)
    VALUES (p_id_conversacion, p_id_usuario, p_fecha)
    ON CONFLICT ON CONSTRAINT uq_read_state_conversation_user
    DO UPDATE SET fecha_ultima_lectura = EXCLUDED.fecha_ultima_lectura
    RETURNING fecha_ultima_lectura INTO v_fecha;

    RETURN v_fecha;
END $$;

-- FUNCION 5 (HU018): conversaciones del usuario con su numero de mensajes no leidos
-- (mensajes recibidos posteriores a la ultima lectura, o todos si nunca la abrio). Incluye las de 0.
CREATE OR REPLACE FUNCTION fn_conteo_no_leidos(p_id_usuario UUID)
RETURNS TABLE (id_conversacion UUID, id_otro_usuario UUID, no_leidos BIGINT)
LANGUAGE sql STABLE
SET search_path = public AS $$
    SELECT c.id,
           CASE WHEN c.id_participante_uno = p_id_usuario THEN c.id_participante_dos
                ELSE c.id_participante_uno END,
           count(m.id)
    FROM conversaciones c
    LEFT JOIN conversation_read_states r
           ON r.id_conversacion = c.id AND r.id_usuario = p_id_usuario
    LEFT JOIN mensajes_privados m
           ON m.id_conversacion = c.id
          AND m.destinatario_id = p_id_usuario
          AND (r.id IS NULL OR m.fecha_envio > r.fecha_ultima_lectura)
    WHERE p_id_usuario IN (c.id_participante_uno, c.id_participante_dos)
    GROUP BY c.id, c.id_participante_uno, c.id_participante_dos
    ORDER BY 3 DESC, 1;
$$;

-- FUNCION 6 (HU019): bloquea a un usuario. Mismos codigos de error que la API.
CREATE OR REPLACE FUNCTION fn_bloquear_usuario(p_blocker_id UUID, p_blocked_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_id UUID;
BEGIN
    IF p_blocked_id = p_blocker_id THEN
        RAISE EXCEPTION 'AUTO_BLOQUEO: No puedes bloquear tu propio usuario' USING ERRCODE = 'P0001';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.id = p_blocked_id) THEN
        RAISE EXCEPTION 'USUARIO_NO_EXISTE: El usuario no existe' USING ERRCODE = 'P0002';
    END IF;
    IF EXISTS (SELECT 1 FROM usuarios_bloqueados b
               WHERE b.blocker_id = p_blocker_id AND b.blocked_id = p_blocked_id) THEN
        RAISE EXCEPTION 'BLOQUEO_DUPLICADO: Este usuario ya se encuentra bloqueado' USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO usuarios_bloqueados (blocker_id, blocked_id)
    VALUES (p_blocker_id, p_blocked_id)
    RETURNING id INTO v_id;
    RETURN v_id;
END $$;

-- FUNCION 7 (HU019): desbloquea a un usuario. Error BLOQUEO_NO_ENCONTRADO si no habia bloqueo.
CREATE OR REPLACE FUNCTION fn_desbloquear_usuario(p_blocker_id UUID, p_blocked_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    DELETE FROM usuarios_bloqueados b
    WHERE b.blocker_id = p_blocker_id AND b.blocked_id = p_blocked_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'BLOQUEO_NO_ENCONTRADO: No existe un bloqueo para este usuario' USING ERRCODE = 'P0002';
    END IF;
END $$;

-- FUNCION 8 (votar comentarios): alterna el voto del usuario en un comentario de proyecto
-- (si no habia voto lo registra; si ya habia, lo retira) y devuelve el estado y el total.
-- Mismas validaciones y codigos que la API: PROJECT_NOT_FOUND, COMMENT_NOT_FOUND, COMMENT_NOT_IN_PROJECT.
CREATE OR REPLACE FUNCTION fn_alternar_voto_comentario(
    p_id_proyecto   UUID,
    p_id_comentario UUID,
    p_id_usuario    UUID
) RETURNS TABLE (votado BOOLEAN, total_votos BIGINT)
LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_proyecto_del_comentario UUID;
    v_votado                  BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM proyectos p WHERE p.id = p_id_proyecto) THEN
        RAISE EXCEPTION 'PROJECT_NOT_FOUND: El proyecto no existe' USING ERRCODE = 'P0002';
    END IF;

    SELECT c.id_proyecto INTO v_proyecto_del_comentario
    FROM interaccion_proyecto c WHERE c.id = p_id_comentario;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'COMMENT_NOT_FOUND: El comentario no existe' USING ERRCODE = 'P0002';
    END IF;
    IF v_proyecto_del_comentario <> p_id_proyecto THEN
        RAISE EXCEPTION 'COMMENT_NOT_IN_PROJECT: El comentario no pertenece a este proyecto' USING ERRCODE = 'P0002';
    END IF;

    DELETE FROM votos_comentario v WHERE v.id_comentario = p_id_comentario AND v.id_usuario = p_id_usuario;
    IF FOUND THEN
        v_votado := FALSE;
    ELSE
        INSERT INTO votos_comentario (id_comentario, id_usuario) VALUES (p_id_comentario, p_id_usuario);
        v_votado := TRUE;
    END IF;

    RETURN QUERY
    SELECT v_votado, (SELECT count(*) FROM votos_comentario v WHERE v.id_comentario = p_id_comentario);
END $$;

-- FUNCION 9 (votar comentarios): total de votos de cada comentario de un proyecto (incluye los de 0).
CREATE OR REPLACE FUNCTION fn_conteo_votos_proyecto(p_id_proyecto UUID)
RETURNS TABLE (id_comentario UUID, total_votos BIGINT)
LANGUAGE sql STABLE
SET search_path = public AS $$
    SELECT c.id, count(v.id_usuario)
    FROM interaccion_proyecto c
    LEFT JOIN votos_comentario v ON v.id_comentario = c.id
    WHERE c.id_proyecto = p_id_proyecto
    GROUP BY c.id, c.fecha_creacion
    ORDER BY c.fecha_creacion, c.id;
$$;

COMMENT ON FUNCTION fn_hay_bloqueo(UUID, UUID) IS 'HU019: TRUE si alguno de los dos usuarios bloqueo al otro.';
COMMENT ON FUNCTION fn_marcar_conversacion_leida(UUID, UUID, TIMESTAMP WITH TIME ZONE) IS 'HU018: marca la conversacion como leida; la marca solo avanza.';
COMMENT ON FUNCTION fn_conteo_no_leidos(UUID) IS 'HU018: mensajes no leidos por conversacion del usuario (con ceros).';
COMMENT ON FUNCTION fn_bloquear_usuario(UUID, UUID) IS 'HU019: bloquea a un usuario; devuelve el id del bloqueo.';
COMMENT ON FUNCTION fn_desbloquear_usuario(UUID, UUID) IS 'HU019: retira un bloqueo.';
COMMENT ON FUNCTION fn_alternar_voto_comentario(UUID, UUID, UUID) IS 'Votar comentarios: registra o retira el voto y devuelve el total.';
COMMENT ON FUNCTION fn_conteo_votos_proyecto(UUID) IS 'Votar comentarios: votos por comentario de un proyecto (con ceros).';

-- Por defecto PostgreSQL da EXECUTE a PUBLIC: se quita. Los permisos por rol estan en seguridad.sql.
REVOKE ALL ON FUNCTION fn_hay_bloqueo(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_marcar_conversacion_leida(UUID, UUID, TIMESTAMP WITH TIME ZONE) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_conteo_no_leidos(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_bloquear_usuario(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_desbloquear_usuario(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_alternar_voto_comentario(UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_conteo_votos_proyecto(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_trg_mensaje_sin_bloqueo() FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_trg_lectura_participante() FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_trg_lectura_no_retrocede() FROM PUBLIC;
