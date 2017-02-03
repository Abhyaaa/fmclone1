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

# EPEL repo
yum -y update; yum clean all; yum -y install epel-release; yum clean all

PACKAGES="sudo pwgen pwauth unzip rsync openssh-server"
if [ -n "$WITH_HTTPD" ]; then
    PACKAGES+=" owncloud-httpd mod_ssl mod_authnz_external"
elif [ -n "$WITH_NGINX" ]; then
    PACKAGES+=" owncloud-nginx"
fi

if [ -n "$WITH_MARIADB" ]; then
    PACKAGES+=" owncloud-mysql mariadb-server"
else
    PACKAGES+=" owncloud-sqlite"
fi

yum install -y $PACKAGES; yum clean all

# User configs
[ -z "$OC_USER" ] && OC_USER=nimbix
[ -z "$OC_USER_PASS" ] && OC_USER_PASS="$(pwgen -1 32)"

[ -z "$OC_DB_NAME" ] && OC_DB_NAME=owncloud
[ -z "$OC_DB_USER" ] && OC_DB_USER=root
[ -z "$OC_DB_PASS" ] && OC_DB_PASS="$(pwgen -1 32)"

[ -z "$OC_ADMIN_USER" ] && OC_ADMIN_USER=admin
[ -z "$OC_ADMIN_PASS" ] && OC_ADMIN_PASS="$(pwgen -1 32)"

if [ -n "$WITH_HTTPD" ]; then
    echo "Configuring for apache httpd..."

    sed -i -e "s/^User apache/User $OC_USER/" /etc/httpd/conf/httpd.conf
    sed -i -e "s/^Group apache/Group $OC_USER/" /etc/httpd/conf/httpd.conf

    # Use jarvice cert for SSL
    sed -i -e 's/^SSLCertificateKeyFile/#SSLCertificateKeyFile/' \
        /etc/httpd/conf.d/ssl.conf
    sed -i -e \
        's|^SSLCertificateFile.*|SSLCertificateFile /etc/JARVICE/cert.pem|' \
        /etc/httpd/conf.d/ssl.conf

    # Override default owncloud httpd config...
    cat <<EOF | sudo tee -a /etc/httpd/conf.d/z-owncloud.conf >/dev/null
<Directory /usr/share/owncloud/>
    Include conf.d/owncloud-auth-any.inc
    Include conf.d/owncloud-options.inc
</Directory>

<Directory /var/lib/owncloud/apps/>
    Include conf.d/owncloud-auth-any.inc
    Include conf.d/owncloud-options.inc
</Directory>

<Directory /var/lib/owncloud/assets/>
    Include conf.d/owncloud-auth-any.inc
    Include conf.d/owncloud-options.inc
</Directory>

<IfModule reqtimeout_module>
    RequestReadTimeout header=0
    RequestReadTimeout body=0
</IfModule>

#<Location "/owncloud">
#    # Require SSL connection for password protection.
#    SSLRequireSSL
#
#    AuthType Basic
#    AuthName "Nimbix File Manager"
#    AuthBasicProvider external
#    AuthExternal pwauth
#    Require user $OC_USER
#</Location>
EOF
    cat <<EOF | sudo tee -a /etc/httpd/conf.d/owncloud-options.inc >/dev/null

<IfModule mod_php5.c>
    php_value upload_max_filesize 100G
    php_value post_max_size 0
    php_value max_input_time 0
    php_value max_execution_time 0
    php_value memory_limit 1G
    php_value mbstring.func_overload 0
    php_value always_populate_raw_post_data -1
    php_value default_charset 'UTF-8'
    php_value output_buffering off
    <IfModule mod_env.c>
        SetEnv htaccessWorking true
    </IfModule>
</IfModule>
EOF

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
occ_db_pass="$(pwgen -1 32)"
if [ -n "$WITH_MARIADB" ]; then
    echo "Configuring for mariadb/mysql..."

    occ_db_type=mysql
else
    echo "Configuring for sqlite..."
fi

# Now do ownCloud setup and config
occ="sudo -E -u apache /usr/bin/php /usr/share/owncloud/occ -vvv"

# Initialize ownCloud
$occ maintenance:install \
    --database "$occ_db_type" --database-name "$OC_DB_NAME" \
    --database-user "$OC_DB_USER" --database-pass "$OC_DB_PASS" \
    --admin-user "$OC_ADMIN_USER" --admin-pass "$OC_ADMIN_PASS" \
    --data-dir /var/lib/owncloud/data

# Log file is $data-dir/owncloud.log
$occ config:system:set --type=string --value=owncloud log_type

# Loglevel to start logging at. Valid values are: 0 = Debug, 1 = Info,
# 2 = Warning, 3 = Error, and 4 = Fatal. The default value is Warning.
$occ config:system:set --type=int --value=2 loglevel

# Uncomment if extra debug info is needed
#$occ config:system:set --type=bool --value=true debug

# Security check
$occ config:system:set --type=bool --value=true check_for_working_htaccess

# Don't allow unencrypted usage
$occ config:system:set --type=bool --value=true force_ssl

# Allow connections from anywhere
#$occ config:system:delete trusted_domains 0
#$occ config:system:delete trusted_domains

# Deleting trusted_domains config doesn't work due to bug in isTrustedDomain
sed -i -e 's/return in_array.*/return true;/' \
    /usr/share/owncloud/lib/private/security/trusteddomainhelper.php

# Don't allow the user to change name and password
sed -i -e 's/.*displayNameChangeSupported.*//' \
    /usr/share/owncloud/settings/personal.php
sed -i -e 's/.*passwordChangeSupported.*//' \
    /usr/share/owncloud/settings/personal.php

