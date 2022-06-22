#!/bin/bash
# sudo newgrp www-data << EOF
# export DEBUG="true"
[[ "${DEBUG}" == "true" ]] && set -x
OC_HOMEDIR=/var/www/owncloud
OC_CONFIG_ROOT="$HOME/owncloud"
# sudo usermod -a -G www-data $JARVICE_ID_USER
# sed -i 's/www-data/$JARVICE_ID_USER/' /usr/bin/occ
# apache workaround for logging
sudo chmod 777 /dev/stdout /dev/stderr
rm -rf $OC_HOMEDIR
ln -s $HOME/owncloud_root $OC_HOMEDIR
OC_USER="$JARVICE_ID_USER"
OC_GROUP="$JARVICE_ID_GROUP"
export OWNCLOUD_SUB_URL="/${JARVICE_INGRESSPATH:-}"
export OWNCLOUD_OVERWRITE_CLI_URL="http://localhost${OWNCLOUD_SUB_URL}"
export OWNCLOUD_HTACCESS_REWRITE_BASE="${OWNCLOUD_SUB_URL}"

source $OC_CONFIG_ROOT/owncloud-setup.sh
source $OC_CONFIG_ROOT/owncloud-db.sh
export OWNCLOUD_SESSION_SAVE_PATH=${OWNCLOUD_VOLUME_SESSIONS}
export APACHE_ERROR_LOG="/dev/stdout"
export APACHE_LOG_LEVEL="debug"
export APACHE_RUN_USER="$OC_USER"
export APACHE_RUN_GROUP="$OC_GROUP"
export APACHE_LISTEN=8080

ln -s ${OWNCLOUD_VOLUME_CONFIG} /var/www/owncloud/config
ln -s ${OWNCLOUD_VOLUME_APPS} /var/www/owncloud/custom

owncloud server
# EOF
