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

