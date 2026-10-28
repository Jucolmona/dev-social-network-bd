# Análisis de almacenamiento, costo y optimización

Sección 7 del entregable Sprint 2 (Bases de Datos y Laboratorio). Usa solo las fórmulas de referencia de la rúbrica. Las referencias a los apartados 2, 5 y 6 corresponden a la documentación del README.

Este apartado usa únicamente las fórmulas de referencia de la rúbrica (almacenamiento e índices, costo de consultas en páginas de E/S y optimización algebraica) y sus símbolos. Analiza la tabla `mensajes_privados` (7.1) y la consulta PC13, que incluye dos reuniones (7.2 y 7.3). Todas las cifras se calculan paso a paso y llevan su unidad.

**Parámetros y estadísticas comunes**

| Parámetro | Valor | Origen |
|---|---|---|
| P = B (página o bloque) | 4096 bytes | Supuesto del modelo: las fórmulas usan P como parámetro. PostgreSQL usa 8192 bytes; la sensibilidad a ese valor se muestra en 7.1.2. |
| Apuntador de índice | 8 bytes | Supuesto: tamaño de un identificador de registro. |
| M (páginas de memoria) | 50 páginas | Supuesto para las reuniones de 7.2. |
| Área de control de cluster | 20 bytes por cluster | Supuesto para la alternativa de cluster multitabla. |
| TR de mensajes_privados, conversaciones, usuarios | 45.000, 3000, 2000 | Estimación de volumen al mes 12 (apartado 5.3), confirmada con la carga sintética de 5.5. |
| Tamaños de campos fijos | UUID 16 · TIMESTAMPTZ 8 bytes | Tipos del modelo físico (apartado 2). |
| Tamaños estimados de campos variables | contenido 100 · username 10 · nombre 8 · apellido 9 · email 26 bytes | Supuestos del apartado 5.2. |
| Tamaño del mapa de bits | ⌈#campos / 8⌉ bytes | Un bit por campo (anulabilidad). |
| V(a,R) y S(a,R) | Se calculan en 7.1 y 7.2 | V(a,R) sale de contar valores distintos (consulta en 7.2.2); S(a,R) = TR / V(a,R). |

## 7.1 Estrategia de almacenamiento e índices y estimación de una tabla principal

### 7.1.1 Tabla elegida

Se analiza `mensajes_privados` porque es la tabla de mayor crecimiento (112.500 registros al mes 24, el 44 % del espacio estimado en 5.4), la consultan PC13 y PC14 y es inmutable: la aplicación solo inserta y lee (HU017). Esa forma de uso (inserciones al final, sin actualizaciones) condiciona la organización de archivo que se elige en 7.1.3.

### 7.1.2 Longitud del registro, registros por bloque y páginas de la tabla

Fórmulas: **L = 4 · #campos var. + Σ size(campos fijos) + size(mapa de bits) + Σ tamaño estimado(campos var.)**; **FR = ⌊(P − 2) / (4 + L)⌋**; **BR = ⌈TR / FR⌉**.

| Campo | Tipo | Clase | Bytes |
|---|---|---|---|
| id | UUID | fijo | 16 |
| id_conversacion | UUID | fijo | 16 |
| remitente_id | UUID | fijo | 16 |
| destinatario_id | UUID | fijo | 16 |
| fecha_envio | TIMESTAMPTZ | fijo | 8 |
| contenido | VARCHAR(2000) | variable | 100 (estimado) |

```text
#campos var. = 1  →  4 · 1 = 4 bytes
Σ campos fijos = 16 + 16 + 16 + 16 + 8 = 72 bytes
Mapa de bits = ⌈6 / 8⌉ = 1 byte
Σ campos variables = 100 bytes
L = 4 + 72 + 1 + 100 = 177 bytes

FR = ⌊(4096 − 2) / (4 + 177)⌋ = ⌊4094 / 181⌋ = ⌊22,62⌋ = 22 registros por página
Comprobación: P = 2 + 4·FR + FR·L = 2 + 88 + 3894 = 3984 ≤ 4096 bytes

BR (mes 12) = ⌈45.000 / 22⌉ = ⌈2045,45⌉ = 2046 páginas  →  2046 · 4096 = 8.380.416 bytes ≈ 7,99 MB
BR (mes 24) = ⌈112.500 / 22⌉ = ⌈5113,64⌉ = 5114 páginas  →  20.946.944 bytes ≈ 19,98 MB
```

