#!/bin/bash

OC_HOMEDIR=/var/www/owncloud

# if [ -x /usr/sbin/sshd ]; then
#     /usr/sbin/ssh-keygen && /usr/sbin/sshd
# fi
    # apache workaround for logging
    sudo chmod 777 /dev/stdout /dev/stderr
    OC_USER="$(whoami)"
    # sudo chown -R $OC_USER.root $OC_HOMEDIR
    mkdir -p /tmp/config /tmp/files /tmp/apps /tmp/sessions
    cp -r /var/www/owncloud/apps/* /tmp/apps/
    # sudo useradd -o -u 505 -g 505 -M nimbix || true
    # sudo sed -i "%s/www-data/${OC_USER}/g" /etc/owncloud.d/25-chown.sh
    sed -i "s/www-data/${OC_USER}/g" $HOME/bin/occ
    export PATH=$HOME/bin:$PATH
    JOB_SUBPATH=""
    [[ -n "${JARVICE_INGRESSPATH}" ]] && JOB_SUBPATH="/${JARVICE_INGRESSPATH}" 
    APACHE_ERROR_LOG="/dev/stdout" \
    APACHE_LOG_LEVEL="debug" \
    APACHE_RUN_USER=$OC_USER \
    APACHE_RUN_GROUP=$OC_USER \
    APACHE_LISTEN=8080 \
    OWNCLOUD_SKIP_CHOWN="true" \
    OWNCLOUD_SKIP_CHMOD="true" \
    OWNCLOUD_VOLUME_CONFIG="/tmp/config" \
    OWNCLOUD_VOLUME_FILES="/tmp/files" \
    OWNCLOUD_VOLUME_APPS="/tmp/apps" \
    OWNCLOUD_VOLUME_SESSIONS="/tmp/sessions" \
    OWNCLOUD_PROTOCOL="http" \
    OWNCLOUD_SUB_URL="$JOB_SUBPATH" \
    OWNCLOUD_CROND_ENABLED="false" \
    OWNCLOUD_LOG_FILE="/tmp/files/owncloud.log" \
    sleep 6000
    # owncloud server
    # /usr/bin/entrypoint /usr/sbin/apache2 -f /etc/apache2/apache2.conf -D FOREGROUND
