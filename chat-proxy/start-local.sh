#!/bin/bash

DIR=$( dirname `realpath $0` )
CONTAINER_NAME=local-proxy

docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
docker run -it \
    --name $CONTAINER_NAME \
    -p 8080:8080 \
    -p 8081:8081 \
    -v ${DIR}/envoy-local.yaml:/etc/envoy/envoy.yaml \
    -e NODE_ENV=development \
    -d envoyproxy/envoy:v1.26.4
