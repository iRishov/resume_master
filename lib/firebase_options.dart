import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCsA7j4ekgqRITTxLkkkcUSV-8ws4jw4fM',
    appId: '1:541168145892:web:024bd92ffcbf48f600e3f1',
    messagingSenderId: '541168145892',
    projectId: 'resume-master-61af6',
    authDomain: 'resume-master-61af6.firebaseapp.com',
    storageBucket: 'resume-master-61af6.firebasestorage.app',
    measurementId: 'G-V74QTBWY0N',
  );
} 