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
docker pull "$IMAGE_FULL" || {
  echo "⚠️ Failed to pull $IMAGE_FULL"
  exit 1
}

docker compose --env-file "$ENV_FILE" pull
docker compose --env-file "$ENV_FILE" up -d --remove-orphans

echo "Waiting for app to respond..."
sleep 5

for i in $(seq 1 10); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8181 || echo "000")
  if [[ "$HTTP_CODE" =~ ^(200|302|301|401)$ ]]; then
    echo "✓ App is reachable (HTTP $HTTP_CODE)"
    echo "Deploy complete!"
    exit 0
  fi
  echo "⏳ Attempt $i/10: HTTP $HTTP_CODE"
  sleep 3
done

echo "✗ Error: App not reachable after 10 attempts"
docker compose ps
docker compose logs --tail=20 app
exit 1
