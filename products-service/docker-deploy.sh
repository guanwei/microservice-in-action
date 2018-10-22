#!/bin/bash
set -e

DOCKER_REGISTRY_USER_NAME="guanwei"
APP_NAME="products-service"
APP_VERSION="latest"

FULL_TAG=$DOCKER_REGISTRY_USER_NAME/$APP_NAME:$APP_VERSION

echo "Pulling Dokcer image from Registry"
docker pull $FULL_TAG

echo "Launching Docker Container"
docker run -d -p 80:9292 $FULL_TAG