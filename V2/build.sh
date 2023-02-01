#!/bin/bash
docker build --no-cache -t jfm2:buff -f Dockerfile .
docker run -d --name jfm2 jfm2:buff
docker export jfm2 > flat.tar
docker stop jfm2 && docker rm jfm2
docker rmi jfm2:buff
cat flat.tar | docker import - jfm2:latest

