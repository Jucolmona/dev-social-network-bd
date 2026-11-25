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


## Version 3 (Sprint 3)

Se agregan las relaciones de comentarios de proyecto y sus derivadas (la Version 2 no las listaba):

- INTERACCION_PROYECTO(id, id_proyecto, id_usuario, comentario, fecha_creacion)
- VOTOS_COMENTARIO(id_comentario, id_usuario, fecha_creacion)
- RESPUESTAS_COMENTARIO(id, id_comentario, id_usuario, respuesta, fecha_creacion)

#### RESPUESTAS_COMENTARIO (HU014)

**id --> id_comentario:** una respuesta pertenece a un único comentario
**id --> id_usuario:** una respuesta tiene un único autor
**id --> respuesta:** una respuesta tiene un único texto (no vacío, máximo 1000 caracteres)
**id --> fecha_creacion:** una respuesta se publica en un único instante

> Un comentario tiene 0..N respuestas y un usuario escribe 0..N respuestas (1:N en ambos sentidos). Se separa en una relación propia, y no como columna `id_padre` de INTERACCION_PROYECTO, para no alterar el listado de comentarios (HU013) y porque cada atributo depende solo de `id` (3FN/BCNF).

#### VOTOS_COMENTARIO

**(id_comentario, id_usuario) --> fecha_creacion:** un usuario vota una sola vez cada comentario; la fecha depende de la clave completa.

## Version 4 (Sprint 3, HU018 y HU019)

Se agregan dos relaciones:

- CONVERSATION_READ_STATES(id, id_conversacion, id_usuario, fecha_ultima_lectura)
- USUARIOS_BLOQUEADOS(id, blocker_id, blocked_id, fecha_bloqueo)

#### CONVERSATION_READ_STATES (HU018)

**id --> id_conversacion, id_usuario, fecha_ultima_lectura:** cada marca pertenece a una conversación y a un usuario, y guarda su último momento de lectura.
**(id_conversacion, id_usuario) --> id, fecha_ultima_lectura:** clave candidata: hay una sola marca por usuario y conversación.

> Se separa de MENSAJES_PRIVADOS porque la lectura es un hecho del par (usuario, conversación), no de cada mensaje: guardarla en el mensaje repetiría el dato y exigiría actualizar muchas filas al leer (3FN/BCNF).

#### USUARIOS_BLOQUEADOS (HU019)

**id --> blocker_id, blocked_id, fecha_bloqueo:** cada bloqueo tiene un único bloqueador, un único bloqueado y una fecha.
**(blocker_id, blocked_id) --> id, fecha_bloqueo:** clave candidata: un usuario bloquea una sola vez a otro.

> Es direccional (A bloquea a B no implica que B bloquee a A); la restricción de mensajes sí es mutua y se aplica con el trigger `trg_mensaje_sin_bloqueo`. Un usuario no puede bloquearse a sí mismo (CHECK).
