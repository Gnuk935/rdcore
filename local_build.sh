#!/bin/bash
source ./.env

echo Radiusdesk 2-docker system builder v1.0
echo ---------------------------------------
echo
echo Special shout out to:
echo - Dirk van der Walt for building this brilliant software and helping debug the dockers
echo - Enock Mbewe for building the first docker version and showing the way with supervisord
echo - Keegan White for all the work on traefik and improving the iNethi architecture
echo
echo Starting Build ....
echo
echo Copying database files to volume mounts for MariaDB ...
mkdir  -p "${RADIUSDESK_VOLUME}"
mkdir  -p "${RADIUSDESK_VOLUME}/db_startup"
mkdir  -p "${RADIUSDESK_VOLUME}/db_conf"
chmod -R 777 "${RADIUSDESK_VOLUME}"
chmod -R 777 "${RADIUSDESK_VOLUME}/db_startup"
chmod -R 777 "${RADIUSDESK_VOLUME}/db_conf"

cp ./cake4/rd_cake/setup/db/rd.sql "${RADIUSDESK_VOLUME}/db_startup"
cp ./docker/db_priveleges.sql "$RADIUSDESK_VOLUME/db_startup"
cp ./docker/startup.sh "$RADIUSDESK_VOLUME/db_startup"
cp ./docker/my_custom.cnf "$RADIUSDESK_VOLUME/db_conf"

docker network create -d macvlan \
  --subnet=192.168.150.0/24 \
  --gateway=192.168.150.1 \
  --ip-range=192.168.150.0/24 \
  -o parent=enp6s18 \
  macvlan-net

echo "init mariadb"
docker compose -f radiusDesk-stack.yml up -d rdmariadb

echo "Building Radiusdesk image with nginx, php-fpm and freeradius ..."
docker build --build-arg radiusdesk_volume=${RADIUSDESK_VOLUME} \
             -t radiusdesk/rdcore:latest \
             .

echo "Run script:"
docker exec -u 0 -it $(docker ps -qf name=mariadb) /tmp/startup.sh

echo "Deploy radius:"
docker compose -f radiusDesk-stack.yml up -d radiusdesk

echo
echo All done!