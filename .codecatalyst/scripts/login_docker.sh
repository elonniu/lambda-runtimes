#!/usr/bin/env bash

# Fail on error
set -e

printenv

slack() {
  echo "$1"
  curl --silent POST "$SLACK_URL" -d "{\"text\": \"$1\"}" >/dev/null
}

if [ -z "$DOCKER_USER_NAME" ]; then
  slack "\$DOCKER_USER_NAME must be set"
  exit 1
fi

if [ -z "$DOCKER_PASSWORD" ]; then
  slack "\$DOCKER_PASSWORD must be set"
  exit 1
fi

NOTIFY_PREFIX="[Login Docker]"

ECP_PASSWORD=$(aws ecr-public get-login-password --region us-east-1)
if [ $? != 0 ]; then
  slack "$NOTIFY_PREFIX get-login-password failed: $WORKFLOW_URL"
  exit 1
fi

docker login --username AWS --password "$ECP_PASSWORD" public.ecr.aws/awsguru
if [ $? != 0 ]; then
  slack "$NOTIFY_PREFIX login ECR failed: $WORKFLOW_URL"
  exit 1
fi

docker login --username "$DOCKER_USER_NAME" --password "$DOCKER_PASSWORD"
if [ $? != 0 ]; then
  slack "$NOTIFY_PREFIX login docker failed: $WORKFLOW_URL"
  exit 1
fi
