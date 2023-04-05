#!/bin/bash
set -eo pipefail
[[ "${DEBUG}" == "true" ]] && set -x || true

echo "In Owncloud-setup..."

# OC_CONFIG_ROOT="$HOME/owncloud"
OC_CONFIG_ROOT=/etc/skel/owncloud
for FILE in $(find /etc/entrypoint.d -iname \*.sh | sort)
do
  source ${FILE}
done
JOB_SUBPATH=""
[[ -n "${JARVICE_INGRESSPATH}" ]] && JOB_SUBPATH="/${JARVICE_INGRESSPATH}" || true
OWNCLOUD_SUB_URL="$JOB_SUBPATH"
source $OC_CONFIG_ROOT/owncloud-setup.sh
source $OC_CONFIG_ROOT/owncloud-db.sh
# Set uid for pwauth
OC_USER="${JARVICE_ID_USER:-nimbix}"
OC_USER_UID=$(id -u ${JARVICE_ID_USER:-nimbix})
occ config:app:set --value=$OC_USER_UID user_pwauth uid_list
OC_PASS="$(cat /etc/JARVICE/random128.txt)" occ user:add --password-from-env --email "${OC_USER}@localhost" "${OC_USER}_token"
