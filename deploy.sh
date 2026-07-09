#!/bin/bash

set -e

# ==========================================================
# Zero Downtime Blue-Green Deployment Script
# ==========================================================

DOCKER_USER="dhanushs2k5"
REPO="zero-downtime-api"

GREEN_DEPLOYMENT="zero-downtime-green"
SERVICE_NAME="zero-downtime-service"
MANIFEST="kubernetes/green-deployment.yml"

echo
echo "========================================================="
echo "        ZERO DOWNTIME DEPLOYMENT PIPELINE"
echo "========================================================="
echo

# ----------------------------------------------------------
# Check Dependencies
# ----------------------------------------------------------

for cmd in docker kubectl minikube curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "$cmd is not installed."
        exit 1
    fi
done

# ----------------------------------------------------------
# Fetch Available Docker Images
# ----------------------------------------------------------

echo "Fetching available Docker images..."
echo

mapfile -t TAGS < <(
curl -s "https://hub.docker.com/v2/repositories/$DOCKER_USER/$REPO/tags?page_size=100" \
| jq -r '.results[].name'
)

if [ ${#TAGS[@]} -eq 0 ]; then
    echo "No Docker images found."
    exit 1
fi

echo "Available Images"
echo "----------------"

select TAG in "${TAGS[@]}"; do
    if [[ -n "$TAG" ]]; then
        echo
        echo "Selected Image:"
        echo "$DOCKER_USER/$REPO:$TAG"
        break
    else
        echo "Invalid selection."
    fi
done

IMAGE="$DOCKER_USER/$REPO:$TAG"

echo
read -p "Deploy this image? (Y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo
    echo "Deployment cancelled."
    exit 0
fi

# ----------------------------------------------------------
# Pull Image
# ----------------------------------------------------------

echo
echo "Pulling Docker image..."

docker pull "$IMAGE"

# ----------------------------------------------------------
# Load into Minikube
# ----------------------------------------------------------

echo
echo "Loading image into Minikube..."

minikube image load "$IMAGE"

# ----------------------------------------------------------
# Deploy GREEN
# ----------------------------------------------------------

echo
echo "Updating GREEN deployment..."

sed "s|IMAGE_TAG|$IMAGE|g" "$MANIFEST" | kubectl apply -f -

# ----------------------------------------------------------
# Wait for Rollout
# ----------------------------------------------------------

echo
echo "Waiting for rollout..."

kubectl rollout status deployment/$GREEN_DEPLOYMENT

# ----------------------------------------------------------
# Health Check
# ----------------------------------------------------------

echo
echo "Running Health Check..."

URL=$(minikube service $SERVICE_NAME --url)

HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$URL/health")

if [ "$HTTP" != "200" ]; then

    echo
    echo "Health Check Failed!"
    echo
    echo "Keeping BLUE deployment active."
    exit 1

fi

echo
echo "Health Check Passed."

# ----------------------------------------------------------
# Traffic Switch
# ----------------------------------------------------------

echo
read -p "Switch traffic to GREEN? (Y/N): " SWITCH

if [[ "$SWITCH" =~ ^[Yy]$ ]]; then

    kubectl patch service $SERVICE_NAME \
    -p '{"spec":{"selector":{"app":"zero-downtime-api","color":"green"}}}'

    echo
    echo "Traffic switched to GREEN."

else

    echo
    echo "Traffic remains on BLUE."

fi

# ----------------------------------------------------------
# Deployment Summary
# ----------------------------------------------------------

echo
echo "========================================================="
echo "Deployment Summary"
echo "========================================================="

echo
echo "Image:"
echo "$IMAGE"

echo
echo "Application URL:"
minikube service $SERVICE_NAME --url

echo
echo "Deployments"
kubectl get deployments

echo
echo "Pods"
kubectl get pods -o wide

echo
echo "Services"
kubectl get svc

echo
echo "========================================================="
echo "Deployment Completed Successfully"
echo "========================================================="