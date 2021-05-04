#!/bin/bash

while getopts a:d: flag
do
    case "${flag}" in
        a) AUTH=${OPTARG};;
        # json formatted auth token for registry login
        d) DEST=${OPTARG};;
        # URL of target registry to upload to. Sometimes requires port appended to end of url
    esac
done

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]
do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done  
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

export BUNDLE_ROOT=$DIR/..

function __getAuth() {
  echo $(cat ${AUTH})
}

podman load < containers/operator-mirror.tar

podman run \
  -it --security-opt label=disable \
  -v /dev/fuse:/dev/fuse:rw \
  --mount=type=bind,src=$BUNDLE_ROOT,dst=bundle \
  --mount=type=bind,src=$KUBECONFIG,dst=/kubeconfig \
  -e KUBECONFIG=/kubeconfig \
  --rm --ulimit host --privileged \
  quay.io/redhatgov/compliance-disconnected:latest ./install.sh -a ''"$(__getAuth)"'' -d ${DEST}

