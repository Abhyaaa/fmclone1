FROM owncloud/server:10.10
LABEL maintainer="Nimbix, Inc."

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash -s -- --setup-nimbix-desktop

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install pwgen pwauth ssh

# Copy in custom owncloud installer and components, run the installer
COPY owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    rm -rf /tmp/owncloud

RUN mkdir -p /run/apache2 && \
    sudo mkdir -p /var/lock/apache2 && \
    sudo chmod 01777 /run/apache2 && \
    sudo chmod 750 /run/apache2
 
RUN chmod -R 777 /var/www/owncloud && \
    chmod -R 777 /etc/php/7.4/mods-available/owncloud.ini && \
    chmod -R 777 /etc/apache2/sites-enabled/ && \
    chmod 777 /dev/stderr && \
    chmod 777 /dev/stdout

RUN mkdir /etc/skel/bin && \
    cp /usr/bin/occ /etc/skel/bin && \
    echo 'export PATH=$HOME/bin:$PATH' >> /etc/skel/.bashrc

COPY owncloud-start.sh /usr/local/bin/owncloud-start.sh
COPY owncloud-setup.sh /usr/local/bin/owncloud-setup.sh

COPY NAE/AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

COPY NAE/help.html /etc/NAE/help.html

RUN mkdir -p /etc/NAE && touch /etc/NAE/screenshot.png /etc/NAE/screenshot.txt /etc/NAE/license.txt /etc/NAE/AppDef.json

ENTRYPOINT ["/usr/local/bin/owncloud-start.sh"]
