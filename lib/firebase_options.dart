// File generated using FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return ios;
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
    apiKey: 'AIzaSyCoJvt4Wa-teEcFCanD-BYS8TUuKgZVu-0',
    appId: '1:777661093391:web:4l061mqq5jn4ck2qktj5s3',
    messagingSenderId: '777661093391',
    projectId: 'must11',
    authDomain: 'must11.firebaseapp.com',
    storageBucket: 'must11.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoJvt4Wa-teEcFCanD-BYS8TUuKgZVu-0',
    appId: '1:777661093391:android:2c261d2a17626677acf57a',
    messagingSenderId: '777661093391',
    projectId: 'must11',
    storageBucket: 'must11.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCoJvt4Wa-teEcFCanD-BYS8TUuKgZVu-0',
    appId: '1:777661093391:ios:your-ios-app-id',
    messagingSenderId: '777661093391',
    projectId: 'must11',
    storageBucket: 'must11.firebasestorage.app',
    iosBundleId: 'com.example.anrFixed',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCoJvt4Wa-teEcFCanD-BYS8TUuKgZVu-0',
    appId: '1:777661093391:web:your-web-app-id',
    messagingSenderId: '777661093391',
    projectId: 'must11',
    authDomain: 'must11.firebaseapp.com',
    storageBucket: 'must11.firebasestorage.app',
  );
}
