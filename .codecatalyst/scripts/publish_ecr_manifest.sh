#!/usr/bin/env bash

# Fail on error
set -e

slack() {
  echo "$1"
  curl --silent POST "$SLACK_URL" -d "{\"text\": \"$1\"}" >/dev/null
}

docker manifest create public.ecr.aws/awsguru/$IMAGE:latest \
  public.ecr.aws/awsguru/$IMAGE:$TAG-arm64 \
  public.ecr.aws/awsguru/$IMAGE:$TAG-x86_64

docker manifest annotate --arch arm64 public.ecr.aws/awsguru/$IMAGE:latest \
  public.ecr.aws/awsguru/$IMAGE:$TAG-arm64

docker manifest push public.ecr.aws/awsguru/$IMAGE:latest

if [ $? != 0 ]; then
  slack "$IMAGE:latest build failed"
  exit 1
fi
