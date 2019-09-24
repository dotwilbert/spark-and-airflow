#! /bin/bash

IMAGE_NAME=debian_base
VERSION=$(< VERSION)

docker run -it --rm ${IMAGE_NAME}:${VERSION} /bin/bash