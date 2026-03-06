# 🔥 FIREBASE CONSOLE SETUP

## Step 1: Enable Authentication (3 minutes)

1. Go to https://console.firebase.google.com/
2. Select your project
3. Click **Build > Authentication**
4. Click **Get Started** (if first time)
5. Click **Email/Password** under Sign-in providers
6. Toggle **Enable** to ON
7. Click **Save**

---

## Step 2: Enable Firestore Database (3 minutes)

1. Click **Build > Firestore Database**
2. Click **Create database**
3. Select **Start in test mode**
4. Choose location: **europe-west** (closest to Rwanda)
5. Click **Enable**

---

## Step 3: Set Security Rules (2 minutes)

1. In Firestore Database, click **Rules** tab
2. **DELETE ALL** existing rules
3. **COPY & PASTE** the rules below:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can only read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Services collection
    match /services/{serviceId} {
      // Anyone authenticated with verified email can read
      allow read: if request.auth != null && request.auth.token.email_verified;
      
      // Only authenticated users with verified email can create
      // Must set createdBy to their own UID
      allow create: if request.auth != null 
                    && request.auth.token.email_verified
                    && request.resource.data.createdBy == request.auth.uid;
      
      // Only the creator can update or delete their own services
      allow update, delete: if request.auth != null 
                            && request.auth.token.email_verified
                            && resource.data.createdBy == request.auth.uid;
    }
  }
}
```

4. Click **Publish**
5. Verify no errors appear

---

## ✅ VERIFICATION

### Check Authentication:
- Go to **Authentication > Users**
- Should be empty initially
- After registration, users will appear here

### Check Firestore:
- Go to **Firestore Database > Data**
- Should be empty initially
- After loading sample data, collections will appear

### Check Rules:
- Go to **Firestore Database > Rules**
- Should show the rules you pasted
- Status should be "Published"

---

## 🎯 DONE!

Your Firebase is now configured. Return to the app and:
1. Run `flutter pub get`
2. Run `flutter run`
3. Register a new account
4. Verify your email
5. Start using the app!
