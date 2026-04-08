import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
        'This admin panel is web only.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCzhbIp7F5sSB_gsUNhCQ9zF6_nTdjp_bI',
    appId: '1:377469784644:web:1ec055a921a1c06174e211',
    messagingSenderId: '377469784644',
    projectId: 'inlo-1264a',
    authDomain: 'inlo-1264a.firebaseapp.com',
    storageBucket: 'inlo-1264a.firebasestorage.app',
  );
}