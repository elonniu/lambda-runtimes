#!/usr/bin/env bash

# Fail on error
set -e

export VERSION=2023.1.30.1

printenv

if [ -z "$ARCH" ]; then
  MSG="\$ARCH must be set"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

if [ -z "$PLATFORM" ]; then
  MSG="\$PLATFORM must be set"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

if [ -z "$DIR" ]; then
  MSG="\$DIR must be set"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

NOTIFY_PREFIX="[Upload Layer $DIR $ARCH]"

if [ "$ARCH" == "arm64" ]; then
  docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
fi

make layer-export-$DIR
if [ $? != 0 ]; then
  MSG="$NOTIFY_PREFIX layer-export failed: $WORKFLOW_URL"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

make layer-upload-$DIR
if [ $? != 0 ]; then
  MSG="$NOTIFY_PREFIX layer-upload failed: $WORKFLOW_URL"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi
