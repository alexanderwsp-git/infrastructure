#!/usr/bin/env bash
# Build and push the myxperiences frontend image to ECR (linux/amd64).
#
# Usage:
#   VITE_API_SERVICE=https://api.myxperiences.org \
#   ./scripts/myxperiences/build-myxperiences-frontend-image.sh [tag]
#
# VITE_ variables are baked into the bundle at build time — they must be
# set as environment variables before running this script.
#
# Default tag: first 7 characters of the current git commit.
# Requires: docker, aws CLI, ECR repository mexp-myxperiences-front

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-991795763909}"
ECR_REPO="mexp-myxperiences-front"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/../../ecs-myxperiences/.env_myxperiences_frontend" ]; then
  set -a
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/../../ecs-myxperiences/.env_myxperiences_frontend"
  set +a
elif [ -f "${SCRIPT_DIR}/../../ecs-myxperiences/.env_myxperiences_frontend.template" ]; then
  set -a
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/../../ecs-myxperiences/.env_myxperiences_frontend.template"
  set +a
fi

: "${VITE_API_SERVICE:?VITE_API_SERVICE is required}"

FRONTEND_ROOT="/c/Users/leona/Documents/Trabajo/Prueba/frontend"

cd "${FRONTEND_ROOT}"

if [ -n "${1:-}" ]; then
  IMAGE_TAG="$1"
else
  IMAGE_TAG="$(git rev-parse --short=7 HEAD)"
fi

IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"

echo "Image tag : ${IMAGE_TAG}"
echo "Image URI : ${IMAGE_URI}"
echo "VITE_API_SERVICE : ${VITE_API_SERVICE}"

echo "Logging in to ECR (${AWS_REGION})..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building and pushing ${IMAGE_URI} (linux/amd64)..."
docker buildx build \
  --platform linux/amd64 \
  --build-arg VITE_API_SERVICE="${VITE_API_SERVICE}" \
  -f Dockerfile \
  -t "${IMAGE_URI}" \
  --push \
  .

echo "Done: ${IMAGE_URI}"
echo ""
echo "⚠️  Don't forget to update IMAGE_TAG=${IMAGE_TAG} in your .env_myxperiences_frontend file!"
