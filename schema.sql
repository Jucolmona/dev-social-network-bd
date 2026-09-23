
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- USUARIOS
CREATE TABLE usuarios (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          VARCHAR(100),
    apellido        VARCHAR(100),
    username        VARCHAR(50) UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    fecha_registro  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_usuario_email CHECK (btrim(email) <> '')
);

CREATE INDEX idx_usuarios_email ON usuarios(email);

-- CREDENCIALES

CREATE TABLE credenciales (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id            UUID NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo                  VARCHAR(30) NOT NULL DEFAULT 'LOCAL',
    password_hash         VARCHAR(255),
    proveedor_id_externo  VARCHAR(255),
    intentos_fallidos     INT NOT NULL DEFAULT 0,
    bloqueado_hasta       TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_credenciales_usuario_id ON credenciales(usuario_id);

-- PERFIL DE USUARIO

CREATE TABLE perfiles_usuario (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario          UUID NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_creacion      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    bio                 VARCHAR(500),
    nivel_completado    NUMERIC(5,2) DEFAULT 0,
    enlace_portafolio   VARCHAR(255),
    anio_inicio_dev     INT,
    nivel               VARCHAR(20) NOT NULL DEFAULT 'ENTRY',

    CONSTRAINT chk_perfil_nivel CHECK (nivel IN ('ENTRY', 'JUNIOR', 'MID', 'SENIOR'))
);

-- ENLACES EXTERNOS 

CREATE TABLE enlaces_externos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_perfil       UUID NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    nombre_enlace   VARCHAR(50) NOT NULL,
    url_enlace      VARCHAR(255) NOT NULL
);

CREATE INDEX idx_enlaces_perfil ON enlaces_externos(id_perfil);

-- TECNOLOGÍAS

CREATE TABLE tecnologias (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_tecnologia   VARCHAR(100) NOT NULL UNIQUE,
    tipo                VARCHAR(20) NOT NULL,

    CONSTRAINT chk_tecnologia_tipo CHECK (tipo IN ('ROL', 'LENGUAJE', 'FRAMEWORK'))
);

-- HABILIDADES 

CREATE TABLE habilidades (
    id_perfil       UUID NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    id_tecnologia   UUID NOT NULL REFERENCES tecnologias(id) ON DELETE CASCADE,

    PRIMARY KEY (id_perfil, id_tecnologia)
);

-- PROYECTOS

CREATE TABLE proyectos (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    titulo              VARCHAR(50) NOT NULL,
    descripcion         VARCHAR(250) NOT NULL,
    repositorio_url     VARCHAR(255),
    fecha_creacion      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultima_actualizacion TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_proyectos_usuario ON proyectos(usuario_id);

-- PROYECTO ↔ TECNOLOGÍAS

CREATE TABLE proyecto_tecnologias (
    id_proyecto     UUID NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    id_tecnologia   UUID NOT NULL REFERENCES tecnologias(id) ON DELETE CASCADE,

    PRIMARY KEY (id_proyecto, id_tecnologia)
);

-- DISCUSIONES
CREATE TABLE discusiones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo          VARCHAR(150) NOT NULL,
    autor_id        UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    contenido       TEXT NOT NULL,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_tecnologia   UUID NOT NULL REFERENCES tecnologias(id)
);

CREATE INDEX idx_discusiones_autor ON discusiones(autor_id);
CREATE INDEX idx_discusiones_tecnologia ON discusiones(id_tecnologia);

-- INTERACCIÓN EN DISCUSIONES 

CREATE TABLE interaccion_discusion (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_discusion    UUID NOT NULL REFERENCES discusiones(id) ON DELETE CASCADE,
    id_usuario      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    comentario      TEXT NOT NULL,
    fecha_creacion  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_interaccion_discusion ON interaccion_discusion(id_discusion);



