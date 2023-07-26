FROM ubuntu:jammy as builder
# FROM ubuntu:jammy

# RUN apt-get -y update && apt-get -y upgrade && \
#     DEBIAN_FRONTEND=noninteractive apt-get -y install ca-certificates curl --no-install-recommends && \
#     curl -H 'Cache-Control: no-cache' \
#         https://raw.githubusercontent.com/nimbix/jarvice-desktop/master/install-nimbix.sh \
#         | bash

# RUN add-apt-repository ppa:mozillateam/ppa && \
#     apt-get install -y firefox-esr

RUN apt-get -y update && apt-get -y upgrade && apt-get install -y unrar p7zip p7zip-full curl

RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

COPY scripts /usr/local/scripts
COPY NAE /etc/NAE
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
RUN mkdir -p /etc/NAE && touch /etc/NAE/screenshot.png /etc/NAE/screenshot.txt /etc/NAE/license.txt /etc/NAE/AppDef.json


# # # For testing locally
# # Add nimbix user
# RUN useradd --shell /bin/bash nimbix
# RUN mkdir -p /home/nimbix/
# RUN mkdir -p /data

# # Have all files be owned by nimbix user
# RUN chown -R nimbix:nimbix /home/nimbix
# RUN chown -R nimbix:nimbix /data

# #    30  filebrowser config init
# #    31  filebrowser config set --commands ls,zip,unzip,tar
# #    32  filebrowser config set --auth.method noauth
# #    33  filebrowser users add nimbix nimbix
# #    34  filebrowser -r /data --username nimbix --password nimbix

# # Try deleting some packages...
# RUN apt-get purge -y \
#     cmake* \
#     cpp* \
#     git \
#     xz-utils

RUN apt-get -y autoclean && \
    apt-get -y autoremove && \
    apt-get clean

WORKDIR /var/www

# FROM scratch

# COPY --from=builder / /