**Sensibilidad al tamaño de página.** Con P = 8192 bytes (el valor de PostgreSQL): FR = ⌊8190 / 181⌋ = 45 y BR = ⌈45.000 / 45⌉ = 1000 páginas, es decir, 8.192.000 bytes. En la carga sintética de 5.5, PostgreSQL midió 1125 páginas de 8192 bytes para esos 45.000 registros; la fórmula de referencia da 1000 porque no cuenta los 24 bytes de cabecera de cada fila de PostgreSQL. La diferencia es de 11 % y no cambia las decisiones.

### 7.1.3 Organización de archivo

**Elegida: archivo no ordenado (heap) con índices B+tree secundarios.** Los mensajes se insertan en orden cronológico y nunca se modifican ni se borran, de modo que agregar al final cuesta una sola página y no hay reorganizaciones. La clave primaria es un UUID aleatorio, por lo que ordenar el archivo por `id` no ayuda a ninguna consulta. Las lecturas son por conversación (PC13, PC14) y por destinatario, y se resuelven con índices.

| Alternativa | Qué implicaría | Veredicto |
|---|---|---|
| Archivo ordenado por (id_conversacion, fecha_envio) | Las consultas por conversación leerían páginas contiguas; cada inserción intermedia obliga a abrir espacio o reorganizar. | Descartada: las inserciones llegan de todas las conversaciones a la vez. |
| Hashing sobre id_conversacion | Igualdad en una conversación en pocas páginas. | Descartada: PC13 necesita el orden por fecha y PC14 el máximo por conversación; el hash no ayuda con rangos ni órdenes. |
| Cluster multitabla conversaciones + mensajes | E = L1·N1 + L2·N2 + control = 57·1 + 177·15 + 20 = 2732 bytes por cluster; Bcluster = ⌈E · V(clave,R) / P⌉ = ⌈2732 · 3000 / 4096⌉ = 2001 páginas (frente a 2046 + 45 = 2091 separadas). | Descartada: ahorra poco espacio (4 %), cada cluster crece sin límite con la conversación y penaliza las consultas por destinatario. PostgreSQL tampoco tiene clusters multitabla. |

### 7.1.4 Índices elegidos y justificación

| Índice (tabla mensajes_privados) | Tipo | Consulta que lo usa | Justificación |
|---|---|---|---|
| mensajes_privados_pkey (id) | B+tree, primario | Búsqueda de un mensaje; garantiza unicidad | Lo exige la clave primaria; la fórmula de selección primaria es HI + 1. |
| idx_mensajes_conversacion (id_conversacion, fecha_envio) | B+tree, secundario compuesto | PC13 y PC14: mensajes de una conversación, ordenados por fecha, y último mensaje | La igualdad en id_conversacion localiza a los S(a,R) mensajes y, al estar ordenados por fecha_envio dentro de cada conversación, evita ordenar. |
| idx_mensajes_destinatario (destinatario_id) | B+tree, secundario | Mensajes recibidos por un usuario | Sin él, cada consulta de «mis mensajes recibidos» leería todas las páginas de la tabla. |

### 7.1.5 Cálculo paso a paso del índice idx_mensajes_conversacion

Fórmulas: **FR = ⌊B / L⌋**; **2d − 1 = FR** (con d ≥ 3); **H ≤ log_d V(a,R)**; **nodos del nivel k ≈ V(a,R) / d^k**; **Espacio = (Σ nodos de todos los niveles) × B**.

```text
Clave compuesta: id_conversacion (16) + fecha_envio (8) = 24 bytes; apuntador = 8 bytes
L = 24 + 8 = 32 bytes por entrada
FR = ⌊4096 / 32⌋ = 128 entradas por nodo
2d − 1 = 128  →  d = ⌊(128 + 1) / 2⌋ = 64   (d ≥ 3 se cumple; 2·64 − 1 = 127 ≤ 128)
V(a,R) = 45.000 claves distintas (una por mensaje, porque fecha_envio distingue los mensajes)
H ≤ log_64(45.000) = ln 45.000 / ln 64 = 2,58  →  H = 3 niveles
Nodos nivel 1 (hojas) ≈ 45.000 / 64^1 = 703,1  →  704
Nodos nivel 2         ≈ 45.000 / 64^2 = 11,0  →  11
Nodos nivel 3 (raíz)  ≈ 45.000 / 64^3 = 0,17  →  1
Σ nodos = 704 + 11 + 1 = 716
Espacio = 716 · 4096 = 2.932.736 bytes ≈ 2,80 MB
LB_I (páginas hoja) = 704   HI = 3
```

