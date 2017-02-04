#!/bin/bash

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
    sudo mkdir -p /run/httpd
    sudo chown root:apache /run/httpd
    sudo chmod 750 /run/httpd
    sudo /usr/sbin/httpd -D FOREGROUND
fi

