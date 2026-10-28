
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
