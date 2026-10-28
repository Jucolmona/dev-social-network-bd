-- [S1] Roles creados (4 grupos + 4 usuarios de conexion)
SELECT rolname AS rol, rolcanlogin AS login, rolconnlimit AS limite_conexiones, rolsuper AS superusuario
FROM pg_roles WHERE rolname ~ '^(rol_|svc_|usr_)' ORDER BY rolcanlogin, rolname;
-- [S2] Privilegios por tabla (nivel tabla)
SELECT grantee AS rol, table_name AS tabla, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privilegios
FROM information_schema.role_table_grants
WHERE table_schema='public' AND grantee LIKE 'rol\_%' GROUP BY 1,2 ORDER BY 1,2;
-- [S3] Privilegios por columna (solo SELECT parcial)
SELECT grantee AS rol, table_name AS tabla, string_agg(column_name, ', ' ORDER BY column_name) AS columnas_legibles
FROM information_schema.column_privileges
WHERE table_schema='public' AND grantee LIKE 'rol\_%' AND privilege_type='SELECT'
  AND (grantee, table_name) NOT IN (SELECT grantee, table_name FROM information_schema.role_table_grants WHERE table_schema='public' AND privilege_type='SELECT')
GROUP BY 1,2 ORDER BY 1,2;
-- [S4] Nadie fuera de los roles definidos tiene acceso (PUBLIC)
SELECT count(*) AS permisos_para_public FROM information_schema.role_table_grants WHERE table_schema='public' AND grantee='PUBLIC';
