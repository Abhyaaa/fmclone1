#!/bin/bash

if [ -x /usr/bin/mysql ]; then
    echo
fi

if [ -x /usr/sbin/php-fpm -a -x /usr/sbin/nginx ]; then
    sudo /usr/sbin/php-fpm -D && sudo /usr/sbin/nginx
fi

if [ -x /usr/sbin/httpd ]; then
    sudo /usr/sbin/httpd -D FOREGROUND
fi

