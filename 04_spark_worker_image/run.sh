#! /bin/bash

set -eu
IMAGE_NAME=$(< NAME)
VERSION=$(< VERSION)

masterid=$(
	docker container ls --format '{{.Image}} {{.ID}}' | while read imagetag imageid
	do
		if [[ "${imagetag#spark_master}" != "${imagetag}" ]]; then
			printf "%s" "${imageid}"
			break
		fi
	done
)

workercount=$(docker container ls --format '{{.Image}}' | grep spark_worker | wc -l)
portno=$(( 8081+workercount ))

docker run -d --rm --link="${masterid}:sparkmaster" -p ${portno}:8081/tcp ${IMAGE_NAME}:${VERSION}
