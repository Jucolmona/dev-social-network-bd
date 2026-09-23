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
