#!/usr/bin/env bash

# Fail on error
set -e

slack() {
  echo "$1"
  curl --silent POST "$SLACK_URL" -d "{\"text\": \"$1\"}" >/dev/null
}

printenv

if [ -z "$CONTEXT_DIR" ]; then
  slack "\$CONTEXT_DIR must be set"
  exit 1
fi

NOTIFY_PREFIX="[Upload Layer $CONTEXT_DIR]"

ARCH=x86_64 && make layer-export-al2
if [ $? != 0 ]; then
  slack "$NOTIFY_PREFIX layer export failed: $WORKFLOW_URL"
  exit 1
fi

docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64

ARCH=arm64 && make layer-export-al2
if [ $? != 0 ]; then
  slack "$NOTIFY_PREFIX layer export failed: $WORKFLOW_URL"
  exit 1
fi
