import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default Firebase options for this app.
///
/// Generated manually from android/app/google-services.json.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3u9k8d5bqjfAazjjrejak2j5yL2AMMwc',
    appId: '1:58959146049:android:b47f7fc594b97c4b516ac0',
    messagingSenderId: '58959146049',
    projectId: 'three-degrees-of-doubt',
    storageBucket: 'three-degrees-of-doubt.firebasestorage.app',
  );
}
