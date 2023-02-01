FROM gcr.io/jarvice/app-filemanager:ocpassform-sameorigin as V1

RUN chmod -R 777 /usr /etc /run /var; \
    chmod -R 777 /run/httpd; \
    sed -i "/smbpasswd/d" /usr/local/bin/owncloud-start.sh; \
    sed -i "s/sudo//g" /usr/local/bin/owncloud-start.sh; \
    sed -i 's/\(self::runningOnWindows\(\)\)/0 == 0/' /usr/share/owncloud/lib/private/legacy/util.php; \
    sed -i 's/0()/0/' /usr/share/owncloud/lib/private/legacy/util.php; \
    sed -i '83 i if (getenv("JARVICE_JOBTOKEN64") == $password) return $uid;' /var/lib/owncloud/apps/user_pwauth/user_pwauth.php ;\
    sed -i 's/.*upload_tmp_dir\ =.*/upload_tmp_dir = \/data\/.jarvice-file-manager/' /etc/php.ini; \
    rm -f /etc/httpd/conf.d/ssl.conf; \
    rm -f /etc/NAE/AppDef.json; \
    echo 'https://%PUBLICADDR%:5902/owncloud/index.php/login?user=%NIMBIXUSER%&password=%RANDOM64%' > /etc/NAE/url.txt

FROM scratch

COPY --from=V1 / /

COPY owncloud-start.sh /usr/local/bin/owncloud-start.sh
COPY AppDef.json /etc/NAE/AppDef.json

RUN mkdir -p /etc/NAE && touch /etc/NAE/{url.txt,AppDef.json}
 
