FROM centos:7
LABEL maintainer="Nimbix, Inc."

RUN curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash

RUN rpm --import https://download.owncloud.org/download/repositories/9.1/CentOS_7/repodata/repomd.xml.key && \
    yum install -y owncloud owncloud-files && \
    yum -y install pwgen pwauth rsync mod_ssl mod_authnz_external

COPY owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    rm -rf /tmp/owncloud

COPY owncloud-start.sh /usr/local/bin/owncloud-start.sh

ENTRYPOINT ["/usr/local/bin/owncloud-start.sh"]

EXPOSE 443/tcp 22/tcp

COPY ./NAE/AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://api.jarvice.com/jarvice/validate
