# Relaciones extraidas de las tablas

## Version 1

- USUARIO(id, nombre, apellido, username, email, contrasena, intentos_fallidos, tiempo_bloqueo)
- SESIONES(id, usuario_id, fecha_inicio, activa)
- PERFIL_USUARIO(id, id_usuario, fecha_creacion, nivel_completado, enlaces_externos, enlace_portafolio, habilidades, anios_experiencia, nivel)
- PROYECTO(id, usuario_id, titulo, descripcion, repositorioURL, fecha_creacion, ultima_actualizacion, tecnologias)
- DISCUSIONES(id, usuario_id, titulo, tecnologia, contenido, fecha_creacion)

### Análisis de dependencias funcionales

#### Usuarios

**id --> nombre:** un id de usuario no puede estar asociado a dos nombres diferentes
**id --> apellido:** un id de usuario no puede estar asociado a dos nombres de usuario diferentes
**id --> username:** un id de usuario solo puede tener un username de usuario
**id --> email:** un id de usuario solo puede tener un email
**id --> contrasena:** un id de usuario puede tener una sola contraseña
**id --> intentos_fallidos:**  un id de usuario puede tener varios intentos fallidos de seccion
**id --> tiempos_bloqueo:**  un id de usuario puede tener varios bloqueos de seccion

Se deriva una dependencia funcional completa en la relacion usuarios

(id, nombre, apellido) --> username
(id, nombre, apellido) --> email
(id, nombre, apellido) --> contrasena

USUARIO(id, nombre, apellido, username, contrasena, email)
CONTROL_SESION(id, intentos_fallidos, tiempo_bloqueo, id_usuario, id_sesion)

> Se retira de la relacion USUARIO , intentos_fallidos y tiempo_bloqueo, ya que no tienen una. relacion inherente con la clave primaria de usuario. Se pasan estos atributos a una nueva relacion de CONTROL_SESION. Ademas si se borra algun registro de control de sección, no se veria afectado alguna sección o algun usuario.

#### PERFIL_USUARIO

PERFIL_USUARIO(id, id_usuario, fecha_creacion, nivel_completado, enlaces_externos, enlace_portafolio, habilidades, anios_experiencia, nivel)

**id --> id_usuario:** un perfil de usuario solo puede tener un único usuario
**id --> fecha_creacion:** el perfil de usuario solo puede ser creada en una unica fecha especifica.
**id --> enlace_portafolio:** un perfil de usario solo tiene un enlace de portafolio


**id --> nivel_completado:** un perfil de usuario puede tener varios niveles de completitud
**id --> enlaces_externos:** un perfil de usuario puede tener varios enlaces externos
**id --> habilidades:** un perfil de usuario puede tener varias habilidades

## Version 2

- USUARIO(id, nombre, apellido, username, contrasena, email)
- CONTROL_SESION(id, intentos_fallidos, tiempo_bloqueo, id_usuario, id_sesion)
- SESIONES(id, usuario_id, fecha_inicio, activa)