**Resumen de los tres índices y de la tabla**

| Estructura | L (bytes) | FR | d | V(a,R) | H | Nodos | Espacio |
|---|---|---|---|---|---|---|---|
| Tabla mensajes_privados (heap) | 177 | 22 | — | — | — | 2046 páginas | 7,99 MB |
| mensajes_privados_pkey (id) | 24 | 170 | 85 | 45.000 | 3 | 538 | 2,10 MB |
| idx_mensajes_conversacion | 32 | 128 | 64 | 45.000 | 3 | 716 | 2,80 MB |
| idx_mensajes_destinatario | 24 | 170 | 85 | 2000 | 2 | 25 | 0,10 MB |
| **Total índices** |  |  |  |  |  | 1279 | 5,00 MB |

Para idx_mensajes_destinatario, V(a,R) = 2000 es el número de destinatarios distintos (todos los usuarios); según la fórmula de referencia, el tamaño del índice depende de V(a,R) y no del número de filas.

### 7.1.6 Efecto de la estrategia en el costo de acceso

Selección por igualdad de PC13 sobre `mensajes_privados` (id_conversacion = valor): S(a,R) = TR / V(a,R) = 45.000 / 3000 = 15 mensajes por conversación.

| Alternativa | Fórmula | Cálculo | Páginas de E/S |
|---|---|---|---|
| Búsqueda lineal | Peor caso: BR | BR = 2046 | **2046** |
| Índice secundario (elegido) | HI + S(a,R) | 3 + 15 | **18** |
| Cluster multitabla | HI + ⌈E / P⌉ | 2 + ⌈2732 / 4096⌉ = 2 + 1 | **3** |

El índice reduce el costo de 2046 a 18 páginas (114 veces menos). El cluster llegaría a 3, pero no compensa sus desventajas (7.1.3); por eso se conserva el heap con el índice compuesto.

## 7.2 Análisis de costo de una consulta

### 7.2.1 Consulta analizada

Se analiza la consulta PC13 (pregunta clave HU017: ¿qué mensajes contiene la conversación entre dos usuarios, en orden de envío?). Contiene dos reuniones: mensajes ⋈ conversaciones y el resultado ⋈ usuarios. Para el costo, las dos subconsultas que obtienen los id de los usuarios (por username, con el índice único de `usuarios.username`) se tratan como los valores constantes :a y :b, con :a < :b.

```sql
SELECT r.username AS remitente, m.contenido, m.fecha_envio
FROM mensajes_privados m
JOIN conversaciones cv ON cv.id = m.id_conversacion
JOIN usuarios r        ON r.id  = m.remitente_id
WHERE cv.id_participante_uno = :a
  AND cv.id_participante_dos = :b
ORDER BY m.fecha_envio;
```

Plan elegido: (1) seleccionar la conversación con el índice único (uno, dos); (2) reunir con `mensajes_privados` por el índice idx_mensajes_conversacion (indexed nested-loop); (3) reunir cada mensaje con su remitente por la clave primaria de `usuarios`. Como idx_mensajes_conversacion ya entrega los mensajes ordenados por fecha_envio, el ORDER BY no agrega costo; además los 15 resultados caben en memoria.

### 7.2.2 Estadísticas usadas y de dónde salen