# Disable unnecessary settings that could confuse users
names="updatechecker appstoreenabled knowledgebaseenabled enable_avatars"
names+=" allow_user_to_change_display_name"
for name in $names; do
    $occ config:system:set --type=bool --value=false $name
done

# Remove unnecessary apps that could confuse users
apps="files_sharing files_versions files_trashbin activity gallery systemtags"
apps+=" notifications templateeditor firstrunwizard"
#apps+=" federatedfilesharing"  # federatedfilesharing can't be disabled?
for app in $apps; do
    $occ app:disable $app
done

# ownCloud app store is disabled
$occ config:system:set --type=bool --value=false apps_paths 1 writable

# Configure external storage
$occ app:enable files_external
$occ files_external:create / local null::null
$occ files_external:config 1 datadir /data
$occ files_external:option 1 enable_sharing true
$occ config:app:set \
    --value 'ftp,dav,owncloud,sftp,amazons3,dropbox,googledrive,swift,smb' \
    files_external user_mounting_backends

# Check each file or folder at most once per request
$occ config:system:set --type=int --value=1 filesystem_check_changes

# Empty skel dir to keep extraneous files out of user dirs when created
$occ config:system:set skeletondirectory

# Configure unix pwauth to allow $OC_USER to login
pwauth_pkg=$(ls $(dirname $0)/*-user_pwauth-*.zip)
unzip $pwauth_pkg -d /var/lib/owncloud/apps
chown -R apache.apache /var/lib/owncloud/apps/user_pwauth
sed -i -e 's|apps/user_pwauth|user_pwauth|' \
    /var/lib/owncloud/apps/user_pwauth/appinfo/app.php  # fix require_once bug
$occ app:enable user_pwauth
$occ config:app:set --value=/usr/bin/pwauth user_pwauth pwauth_path

# $_REQUEST is a combination of $_POST and $_GET
sed -i -e 's/_POST\["user"\]/_REQUEST\["user"\]/g' \
    /usr/share/owncloud/lib/base.php
sed -i -e 's/_POST\["password"\]/_REQUEST\["password"\]/g' \
    /usr/share/owncloud/lib/base.php
sed -i -e "s/_POST\['password'\]/_REQUEST\['password'\]/g" \
    /usr/share/owncloud/lib/base.php
# Don't check requesttoken
sed -i -e 's/passesCSRFCheck() {/passesCSRFCheck() { return true;/' \
    /usr/share/owncloud/lib/private/appframework/http/request.php

OC_USER_UID=$(/usr/bin/id -u $OC_USER 2>/dev/null)
if [ -n "$OC_USER_UID" ]; then
    $occ config:app:set --value=$OC_USER_UID user_pwauth uid_list
else
    export OC_PASS=$OC_USER_PASS
    $occ user:add --password-from-env --group=$OC_USER $OC_USER
fi

# Setup Nimbix theme
if [ -d $(dirname $0)/nimbix-theme ]; then
    cp -r $(dirname $0)/nimbix-theme /usr/share/owncloud/themes
    $occ config:system:set --type=string --value=nimbix-theme theme
fi

# Done configuring, don't allow changes from the web interface
$occ config:system:set --type=bool --value=true config_is_read_only

# Make sure permissions are adjusted for $OC_USER
chown -R $OC_USER.$OC_USER /var/lib/owncloud /var/lib/php/session
chown $OC_USER.$OC_USER /etc/owncloud /etc/owncloud/config.php
chgrp $OC_USER /usr/bin/pwauth

OC_URL="https://%PUBLICADDR%/owncloud/index.php?user=nimbix&password=%NIMBIXPASSWD%"
OC_CLIENTS="https://owncloud.org/sync-clients/"
mkdir -p /etc/NAE
cat <<EOF | sudo tee /etc/NAE/url.txt >/dev/null
$OC_URL
EOF

cat <<EOF | sudo tee /etc/NAE/help.html >/dev/null
<h1><a href="$OC_URL" target="%JOBNAME%">Click Here to Connect</a></h1>
<p>
Alternatively, you may connect securely with an
<a href="$OC_CLIENTS" target="_owncloud_download"><b>ownCloud desktop or mobile client</b></a>:
</p>
<p>
<table>
<tr>
<td align="right">ownCloud Server:</td>
<td><b>https://%PUBLICADDR%</b><br></td>
</tr>
<tr>
<td align="right">User:</td>
<td><b>nimbix</b><br></td>
</tr>
<tr>
<td align="right">Password:</td>
<td><b>%NIMBIXPASSWD%</b><br></td>
</tr>
</table>
</p>
<p>
Please note that the password is case sensitive and should not contain any
leading or trailing spaces when entered.  It is recommended that you copy and
paste it from above directly into the ownCloud client password prompt to
ensure accuracy.
</p>
<p>
<a href="$OC_CLIENTS" target="_owncloud_download"><b>Click here to download an ownCloud desktop or mobile client</b></a><br>
</p>

<h2>Alternative Connection Methods</h2>
<p>
You may also upload and download files from the command line with a tool
like curl:
<pre style="overflow-x:scroll;">
curl -u nimbix:%NIMBIXPASSWD% -k --upload-file "source_file" "https://%PUBLICADDR%/owncloud/remote.php/webdav/target_file"<br>
</pre>
<pre style="overflow-x:scroll;">
curl -u nimbix:%NIMBIXPASSWD% -k --output "target_file" "https://%PUBLICADDR%/owncloud/remote.php/webdav/source_file"
</pre>
</p>

<p>
A <a href="https://github.com/owncloud/pyocclient" target="_owncloud_download"><b>python client library for ownCloud</b></a> is also available for
programmatically accessing files via ownCloud APIs.
</p>
EOF

