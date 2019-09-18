FROM centos:7
LABEL maintainer="Nimbix, Inc."

RUN yum -y install epel-release && \
    curl -H 'Cache-Control: no-cache' \
    https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
    | bash

# Prep for OwnCloud install with PHP 7.2 install and httpd
RUN yum-config-manager --add-repo=http://download.owncloud.org/download/repositories/production/CentOS_7/ce:stable.repo && \
    yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm  && \
    yum-config-manager --enable remi-php72 && \
    yum install -y httpd php72 php72-php php72-php-gd php72-php-mbstring \
        php72-php-mysqlnd php72-php-cli php72-pecl-apcu php72-php-common \
        php72-php-ldap php72-php-xml php72-php-intl php72-php-zip php72-php-posix

# OwnCloud install
RUN yum-config-manager --add-repo=http://download.owncloud.org/download/repositories/production/CentOS_7/ce:stable.repo && \
    yum install -y owncloud-files pwgen pwauth samba-common-tools rsync mod_ssl mod_authnz_external && \
    yum clean all

# Copy in custom owncloud installer and components, run the installer
COPY owncloud /tmp/owncloud
RUN /tmp/owncloud/owncloud-install.sh --with-httpd && \
    mv /tmp/owncloud/owncloud-start.sh /usr/local/bin && \
    rm -rf /tmp/owncloud

ENTRYPOINT ["/usr/local/bin/owncloud-start.sh"]

EXPOSE 443/tcp 22/tcp

COPY NAE/AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://api.jarvice.com/jarvice/validate

COPY NAE/help.html /etc/NAE/help.html
