#!/bin/bash
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
# Set uid for pwauth
OC_USER="$(whoami)"
OC_USER_UID=$(id -u)
occ app:enable user_pwauth
occ config:app:set --value=/usr/sbin/pwauth user_pwauth pwauth_path
occ config:app:set --value=$OC_USER_UID user_pwauth uid_list
occ app:enable files_external
occ files_external:create / local null::null
occ files_external:config 1 datadir /data
occ files_external:option 1 enable_sharing true
occ config:app:set --value 'ftp,dav,owncloud,sftp,amazons3,dropbox,googledrive,swift,smb,local' files_external user_mounting_backends
occ config:app:set --value=yes -- core enable_external_storage
occ config:system:set --type=int --value=1 filesystem_check_changes
occ config:system:set skeletondirectory
occ app:enable nimbix-theme

# Add JARVICE cert
# occ security:certificates:import /etc/JARVICE/cert.pem
occ config:app:set files max_chunk_size --value 2147483648
occ config:system:set --type=bool --value=true config_is_read_only
OC_PASS="$(cat /etc/JARVICE/random128.txt)" occ user:add --password-from-env --email "${OC_USER}@localhost" "${OC_USER}_token"
