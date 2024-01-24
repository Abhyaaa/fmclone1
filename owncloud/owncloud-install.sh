#!/bin/bash

sed -i 's/www-data:root/www-data:www-data/g' /etc/owncloud.d/25-chown.sh
OC_CONFIG_ROOT="/etc/skel/owncloud"
export OWNCLOUD_VOLUME_CONFIG="$OC_CONFIG_ROOT/config"
export OWNCLOUD_VOLUME_FILES="$OC_CONFIG_ROOT/files"
export OWNCLOUD_VOLUME_APPS="$OC_CONFIG_ROOT/apps"
export OWNCLOUD_VOLUME_SESSIONS="$OC_CONFIG_ROOT/sessions"
export OWNCLOUD_PROTOCOL="http"
export OWNCLOUD_CROND_ENABLED="false"
export OWNCLOUD_LOG_FILE="$OC_CONFIG_ROOT/files/owncloud.log"

set -e

# User configs
[[ -z "$OC_USER_PASS" ]] && OC_USER_PASS="$(pwgen -1 32)" || true

[[ -z "$OC_DB_NAME" ]] && OC_DB_NAME=owncloud || true
[[ -z "$OC_DB_USER" ]] && OC_DB_USER=root || true
[[ -z "$OC_DB_PASS" ]] && OC_DB_PASS="$(pwgen -1 32)" || true

[[ -z "$OC_ADMIN_USER" ]] && OC_ADMIN_USER=admin || true
[[ -z "$OC_ADMIN_PASS" ]] && OC_ADMIN_PASS="$(pwgen -1 32)" || true

OC_HOMEDIR=/var/www/owncloud

occ_db_type=sqlite
# DEBUG="true"
[[ "${DEBUG}" == "true" ]] && set -x || true

for FILE in $(find /etc/entrypoint.d -iname \*.sh | sort)
do
  source ${FILE}
done

# Initialize ownCloud
echo 'export OWNCLOUD_SKIP_CHOWN="true"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_SKIP_CHMOD="true"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_VOLUME_CONFIG="$HOME/owncloud/config"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_VOLUME_FILES="$HOME/owncloud/files"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_VOLUME_APPS="$HOME/owncloud/apps"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_VOLUME_SESSIONS="$HOME/owncloud/sessions"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_VOLUME_ROOT="$HOME/owncloud"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_PROTOCOL="http"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_CROND_ENABLED="false"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
echo 'export OWNCLOUD_LOG_FILE="$HOME/owncloud/files/owncloud.log"' >> $OC_CONFIG_ROOT/owncloud-setup.sh
# echo 'export OWNCLOUD_SKIP_TRUSTED_DOMAIN_VERIFICATION="true"' >> $OC_CONFIG_ROOT/owncloud-setup.sh


echo "Configuring Owncloud initial maintenance install"
echo "export OWNCLOUD_DB_TYPE=$occ_db_type" > $OC_CONFIG_ROOT/owncloud-db.sh
echo "export OWNCLOUD_DB_NAME=$OC_DB_NAME" >> $OC_CONFIG_ROOT/owncloud-db.sh
echo "export OWNCLOUD_DB_USERNAME=$OC_DB_USER" >> $OC_CONFIG_ROOT/owncloud-db.sh
echo "export OWNCLOUD_DB_PASSWORD=$OC_DB_PASS" >> $OC_CONFIG_ROOT/owncloud-db.sh
echo "export OWNCLOUD_ADMIN_USERNAME=$OC_ADMIN_USER" >> $OC_CONFIG_ROOT/owncloud-db.sh
echo "export OWNCLOUD_ADMIN_PASSWORD=$OC_ADMIN_PASS" >> $OC_CONFIG_ROOT/owncloud-db.sh
source $OC_CONFIG_ROOT/owncloud-db.sh
/usr/bin/entrypoint owncloud install

# Log file is $data-dir/owncloud.log
echo "Configuring OwnCloud logging"
occ config:system:set --type=string --value=owncloud log_type

# Loglevel to start logging at. Valid values are: 0 = Debug, 1 = Info,
# 2 = Warning, 3 = Error, and 4 = Fatal. The default value is Warning.
occ config:system:set --type=int --value=0 loglevel

# Uncomment if extra debug info is needed
# occ config:system:set --type=bool --value=true debug

# Security check
occ config:system:set --type=bool --value=true check_for_working_htaccess

# Don't allow unencrypted usage
occ config:system:set --type=bool --value=true force_ssl

# Allow connections from anywhere
# occ config:system:delete trusted_domains 0
# occ_cmd "config:system:delete trusted_domains"

# sudo -u www-data ./occ config:system:get trusted_domains
# localhost
# owncloud.local
# sample.tld
# To replace sample.tld with example.com trusted_domains ⇒ 2 needs to be set:

