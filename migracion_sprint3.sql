-- migracion_sprint3.sql - Aplica SOLO lo nuevo de HU018, HU019 y votar comentarios (Sprint 3) sobre una BD que ya tiene
-- el schema de main con HU014 (tablas 1 a 17 y migracion_hu014.sql). Para una BD vacia basta con ejecutar schema.sql,
-- que ya incluye todo (tablas 18 y 19 y secciones 20 y 21).
-- Agrega: 2 tablas (conversation_read_states, usuarios_bloqueados), 3 triggers y 7 funciones, y los permisos de seguridad.sql.
-- Es idempotente: se puede ejecutar mas de una vez.

-- 18. CONVERSATION_READ_STATES  (HU018: mensajes no leidos)  [NUEVA EN SPRINT 3]
--     Hasta que momento leyo cada participante cada conversacion. Un mensaje recibido
--     es "no leido" si es posterior a fecha_ultima_lectura (o si no hay fila).
--     Nombres de tabla y columnas iguales a los que ya mapea el backend (ConversationReadStateEntity).

CREATE TABLE IF NOT EXISTS conversation_read_states (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_conversacion       UUID NOT NULL REFERENCES conversaciones(id) ON DELETE CASCADE,
    id_usuario            UUID NOT NULL REFERENCES usuarios(id)       ON DELETE CASCADE,
    fecha_ultima_lectura  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_read_state_conversation_user UNIQUE (id_conversacion, id_usuario)
);
CREATE INDEX IF NOT EXISTS idx_read_states_usuario ON conversation_read_states(id_usuario);
COMMENT ON TABLE conversation_read_states IS 'HU018: ultimo momento de lectura de un usuario en una conversacion; base del conteo de mensajes no leidos.';


-- 19. USUARIOS_BLOQUEADOS  (HU019: bloquear usuario)  [NUEVA EN SPRINT 3]
--     Bloqueo direccional (blocker_id bloquea a blocked_id); la restriccion de
--     mensajes es mutua: se aplica si cualquiera de los dos bloqueo al otro.
--     Nombres iguales a los de UsuarioBloqueadoEntity del backend.

CREATE TABLE IF NOT EXISTS usuarios_bloqueados (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    blocked_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_bloqueo  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_bloqueo_par             UNIQUE (blocker_id, blocked_id),
    CONSTRAINT chk_bloqueo_no_a_si_mismo  CHECK (blocker_id <> blocked_id)
);
-- uq_bloqueo_par cubre la busqueda por blocker_id; este cubre la inversa (quien me bloqueo).
CREATE INDEX IF NOT EXISTS idx_bloqueos_bloqueado ON usuarios_bloqueados(blocked_id);
COMMENT ON TABLE usuarios_bloqueados IS 'HU019: bloqueo direccional entre usuarios; impide mensajes en ambos sentidos.';


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

DROP TRIGGER IF EXISTS trg_mensaje_sin_bloqueo ON mensajes_privados;
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

DROP TRIGGER IF EXISTS trg_lectura_participante ON conversation_read_states;
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

DROP TRIGGER IF EXISTS trg_lectura_no_retrocede ON conversation_read_states;
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

-- Permisos: solo se otorgan si el rol existe (si seguridad.sql aun no se aplico, ese script ya los incluye).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_administracion') THEN
    GRANT SELECT, INSERT, UPDATE ON conversation_read_states TO rol_administracion;
    GRANT SELECT, INSERT, DELETE ON usuarios_bloqueados TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_hay_bloqueo(UUID, UUID) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_marcar_conversacion_leida(UUID, UUID, TIMESTAMP WITH TIME ZONE) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_conteo_no_leidos(UUID) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_bloquear_usuario(UUID, UUID) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_desbloquear_usuario(UUID, UUID) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_alternar_voto_comentario(UUID, UUID, UUID) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_conteo_votos_proyecto(UUID) TO rol_administracion;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_consultas') THEN
    GRANT EXECUTE ON FUNCTION fn_conteo_votos_proyecto(UUID) TO rol_consultas;
  END IF;
END $$;

-- Verificacion: IF NOT EXISTS no cambia una tabla ya existente. Si alguien la creo antes sin sus restricciones
-- (por ejemplo, Hibernate con ddl-auto=update), esta migracion fallaria en silencio; aqui se detecta.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_read_state_conversation_user') THEN
    RAISE EXCEPTION 'conversation_read_states existe sin uq_read_state_conversation_user: recrear la tabla con schema.sql';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_bloqueo_par')
     OR NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_bloqueo_no_a_si_mismo') THEN
    RAISE EXCEPTION 'usuarios_bloqueados existe sin uq_bloqueo_par o chk_bloqueo_no_a_si_mismo: recrear la tabla con schema.sql';
  END IF;
  IF (SELECT count(*) FROM pg_trigger WHERE tgname IN ('trg_mensaje_sin_bloqueo','trg_lectura_participante','trg_lectura_no_retrocede') AND NOT tgisinternal) <> 3 THEN
    RAISE EXCEPTION 'faltan triggers de HU018 o HU019';
  END IF;
  IF (SELECT count(*) FROM pg_proc WHERE pronamespace = 'public'::regnamespace AND proname IN ('fn_hay_bloqueo','fn_marcar_conversacion_leida','fn_conteo_no_leidos','fn_bloquear_usuario','fn_desbloquear_usuario','fn_alternar_voto_comentario','fn_conteo_votos_proyecto')) <> 7 THEN
    RAISE EXCEPTION 'faltan funciones de HU018, HU019 o votar comentarios';
  END IF;
END $$;
