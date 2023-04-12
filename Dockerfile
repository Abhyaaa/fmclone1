# Using 10 gets us to trusted_domains error
FROM owncloud/server:10.9 as builder 
LABEL maintainer="Nimbix, Inc."

# Serial Number
ARG SERIAL_NUMBER=20230407.1000
ENV SERIAL_NUMBER=${SERIAL_NUMBER}

ARG OC_CONFIG_ROOT
# ENV OC_CONFIG_ROOT=${OC_CONFIG_ROOT:-/etc/skel/owncloud}
ENV OC_CONFIG_ROOT=/etc/skel/owncloud

# Try adding a file that apache keeps erroring at
RUN mkdir -p /etc/apache2 && touch /etc/apache2/envvars

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash -s -- --skip-mpi-pkg

RUN apt-get -y update && apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install pwgen pwauth

RUN mkdir -p $OC_CONFIG_ROOT/config $OC_CONFIG_ROOT/files $OC_CONFIG_ROOT/apps $OC_CONFIG_ROOT/sessions && \
    chown -R www-data.www-data $OC_CONFIG_ROOT

# Set locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# Copy in custom owncloud installer and components, run the installer
COPY --chown=www-data owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    rm -rf /tmp/owncloud && \
    cp -r /var/www/owncloud/apps /etc/skel/owncloud

RUN mkdir -p /etc/NAE && \
    echo 'http://%PUBLICADDR%:8080/login?user=%NIMBIXUSER%&password=%NIMBIXPASSWD%' > /etc/NAE/url.txt

RUN mkdir -p /etc/skel/owncloud_root && \
    mv /var/www/owncloud/* /etc/skel/owncloud_root && \
    chmod --recursive 0777 /var/www

RUN chmod --recursive 0777 /etc/php/7.4/mods-available/owncloud.ini && \
    chmod --recursive 0777 /etc/apache2/sites-enabled/

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

RUN chmod -R 777 /etc/skel /run /var

# Try deleting some packages...
RUN apt-get purge -y \
    cmake* \
    cpp* \
    git \
    xz-utils \
    samba*

RUN apt-get -y autoclean && \
    apt-get -y autoremove && \
    apt-get clean

WORKDIR /var/www
# ENTRYPOINT ["/usr/local/bin/owncloud-start.sh"]

FROM scratch

COPY --from=builder / /
