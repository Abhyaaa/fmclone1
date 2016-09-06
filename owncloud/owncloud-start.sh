#!/bin/bash

if [ -x /usr/bin/mysql ]; then
    echo
fi

if [ -x /usr/sbin/php-fpm -a -x /usr/sbin/nginx ]; then
    /usr/sbin/php-fpm -D && /usr/sbin/nginx
fi

if [ -x /usr/sbin/httpd ]; then
    /usr/sbin/httpd -D FOREGROUND
fi

