-- Tabla de cradenciales para HU-002

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE credenciales (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correo              VARCHAR(150) NOT NULL UNIQUE,
    contrasena          VARCHAR(255) NOT NULL,
    intentos_fallidos   SMALLINT NOT NULL DEFAULT 0,
    bloqueado_hasta     TIMESTAMP NULL,
    estado              VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    fecha_creacion      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

/* Busquedas espacificas de HU-002 */
--Busqueda credencial por correo
SELECT id, correo, contrasena, intentos_fallidos, bloqueado_hasta
FROM credenciales
WHERE correo = :correo;