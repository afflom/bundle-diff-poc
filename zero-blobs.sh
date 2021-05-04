#!/bin/bash

BLOBS_ROOT=bundle/operators/docker/registry/v2/blobs/sha256/
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



