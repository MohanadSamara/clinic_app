# Deploy Guide — Firebase Hosting + Cloud Run proxy

This document describes the recommended production setup: Flutter web on Firebase Hosting and a small proxy deployed to Google Cloud Run to securely forward requests to Qdrant Cloud (injecting the `api-key`).

Prerequisites
- GCP project with billing enabled
- gcloud CLI installed and authenticated
- Docker installed for building images locally
- Firebase project and `firebase` CLI authenticated
- GitHub repo for CI (optional)

Required GitHub secrets (if using the provided workflow)
- `GCP_SA_KEY`: JSON contents of a GCP service account with `roles/run.admin`, `roles/storage.admin`, `roles/iam.serviceAccountUser` and `roles/storage.objectViewer`.
- `GCP_PROJECT`: your GCP project id (also used in workflow env)
- `FIREBASE_TOKEN`: token from `firebase login:ci` for the Firebase project

Local dev (quick test)
1. Start the proxy locally:

```bash
cd server-proxy
npm install
# set env vars for local testing (PowerShell example)
$env:QDRANT_URL='https://<your-cluster>.gcp.cloud.qdrant.io'
$env:QDRANT_API_KEY='<your-api-key>'
node index.js
```

The proxy will listen on `http://localhost:3000` and forward `/qdrant/*` to Qdrant.

2. Build and run Flutter web pointing to the local proxy:

```bash
# from repo root
flutter build web --release --dart-define=QDRANT_PROXY_BASE="http://localhost:3000/qdrant"
# serve the build (or use Firebase hosting local serve)
npx http-server build/web -p 8080
# open http://localhost:8080
```

Production deploy (manual)
1. Build and push Docker image for proxy:

```bash
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT
cd server-proxy
docker build -t gcr.io/YOUR_GCP_PROJECT/qdrant-proxy:latest .
docker push gcr.io/YOUR_GCP_PROJECT/qdrant-proxy:latest
```

2. Deploy to Cloud Run:

```bash
gcloud run deploy qdrant-proxy \
  --image gcr.io/YOUR_GCP_PROJECT/qdrant-proxy:latest \
  --region YOUR_REGION \
  --platform managed \
  --allow-unauthenticated
```

3. Build Flutter web using the Cloud Run URL as proxy base (append `/qdrant`):

```bash
flutter build web --release --dart-define=QDRANT_PROXY_BASE="https://<your-cloud-run-host>/qdrant"
```

4. Deploy web to Firebase Hosting:

```bash
firebase deploy --only hosting
```

CI/CD with GitHub Actions
- The repo includes `.github/workflows/deploy.yml`. Set the required GitHub secrets and the workflow will:
  1. Build and push the proxy image to GCR
  2. Deploy the proxy to Cloud Run
  3. Build Flutter web and deploy to Firebase Hosting

Security notes
- Do not embed the Qdrant API key into the web client. The proxy injects the `api-key` server-side.
- Protect the proxy endpoint (authentication, rate-limiting) before exposing it publicly for production.
- Consider using per-user authentication and short-lived credentials for high-security apps.
