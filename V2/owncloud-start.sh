#!/bin/bash

mkdir -p /run/httpd
chmod 01777 /run/httpd
chmod 750 /run/httpd
chown -R $USER:$USER /var/lib/owncloud/
chmod -R 770 /var/lib/owncloud/
mkdir -p /data/.jarvice-file-manager
export JARVICE_JOBTOKEN64=${JARVICE_JOBTOKEN:0:64}
PORTNUM=${JARVICE_SERVICE_PORT:-5902}
sed -i "s/Listen\ 80/Listen $PORTNUM/" /etc/httpd/conf/httpd.conf
/usr/sbin/httpd -D FOREGROUND
