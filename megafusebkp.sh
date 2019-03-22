#!/bin/bash
# Diego Cordoba - @d1cor / juncotic.com
# Modificado y adaptado Luis Urbina

# Nombre del servidor sobre el que estamos realizando el backup
SERVER="servidor"
DEBUG="true"

# Directorio temporal de backup (para tar)
TMP_DIR="/tmp/backupsmega"
DAYS_TO_BACKUP=7
BACKUP_MYSQL="true"
 
# Credenciales de acceso a la DB
MYSQL_USER="USUARIO-ESPECIAL-EN-BASE-DE-DATOS"
MYSQL_PASSWORD="PASSWORD-DE-ACCESO-USUARIO-ESPECIAL"

# Especificacion del basedir para los sitios web:
WEBS_DIR="/var/www"

# Binario de MegaFuse a ejecutar:
MEGA_BIN=/opt/MegaFuse/MegaFuse
MEGA_CONF=/root/.megafuse.conf

# Punto de montaje Mega y cache path (deben coincidir con los del archivos de conf .megafuse.conf
MOUNTPOINT="/tmp/mega"
CACHEPATH="/tmp/megacache"

# calculamos la fecha para diferenciar a los backups
DATE="$(date +%Y%m%d_%H%M%S)"

##################################
## Creamos el dir temporal de backup
rm -rf ${TMP_DIR}
mkdir ${TMP_DIR}
cd ${TMP_DIR}
 
# Backup de la db mysql
if [ "${DEBUG}" = "true" ]
then
    echo "MYSQL Backup"
fi
mkdir ${TMP_DIR}/mysql

if [ "${BACKUP_MYSQL}" = "true" ]
then
        mkdir ${TMP_DIR}/mysql
        for db in $(mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e 'show databases;' | grep -Ev "^(Database|mysql|information_schema|performance_schema|phpmyadmin)$")
        do
                if [ "${DEBUG}" = "true" ]
                then
                    echo "Procesando ${db}"
                fi
                mysqldump --opt -u${MYSQL_USER} -p${MYSQL_PASSWORD} "${db}" | gzip > ${TMP_DIR}/mysql/${db}_$(date +%F_%T).sql.gz
        done
        mysqldump --opt -u${MYSQL_USER} -p${MYSQL_PASSWORD} --events --ignore-table=mysql.event --all-databases | gzip > ${TMP_DIR}/mysql/ALL_DATABASES_$(date +%F_%T).sql.gz
fi

# Backup websites
if [ "${DEBUG}" = "true" ]
then
    echo "\ Websites"
fi
mkdir ${TMP_DIR}/websites
for dir in $(find ${WEBS_DIR} -mindepth 1 -maxdepth 1 -type d)
do
    ## Me interesan que los Websites de los clientes esten por separado y no juntos
    ## y como la carpeta donde estan los websites es /var/www/clients pregunto por ella
    ## despues tomo cada subcarpeta (cliente) y lo compacto
    if [ "${dir}" = "/var/www/clients" ]
    then
        for clients in $(find ${dir} -mindepth 1 -maxdepth 1 -type d)
        do
            if [ "${DEBUG}" = "true" ]
                then
                echo "  \-- Procesando dir: ${clients}"
            fi
            cd $(dirname ${clients})
            sudo tar czf ${TMP_DIR}/websites/$(basename ${clients}).tar.gz $(basename ${clients})
            cd - > /dev/null
        done
    else
        if [ "${DEBUG}" = "true" ]
            then
            echo "  \-- Procesando dir: ${dir}"
        fi
        cd $(dirname ${dir})
        sudo tar czf ${TMP_DIR}/websites/$(basename ${dir}).tar.gz $(basename ${dir})
        cd - > /dev/null
    fi
done

## Eliminamos dirs de cache y mountpoint, y los re-creamos
rm -rf $MOUNTPOINT/
rm -rf $CACHEPATH/

mkdir $MOUNTPOINT
mkdir $CACHEPATH

if [ "${DEBUG}" = "true" ]
then
    echo "Montando directorio Mega"
fi
sudo umount megafuse
$MEGA_BIN -c $MEGA_CONF &> /dev/null &

## Esperamos  a que se monte para seguir
while  [ $(mount|grep megafuse|wc -l) -ne 1 ]; do
    if [ "${DEBUG}" = "true" ]
    then
        echo "esperando que mega monte..."
    fi
    sleep 1
done

## si no está creado el dir del backup del server en Mega, lo creamos
[ ! -d $MOUNTPOINT/backup_${SERVER} ] && mkdir $MOUNTPOINT/backup_${SERVER}

if [ "${DEBUG}" = "true" ]
then
    echo "Eliminando Archivos viejos del dir montado..."
fi

## Busco los archivos que tengan mas de "n" dyas de antiguedad y los borro de Mega
find $MOUNTPOINT/backup_${SERVER}/ -mindepth 1 -maxdepth 1 -type d -daystart -mtime ${DAYS_TO_BACKUP} -exec rm -rf {} +
sync
 
if [ "${DEBUG}" = "true" ]
then
    echo "Copiando los archivos del Backup a Mega..."
fi
cp -r --no-preserve=mode,ownership ${TMP_DIR} $MOUNTPOINT/backup_${SERVER}/$DATE 
sync; sync; sync

# Esperamos un tiempo prudencial para desmontar el directorio y limpiar los temporales
sleep 600

if [ "${DEBUG}" = "true" ]
then
    echo "limpiando Y Finalizando"
fi
sudo umount $MOUNTPOINT
sudo rm -rf ${TMP_DIR}

# Matando al proceso de MegaFuse por si quedó algo dando vueltas...
sudo kill -9 $(ps fax|grep .megafuse.conf|grep -v grep |awk -F' ' '{print $1}')