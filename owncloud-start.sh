#!/bin/bash

# Hack around smbpasswd issue
chmod +x /usr/bin/smbpasswd

if [[ -x /usr/sbin/sshd ]]; then
    /usr/sbin/sshd-keygen && /usr/sbin/sshd
fi

if [[ -x /usr/bin/mysql ]]; then
    echo
fi

if [[ -x /usr/sbin/php-fpm && -x /usr/sbin/nginx ]]; then
    sudo /usr/sbin/php-fpm -D && sudo /usr/sbin/nginx
fi

if [[ -x /usr/sbin/httpd ]]; then
    sudo mkdir -p /run/httpd
    sudo chmod 01777 /run/httpd
    sudo chmod 750 /run/httpd
    # extra useradd after platform has created the user already
#    sudo useradd -o -u 505 -g 505 -M ${USER} || true
    sudo /usr/sbin/httpd -D FOREGROUND
fi
