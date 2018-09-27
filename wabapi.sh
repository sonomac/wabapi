#!/bin/bash
#
# Run all images on local VM
#

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

WADB_IMAGE="mysql:5.7.22"
WACORE_IMAGE="docker.whatsapp.biz/coreapp:v2.19.4"
WAWEB_IMAGE="docker.whatsapp.biz/web:v2.19.4"

DATAROOT=${DATAROOT:-${BASEDIR}}

WABAPI_VOLUMES=( 
     "${DATAROOT}/data:/usr/local/waent/data"
     "${DATAROOT}/media:/usr/local/wamedia"
   )

WABAPI_COMMANDS=(
     "/opt/whatsapp/bin/wait_on_mysql.sh"
     "/opt/whatsapp/bin/launch_within_docker.sh"
   )

MYSQL_SECRETS=${DATAROOT}/secrets
#NOTE: remove the IP-Address to be exposed outside of the local network
MYSQL_PORTS="127.0.0.1:33060:3306"


function docker_run() {

}

function wabapi_start() {
   echo "Starting WhatsApp Business API Images ..."

   docker run -d --name=wadb  -p 127.0.0.1:33060:3306  -e MYSQL_ROOT_PASSWORD_FILE="/run/secrets/mysql/credentials.root"  -e MYSQL_USER="wauser"  -e MYSQL_PASSWORD_FILE="/run/secrets/mysql/credentials.mysql" mysql:5.7.22
 
   docker run -d --name=wacore  --link=wadb  --link=wadb docker.whatsapp.biz/coreapp:v2.19.4 /opt/whatsapp/bin/wait_on_mysql.sh /opt/whatsapp/bin/launch_within_docker.sh
 
   docker run -d --name=waweb  --link=wadb  --link=wacore  --link=wadb  --link=wacore  -p 9090:443  -e WACORE_HOSTNAME="wacore.local" docker.whatsapp.biz/web:v2.19.4 /opt/whatsapp/bin/wait_on_mysql.sh /opt/whatsapp/bin/launch_within_docker.sh

}

function wabapi_stop() {
   echo "Stopping WhatsApp Business API Images ..."

   # 1. shutdown gracefully local HTTPD server
   service apache2 graceful-stop


}