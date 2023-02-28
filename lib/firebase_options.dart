// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCOHxylqUn6sgQrZ6QyQVXXQgvslRXA3IE',
    appId: '1:62323116792:web:1cc20090828a20c058090d',
    messagingSenderId: '62323116792',
    projectId: 'stocklio-beta',
    authDomain: 'stocklio-beta.firebaseapp.com',
    databaseURL: 'https://stocklio-beta.firebaseio.com',
    storageBucket: 'stocklio-beta.appspot.com',
    measurementId: 'G-WC978VV3YF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrqqyvzlOK65LHotK4DJiOtGwrkGI6LT0',
    appId: '1:62323116792:android:7828f2e6f3c1a8cf58090d',
    messagingSenderId: '62323116792',
    projectId: 'stocklio-beta',
    databaseURL: 'https://stocklio-beta.firebaseio.com',
    storageBucket: 'stocklio-beta.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAhLFQgzFr1Z1vpP33Ovjq9smXbYQmVSWw',
    appId: '1:62323116792:ios:25d9d1408bcf09ee58090d',
    messagingSenderId: '62323116792',
    projectId: 'stocklio-beta',
    databaseURL: 'https://stocklio-beta.firebaseio.com',
    storageBucket: 'stocklio-beta.appspot.com',
    iosClientId:
        '62323116792-k31vn3tp1dd6ocqgpfdgqb1s2prib3ak.apps.googleusercontent.com',
    iosBundleId: 'io.stockl.stocklio',
  );
}