FROM owncloud/server:10.10
LABEL maintainer="Nimbix, Inc."

ARG OC_CONFIG_ROOT
ENV OC_CONFIG_ROOT=${OC_CONFIG_ROOT:-/etc/skel/owncloud}

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash -s -- --setup-nimbix-desktop

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install pwgen pwauth

RUN mkdir -p $OC_CONFIG_ROOT/config $OC_CONFIG_ROOT/files $OC_CONFIG_ROOT/apps $OC_CONFIG_ROOT/sessions && \
    mkdir -p /run/apache2 && \
    mkdir -p /var/run/lock/apache2 && \
    chown -R www-data.www-data /var/www/owncloud /var/run/lock/apache2 && \
    chown -R www-data.www-data $OC_CONFIG_ROOT && \
    chmod 01777 /run/apache2 && \
    chmod 750 /run/apache2

# Set locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# Copy in custom owncloud installer and components, run the installer
COPY --chown=www-data owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    rm -rf /tmp/owncloud && \
    cp -r /var/www/owncloud/apps /etc/skel/owncloud

RUN echo 'http://%PUBLICADDR%:8080/login?user=%NIMBIXUSER%&password=%NIMBIXPASSWD%' > /etc/NAE/url.txt

RUN chown -R www-data.www-data /etc/php/7.4/mods-available/owncloud.ini && \
    chown -R www-data.www-data /etc/apache2/sites-enabled/ && \
    chmod -R 770 /var/www/owncloud

# RUN mkdir /etc/skel/bin && \
#      cp /usr/bin/occ /etc/skel/bin && \
#      echo 'export PATH=$HOME/bin:$PATH' >> /etc/skel/.bashrc

RUN sed -i 's/${OWNCLOUD_PRE_SERVER_PATH} -iname \*.sh/\${OWNCLOUD_PRE_SERVER_PATH} -iname \\*.sh/g' /usr/bin/server

COPY --chown=www-data owncloud-start.sh /usr/local/bin/owncloud-start.sh
COPY --chown=www-data owncloud-setup.sh /etc/pre_server.d/owncloud-setup.sh

COPY NAE/AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

COPY NAE/help.html /etc/NAE/help.html

RUN mkdir -p /etc/NAE && touch /etc/NAE/screenshot.png /etc/NAE/screenshot.txt /etc/NAE/license.txt /etc/NAE/AppDef.json

ENTRYPOINT ["/usr/local/bin/owncloud-start.sh"]
