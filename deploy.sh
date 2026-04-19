#!/bin/bash
set -e

IMAGE_NAME="$1"
DEPLOY_REF="$2"
IMAGE_FULL="${IMAGE_NAME}:${DEPLOY_REF}"

APP_DIR="/home/kirill/desktop/devops"
ENV_FILE="$APP_DIR/.env.deploy"

echo "Deploying with Docker Compose: $IMAGE_FULL"
echo "DEPLOY_REF: $DEPLOY_REF"

printf 'DEPLOY_REF=%s\n' "$DEPLOY_REF" > "$ENV_FILE"
echo "Saved DEPLOY_REF=$DEPLOY_REF to $ENV_FILE"

echo "${GHCR_PAT}" | docker login ghcr.io -u kirilldrs --password-stdin 2>/dev/null || true

cd "$APP_DIR"

docker compose pull
docker compose up -d --remove-orphans

sleep 5
curl -s -o /dev/null -w "%{http_code}" http://localhost:8181 | grep -q "200\|302" && echo "App is reachable" || echo "Error!"

echo "Deploy complete!"
