#!/bin/bash
# ================================================
# Flutter Web Deployment Script for Appwrite
# ================================================

set -e

echo "============================================"
echo "Vet2u Flutter Web Deployment Script"
echo "============================================"
echo ""

# Set variables
PROJECT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_PATH="${PROJECT_PATH}/build/web"
APPWRITE_PROJECT_ID="695f9b250005a6c99e08"
APPWRITE_ENDPOINT="https://fra.cloud.appwrite.io/v1"

echo "[1/5] Cleaning previous build..."
flutter clean

echo ""
echo "[2/5] Getting dependencies..."
flutter pub get

echo ""
echo "[3/5] Building Flutter web..."
flutter build web --release

echo ""
echo "[4/5] Verifying build files..."
if [ ! -f "${BUILD_PATH}/index.html" ]; then
    echo "ERROR: index.html not found in build/web"
    exit 1
fi

if [ ! -f "${BUILD_PATH}/flutter_bootstrap.js" ]; then
    echo "ERROR: flutter_bootstrap.js not found in build/web"
    exit 1
fi

echo ""
echo "[5/5] Build complete!"
echo ""
echo "============================================"
echo "Deployment Ready!"
echo "============================================"
echo ""
echo "Build files are located in: ${BUILD_PATH}"
echo ""
echo "To deploy to Appwrite:"
echo "1. Go to https://cloud.appwrite.io"
echo "2. Open your project: ${APPWRITE_PROJECT_ID}"
echo "3. Navigate to Storage > Create Bucket"
echo "4. Upload all files from ${BUILD_PATH}"
echo "5. Set the bucket as public"
echo "6. Configure index.html as the default file"
echo ""
echo "Or use Appwrite CLI:"
echo "  appwrite login"
echo "  appwrite storage createBucket web-app --public"
echo "  appwrite storage uploadDirectory ${BUILD_PATH} --bucketId web-app"
echo ""
echo "Your Appwrite endpoint: ${APPWRITE_ENDPOINT}"
echo ""

