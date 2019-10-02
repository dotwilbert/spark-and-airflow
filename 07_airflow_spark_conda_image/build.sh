#! /bin/bash

IMAGE_NAME=$(< NAME)
VERSION=$(< VERSION)

cat Dockerfile | docker build -t ${IMAGE_NAME}:${VERSION} -f - resources/