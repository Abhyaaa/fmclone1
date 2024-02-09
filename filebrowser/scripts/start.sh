#!/usr/bin/env bash

set -e

JARVICE_ID_USER="${JARVICE_ID_USER:-nimbix}"

COMMANDS=""
for f in /usr/bin/*; do
    com=$(basename $f)
    if [[ $com == '[' ]]; then
        continue
    fi
    if [[ $com == *"++"* ]]; then
        continue
    fi
    if [[ $com == *"-"* ]]; then
        continue
    fi
    if [[ $com == *"_"* ]]; then
        continue
    fi
    if [[ $com == *"."* ]]; then
        continue
    fi
    if [[ -z $COMMANDS ]]; then
        COMMANDS=$com
    else
        COMMANDS="$COMMANDS,$com"
    fi
done

if [[ -z $STARTING_DIRECTORY ]]; then
    STARTING_DIRECTORY="/data"
else
    mkdir -p $STARTING_DIRECTORY
fi

# Use /data to hold user settings
# DATABASE=/data/AppConfig/filebrowser/filebrowser.db
DATABASE="$STARTING_DIRECTORY/AppConfig/filebrowser/filebrowser.db"
if [[ -n $DELETE_OLD_DB ]]; then
    rm $DATABASE
fi

PATH=/opt/filebrowser:$PATH
TOKEN=$(cat /etc/JARVICE/random128.txt | cut -c 1-64)
if [[ ! -f $DATABASE ]]; then
    mkdir -p $(dirname $DATABASE)
    filebrowser -d $DATABASE config init > /dev/null 2> /dev/null
    filebrowser -d $DATABASE config set --commands $COMMANDS > /dev/null 2> /dev/null
    filebrowser -d $DATABASE config set --auth.method nimbixpw > /dev/null 2> /dev/null
    filebrowser -d $DATABASE config set --perm.share=false > /dev/null 2> /dev/null
    filebrowser -d $DATABASE users add $JARVICE_ID_USER $TOKEN > /dev/null 2> /dev/null
else
    filebrowser -d $DATABASE users update $JARVICE_ID_USER --password $TOKEN > /dev/null 2> /dev/null
fi

if [[ -n $DARK_MODE ]]; then
    filebrowser -d $DATABASE config set --branding.color dark > /dev/null 2> /dev/null
    filebrowser -d $DATABASE config set --branding.theme dark > /dev/null 2> /dev/null
fi

if [[ -n $JARVICE_INGRESSPATH ]]; then
    BASEURL="/$JARVICE_INGRESSPATH"
else
    BASEURL="/"
fi

PORTNUM=${JARVICE_SERVICE_PORT:-5902}

filebrowser -d $DATABASE -r $STARTING_DIRECTORY --address 0.0.0.0 --port "$PORTNUM" -b "$BASEURL"
