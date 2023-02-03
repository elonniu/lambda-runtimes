#!/bin/bash

# Fail on error
set -e

slack() {
  echo "$1"
  curl --silent POST "$SLACK_URL" -d "{\"text\": \"$1\"}" >/dev/null
}

if [ -z "$LAYER" ]; then
  slack "\$LAYER must be set"
  exit 1
fi

if [ -z "$LAYER_NAME" ]; then
  LAYER_NAME=$(echo $LAYER | perl -pe 's/(^|-|_)(\w)/\U\2/g')
  LAYER_NAME=${LAYER_NAME/64/}
fi

aws s3api put-object --bucket lambda-web-runtimes-layers --key "$LAYER_NAME.zip" --body /tmp/$LAYER.zip

LAYERS=$(aws lambda list-layers --query 'Layers[*].LayerName' --output text)
if [ $? != 0 ]; then
  slack "$NOTIFY_PREFIX list-layers failed: $WORKFLOW_URL"
  exit 1
fi

if [[ "$LAYERS" == *"$LAYER_NAME"* ]]; then

  ARN="arn:aws:lambda:$AWS_DEFAULT_REGION:753240598075:layer:$LAYER_NAME"
  LAST_VERSION=$(aws lambda list-layer-versions --layer-name $ARN --query 'LayerVersions[0].Version')
  if [ $? != 0 ]; then
    slack "$NOTIFY_PREFIX list-layer-versions failed: $WORKFLOW_URL"
    exit 1
  fi

  CODE_SHA256=$(aws lambda get-layer-version --layer-name $ARN --version-number $LAST_VERSION --query Content.CodeSha256 --output text)
  if [ $? != 0 ]; then
    slack "$NOTIFY_PREFIX get-layer-version failed: $WORKFLOW_URL"
    exit 1
  fi

  yum install -y vim-common
  SHE256=$(cat /tmp/$LAYER.zip | sha256sum | cut -d' ' -f1 | xxd -r -p | base64)
  if [ "$SHE256" == "$CODE_SHA256" ]; then
    slack "TNo need to upload, sha hashes are the same: $LAYER_NAME"
    return
  fi

  echo "CODE_SHA256 $CODE_SHA256"
  echo "SHE256 $SHE256"

fi

echo "[Publish] Publishing layer $LAYER -> $LAYER_NAME to $AWS_DEFAULT_REGION..."

LAYER_VERSION=$(aws lambda publish-layer-version \
  --layer-name $LAYER_NAME \
  --description "Layer for $IMAGE:$TAG $ARCH" \
  --license-info MIT \
  --zip-file fileb:///tmp/$LAYER.zip \
  --compatible-runtimes $COMPATIBLE_RUNTIMES \
  --compatible-architectures $ARCH \
  --output text \
  --query Version)

echo "[Publish] Layer $LAYER -> $LAYER_NAME:$LAYER_VERSION uploaded, adding permissions..."

aws lambda add-layer-version-permission \
  --layer-name $LAYER_NAME \
  --version-number $LAYER_VERSION \
  --statement-id public \
  --action lambda:GetLayerVersion \
  --principal "*"

echo "[Publish] Layer $LAYER -> $LAYER_NAME:$LAYER_VERSION published to $AWS_DEFAULT_REGION"
