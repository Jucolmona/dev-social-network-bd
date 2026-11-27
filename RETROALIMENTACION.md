# Retroalimentación – Bases de Datos

Calificación por sprint según la rúbrica de cada entrega. Los scripts se ejecutaron en PostgreSQL 16 vacío. Lo que venía de un sprint anterior aparece como sugerencia y no descuenta.

## Sprint 1 — 4.5 / 5.0

| Criterio | Nivel | Puntos |
|---|---|---|
| C1 Entidades y relaciones | Excelente | 1.25 / 1.25 |
| C2 Preguntas clave | Excelente | 0.75 / 0.75 |
| C3 Modelo lógico | Excelente | 1.00 / 1.00 |
| C4 Modelo físico | Aceptable | 0.90 / 1.25 |
| C5 Repositorio y documentación | Aceptable | 0.55 / 0.75 |

- C4: `nombre`, `apellido` y `username` de `usuarios` admiten nulos. `credenciales.tipo` sin CHECK y sin regla que obligue `password_hash` o `proveedor_id_externo` según el tipo. `nivel_completado` sin CHECK de rango.
- C5: `DDL.sql` en la raíz contradice a `schema.sql` y falla al ejecutarse. `docs/RELACIONES.md` mezcla versiones. La lista de integrantes no coincide con la de la entrega.
- C5: el mejor proceso del grupo: ramas por HU y PR integrados.
- Sugerencia: archivo `.sql` con las seis preguntas.

## Sprint 2 — 4.7 / 5.0

| Criterio | Nivel | Puntos |
|---|---|---|
| C1 MER refinado | Aceptable | 0.45 / 0.60 |
| C2 Modelo físico | Aceptable | 0.60 / 0.80 |
| C3 schema.sql | Excelente | 0.80 / 0.80 |
| C4 Consultas | Excelente | 0.70 / 0.70 |
| C5 Volumen | Excelente | 0.50 / 0.50 |
| C6 Roles y seguridad | Excelente | 0.60 / 0.60 |
| C7 Almacenamiento e índices | Excelente | 0.40 / 0.40 |
| C8 Costo de una consulta | Excelente | 0.30 / 0.30 |
| C9 Optimización algebraica | Excelente | 0.30 / 0.30 |

- C1: el MER del README tiene 21 relaciones para 23 FK; faltan `id_participante_dos` y el destinatario de `mensajes_privados`.
- C2: `mensajes_privados` (tabla nueva) queda en 2FN por `destinatario_id`; la rúbrica pide mínimo 3FN.
- C5: buena validación con `carga_sintetica.sql` (29,0 MB medidos vs. 31,2 MB estimados).
- C6: los 10 rechazos esperados de `pruebas_seguridad.sql` se reprodujeron.

## Sprint 3 — 5.0 / 5.0

| Criterio | Nivel | Puntos |
|---|---|---|
| C1 MER refinado | Excelente | 0.70 / 0.70 |
| C2 Script refinado | Excelente | 0.80 / 0.80 |
| C3 Triggers | Excelente | 1.10 / 1.10 |
| C4 Procedimientos | Excelente | 1.10 / 1.10 |
| C5 Consultas | Excelente | 0.60 / 0.60 |
| C6 Roles y seguridad | Excelente | 0.70 / 0.70 |

- C1: 31 relaciones = 31 FK; se corrigieron las dos que faltaban.
- C3: 5 triggers nuevos; en las verificaciones fallan exactamente los casos marcados "debe fallar" (8 y 13).
- C4: 10 funciones con los mismos códigos de error de la API.
- C5: 49 consultas, 46 con filas.
- C6: matriz de EXECUTE por función; las 21 pruebas negativas dan `permission denied`.
- README: el título dice "Sprint 2", la sección 4 dice "dos primeros sprints", el orden de ejecución no incluye `verificacion_sprint3.sql`, dice 16 errores esperados y son 21, y quedan comentarios `PENDIENTE`.
- Sugerencias: mover "Cambios respecto al Sprint 2" al inicio; sacar del repo las contraseñas de ejemplo de `seguridad.sql`.

## Nota final: 4.7

Promedio simple de los tres sprints.
