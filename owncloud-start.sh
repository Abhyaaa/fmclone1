#!/bin/bash

# Hack around smbpasswd issue
chmod +x /usr/bin/smbpasswd

OC_HOMEDIR=/var/www/owncloud

occ_cmd() {
    sudo -u www-data bash -c "php $OC_HOMEDIR/occ $*"
}
# Add JARVICE cert
occ_cmd "security:certificates:import /etc/JARVICE/cert.pem"
if [ -x /usr/sbin/sshd ]; then
    /usr/sbin/sshd-keygen && /usr/sbin/sshd
fi

if [ -x /usr/bin/mysql ]; then
    echo
fi

if [ -x /usr/sbin/php-fpm -a -x /usr/sbin/nginx ]; then
    sudo /usr/sbin/php-fpm -D && sudo /usr/sbin/nginx
fi

if [ -x /usr/sbin/httpd ]; then
    sudo mkdir -p /run/apache2
    sudo chmod 01777 /run/apache2
    sudo chmod 750 /run/apache2
    # sudo useradd -o -u 505 -g 505 -M nimbix || true
    usermod -a -G www-data $(whoami)
    # Set uid for pwauth
    OC_USER_UID=$(id -u)
    occ_cmd "config:app:set --value=$OC_USER_UID user_pwauth uid_list"
    sudo APACHE_RUN_USER=$(whoami) APACHE_RUN_GROUP=$(whoami) /usr/bin/entrypoint /usr/sbin/apache2 -f /etc/apache2/apache2.conf -D FOREGROUND
fi
