#!/usr/bin/env bash

# Fail on error
set -e

export VERSION=2023.1.30.1

printenv

if [ -z "$DOCKER_USER_NAME" ]; then
  MSG="\$DOCKER_USER_NAME must be set"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

if [ -z "$DOCKER_PASSWORD" ]; then
  MSG="\$DOCKER_PASSWORD must be set"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

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

NOTIFY_PREFIX="[Build IMAGE $DIR $TAG_PRE $ARCH]"

ECP_PASSWORD=$(aws ecr-public get-login-password --region us-east-1)
if [ $? != 0 ]; then
  MSG="$NOTIFY_PREFIX get-login-password failed: $WORKFLOW_URL"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

docker login --username AWS --password "$ECP_PASSWORD" public.ecr.aws/awsguru
if [ $? != 0 ]; then
  MSG="$NOTIFY_PREFIX login ECR failed: $WORKFLOW_URL"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

docker login --username "$DOCKER_USER_NAME" --password "$DOCKER_PASSWORD"
if [ $? != 0 ]; then
  MSG="$NOTIFY_PREFIX login docker failed: $WORKFLOW_URL"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

docker manifest inspect public.ecr.aws/awsguru/"$IMAGE":"$TAG_PRE""$VERSION"-"$ARCH" >/dev/null 2>&1 && EXISTS="TRUE" || EXISTS="FALSE"
if [ "$EXISTS" == "TRUE" ]; then
  MSG="$NOTIFY_PREFIX image already exists: $WORKFLOW_URL"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

if [ "$ARCH" == "arm64" ]; then
  docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
fi

make image-build-$DIR
if [ $? != 0 ]; then
  MSG="$NOTIFY_PREFIX build images failed: $WORKFLOW_URL"
  echo "$MSG"
  curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
  exit 1
fi

if [ "$ARCH" == "arm64" ]; then
  make manifest-$DIR
  if [ $? != 0 ]; then
    MSG="$NOTIFY_PREFIX build manifest failed: $WORKFLOW_URL"
    echo "$MSG"
    curl -X POST "$SLACK_URL" -d "{\"text\": \"$MSG\"}"
    exit 1
  fi
fi
