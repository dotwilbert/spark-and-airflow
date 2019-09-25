#! /bin/bash

set -eu
IMAGE_NAME=$(< NAME)
VERSION=$(< VERSION)

masterid=$(docker container ls --format '{{.Image}} {{.ID}}' | while read imagetag imageid
do
	if [[ "${imagetag#spark_master}" != "${imagetag}" ]]; then
		printf "%s" "${imageid}"
		break
	fi
done)

docker run -d --rm --link="${masterid}:sparkmaster" ${IMAGE_NAME}:${VERSION}