| Estadística | Valor | Cómo se obtiene |
|---|---|---|
| TR(mensajes), BR | 45.000 tuplas · 2046 páginas | Estimación del mes 12 (5.3); BR = ⌈TR / FR⌉ con L = 177 y FR = 22 (7.1.2). |
| TR(conversaciones), BR | 3000 tuplas · 45 páginas | L = 57, FR = ⌊4094 / 61⌋ = 67, BR = ⌈3000 / 67⌉ = 45. |
| TR(usuarios), BR | 2000 tuplas · 49 páginas | L = 94, FR = ⌊4094 / 98⌋ = 41, BR = ⌈2000 / 41⌉ = 49. |
| V(id_conversacion, mensajes) | 3000 | Una conversación por cada una de las 3000; medido con COUNT(DISTINCT id_conversacion). |
| S(id_conversacion, mensajes) | 15 mensajes | TR / V = 45.000 / 3000. |
| V(id_participante_uno), V(id_participante_dos) | 1999 y 1999 | Medido con COUNT(DISTINCT ...) sobre conversaciones. |
| Parejas (uno, dos) | únicas | Restricción uq_conversacion_participantes: como máximo 1 conversación por pareja. |
| HI de cada índice | 3 (uno, dos) · 2 (dos) · 3 (mensajes) · 2 (usuarios.id) | Cálculo de altura de 7.1.5 aplicado a cada índice (tabla de 7.2.3). |
| M | 50 páginas | Supuesto de memoria disponible. |

Consulta para obtener las estadísticas en pgAdmin:

```sql
SELECT (SELECT count(*) FROM mensajes_privados)                         AS tr_mensajes,
       (SELECT count(*) FROM conversaciones)                           AS tr_conversaciones,
       (SELECT count(*) FROM usuarios)                                 AS tr_usuarios,
       (SELECT count(DISTINCT id_conversacion) FROM mensajes_privados) AS v_id_conversacion,
       (SELECT count(DISTINCT id_participante_uno) FROM conversaciones) AS v_uno,
       (SELECT count(DISTINCT id_participante_dos) FROM conversaciones) AS v_dos;
```

Sobre la carga sintética del mes 12 devuelve 45.000, 3000, 2000, 3000, 1999 y 1999.

| Índice | L (bytes) | FR | d | V(a,R) | HI |
|---|---|---|---|---|---|
| uq_conversacion_participantes (uno, dos) | 40 | 102 | 51 | 3000 | 3 |
| idx_conversaciones_participante_dos | 24 | 170 | 85 | 1999 | 2 |
| idx_mensajes_conversacion | 32 | 128 | 64 | 45.000 | 3 |
| usuarios_pkey (id) | 24 | 170 | 85 | 2000 | 2 |

### 7.2.3 Paso 1: seleccionar la conversación (σ sobre conversaciones)

Predicado conjuntivo id_participante_uno = :a ∧ id_participante_dos = :b. Fórmula de conjunción: **Tuplas = TR · s1 · s2**, con si = S(ai,R) / TR.

```text
S(uno, conversaciones) = TR / V = 3000 / 1999 = 1,50   s1 = 1,50 / 3000 = 0,00050
S(dos, conversaciones) = 3000 / 1999 = 1,50   s2 = 0,00050
Tuplas = 3000 · 0,00050 · 0,00050 = 0,00075  →  por la restricción UNIQUE (uno, dos) el resultado es exactamente 1 tupla
```

| Alternativa | Fórmula | Cálculo | Páginas de E/S |
|---|---|---|---|
| Búsqueda lineal | Peor caso: BR | BR = 45 | 45 |
| Índice secundario sobre id_participante_dos | HI + S(a,R) | 2 + ⌈3000 / 1999⌉ = 2 + 2 | 4 |
| **Índice único (uno, dos), elegido** | Primario: HI + 1 | 3 + 1 | **4** |

Se elige el índice único: con una sola búsqueda encuentra la conversación (resultado: 1 tupla, que cabe en 1 página). Costo del paso 1: **4 páginas**.

### 7.2.4 Paso 2: reunión conversaciones ⋈ mensajes_privados

R = mensajes_privados (BR = 2046, TR = 45.000) y T = resultado del paso 1 (1 tupla, BT = 1, TT = 1). Atributo de reunión b = id_conversacion, que no es clave de R.

```text
Tamaño de la salida (b no es clave de S): TR · TS / V(b,S) = 1 · 45.000 / 3000 = 15 tuplas
Longitud de la tupla reunida = 57 + 177 = 234 bytes
```

| Algoritmo | Fórmula | Cálculo | Páginas de E/S |
|---|---|---|---|
| Nested-loop (T externa) | BR + BS · ⌈BR / (M − 2)⌉ | 1 + 2046 · ⌈1 / 48⌉ = 1 + 2046 · 1 | 2047 |
| Sort-merge | BR + BS + 2·BR·⌈log(M−1) BR⌉ + 2·BS·⌈log(M−1) BS⌉ | 1 + 2046 + 2·1·0 + 2·2046·⌈log49 2046⌉ = 2047 + 2·2046·2 | 10.231 |
| Hash join en memoria | BR + BS | 1 + 2046 | 2047 |
| **Indexed nested-loop, elegido** | BT + TT · S(b,R) | 1 + 1 · 15 | **16** |

