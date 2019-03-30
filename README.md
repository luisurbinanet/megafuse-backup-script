MEGAFUSE: REALIZANDO BACKUPS EN MEGA DESDE LINUX
Tomado del post de Diego Córdoba, el 19 de diciembre de 2016 en https://juncotic.com/megafuse-realizando-backups-mega-linux/

Hoy aprenderemos cómo, mediante herramientas de línea de comandos como MegaFuse, podemos realizar backups de nuestros servidores directamente usando servicios de nube como MEGA.

Escenario inicial
Supongamos que disponemos de un servidor en Internet, y no tenemos (o no queremos usar) tanto espacio en disco para almacenar nuestros backups o copias de seguridad.

Una solución sería programar un script (o utilizar alguna herramienta automatizada como Bacula) para realizar nuestros backups, y periódicamente descargarlos a nuestro ordenador.

Esta descarga puede ser también automatizada, rsync, scp o ftp/ftps incluso pueden ser de utilidad.

Pero pensemos, teniendo servicios de almacenamiento en la nube, como Dropbox, Mega, GDrive, o incluso, servicios montados por nosotros con herramientas como OwnCloud, por qué no aprovecharlos?

Este script toma como base la explicación de Diego y realicé algunos cambios funcionales para mi caso del script original, agregando:

-.Agregue un parametro para activar el modo debug para que veamos en consola lo que va haciendo el script y asi ver su desempeño.
  Obviamente una vez que veas que todo funciona correctamente, pones el DEBUG="false" y lo montas como un cronjob, así puedes dedicar
  ese tiempo en estudiar otras cosas o pasarlo con la familia.
  
-. La persistencia de backups anteriores hasta solo DAYS_TO_BACKUP que por defecto lo puse en 15 días.


-. Establecer el Tiempo de Espera a que finalice la copia entre tu SERVIDOR y MEGA
   Si tu servidore esta en Internet, con 600 segundos (10 minutos) es mas que suficiente
   STANDBY_SECONDS=600
   
Si se me ocurre otra cosa o a ti se te ocurre algo, vamos a implementarlo, me comentas y asi aprendemos todos.

Saludos.
