# Firebase Initialization and Required Settings

This project is already wired to Firebase project `citywest-f4c4f` through:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`

## 1) Firebase Console Settings

1. Open Firebase Console -> project `citywest-f4c4f`.
2. Go to `Authentication` -> `Sign-in method` -> enable `Email/Password`.
3. Go to `Authentication` -> `Templates` -> `Email address verification`.
4. Make sure verification email template is enabled and has your app name.
5. Go to `Firestore Database` -> create database (if not created yet).
6. Start in production mode (recommended for assignment security checks).

## 2) Deploy Firestore Rules and Indexes

This repo now includes:
- `firestore.rules`
- `firestore.indexes.json`

Deploy them:

```bash
firebase login
firebase use citywest-f4c4f
firebase deploy --only firestore:rules,firestore:indexes
```

## 3) Flutter Initialization Check

`main.dart` initializes Firebase before app startup:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

No extra code changes are needed for initialization.

## 4) Email Verification Flow in App

Implemented behavior:
- Signup sends verification email automatically.
- Unverified users are blocked from app access.
- A dedicated screen allows resend + refresh verification status.

## 5) Security Expectations Enforced

Rules now enforce:
- Only authenticated + email-verified users can read services.
- Only owner (`createdBy == request.auth.uid`) can create/update/delete their listings.
- Users can only read/write their own profile document.

## 6) ENOTFOUND Error You Reported

`getaddrinfo ENOTFOUND codewhisperer.us-east-1.amazonaws.com` is a DNS/network resolution issue for AWS CodeWhisperer/Amazon Q endpoint, not a Flutter/Firebase app code issue.

Quick checks:
- Verify internet/DNS works (`nslookup codewhisperer.us-east-1.amazonaws.com`).
- If on school/company network, check firewall/proxy restrictions.
- If using VS Code AWS extension, sign out/in and restart VS Code.
- If blocked by policy, disable CodeWhisperer extension while working on this app.
