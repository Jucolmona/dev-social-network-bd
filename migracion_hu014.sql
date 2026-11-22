-- migracion_hu014.sql - Aplica SOLO la tabla nueva de HU014 (Sprint 3) sobre una BD que ya tiene el schema de main
-- (incluye votos_comentario). Para una BD vacia basta con ejecutar schema.sql, que ya la incluye (tabla 17).
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
END $$;

-- Verificacion: IF NOT EXISTS no cambia una tabla ya existente. Si alguien la creo antes sin restricciones
-- (por ejemplo, Hibernate con ddl-auto=update), esta migracion fallaria en silencio; aqui se detecta.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_respuesta_comentario') THEN
    RAISE EXCEPTION 'respuestas_comentario existe sin chk_respuesta_comentario: recrear la tabla con schema.sql';
  END IF;
END $$;
