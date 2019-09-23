#!/bin/bash

usage() {
    echo "$0 [--oc-user <username>] [--oc-user-password <password>] [--with-mariadb|--with-mysql] --with-httpd|--with-nginx"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --with-httpd)
            [ -n "$WITH_NGINX" ] && usage && exit 1
            WITH_HTTPD=1
            ;;
        --with-nginx)
            [ -n "$WITH_HTTPD" ] && usage && exit 1
            WITH_NGINX=1
            ;;
        --with-mariadb|--with-mysql)
            WITH_MARIADB=1
            ;;
        --oc-user)
            OC_USER="$2"
            shift
            ;;
        --oc-user-password)
            OC_USER_PASS="$2"
            shift
            ;;
        --oc-db-name)
            OC_DB_NAME="$2"
            shift
            ;;
        --oc-db-user)
            OC_DB_USER="$2"
            shift
            ;;
        --oc-db-password)
            OC_DB_PASS="$2"
            shift
            ;;
        --oc-admin-user)
            OC_ADMIN_USER="$2"
            shift
            ;;
        --oc-admin-password)
            OC_ADMIN_PASS="$2"
            shift
            ;;
        *)
            usage && exit 1
            ;;
    esac
    shift
done

[ -z "$WITH_HTTPD" ] && [ -z "$WITH_NGINX" ] && usage && exit 1

set -e

# User configs
[ -z "$OC_USER" ] && OC_USER=nimbix
[ -z "$OC_USER_PASS" ] && OC_USER_PASS="$(pwgen -1 32)"

[ -z "$OC_DB_NAME" ] && OC_DB_NAME=owncloud
[ -z "$OC_DB_USER" ] && OC_DB_USER=root
[ -z "$OC_DB_PASS" ] && OC_DB_PASS="$(pwgen -1 32)"

[ -z "$OC_ADMIN_USER" ] && OC_ADMIN_USER=admin
[ -z "$OC_ADMIN_PASS" ] && OC_ADMIN_PASS="$(pwgen -1 32)"

OC_HOMEDIR=/var/www/html/owncloud

if [ -n "$WITH_HTTPD" ]; then
    echo "Configuring for Apache httpd..."

    sed -i -e "s/^User apache/User $OC_USER/" /etc/httpd/conf/httpd.conf
    sed -i -e "s/^Group apache/Group $OC_USER/" /etc/httpd/conf/httpd.conf

    # Use JARVICE cert for SSL
    sed -i -e 's/^SSLCertificateKeyFile/#SSLCertificateKeyFile/' \
        /etc/httpd/conf.d/ssl.conf
    sed -i -e \
        's|^SSLCertificateFile.*|SSLCertificateFile /etc/JARVICE/cert.pem|' \
        /etc/httpd/conf.d/ssl.conf

elif [ -n "$WITH_NGINX" ]; then
    echo "Configuring for nginx..."

    cp nginx.conf /etc/nginx/nginx.conf
    cp /etc/php-fpm.d/owncloud.conf /etc/php-fpm.d/owncloud.conf~
    grep -v '^listen.allowed_clients' /etc/php-fpm.d/owncloud.conf~ >/etc/php-fpm.d/owncloud.conf
    sed -i -e "s/^user =.*/user = $OC_USER/" /etc/php-fpm.d/owncloud.conf
    sed -i -e "s/^group =.*/group = $OC_USER/" /etc/php-fpm.d/owncloud.conf
    sed -i -e "s/^acl_users =.*/acl_users = $OC_USER,apache,nginx/" /etc/php-fpm.d/owncloud.conf
    sed -i -e 's/10G/50G/g' /etc/php-fpm.d/owncloud.conf
fi

occ_db_type=sqlite
if [ -n "$WITH_MARIADB" ]; then
    echo "Configuring for mariadb/mysql..."

    occ_db_type=mysql
else
    echo "Configuring for sqlite..."
fi

# Set locale
localedef -i en_US -f UTF-8 en_US.UTF-8

# Now do ownCloud setup and config
#occ="sudo -u apache bash -c "source scl_source enable php72 && php /var/www/html/owncloud/occ -vvv\""
occ_cmd() {
    sudo -u apache bash -c "source scl_source enable php72 && php $OC_HOMEDIR/occ $*"
}

echo "Chown ownCloud directory... "
chown -R apache:apache $OC_HOMEDIR

# Initialize ownCloud
echo "Configuring Owncloud initial maintenance install"
INSTARGS="maintenance:install "
INSTARGS+="--database=$occ_db_type "
INSTARGS+="--database-name=$OC_DB_NAME "
INSTARGS+="--database-user=$OC_DB_USER "
INSTARGS+="--database-pass=$OC_DB_PASS "
INSTARGS+="--admin-user=$OC_ADMIN_USER "
INSTARGS+="--admin-pass=$OC_ADMIN_PASS "
INSTARGS+="--data-dir=$OC_HOMEDIR/data -vvv"
occ_cmd "$INSTARGS"

# Log file is $data-dir/owncloud.log
echo "Configuring OwnCloud logging"
occ_cmd "config:system:set --type=string --value=owncloud log_type"

