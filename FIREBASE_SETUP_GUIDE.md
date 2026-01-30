# Firebase Configuration Guide for Vet2U Clinic App

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click **"Add project"**
3. Enter project name: `vet2u-clinic-app`
4. Disable Google Analytics (optional, keeps it free)
5. Wait for project creation

## Step 2: Add Web App to Firebase

1. In Firebase Console, click **Web icon (</>)**
2. Register app with nickname: `vet2u-web`
3. **Copy the firebaseConfig** - you'll need these values:
   ```javascript
   {
     apiKey: "YOUR_API_KEY",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc123"
   }
   ```

## Step 3: Update lib/firebase_options.dart

Replace the placeholder values with your actual Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY_HERE',           // ← Get from Firebase Console
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT.appspot.com',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
  measurementId: 'G-XXXXXXXXXX',
);
```

## Step 4: Enable Authentication

1. Go to **Authentication** → **Get started**
2. Go to **"Sign-in method"** tab
3. Enable these providers:
   - ✅ **Email/Password** (Enable "Email link" too)
   - ✅ **Google** (optional)
   - ✅ **Facebook** (optional)

## Step 5: Enable Firestore Database

1. Go to **Firestore Database** → **Create database**
2. Choose location (select one close to Jordan)
3. Start in **"Test mode"** (allows all reads/writes for 30 days)
4. Click **"Enable"**

## Step 6: Add Authorized Domains

1. Go to **Authentication → Sign-in method**
2. Scroll to **"Authorized domains"**
3. Add:
   - `localhost` (for local testing)
   - `your-app.netlify.app` (after deploying)
   - `127.0.0.1` (for local development)

## Step 7: Configure EmailJS (for OTP Verification)

1. Go to https://www.emailjs.com/
2. Sign up for FREE account
3. Create Email Service (select Gmail, Outlook, etc.)
4. Create Email Template:
   ```
   Subject: Your Vet2U Verification Code

   Hi,

   Your verification code is: {{passcode}}

   This code expires in 15 minutes.
   ```
5. Update `lib/services/email_service.dart`:
   ```dart
   const String _emailJsServiceId = 'your_service_id';
   const String _emailJsTemplateId = 'your_template_id';
   const String _emailJsPublicKey = 'your_public_key';
   ```

## Step 8: Test Locally

```bash
flutter run -d chrome
```

## Step 9: Deploy to Netlify

```bash
# Build for web
flutter build web

# Deploy
netlify deploy --prod --dir=build/web
```

## Step 10: Add Netlify Domain to Firebase

After deploying to Netlify:
1. Copy your Netlify URL (e.g., `vet2u.netlify.app`)
2. Go to Firebase Console → Authentication → Sign-in method
3. Add your Netlify domain to **Authorized domains**

---

## Quick Reference - Firebase Console URLs

| What | URL |
|------|-----|
| Firebase Console | https://console.firebase.google.com/ |
| Project Settings | ⚙️ → Project Settings |
| Authentication | 🔐 → Authentication |
| Firestore Database | 📦 → Firestore Database |
| Add Authorized Domains | 🔐 → Sign-in method → Authorized domains |

---

## Free Tier Limits (You Won't Exceed These)

| Service | Free Limit |
|---------|------------|
| Authentication | Unlimited users |
| Firestore | 1 GB storage, 50K reads/day |
| Storage | 5 GB |
| Hosting | 10 GB bandwidth/month |

---

## Troubleshooting

### "No Firebase App has been created"
- Make sure Firebase is initialized in `main.dart`
- Check `firebase_options.dart` has correct values

### "Domain not authorized"
- Add your domain to Firebase Console → Authentication → Authorized domains

### "Permission denied" in Firestore
- Change Firestore rules to test mode temporarily:
  ```
  allow read, write: if true;
  ```
- Or set proper rules for production

### Users not showing for admin
- Make sure to use `registerWithFirebase()` instead of `register()`
- Users are synced to Firestore automatically
- Admin loads from Firestore first, then falls back to local

