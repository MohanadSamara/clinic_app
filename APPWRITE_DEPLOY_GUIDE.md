# Flutter Web Deployment Guide for Appwrite

This guide provides step-by-step instructions to deploy your Vet2u Flutter web application to Appwrite Cloud.

## Prerequisites

- [Appwrite Cloud Account](https://cloud.appwrite.io) (Project ID: `695f9b250005a6c99e08`)
- [Appwrite CLI](https://github.com/appwrite/cli) - Install via: `npm install -g appwrite-cli`
- Flutter SDK installed

## Deployment Options

### Option 1: Appwrite Storage (Recommended)

This is the simplest method for deploying a static Flutter web app.

#### Step 1: Build the Flutter Web App

**Windows:**
```bash
deploy_appwrite.bat
```

**macOS/Linux:**
```bash
chmod +x deploy_appwrite.sh
./deploy_appwrite.sh
```

Or manually:
```bash
flutter clean
flutter pub get
flutter build web --release
```

#### Step 2: Create Storage Bucket in Appwrite Console

1. Go to [Appwrite Cloud](https://cloud.appwrite.io)
2. Sign in with your account
3. Select project: **Vet2u** (ID: `695f9b250005a6c99e08`)
4. Navigate to **Storage** in the left sidebar
5. Click **Create Bucket**
6. Configure bucket settings:
   - **Bucket Name:** `web-app`
   - **Permissions:** Public (read access for all users)
   - **Maximum File Size:** 100 MB
   - **Allowed Extensions:** `html, js, css, png, jpg, jpeg, gif, svg, woff, woff2, ttf, json`

#### Step 3: Upload Files

1. Open the `web-app` bucket
2. Click **Upload Files**
3. Select all files from `build/web/` directory
4. Ensure these files are uploaded:
   - `index.html`
   - `flutter_bootstrap.js`
   - `main.dart.js`
   - `flutter.js`
   - All files in `assets/` folder
   - All files in `canvaskit/` folder

#### Step 4: Configure Bucket

1. Go to **Settings** tab in the bucket
2. Set **Default Homepage:** `index.html`
3. Add your domain to **CORS** settings:
   ```
   https://fra.cloud.appwrite.io
   https://your-custom-domain.com
   http://localhost:8080
   ```

#### Step 5: Access Your App

Your app will be available at:
```
https://fra.cloud.appwrite.io/v1/storage/buckets/web-app/files/[fileId]/view
```

Or configure a custom domain in bucket settings for a cleaner URL.

---

### Option 2: Appwrite Functions (Advanced)

Use Appwrite Functions to serve your Flutter web app with server-side rendering.

#### Step 1: Create a Function

```bash
appwrite login
appwrite init function
```

#### Step 2: Deploy Function

Configure your function to serve static files from the `build/web` directory.

---

### Option 3: Continuous Deployment with GitHub Actions

Update `.github/workflows/deploy.yml` to include Appwrite deployment steps.

```yaml
- name: Deploy to Appwrite Storage
  run: |
    npx appwrite-cli login --key ${{ secrets.APPWRITE_API_KEY }}
    npx appwrite-cli storage uploadDirectory build/web --bucketId web-app --recursive
```

## Configuration Files

This project includes:

| File | Purpose |
|------|---------|
| `appwrite.yaml` | Appwrite project configuration |
| `deploy_appwrite.bat` | Windows deployment script |
| `deploy_appwrite.sh` | macOS/Linux deployment script |

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Add your domain to bucket's CORS settings
   - Ensure the origin matches exactly

2. **404 on Refresh**
   - Enable "Default Homepage" in bucket settings
   - Configure routing to handle SPA navigation

3. **Large Files Upload**
   - Check bucket's maximum file size limit
   - Compress large assets

4. **Authentication Issues**
   - Verify project ID in configuration
   - Check API key permissions

### Check Build Output

Verify your build is successful:
```bash
ls -la build/web/
```

Expected files:
- `index.html` - Main HTML file
- `flutter_bootstrap.js` - Flutter bootstrap script
- `main.dart.js` - Compiled Dart code
- `flutter.js` - Flutter web runtime
- `assets/` - Static assets directory
- `canvaskit/` - Canvas rendering library

## Appwrite Configuration Details

```yaml
Project ID: 695f9b250005a6c99e08
Endpoint: https://fra.cloud.appwrite.io/v1
Region: fra (Frankfurt)
```

## Security Best Practices

1. **Keep API Keys Secure**
   - Never commit API keys to version control
   - Use environment variables
   - Rotate keys regularly

2. **Configure CORS Properly**
   - Only allow trusted origins
   - Restrict HTTP methods if possible

3. **Set Appropriate Permissions**
   - Make only necessary buckets public
   - Use role-based access control

## Additional Resources

- [Appwrite Documentation](https://appwrite.io/docs)
- [Flutter Web Deployment](https://docs.flutter.dev/web/deployment)
- [Appwrite Storage API](https://appwrite.io/docs/storage)

---

**Built with ❤️ for Vet2u**