Con la tupla de T ya en memoria, el indexed nested-loop usa idx_mensajes_conversacion y lee solo los S(b,R) = 15 mensajes de esa conversación; los demás algoritmos recorren las 2046 páginas de `mensajes_privados`. Costo del paso 2: **16 páginas**. Si además se contara el descenso por el índice (HI = 3), serían 19, que coincide con el 18 de 7.1.6 más la página de T.

### 7.2.5 Paso 3: reunión del resultado con usuarios

T = resultado del paso 2 (15 tuplas de 234 bytes: FR = ⌊4094 / 238⌋ = 17, BT = ⌈15 / 17⌉ = 1 página). Atributo b = usuarios.id, que sí es clave de R = usuarios: la salida es ≤ TT = 15 tuplas, y S(id, usuarios) = TR / V = 2000 / 2000 = 1.

| Algoritmo | Fórmula | Cálculo | Páginas de E/S |
|---|---|---|---|
| Hash join en memoria | BR + BS | 1 + 49 | 50 |
| **Indexed nested-loop con usuarios_pkey, elegido** | BT + TT · S(b,R) | 1 + 15 · 1 | **16** |

Costo del paso 3: **16 páginas**.

### 7.2.6 Costo total y comparación con una alternativa de ejecución

| Paso | Plan elegido (índices) | Páginas | Plan alternativo (sin índices) | Páginas |
|---|---|---|---|---|
| 1. Selección de la conversación | Índice único (uno, dos): HI + 1 | 4 | Búsqueda lineal: BR | 45 |
| 2. conversaciones ⋈ mensajes | Indexed nested-loop: BT + TT·S(b,R) | 16 | Hash join: BR + BS | 2047 |
| 3. resultado ⋈ usuarios | Indexed nested-loop: BT + TT·S(b,R) | 16 | Hash join: BR + BS | 50 |
| **Total** |  | **36** |  | **2142** |

El plan con índices cuesta 36 páginas de E/S frente a 2142 del plan sin índices: es 60 veces más barato. Casi todo el ahorro viene del paso 2, que pasa de recorrer toda la tabla de mensajes a leer solo los 15 mensajes de la conversación. Con el crecimiento del mes 24 la tabla ocuparía 5114 páginas: el plan sin índices las leería completas en cada consulta, mientras que el elegido sigue leyendo solo los mensajes de una conversación (S(b,R) = 15 si la actividad por conversación se mantiene).

## 7.3 Optimización algebraica de una consulta

### 7.3.1 SQL original y expresión algebraica inicial

Se optimiza la misma consulta PC13 de 7.2.1. Notación: M = mensajes_privados, CV = conversaciones, U = usuarios; p1 ≡ id_participante_uno = :a; p2 ≡ id_participante_dos = :b; ⋈ con su condición de reunión.

```sql
SELECT r.username, m.contenido, m.fecha_envio
FROM mensajes_privados m
JOIN conversaciones cv ON cv.id = m.id_conversacion
JOIN usuarios r        ON r.id  = m.remitente_id
WHERE cv.id_participante_uno = :a AND cv.id_participante_dos = :b;
```

```text
E0 = π username, contenido, fecha_envio (
        σ p1 ∧ p2 (
            (M ⋈ m.id_conversacion = cv.id  CV)  ⋈ m.remitente_id = r.id  U ) )
```

El árbol inicial reúne primero las tablas completas y filtra al final.

### 7.3.2 Transformaciones y leyes aplicadas

