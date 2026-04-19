#!/bin/bash
set -e

IMAGE_NAME="$1"
DEPLOY_REF="$2"
IMAGE_FULL="${IMAGE_NAME}:${DEPLOY_REF}"

APP_DIR="/home/kirill/desktop/devops"
ENV_FILE="$APP_DIR/.env"
CONTAINER_NAME="catty-reminders-app"
PORT=8181

echo "Deploying with Docker Compose: $IMAGE_FULL"
echo "DEPLOY_REF: $DEPLOY_REF"

cd "$APP_DIR"

printf 'DEPLOY_REF=%s\n' "$DEPLOY_REF" > "$ENV_FILE"
echo "Saved DEPLOY_REF=$DEPLOY_REF to $ENV_FILE"

echo "${GHCR_PAT}" | docker login ghcr.io -u kirilldrs --password-stdin 2>/dev/null || true

echo "Pulling image: $IMAGE_FULL"
docker pull "$IMAGE_FULL"

docker compose --env-file "$ENV_FILE" pull
docker compose --env-file "$ENV_FILE" up -d --remove-orphans

sleep 5
curl -s -o /dev/null -w "%{http_code}" http://localhost:8181 | grep -q "200\|302" && echo "✓ App is reachable" || echo "✗ Error!"

echo "Deploy complete!"
