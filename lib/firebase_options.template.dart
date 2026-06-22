import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "YOUR_API_KEY_HERE",
      appId: "YOUR_APP_ID_HERE",
      messagingSenderId: "YOUR_SENDER_ID_HERE",
      projectId: "YOUR_PROJECT_ID_HERE",
      authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
      databaseURL: "https://YOUR_PROJECT_ID.firebaseio.com",
      storageBucket: "YOUR_PROJECT_ID.appspot.com",
      measurementId: "YOUR_MEASUREMENT_ID",
    );
  }
}