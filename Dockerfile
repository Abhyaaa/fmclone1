FROM nimbix/centos-base:7
MAINTAINER Nimbix, Inc.

ADD owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    mv /tmp/owncloud/owncloud-start.sh /usr/local/bin && \
    rm -rf /tmp/owncloud

ENTRYPOINT ["/usr/local/bin/owncloud-start.sh"]

EXPOSE 443/tcp 22/tcp

COPY ./NAE/AppDef.json /etc/NAE/AppDef.json
