#!/usr/bin/env bash
# Updates IMAGE_TAG in an ecs-lanapp .env file from git (7-char short hash) or an override.
#
# Usage:
#   ./set-image-tag.sh .env_frontend ../../webapp
#   ./set-image-tag.sh .env_backend ../../webapp abc1234

set -euo pipefail

ENV_FILE="$1"
REPO_DIR="$2"
OVERRIDE_TAG="${3:-}"

if [ -z "$ENV_FILE" ] || [ -z "$REPO_DIR" ]; then
  echo "Usage: $0 <env_file> <repo_dir> [image_tag]"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

if [ -n "$OVERRIDE_TAG" ]; then
  IMAGE_TAG="$OVERRIDE_TAG"
else
  IMAGE_TAG="$(git -C "$REPO_DIR" rev-parse --short=7 HEAD 2>/dev/null || echo "manual")"
fi

echo "Updating $ENV_FILE → IMAGE_TAG=$IMAGE_TAG"

TEMP_FILE="${ENV_FILE}.tmp"
while IFS= read -r line || [ -n "$line" ]; do
  if [[ "$line" =~ ^IMAGE_TAG= ]]; then
    echo "IMAGE_TAG=$IMAGE_TAG"
  else
    echo "$line"
  fi
done < "$ENV_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$ENV_FILE"
echo "Done: IMAGE_TAG=$IMAGE_TAG"
