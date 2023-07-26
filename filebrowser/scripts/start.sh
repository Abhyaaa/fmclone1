#!/usr/bin/env bash

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
# echo $COMMANDS

set -x

# Use /data to hold user settings
DATABASE=/data/AppConfig/filebrowser/filebrowser.db
if [[ ! -f $DATABASE ]]; then
    mkdir -p $(dirname $DATABASE)
fi

if [[ -z $STARTING_DIRECTORY ]]; then
    STARTING_DIRECTORY="/data"
else
    mkdir -p $STARTING_DIRECTORY
fi

filebrowser -d $DATABASE config init > /dev/null 2> /dev/null
filebrowser -d $DATABASE config set --commands $COMMANDS > /dev/null 2> /dev/null
filebrowser -d $DATABASE config set --auth.method noauth > /dev/null 2> /dev/null
filebrowser -d $DATABASE users add $JARVICE_ID_USER nimbix > /dev/null 2> /dev/null

# echo "filebrowser -r /data --username $JARVICE_ID_USER --password nimbix --address 0.0.0.0 --port 5902 -b /${JARVICE_INGRESSPATH:-}"
BASEURL="/$JARVICE_INGRESSPATH/$(cat /etc/JARVICE/random128.txt | cut -c 1-64)"
filebrowser -d $DATABASE -r $STARTING_DIRECTORY --username $JARVICE_ID_USER --password nimbix --address 0.0.0.0 --port 5902 -b "$BASEURL"
