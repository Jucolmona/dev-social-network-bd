-- migracion_hu014.sql - Aplica SOLO la tabla nueva de HU014 sobre una BD que ya tiene el schema del Sprint 2.
-- (Para una BD vacia basta con ejecutar schema.sql, que ya la incluye.)
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

-- migracion_hu014.sql - Aplica SOLO la tabla nueva de HU014 sobre una BD que ya tiene el schema del Sprint 2.
-- (Para una BD vacia basta con ejecutar schema.sql, que ya la incluye.)
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

-- Si ya aplicó seguridad.sql (existen los roles rol_*):
--   GRANT SELECT, INSERT ON respuestas_comentario TO rol_administracion;
--   GRANT SELECT ON respuestas_comentario TO rol_consultas;
--   GRANT SELECT ON respuestas_comentario TO rol_analista;
