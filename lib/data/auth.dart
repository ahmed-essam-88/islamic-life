import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth only (email + password). Client keys are public identifiers.
class Auth {
  static bool ready = false;
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp(
          options: const FirebaseOptions(
        apiKey: 'AIzaSyAbDBbJCPLJ_xIcfZEwkws74zPE-P_md9o',
        appId: '1:976940624075:android:706cb9e4a1b017d0d2534e',
        messagingSenderId: '976940624075',
        projectId: 'islamic-life-app-79502',
      ));
      ready = true;
    } catch (_) {
      ready = false;
    }
  }

  static User? get user => ready ? FirebaseAuth.instance.currentUser : null;
  static Stream<User?> get changes =>
      ready ? FirebaseAuth.instance.authStateChanges() : const Stream.empty();

  static String msg(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email': return 'البريد الإلكتروني غير صالح';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential': return 'البريد أو كلمة المرور غير صحيحة';
        case 'email-already-in-use': return 'هذا البريد مسجل بالفعل';
        case 'weak-password': return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
        case 'network-request-failed': return 'تحقق من الاتصال بالإنترنت';
        case 'too-many-requests': return 'محاولات كثيرة، حاول لاحقاً';
      }
    }
    return 'حدث خطأ، حاول مرة أخرى';
  }
}
