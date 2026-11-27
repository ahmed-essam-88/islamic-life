import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/sync.dart';

/// Admin dashboard: publish announcements shown on every user's home screen.
/// Access is enforced by Firestore rules (admins/{uid}), not by this UI.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final t = TextEditingController(), b = TextEditingController();
  String? err;
  Future<void> _post() async {
    if (t.text.trim().isEmpty || b.text.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': t.text.trim(),
        'body': b.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      t.clear(); b.clear();
      setState(() => err = null);
    } catch (_) {
      setState(() => err = 'تعذر النشر (تحقق من الصلاحيات)');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('لوحة الإدارة')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('نشر إعلان للمستخدمين', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: t, maxLength: 150, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
          TextField(controller: b, maxLines: 3, maxLength: 2000, decoration: const InputDecoration(labelText: 'النص', border: OutlineInputBorder())),
          if (err != null) Text(err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FilledButton.icon(onPressed: _post, icon: const Icon(Icons.send), label: const Text('نشر')),
          const Divider(height: 32),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: Sync.announcements(),
            builder: (c, s) => Column(children: [
              for (final d in s.data?.docs ?? [])
                Card(child: ListTile(
                  title: Text(d['title'] ?? ''), subtitle: Text(d['body'] ?? ''),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => d.reference.delete()),
                )),
            ]),
          ),
        ]),
      );
}
