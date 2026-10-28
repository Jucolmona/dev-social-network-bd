-- Tabla de cradenciales para HU-002

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE credencial (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id            UUID NOT NULL UNIQUE REFERENCES usuarios (id),
    tipo                  VARCHAR(30) NOT NULL DEFAULT 'LOCAL',
    password_hash         VARCHAR(255) NULL,
    proveedor_id_externo  VARCHAR(255) NULL,
    intentos_fallidos     INT NOT NULL DEFAULT 0,
    bloqueado_hasta       TIMESTAMP NULL
);

/* Busquedas espacificas de HU-002 */
--Busqueda credencial por correo
SELECT *
FROM credencial
WHERE usuario_id = :usuario_id;

-- verificar si la credencial esta bloqueada
SELECT *
FROM credencial
WHERE usuario_id = :usuario_id
  AND bloqueado_hasta > NOW();

-- Ver cuántos intentos fallidos lleva
SELECT intentos_fallidos
FROM credencial
WHERE usuario_id = :usuario_id;

-- Listar usuarios con intentos fallidos
SELECT usuario_id, intentos_fallidos
FROM credencial
WHERE intentos_fallidos > 0
ORDER BY intentos_fallidos DESC;


CREATE TABLE user_profiles(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    bio VARCHAR(250),
    complete_prfile DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    portfolio_link VARCHAR(250),
    dev_date_init DATE,
    seniority VARCHAR(20) NOT NULL,

    FOREIGN KEY (user_id)
        REFERENCES usuarios(id)
        ON DELETE CASCADE
)

CREATE TABLE user_habilities(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID, NOT NULL,
    tecnology_id BIGINT NOT NULL,
    FOREIGN KEY (user_id)
        REFERENCES user_profiles(id)
        ON DELETE CASCADE,
    FOREIGN KEY (tecnology_id)
        REFERENCES tecnologies(id)
        ON DELETE CASCADE
)

CREATE TABLE user_social_links(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_link VARCHAR(50) NOT NULL,
    link_url VARCHAR(250) NOT NULL,
    user_id UUID NOT NULL,
    FOREIGN KEY (user_id)
        REFERENCES user_profiles(id)
        ON DELETE CASCADE
)

CREATE TABLE technologies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL,
-- Tabla de usuarios para HU-001

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE usuarios (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          VARCHAR(100),
    apellido        VARCHAR(100),
    username        VARCHAR(50) UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    fecha_registro  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Verificar si un correo ya está registrado (correo duplicado)
SELECT *
FROM usuarios
WHERE email = :email;

-- Buscar un usuario por su id
SELECT *
FROM usuarios
WHERE id = :usuario_id;

-- Registrar un usuario nuevo
INSERT INTO usuarios (nombre, apellido, username, email)
VALUES (:nombre, :apellido, :username, :email)
RETURNING id;

-- Listar usuarios registrados por mes 
SELECT DATE_TRUNC('month', fecha_registro) AS mes, COUNT(*) AS total
FROM usuarios
GROUP BY mes
ORDER BY mes;
