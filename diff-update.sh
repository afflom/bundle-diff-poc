#!/bin/bash

while getopts b: flag
do
    case "${flag}" in
        b) BUNDLE=${OPTARG};;
        # Filepath to Differential Bundle
    esac
done

function __getBundleSequence() {
  tar zxvf $1 bundle/.bundle-counter
  cat  bundle/.bundle-counter
}

function __getMirrorSequence() {
  cat ~/.local/share/registry/.bundle-counter
}

function __listBundle() {
  tar xtf $1
}

function __copyBundleItem() {
  tar zxf $1 $2
  if grep 'v2' <<< $2
  then
    REGPATH=$(grep -oP '(?<=bundle/operators/docker/registry).*' <<< $2)
    FULLPATH="~/.local/share/registry$REGPATH"
    mv -n $2 $FULLPATH
  else
    mkdir -p ./mirror-artifacts-${BS}
    mv -n $2 ./mirror-artifacts-${BS}
  fi
}

function diff-update() {
  BS=$(__getBundleSequence $BUNDLE)
  MS=$(__getMirrorSequence)
  ((NS=MS+1))

  if [[ $NS -ne $BS ]]
  then
    echo "Differential bundle out of sequence. Expected bundle number $NS, got bundle number $BS."
    exit 1
  fi

  BL=$(__listBundle $BUNDLE)

  for i in $BL
  do
    __copyBundleItem $BUNDLE $i
  done
  
}





