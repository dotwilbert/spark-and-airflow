#! /bin/bash

IMAGE_NAME=$(< NAME)
VERSION=$(< VERSION)

docker run -d --rm -p 8080:8080/tcp -p 7077:7077/tcp ${IMAGE_NAME}:${VERSION}