# sudo -u www-data ./occ config:system:set trusted_domains 2 --value=example.com
# System config value trusted_domains => 2 set to string example.com

# Deleting trusted_domains config doesn't work due to bug in isTrustedDomain
# sed -i -e 's/return \\in_array.*/return true;/' \
#     $OC_HOMEDIR/lib/private/Security/TrustedDomainHelper.php

# Don't allow the user to change name and password
#sed -i -e 's/.*displayNameChangeSupported.*//' \
#    /usr/share/owncloud/settings/personal.php
#sed -i -e 's/.*passwordChangeSupported.*//' \
#    /usr/share/owncloud/settings/personal.php

# Disable unnecessary settings that could confuse users
names="updatechecker appstoreenabled knowledgebaseenabled enable_avatars"
names+=" allow_user_to_change_display_name"
for name in $names; do
    occ config:system:set --type=bool --value=false $name
done

# Remove unnecessary apps that could confuse users
apps="files_sharing files_versions files_trashbin systemtags"
apps+=" notifications firstrunwizard"
#apps+=" federatedfilesharing"  # federatedfilesharing can't be disabled?
for app in $apps; do
    occ app:disable $app
done

# ownCloud app store is disabled
occ config:system:set --type=bool --value=false apps_paths 1 writable

#sed -i -e "/'updatechecker' => false,/ a 'files_external_allow_create_new_local' => true," \
#    $OC_HOMEDIR/config/config.php

# Configure external storage
occ app:enable files_external
occ files_external:create / local null::null
occ files_external:config 1 datadir /data
occ files_external:option 1 enable_sharing true
occ config:app:set --value 'local' files_external user_mounting_backends
occ config:app:set --value=yes -- core enable_external_storage

# Check each file or folder at most once per request
occ config:system:set --type=int --value=1 filesystem_check_changes

# Empty skel dir to keep extraneous files out of user dirs when created
occ config:system:set skeletondirectory

# Configure unix pwauth to allow $OC_USER to login
pwauth_pkg=$(ls $(dirname $0)/user_pwauth-*.tar.gz)
tar -xf "$pwauth_pkg" -C /var/www/owncloud/apps
chown -R www-data.www-data /var/www/owncloud/apps/user_pwauth
cp -r /var/www/owncloud/apps/user_pwauth $OC_CONFIG_ROOT/apps
# sed -i -e 's|apps/user_pwauth|user_pwauth|' \
#    $OC_HOMEDIR/apps/user_pwauth/appinfo/app.php  # fix require_once bug
occ app:enable user_pwauth
occ config:app:set --value=/usr/sbin/pwauth user_pwauth pwauth_path

# Modify the "routes" registration..
# sed -i -e 's/showLoginForm/tryLogin/g' $OC_HOMEDIR/core/routes.php

# Don't check requesttoken
sed -i -e 's/passesCSRFCheck() {/passesCSRFCheck() { return true;/' \
    $OC_HOMEDIR/lib/private/AppFramework/Http/Request.php

# Replace LoginController.php to fill in jarvice job password
mv /tmp/owncloud/LoginController.php \
    $OC_HOMEDIR/core/Controller/LoginController.php

# Replace Login.php to fill in jarvice job password
mv /tmp/owncloud/login.php $OC_HOMEDIR/core/templates/login.php

# Add js to auto submit login form
mv /tmp/owncloud/autoLogin.js $OC_HOMEDIR/core/js/autoLogin.js

# OC_USER_UID=$(/usr/bin/id -u $OC_USER 2>/dev/null)
# if [ -n "$OC_USER_UID" ]; then
#     occ_cmd "config:app:set --value=$OC_USER_UID user_pwauth uid_list"
# else
#     export OC_PASS=$OC_USER_PASS
#     occ_cmd "user:add --password-from-env --group=$OC_USER $OC_USER"
# fi

# Setup Nimbix theme, now an OC app
if [ -d $(dirname $0)/nimbix-theme ]; then
    cp -r $(dirname $0)/nimbix-theme $OC_CONFIG_ROOT/apps
    cp -r $(dirname $0)/nimbix-theme /var/www/owncloud/apps
    chown -R www-data.www-data $OC_CONFIG_ROOT/apps/nimbix-theme /var/www/owncloud/apps/nimbix-theme
    occ app:enable nimbix-theme
fi

# Increase chunk size to speed up large uploads
occ config:app:set files max_chunk_size --value 2147483648

# Done configuring, don't allow changes from the web interface
occ config:system:set --type=bool --value=true config_is_read_only

cp /var/www/owncloud/config/config.php $OC_CONFIG_ROOT/config/config.php
