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
    apiKey: 'AIzaSyARP-sff3enADIZoo49biGOgGcxxyJAUGo',
    appId: '1:295278056194:web:3725ab61d3d820133c281b',
    messagingSenderId: '295278056194',
    projectId: 'citywest-f4c4f',
    authDomain: 'citywest-f4c4f.firebaseapp.com',
    storageBucket: 'citywest-f4c4f.firebasestorage.app',
    measurementId: 'G-7V6F7QDGZE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQEYunrCWstAT6Wa3tT5fcLDut1HvBmyE',
    appId: '1:295278056194:android:b8ad2701b3d3be693c281b',
    messagingSenderId: '295278056194',
    projectId: 'citywest-f4c4f',
    storageBucket: 'citywest-f4c4f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5zwbY4t_p0CXLgJ1YqcnClAwgEQDQH24',
    appId: '1:295278056194:ios:e2bca7adde0e39bc3c281b',
    messagingSenderId: '295278056194',
    projectId: 'citywest-f4c4f',
    storageBucket: 'citywest-f4c4f.firebasestorage.app',
    iosBundleId: 'com.example.kigaliServiceApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB5zwbY4t_p0CXLgJ1YqcnClAwgEQDQH24',
    appId: '1:295278056194:ios:e2bca7adde0e39bc3c281b',
    messagingSenderId: '295278056194',
    projectId: 'citywest-f4c4f',
    storageBucket: 'citywest-f4c4f.firebasestorage.app',
    iosBundleId: 'com.example.kigaliServiceApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDwFTaMEQ9XW3AtjUKu8U_sHCDOSRRMTow',
    appId: '1:295278056194:web:30450a6efecdcfae3c281b',
    messagingSenderId: '295278056194',
    projectId: 'citywest-f4c4f',
    authDomain: 'citywest-f4c4f.firebaseapp.com',
    storageBucket: 'citywest-f4c4f.firebasestorage.app',
    measurementId: 'G-0PEEDTC3Y2',
  );

}