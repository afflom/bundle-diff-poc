#!/bin/bash -x

BLOBS_ROOT=bundle/operators/docker/registry/v2/blobs/sha256/
BUNDLE_DIR='bundle'
HOST_DIR='/host/'
AUTH_TOKEN=$1
AUTH_FILE='auth.json'


function __startRegistry() {
  podman container stop registry
  podman container rm registry
  mkdir -p operators
  podman run -d \
  -p 5000:5000 \
  --name registry \
  -v ./operators:/var/lib/registry \
  registry:2
}

function __stopRegistry() {
  podman container stop registry
  podman containre rm registry
}

function __consolidate() {

  mkdir -p bundle
  cp -rn operators bundle/
  cp -rn publish bundle/

}

function __extractCreds() {
  RH_PS=$(echo $1 | jq -r '.auths."registry.redhat.io".auth' | base64 -d -)
  ID=$(grep -o -P "^.+(?=:)" <<< $RH_PS)
  PASS=$(grep -o -P "(?<=\:)(.+$)" <<< $RH_PS)
  echo "$ID $PASS"
}

function __podmanLogin() {
  podman login registry.redhat.io --username $1 --password $2
}

function __writeAuth() {
  echo $1 > auth.json
}

function __mirror() {
  ./mirror-operator-catalogue.py \
    --catalog-version 1.0.0 \
    --authfile $1 \
    --registry-olm localhost:5000 \
    --registry-catalog localhost:5000 \
    --operator-file ./offline-operator-list \
    --icsp-scope=namespace
}

function __zeroBlobs() {
  SAVE=$(ls bundle/operators/docker/registry/v2/repositories/custom-redhat-operator-index/_layers/sha256/)

  for i in $(ls $BLOBS_ROOT)
  do
    for b in $(ls $BLOBS_ROOT/$i)
    do
      if grep -w -q $b <<< $SAVE
      then
        :
      else
        echo "Already in blundle" > $BLOBS_ROOT/$i/$b/data
      fi
    done
  done
}

function __setCounter() {
  if test -f bundle/.bundle-counter
  then
    c=$(cat bundle/.bundle-counter)
    ((c=c+1))
    echo "$c" > bundle/.bundle-counter
    export $c
  else
    echo "1" > bundle/.bundle-counter
    export c=1
  fi
}

function bundle() {

# Write Auth file
__writeAuth ${AUTH_TOKEN}

# Extract credentials
read UN PASS < <(__extractCreds ${AUTH_TOKEN})

# Podman login
__podmanLogin $UN $PASS

# Start the registry
__startRegistry

# Run the mirroring script
__mirror $AUTH_FILE

#if [ $? -eq 0 ]; then
  # Stop the registry
  __stopRegistry

  # Consolidate
  __consolidate

  # Set the differential counter
  __setCounter

  # Compress
  BUNDLE_NAME="operator-bundle-${c}.tar.gz"
  tar -czvf ${BUNDLE_NAME} ${BUNDLE_DIR}

  # Export
  mv ${BUNDLE_NAME} ${HOST_DIR}

  # Zero the blobs
  __zeroBlobs


}

bundle