# Loglevel to start logging at. Valid values are: 0 = Debug, 1 = Info,
# 2 = Warning, 3 = Error, and 4 = Fatal. The default value is Warning.
occ_cmd "config:system:set --type=int --value=0 loglevel"

# Uncomment if extra debug info is needed
#occ_cmd config:system:set --type=bool --value=true debug

# Security check
occ_cmd "config:system:set --type=bool --value=true check_for_working_htaccess"

# Don't allow unencrypted usage
occ_cmd config:system:set --type=bool --value=true force_ssl

# Allow connections from anywhere
#occ_cmd "config:system:delete trusted_domains 0"
#occ_cmd "config:system:delete trusted_domains"

# Deleting trusted_domains config doesn't work due to bug in isTrustedDomain
sed -i -e 's/return \\in_array.*/return true;/' \
    $OC_HOMEDIR/lib/private/Security/TrustedDomainHelper.php

# Don't allow the user to change name and password
#sed -i -e 's/.*displayNameChangeSupported.*//' \
#    /usr/share/owncloud/settings/personal.php
#sed -i -e 's/.*passwordChangeSupported.*//' \
#    /usr/share/owncloud/settings/personal.php

# Disable unnecessary settings that could confuse users
names="updatechecker appstoreenabled knowledgebaseenabled enable_avatars"
names+=" allow_user_to_change_display_name"
for name in $names; do
    occ_cmd "config:system:set --type=bool --value=false $name"
done

# Remove unnecessary apps that could confuse users
apps="files_sharing files_versions files_trashbin systemtags"
apps+=" notifications firstrunwizard"
#apps+=" federatedfilesharing"  # federatedfilesharing can't be disabled?
for app in $apps; do
    occ_cmd "app:disable $app"
done

# ownCloud app store is disabled
occ_cmd "config:system:set --type=bool --value=false apps_paths 1 writable"

#sed -i -e "/'updatechecker' => false,/ a 'files_external_allow_create_new_local' => true," \
#    $OC_HOMEDIR/config/config.php

# Configure external storage
occ_cmd "app:enable files_external"
occ_cmd "files_external:create / local null::null"
occ_cmd "files_external:config 1 datadir /data"
occ_cmd "files_external:option 1 enable_sharing true"
occ_cmd "config:app:set --value 'ftp,dav,owncloud,sftp,amazons3,dropbox,googledrive,swift,smb,local' files_external user_mounting_backends"
occ_cmd "config:app:set --value=yes -- core enable_external_storage"

# Check each file or folder at most once per request
occ_cmd "config:system:set --type=int --value=1 filesystem_check_changes"

# Empty skel dir to keep extraneous files out of user dirs when created
occ_cmd "config:system:set skeletondirectory"

# Configure unix pwauth to allow $OC_USER to login
pwauth_pkg=$(ls $(dirname $0)/user_pwauth-*.tar.gz)
tar -xf "$pwauth_pkg" -C $OC_HOMEDIR/apps
chown -R apache.apache $OC_HOMEDIR/apps/user_pwauth
#sed -i -e 's|apps/user_pwauth|user_pwauth|' \
#    $OC_HOMEDIR/apps/user_pwauth/appinfo/app.php  # fix require_once bug
occ_cmd "app:enable user_pwauth"
occ_cmd "config:app:set --value=/usr/bin/pwauth user_pwauth pwauth_path"

# Modify the "routes" registration..
sed -i -e 's/showLoginForm/tryLogin/g' $OC_HOMEDIR/core/routes.php

# Don't check requesttoken
sed -i -e 's/passesCSRFCheck() {/passesCSRFCheck() { return true;/' \
    $OC_HOMEDIR/lib/private/AppFramework/Http/Request.php

OC_USER_UID=$(/usr/bin/id -u $OC_USER 2>/dev/null)
if [ -n "$OC_USER_UID" ]; then
    occ_cmd "config:app:set --value=$OC_USER_UID user_pwauth uid_list"
else
    export OC_PASS=$OC_USER_PASS
    occ_cmd "user:add --password-from-env --group=$OC_USER $OC_USER"
fi

# Setup Nimbix theme, now an OC app
if [ -d $(dirname $0)/nimbix-theme ]; then
    cp -r $(dirname $0)/nimbix-theme $OC_HOMEDIR/apps
    chown -R apache:apache $OC_HOMEDIR/apps/nimbix-theme
    occ_cmd app:enable nimbix-theme
fi

# Done configuring, don't allow changes from the web interface
#occ_cmd "config:system:set --type=bool --value=true config_is_read_only"
usermod -a -G apache $OC_USER
chmod -R 0770 /var/www/html/owncloud/data
chmod 777 /var/www/html/owncloud/lib/private/Config.php
chmod 777 /var/www/html/owncloud/config/config.php
chmod 0770  /var/www/html/owncloud/config

OC_URL="https://%PUBLICADDR%/owncloud/index.php/login?user=%NIMBIXUSER%&password=%NIMBIXPASSWD%"
mkdir -p /etc/NAE
cat <<EOF | sudo tee /etc/NAE/url.txt >/dev/null
$OC_URL
EOF

# Hack around smbpasswd issue
chmod -x /usr/bin/smbpasswd
