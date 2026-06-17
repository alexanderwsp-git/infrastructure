#!/usr/bin/env bash
# Build and push the admin backend image to ECR (linux/amd64).
#
# Usage:
#   ./scripts/build-admin-backend-image.sh [tag]
#
# Default tag: first 7 characters of the current git commit.
# Requires: docker, aws CLI, ECR repository mexp-admin-back

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-991795763909}"
ECR_REPO="mexp-admin-back"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_ROOT="$(cd "${SCRIPT_DIR}/../../../Backend-Admin" && pwd)"

cd "${BACKEND_ROOT}"

if [ -n "${1:-}" ]; then
  IMAGE_TAG="$1"
else
  IMAGE_TAG="$(git rev-parse --short=7 HEAD)"
fi

IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"

echo "Image tag : ${IMAGE_TAG}"
echo "Image URI : ${IMAGE_URI}"

echo "Logging in to ECR (${AWS_REGION})..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building and pushing ${IMAGE_URI} (linux/amd64)..."
docker buildx build \
  --platform linux/amd64 \
  -f Dockerfile \
  -t "${IMAGE_URI}" \
  --push \
  .

echo "Done: ${IMAGE_URI}"
