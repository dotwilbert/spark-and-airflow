#! /bin/bash

IMAGE_NAME=$(< NAME)
VERSION=$(< VERSION)

docker run -d --rm ${IMAGE_NAME}:${VERSION}
