FROM owncloud/server:10.10
LABEL maintainer="Nimbix, Inc."

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash -s -- --setup-nimbix-desktop

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install pwgen pwauth

# Copy in custom owncloud installer and components, run the installer
COPY owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    rm -rf /tmp/owncloud

COPY owncloud-start.sh /usr/local/bin/owncloud-start.sh

COPY NAE/AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

COPY NAE/help.html /etc/NAE/help.html

RUN mkdir -p /etc/NAE && touch /etc/NAE/screenshot.png /etc/NAE/screenshot.txt /etc/NAE/license.txt /etc/NAE/AppDef.json

ENTRYPOINT ["/usr/local/bin/owncloud-start.sh"]
