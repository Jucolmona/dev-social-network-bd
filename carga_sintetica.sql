\timing off
CREATE TEMP TABLE u AS SELECT row_number() OVER (ORDER BY id) AS rn, id FROM (SELECT gen_random_uuid() AS id FROM generate_series(1,2000)) s;
INSERT INTO usuarios(id,nombre,apellido,username,email) SELECT id,left(md5(rn::text),8),left(md5(rn::text||'a'),9),'user'||lpad(rn::text,6,'0'),'usuario'||lpad(rn::text,7,'0')||'@udea.edu.co' FROM u;
INSERT INTO credenciales(usuario_id,tipo,password_hash) SELECT id,'LOCAL','$2a$10$'||left(md5(rn::text)||md5(rn::text||'x')||md5(rn::text||'y'),53) FROM u;
INSERT INTO perfiles_usuario(id_usuario,bio,nivel_completado,enlace_portafolio,anio_inicio_dev,nivel) SELECT id,left(repeat(md5(rn::text),5),150),60,'https://portafolio.dev/'||left(md5(rn::text),6),2019,'JUNIOR' FROM u WHERE rn<=1800;
CREATE TEMP TABLE p AS SELECT row_number() OVER (ORDER BY id) AS rn, id FROM perfiles_usuario;
INSERT INTO enlaces_externos(id_perfil,nombre_enlace,url_enlace) SELECT p.id,n,'https://'||lower(n)||'.com/'||left(repeat(md5(p.rn::text),2),28) FROM p, (VALUES ('GITHUB'),('LINKEDIN')) v(n);
INSERT INTO tecnologias(nombre_tecnologia,tipo) SELECT 'Tecnologia'||g,(ARRAY['ROL','LENGUAJE','FRAMEWORK'])[1+g%3] FROM generate_series(1,60) g;
CREATE TEMP TABLE t AS SELECT row_number() OVER (ORDER BY id) AS rn, id FROM tecnologias;
INSERT INTO habilidades SELECT p.id,t.id FROM p CROSS JOIN generate_series(0,4) k JOIN t ON true WHERE t.rn = ((p.rn*3+k)%60)+1;
CREATE TEMP TABLE pr AS
 SELECT row_number() OVER (ORDER BY g) AS rn, gen_random_uuid() AS id, g FROM generate_series(1,3000) g;
INSERT INTO proyectos(id,usuario_id,titulo,descripcion,repositorio_url)
 SELECT pr.id,u.id,left(repeat(md5(pr.rn::text),1),30),left(repeat(md5(pr.rn::text),5),150),'https://github.com/'||left(md5(pr.rn::text),8)||'/'||left(md5(pr.rn::text||'r'),12)
 FROM pr JOIN u ON u.rn=1+((pr.rn-1)/3);
INSERT INTO proyecto_tecnologias SELECT pr.id,t.id FROM pr CROSS JOIN generate_series(0,3) k JOIN t ON true WHERE t.rn=((pr.rn*5+k)%60)+1 AND (k<3 OR pr.rn<=1500);
CREATE TEMP TABLE di AS SELECT row_number() OVER (ORDER BY g) AS rn, gen_random_uuid() AS id FROM generate_series(1,1600) g;
INSERT INTO discusiones(id,titulo,autor_id,contenido,estado,id_tecnologia)
 SELECT di.id,left(repeat(md5(di.rn::text),3),70),u.id,left(repeat(md5(di.rn::text),13),400),CASE WHEN di.rn%3=0 THEN 'RESUELTA' ELSE 'ABIERTA' END,t.id
 FROM di JOIN u ON u.rn=1+(di.rn%1000) JOIN t ON t.rn=1+(di.rn%60);
INSERT INTO interaccion_discusion(id_discusion,id_usuario,comentario)
 SELECT di.id,u.id,left(repeat(md5(di.rn::text||k),4),120) FROM di CROSS JOIN generate_series(1,4) k JOIN u ON u.rn=1+((di.rn*13+k*7)%2000);
INSERT INTO interaccion_proyecto(id_proyecto,id_usuario,comentario)
 SELECT pr.id,u.id,left(repeat(md5(pr.rn::text||k),4),120) FROM pr CROSS JOIN generate_series(1,3) k JOIN u ON u.rn=1+((pr.rn*11+k*5)%2000);
INSERT INTO seguidores(id_seguidor,id_seguido) SELECT a.id,b.id FROM u a CROSS JOIN generate_series(1,6) k JOIN u b ON true WHERE b.rn=1+((a.rn-1+k*37)%2000);
INSERT INTO likes_proyecto(id_proyecto,id_usuario) SELECT pr.id,u.id FROM pr CROSS JOIN generate_series(1,8) k JOIN u ON true WHERE u.rn=1+((pr.rn*17+k*101)%2000);
CREATE TEMP TABLE cv AS
 SELECT row_number() OVER (ORDER BY i) AS rn, least(a.id,b.id) AS uno, greatest(a.id,b.id) AS dos, a.id AS ida, b.id AS idb
 FROM generate_series(1,3000) i JOIN u a ON a.rn=1+((i-1)%1999) JOIN u b ON b.rn=a.rn+1+((i-1)/1999);
INSERT INTO conversaciones(id_participante_uno,id_participante_dos) SELECT uno,dos FROM cv;
INSERT INTO mensajes_privados(id_conversacion,remitente_id,destinatario_id,contenido)
 SELECT c.id, CASE WHEN k%2=0 THEN v.ida ELSE v.idb END, CASE WHEN k%2=0 THEN v.idb ELSE v.ida END, left(repeat(md5(v.rn::text||k),4),100)
 FROM cv v JOIN conversaciones c ON c.id_participante_uno=v.uno AND c.id_participante_dos=v.dos CROSS JOIN generate_series(1,15) k;
VACUUM ANALYZE;
