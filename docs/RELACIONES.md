# Relaciones extraidas de las tablas

## Version 1

- USUARIO(id, nombre, apellido, username, email, fecha_registro)
- CREDENCIAL(id, usuario_id, tipo, password_hash, proveedor_id_externo, intentos_fallidos, bloqueado_hasta)
- PERFIL_USUARIO(id, id_usuario, fecha_creacion, bio, nivel_completado, enlaces_externos, enlace_portafolio, habilidades, anios_experiencia, nivel)
- PROYECTO(id, usuario_id, titulo, descripcion, repositorioURL, fecha_creacion, ultima_actualizacion, tecnologias)
- DISCUSIONES(id, usuario_id, titulo, tecnologia, contenido, fecha_creacion)

### Análisis de dependencias funcionales

#### USUARIO

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

USUARIO(id, nombre, apellido, username, email, fecha_registro)
CONTROL_SESION(id, intentos_fallidos, tiempo_bloqueo, id_usuario)

> Se retira de la relacion USUARIO , intentos_fallidos y tiempo_bloqueo, ya que no tienen una. relacion inherente con la clave primaria de usuario. Se pasan estos atributos a una nueva relacion de CONTROL_SESION. Ademas si se borra algun registro de control de sección, no se veria afectado alguna sección o algun usuario.

#### CREDENCIAL

CREDENCIAL(id, usuario_id, tipo, password_hash, proveedor_id_externo, intentos_fallidos, bloqueado_hasta)

**id --> usuario_id:** una credencial solo puede pertenecer a un único usuario
**id --> tipo:** una credencial tiene un único tipo de autenticación (LOCAL u OAUTH_*)
**id --> password_hash:** una credencial solo puede tener un único hash de contraseña (aplica solo si el tipo es LOCAL)
**id --> proveedor_id_externo:** una credencial solo puede tener un único identificador externo (aplica solo si el tipo es OAUTH_*)
**id --> intentos_fallidos:** una credencial lleva un único conteo de intentos fallidos en un momento determinado
**id --> bloqueado_hasta:** una credencial solo puede tener una única fecha/hora de desbloqueo vigente en un momento determinado

CREDENCIAL(id, usuario_id, tipo, password_hash, proveedor_id_externo, intentos_fallidos, bloqueado_hasta)

> A diferencia de la Versión 1, no se separa el control de intentos fallidos y bloqueo en una relación aparte (CONTROL_SESION), ya que estos atributos dependen directamente de la credencial de autenticación (no del usuario en sí): un usuario puede tener varias credenciales (por ejemplo, LOCAL y OAUTH_GOOGLE), y cada una debe controlar sus propios intentos fallidos y bloqueo de forma independiente. Por eso permanecen dentro de CREDENCIAL.

#### PERFIL_USUARIO

PERFIL_USUARIO(id, id_usuario, fecha_creacion, nivel_completado, enlaces_externos, enlace_portafolio, habilidades, anio_inicio_dev, nivel)

**id --> id_usuario:** un perfil de usuario solo puede tener un único usuario
**id --> fecha_creacion:** el perfil de usuario solo puede ser creada en una unica fecha especifica.
**id --> nivel_completado:** el perfil de usuario puede tener un nivel de avance en su perfil en un momento determinado
**id --> enlace_portafolio:** un perfil de usario solo tiene un enlace de portafolio especifico
**id --> anio_inicio_dev:** un perfil de usuario tiene un inicio de experiencia en desarrollo


PERFIL_USUARIO(id, id_usuario, fecha_creacion, bio, nivel_completado, enlace_portafolio, anio_inicio_dev, nivel)
ENLACES_EXTERNOS(id, nombre_enlace, url_enlace, id_perfil)
HABILIDADES(id, nombre_habilidad, id_perfil, id_tecnologia)

#### PROYECTO

PROYECTO(id, usuario_id, titulo, descripcion, repositorio_url, fecha_creacion, ultima_actualizacion, tecnologias)

**id --> usuario_id:** un proyecto solo puede pertenecer a un usuario especifico
**id --> titulo:** un proyecto solo pude tener un único título
**id --> repositorio_url:** un proyecto solo puede tener un único repositorio alojado
**id --> fecha_creacion:** un proyecto se crea en una fecha especifica
**id --> ultima_actualizacion:** un proyecto puede ser actualizado en un momento determinado

PROYECTO(id, usuario_id, titulo, descripcion, repositorio_url, fecha_creacion, ultima_actualizacion)
TECNOLOGIAS(id, nombre_tecnologia)
PROYECTO_TECNOLOGIAS(id_proyecto, id_tecnologia)

#### DISCUSIONES

DISCUSIONES(id, usuario_id, titulo, tecnologia, contenido, fecha_creacion)

**id --> titulo:** una discusion puede tener un unico titulo
**id --> autor:** una discusion solo puede tener un unico creador
**id --> contenido:** una discusion solo puede tener un unico contenido
**id --> fecha creacion:** una discusion solo se puede crear en una fecha especifica

DISCUSIONES(id, titulo, autor_id, contenido, fecha_creacion, id_tecnologia)
INTERACCION_DISCUSION(id, id_discusion, id_usuario, comentario)


## Version 2

- USUARIO(id, nombre, apellido, username, email, fecha_registro)
- CREDENCIAL(id, usuario_id, tipo, password_hash, proveedor_id_externo, intentos_fallidos, bloqueado_hasta)
- PERFIL_USUARIO(id, id_usuario, fecha_creacion, bio, nivel_completado, enlace_portafolio, anio_inicio_dev, nivel)
- ENLACES_EXTERNOS(id, nombre_enlace, url_enlace, id_perfil)
- HABILIDADES(id, nombre_habilidad, id_perfil, id_tecnologia)
- PROYECTO(id, usuario_id, titulo, descripcion, repositorio_url, fecha_creacion, ultima_actualizacion)
- TECNOLOGIAS(id, nombre_tecnologia)
- PROYECTO_TECNOLOGIAS(id_proyecto, id_tecnologia)
- DISCUSIONES(id, titulo, autor_id, contenido, fecha_creacion, id_tecnologia)
- INTERACCION_DISCUSION(id, id_discusion, id_usuario, comentario)
