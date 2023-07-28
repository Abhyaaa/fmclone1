FROM us-docker.pkg.dev/jarvice-apps/images/filemanager:oc10.9-v2-test

RUN rm -f /usr/local/bin/owncloud-start.sh && rm -f /usr/bin/server && rm -Rf /var/www/owncloud && chmod 777 -R /etc/apache2
COPY owncloud-start.sh /usr/local/bin/owncloud-start.sh
COPY server /usr/bin/server