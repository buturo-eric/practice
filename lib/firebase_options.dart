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
        return macos;
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
    apiKey: 'AIzaSyAjYX1HV_K0hZ-RnDOD4h5mzJz5W9VmPYE',
    appId: '1:732749183650:web:8c30c7b28a890f1ffc35fb',
    messagingSenderId: '732749183650',
    projectId: 'testt-bd489',
    authDomain: 'testt-bd489.firebaseapp.com',
    storageBucket: 'testt-bd489.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTHm5ZFU_WrzRLLRE3hjyY8giWVPY1PqI',
    appId: '1:732749183650:android:3ce31540a20ad19afc35fb',
    messagingSenderId: '732749183650',
    projectId: 'testt-bd489',
    storageBucket: 'testt-bd489.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCagZ1nIGc7KPetlWYo8YRo3J85Gzwyumw',
    appId: '1:732749183650:ios:85ce1bf52e68ca71fc35fb',
    messagingSenderId: '732749183650',
    projectId: 'testt-bd489',
    storageBucket: 'testt-bd489.appspot.com',
    iosBundleId: 'com.example.testt',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCagZ1nIGc7KPetlWYo8YRo3J85Gzwyumw',
    appId: '1:732749183650:ios:3b80df99d65b2da8fc35fb',
    messagingSenderId: '732749183650',
    projectId: 'testt-bd489',
    storageBucket: 'testt-bd489.appspot.com',
    iosBundleId: 'com.example.testt.RunnerTests',
  );
}
