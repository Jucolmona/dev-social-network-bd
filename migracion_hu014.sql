-- migracion_hu014.sql - Aplica SOLO lo nuevo de HU014 (Sprint 3): la tabla, 2 triggers y 3 funciones, sobre una BD que ya tiene el schema de main
-- (incluye votos_comentario). Para una BD vacia basta con ejecutar schema.sql, que ya los incluye (tabla 17 y seccion 18).
-- Es idempotente: se puede ejecutar mas de una vez.

CREATE TABLE IF NOT EXISTS respuestas_comentario (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_comentario   UUID NOT NULL REFERENCES interaccion_proyecto(id) ON DELETE CASCADE,
    id_usuario      UUID NOT NULL REFERENCES usuarios(id)             ON DELETE CASCADE,
    respuesta       TEXT NOT NULL,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_respuesta_comentario CHECK (
        btrim(respuesta) <> '' AND char_length(respuesta) <= 1000
    )
);
CREATE INDEX IF NOT EXISTS idx_respuestas_comentario ON respuestas_comentario(id_comentario, fecha_creacion);
COMMENT ON TABLE respuestas_comentario IS 'HU014: respuesta de un usuario a un comentario de proyecto.';
COMMENT ON COLUMN respuestas_comentario.respuesta IS 'HU014: no vacia y maximo 1000 caracteres.';

-- ---------------------------------------------------------------------
-- 18. TRIGGERS Y PROCEDIMIENTOS (HU014 - Sprint 3)
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

DROP TRIGGER IF EXISTS trg_respuesta_normaliza ON respuestas_comentario;
DROP TRIGGER IF EXISTS trg_respuesta_normaliza ON respuestas_comentario;
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

DROP TRIGGER IF EXISTS trg_respuesta_inmutable ON respuestas_comentario;
DROP TRIGGER IF EXISTS trg_respuesta_inmutable ON respuestas_comentario;
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

-- Permisos: solo se otorgan si los roles existen (si seguridad.sql aun no se aplico, ese script ya los incluye).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_administracion') THEN
    GRANT SELECT, INSERT ON respuestas_comentario TO rol_administracion;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_consultas') THEN
    GRANT SELECT ON respuestas_comentario TO rol_consultas;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_analista') THEN
    GRANT SELECT ON respuestas_comentario TO rol_analista;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_administracion') THEN
    GRANT EXECUTE ON FUNCTION fn_publicar_respuesta(UUID, UUID, UUID, TEXT) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_listar_respuestas(UUID) TO rol_administracion;
    GRANT EXECUTE ON FUNCTION fn_conteo_respuestas_proyecto(UUID) TO rol_administracion;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_consultas') THEN
    GRANT EXECUTE ON FUNCTION fn_listar_respuestas(UUID) TO rol_consultas;
    GRANT EXECUTE ON FUNCTION fn_conteo_respuestas_proyecto(UUID) TO rol_consultas;
  END IF;
END $$;

-- Verificacion: IF NOT EXISTS no cambia una tabla ya existente. Si alguien la creo antes sin restricciones
-- (por ejemplo, Hibernate con ddl-auto=update), esta migracion fallaria en silencio; aqui se detecta.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_respuesta_comentario') THEN
    RAISE EXCEPTION 'respuestas_comentario existe sin chk_respuesta_comentario: recrear la tabla con schema.sql';
  END IF;
END $$;

DO $$
BEGIN
  IF (SELECT count(*) FROM pg_trigger WHERE tgname IN ('trg_respuesta_normaliza','trg_respuesta_inmutable') AND NOT tgisinternal) <> 2 THEN
    RAISE EXCEPTION 'faltan triggers de HU014 en respuestas_comentario';
  END IF;
  IF (SELECT count(*) FROM pg_proc WHERE proname IN ('fn_publicar_respuesta','fn_listar_respuestas','fn_conteo_respuestas_proyecto')) <> 3 THEN
    RAISE EXCEPTION 'faltan funciones de HU014';
  END IF;
END $$;
