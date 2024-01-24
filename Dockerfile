# Using 10 gets us to trusted_domains error stay on 9
FROM owncloud/server:10.9 as builder
LABEL maintainer="Nimbix, Inc."

# Serial Number
ARG SERIAL_NUMBER=20240124.1000
ENV SERIAL_NUMBER=${SERIAL_NUMBER}

ARG OC_CONFIG_ROOT=/etc/skel/owncloud
ENV OC_CONFIG_ROOT=${OC_CONFIG_ROOT}

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

# Copy in custom owncloud installer and components, run the installer (composer.lock contains firebase php 5.5 {threat})
COPY --chown=www-data owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    rm -rf /tmp/owncloud && \
    sed -i '83 i if (getenv("JARVICE_JOBTOKEN64") == $password) return $uid;' /var/www/owncloud/apps/user_pwauth/lib/UserPwauth.php && \
    rm /var/www/owncloud/apps/files_external/3rdparty/composer.lock && \
    cp -r /var/www/owncloud/apps /etc/skel/owncloud

RUN mkdir -p /etc/NAE && \
    echo 'http://%PUBLICADDR%:5902/login?user=%NIMBIXUSER%&password=%RANDOM64%' > /etc/NAE/url.txt

# Set /data as the entry point when using sftp [Does nothing as sshd is not run on this image but on init...]
RUN sed -i 's/\Subsystem\tsftp\t\/usr\/lib\/openssh\/sftp-server\b/Subsystem\tsftp\t\/usr\/lib\/openssh\/sftp-server -d \/data/g' /etc/ssh/sshd_config

RUN mkdir -p /etc/skel/owncloud_root && \
    mv /var/www/owncloud/* /etc/skel/owncloud_root && \
    chmod --recursive 0777 /var/www

RUN chmod --recursive 0777 /etc/php/7.4/mods-available/owncloud.ini && \
    chmod --recursive 0777 /etc/apache2/sites-enabled/

RUN sed -i 's/${OWNCLOUD_PRE_SERVER_PATH} -iname \*.sh/\${OWNCLOUD_PRE_SERVER_PATH} -iname \\*.sh/g' /usr/bin/server

COPY --chown=www-data owncloud-start.sh /usr/local/bin/owncloud-start.sh
COPY --chown=www-data owncloud-setup.sh /etc/pre_server.d/owncloud-setup.sh

COPY NAE/AppDef.json /etc/NAE/AppDef.json
COPY NAE/help.html /etc/NAE/help.html
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

RUN mkdir -p /etc/NAE && touch /etc/NAE/screenshot.png /etc/NAE/screenshot.txt /etc/NAE/license.txt /etc/NAE/AppDef.json

RUN chmod -R 777 /etc/skel /run /var

# Try deleting some packages...
RUN apt-get purge -y \
    cmake* \
    cpp* \
    git \
    xz-utils

RUN apt-get -y autoclean && \
    apt-get -y autoremove && \
    apt-get clean

# Remove CVE-2023-49103
RUN rm -rf /etc/skel/owncloud/apps/graphapi/vendor/microsoft/microsoft-graph/tests && \
    rm -rf /etc/skel/owncloud_root/apps/graphapi/vendor/microsoft/microsoft-graph/tests

WORKDIR /var/www

FROM scratch

COPY --from=builder / /
