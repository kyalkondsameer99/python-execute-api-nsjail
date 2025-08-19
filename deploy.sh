#!/bin/bash

# Python Execute API - Cloud Run Deployment Script
# This script deploys the API to Google Cloud Run

set -e

echo "🚀 Deploying Python Execute API to Google Cloud Run..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first:"
    echo "   https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Not authenticated with gcloud. Please run:"
    echo "   gcloud auth login"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ No project ID configured. Please run:"
    echo "   gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "📁 Project ID: $PROJECT_ID"

# Set region
REGION=${1:-us-central1}
echo "🌍 Region: $REGION"

# Service name
SERVICE_NAME="pyexec-api"
echo "🔧 Service name: $SERVICE_NAME"

# Build and tag the image
echo "🏗️  Building Docker image..."
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/$SERVICE_NAME/api:latest .

# Configure Docker to use gcloud as a credential helper
echo "🔐 Configuring Docker authentication..."
gcloud auth configure-docker $REGION-docker.pkg.dev

# Push the image to Artifact Registry
echo "📤 Pushing image to Artifact Registry..."
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$SERVICE_NAME/api:latest

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image $REGION-docker.pkg.dev/$PROJECT_ID/$SERVICE_NAME/api:latest \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --memory 1Gi \
    --cpu 1 \
    --timeout 300 \
    --concurrency 80 \
    --set-env-vars="PYEXEC_TIMEOUT=30,PYEXEC_MAX_SCRIPT_CHARS=100000"

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo ""
echo "✅ Deployment successful!"
echo "🌐 Service URL: $SERVICE_URL"
echo ""
echo "🧪 Test the service:"
echo "curl -X POST $SERVICE_URL/execute \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"script\": \"def main():\\n    return {\\\"message\\\": \\\"Hello from Cloud Run!\\\"}\\n\"}'"
echo ""
echo "📊 Check service status:"
echo "gcloud run services describe $SERVICE_NAME --region=$REGION"
echo ""
echo "🗑️  To delete the service:"
echo "gcloud run services delete $SERVICE_NAME --region=$REGION"