| Paso | Ley | Transformación | Por qué es válida |
|---|---|---|---|
| 1 | Ley 2: σ p1∧p2 (E) ≡ σ p1 (σ p2 (E)) | Se separa el predicado conjuntivo en dos selecciones en cascada. | Permite tratar p1 y p2 por separado y bajarlas por el árbol. |
| 2 | Leyes 4 y 5: σ p (E1 ⋈ E2) ≡ σ p1 (E1) ⋈ σ p2 (E2) | p1 y p2 solo usan atributos de CV: se mueven por debajo de las dos reuniones, hasta quedar sobre CV. | Ni p1 ni p2 usan atributos de M ni de U, de modo que la selección puede aplicarse a CV antes de reunir. |
| 3 | Ley 2 (en sentido inverso) | Se vuelven a juntar en σ p1∧p2 (CV). | Es una sola búsqueda por el índice único (uno, dos). |
| 4 | Leyes 11 y 12: E1 ⋈ E2 ≡ E2 ⋈ E1; (E1 ⋈ E2) ⋈ E3 ≡ E1 ⋈ (E2 ⋈ E3) | (M ⋈ σ(CV)) ⋈ U pasa a (σ(CV) ⋈ M) ⋈ U: se reúne primero la relación pequeña (1 tupla). | La reunión es conmutativa; así la primera reunión produce 15 tuplas y no 45.000. La alternativa σ(CV) ⋈ (M ⋈ U) se descarta porque reuniría M con U antes de filtrar. |
| 5 | Ley 9: π x,y (E1 ⋈ E2) ≡ π x (E1) ⋈ π y (E2) | Se proyectan los atributos necesarios en cada relación antes de reunir: CV → id; M → id_conversacion, remitente_id, contenido, fecha_envio; U → id, username. | Reduce el ancho de las tuplas: la proyección de U baja de L = 94 a L = 31 bytes (de 49 a 18 páginas). |
| 6 | Ley 8: π x (π y (E)) ≡ π x (E), si x ⊆ y | Las proyecciones en cascada se reducen a la más externa y a las que acompañan a cada reunión. | Evita proyectar dos veces; las columnas finales (username, contenido, fecha_envio) están contenidas en las intermedias. |

La Ley 3 (intercambio de π y σ) no se usa: p1 y p2 emplean los atributos uno y dos de CV, que no están en la proyección π id (CV); por eso la selección se aplica primero y la proyección después.

### 7.3.3 Expresión optimizada

```text
E1 = π username, contenido, fecha_envio (
        (  π id ( σ p1 ∧ p2 (CV) )
           ⋈ id = id_conversacion
           π id_conversacion, remitente_id, contenido, fecha_envio (M)  )
        ⋈ remitente_id = id
        π id, username (U) )
```

Equivale a la siguiente forma en SQL (el optimizador de PostgreSQL aplica estas transformaciones por sí mismo; se muestra para visualizar el orden de las operaciones):

```sql
SELECT u.username, m.contenido, m.fecha_envio
FROM (SELECT id FROM conversaciones
      WHERE id_participante_uno = :a AND id_participante_dos = :b) cv
JOIN (SELECT id_conversacion, remitente_id, contenido, fecha_envio
      FROM mensajes_privados) m ON m.id_conversacion = cv.id
JOIN (SELECT id, username FROM usuarios) u ON u.id = m.remitente_id;
```

### 7.3.4 Justificación: tuplas intermedias antes y después

Tamaño de salida de cada reunión con la fórmula de referencia: si b es clave de S, la salida es ≤ TR; si no, TR · TS / V(b,S).

| Operación | Expresión original E0 | Expresión optimizada E1 |
|---|---|---|
| Entrada de la primera reunión | M (45.000) y CV (3000) | σ(CV) (1) y M (45.000) |
| Resultado de M ⋈ CV | 45.000 (b = cv.id es clave de CV: ≤ TM) | 1 · 45.000 / 3000 = 15 |
| Resultado de la reunión con U | 45.000 (b = u.id es clave de U: ≤ 45.000) | 15 (≤ 15) |
| Selección final | 45.000 → 15 tuplas | ya aplicada al inicio |
| **Tuplas intermedias generadas** | **90.000** (45.000 + 45.000) | **31** (1 + 15 + 15) |
| **Costo en páginas (7.2.6)** | 2142 | 36 |

La expresión original genera 90.000 tuplas intermedias y la optimizada 31, unas 2900 veces menos, porque la selección sobre CV, la más selectiva, se ejecuta antes de la primera reunión (heurística general: selecciones y proyecciones hacia las hojas). Además, las proyecciones reducen el ancho de las tuplas leídas de U, y el orden de las reuniones evita producir resultados intermedios del tamaño de toda la tabla de mensajes.
