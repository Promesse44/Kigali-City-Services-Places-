// PLACEHOLDER - Replace with your new Firebase configuration
// Generated from Firebase Console → Project Settings → Your apps → Flutter
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAk8wv9F_mYS3P6N7oek5eWM31CybASnE0',
    appId: '1:689434079379:web:9b6ef164c0f011dfef5d66',
    messagingSenderId: '689434079379',
    projectId: 'kigaliservices-69504',
    authDomain: 'kigaliservices-69504.firebaseapp.com',
    storageBucket: 'kigaliservices-69504.firebasestorage.app',
  );

  // TODO: Replace these with your new Firebase project configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAoXNWhof4zltTeLQ-Q9Qr2DLt9vZRqj-Y',
    appId: '1:689434079379:android:73d16705adc01214ef5d66',
    messagingSenderId: '689434079379',
    projectId: 'kigaliservices-69504',
    storageBucket: 'kigaliservices-69504.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBc7OmJ__2G2s5L3zd3RqRhbS2tfWdLYnI',
    appId: '1:689434079379:ios:666c3509b432be21ef5d66',
    messagingSenderId: '689434079379',
    projectId: 'kigaliservices-69504',
    storageBucket: 'kigaliservices-69504.firebasestorage.app',
    iosBundleId: 'com.example.kigaliServiceApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAk8wv9F_mYS3P6N7oek5eWM31CybASnE0',
    appId: '1:689434079379:web:d6a77eb4b7389966ef5d66',
    messagingSenderId: '689434079379',
    projectId: 'kigaliservices-69504',
    authDomain: 'kigaliservices-69504.firebaseapp.com',
    storageBucket: 'kigaliservices-69504.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.kigaliServiceApp',
  );
}