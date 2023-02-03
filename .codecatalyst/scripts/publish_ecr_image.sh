#!/usr/bin/env bash

# Fail on error
set -e

slack() {
  echo "$1"
  curl --silent POST "$SLACK_URL" -d "{\"text\": \"$1\"}" >/dev/null
}

if [ -z "$CONTEXT_DIR" ]; then
  slack "\$CONTEXT_DIR must be set"
  exit 1
fi

NOTIFY_PREFIX="[Build Image]"

build_image() {

  export ARCH=$1

  IMAGE_EXISTS="public.ecr.aws/awsguru/$IMAGE:$TAG-$ARCH"

  docker manifest inspect "$IMAGE_EXISTS" >/dev/null 2>&1 && EXISTS="TRUE" || EXISTS="FALSE"
  if [ "$EXISTS" == "TRUE" ]; then
    slack "$NOTIFY_PREFIX $IMAGE:$TAG-$ARCH exists"
    return
  fi

  if [ "$ARCH" == "arm64" ]; then
    docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
  fi

  if [ -f "./$CONTEXT_DIR/$ARCH.$DOCKER_FILE" ]; then
    export DOCKER_FILE="$ARCH.$DOCKER_FILE"
  fi

  make build-image
  if [ $? != 0 ]; then
    slack "$NOTIFY_PREFIX $IMAGE_EXISTS build failed: $WORKFLOW_URL"
    exit 1
  fi

  if [ "$ARCH" == "arm64" ]; then
    make tag-manifest
    if [ $? != 0 ]; then
      slack "$NOTIFY_PREFIX manifest failed: $WORKFLOW_URL"
      exit 1
    fi
  fi

}

build_image x86_64
build_image arm64
