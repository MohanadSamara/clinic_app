# Qdrant Proxy

This small Node.js proxy forwards browser requests to a Qdrant Cloud cluster while injecting the required `api-key` header. It's useful for development when running the Flutter web app and CORS is blocking direct requests.

## Setup

1. Install dependencies:

```bash
cd server-proxy
npm install
```

2. Set environment variables (example):

```bash
# Linux / macOS
export QDRANT_URL="https://<your-cluster>.gcp.cloud.qdrant.io"
export QDRANT_API_KEY="<your-api-key>"
export PORT=3000

# Windows (PowerShell)
$env:QDRANT_URL = 'https://<your-cluster>.gcp.cloud.qdrant.io'
$env:QDRANT_API_KEY = '<your-api-key>'
$env:PORT = '3000'
```

3. Run the proxy:

```bash
npm start
```

## Usage with the Flutter app

- Change the Qdrant base URL in `lib/services/qdrant_service.dart` (or when creating the `QdrantService`) to point to the proxy base, for example:

```
http://localhost:3000/qdrant
```

- The proxy will forward requests to the real Qdrant cluster and inject the `api-key` header, avoiding CORS issues.
  
- This proxy forwards Qdrant requests to avoid CORS problems when running the Flutter web client locally. Configure `QDRANT_URL` and `QDRANT_API_KEY` when starting the proxy and call `/qdrant/*` from the browser.

## Deploy to Cloud Run (manual)

Build and push the image, then deploy to Cloud Run (requires `gcloud`):

```bash
# Authenticate
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT

# Build and push
docker build -t gcr.io/YOUR_GCP_PROJECT/qdrant-proxy:latest .
docker push gcr.io/YOUR_GCP_PROJECT/qdrant-proxy:latest

# Deploy
gcloud run deploy qdrant-proxy \
	--image gcr.io/YOUR_GCP_PROJECT/qdrant-proxy:latest \
	--region YOUR_REGION \
	--platform managed \
	--allow-unauthenticated
```

After deploying, use the Cloud Run URL as the proxy base (append `/qdrant`) and pass it to the Flutter web build with `--dart-define`:

```bash
flutter build web --release --dart-define=QDRANT_PROXY_BASE="https://<your-cloud-run-host>/qdrant"

When deploying the proxy, set `QDRANT_URL` and `QDRANT_API_KEY` env vars in Cloud Run and then point Flutter web at the deployed proxy by passing `QDRANT_PROXY_BASE`.
```

Then deploy the web build to Firebase Hosting or any static host.

## Security

This proxy uses the API key from environment variables. Do not deploy this as-is to public production without proper authentication and rate-limiting. For production, prefer a secure backend that signs requests per-user or uses restricted keys.
