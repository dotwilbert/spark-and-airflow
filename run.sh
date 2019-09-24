#! /bin/bash

IMAGE_NAME=$(< NAME)
VERSION=$(< VERSION)

docker run -it --rm ${IMAGE_NAME}:${VERSION} /bin/bash