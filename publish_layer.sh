#!/bin/bash

# Fail on error
set -e

if [ -z "$LAYER" ]; then
  echo "\$LAYER must be set"
  exit 1
fi

if [ -z "$REGION" ]; then
  echo "\$REGION must be set"
  exit 1
fi

LAYER_NAME=$(echo $LAYER | perl -pe 's/(^|-|_)(\w)/\U\2/g')
LAYER_NAME=${LAYER_NAME/64/}

echo "[Publish] Publishing layer $LAYER -> $LAYER_NAME to $REGION..."

VERSION=$(aws lambda publish-layer-version \
  --region $REGION \
  --layer-name $LAYER_NAME \
  --description "PHP Runtime $ARCH" \
  --license-info MIT \
  --zip-file fileb:///tmp/$LAYER.zip \
  --compatible-runtimes provided.al2 \
  --output text \
  --query Version)

echo "[Publish] Layer $LAYER -> $LAYER_NAME:$VERSION uploaded, adding permissions..."

aws lambda add-layer-version-permission \
  --region $REGION \
  --layer-name $LAYER_NAME \
  --version-number $VERSION \
  --statement-id public \
  --action lambda:GetLayerVersion \
  --principal "*"

echo "[Publish] Layer $LAYER -> $LAYER_NAME:$VERSION published to $REGION"
