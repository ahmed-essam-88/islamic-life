import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'store.dart';

/// Syncs favorites and progress to users/{uid} when signed in. Local-first.
class Sync {
  static Timer? _t;
  static bool _busy = false;
  static String? _lastJson;

  static void start() {
    if (!Auth.ready) return;
    Auth.changes.listen((u) {
      if (u != null) pullThenPush(u.uid);
    });
    Store.i.addListener(() {
      final u = Auth.user;
      if (u == null || _busy) return;
      _t?.cancel();
      _t = Timer(const Duration(seconds: 6), () => push(u.uid));
    });
  }

  static Future<void> pullThenPush(String uid) async {
    try {
      _busy = true;
      final doc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await doc.get();
      if (snap.exists) Store.i.mergeSync(snap.data()!);
      _busy = false;
      await push(uid);
    } catch (_) {
      _busy = false;
    }
  }

  static Future<void> push(String uid) async {
    try {
      final d = Store.i.exportSync();
      final j = d.toString();
      if (j == _lastJson) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({...d, 'updated': FieldValue.serverTimestamp()});
      _lastJson = j;
    } catch (_) {}
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> announcements() =>
      FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots();

  static Future<bool> isAdmin(User u) async {
    try {
      final s = await FirebaseFirestore.instance.collection('admins').doc(u.uid).get();
      return s.exists;
    } catch (_) {
      return false;
    }
  }
}
