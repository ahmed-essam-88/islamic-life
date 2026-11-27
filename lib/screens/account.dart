import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/auth.dart';
import '../data/sync.dart';
import 'admin.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool register = false, busy = false, hide = true;
  String? info;

  Future<void> _go() async {
    setState(() { busy = true; info = null; });
    try {
      final a = FirebaseAuth.instance;
      if (register) {
        await a.createUserWithEmailAndPassword(email: email.text.trim(), password: pass.text);
      } else {
        await a.signInWithEmailAndPassword(email: email.text.trim(), password: pass.text);
      }
    } catch (e) {
      info = Auth.msg(e);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _reset() async {
    if (email.text.trim().isEmpty) { setState(() => info = 'اكتب بريدك أولاً'); return; }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
      info = 'تم إرسال رابط إعادة التعيين إلى بريدك';
    } catch (e) { info = Auth.msg(e); }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: !Auth.ready
          ? const Center(child: Padding(padding: EdgeInsets.all(24),
              child: Text('الحسابات متاحة في تطبيق أندرويد فقط. التطبيق يعمل كاملاً بدون حساب.', textAlign: TextAlign.center)))
          : StreamBuilder<User?>(
              stream: Auth.changes,
              builder: (c, s) {
                final u = s.data ?? Auth.user;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: u != null
                      ? ListView(key: const ValueKey('in'), padding: const EdgeInsets.all(24), children: [
                          const SizedBox(height: 20),
                          CircleAvatar(radius: 44, backgroundColor: cs.primary,
                              child: Text((u.email ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 36, color: Colors.white))),
                          const SizedBox(height: 16),
                          Center(child: Text(u.email ?? '', style: const TextStyle(fontSize: 18))),
                          const SizedBox(height: 8),
                          const Center(child: Text('أنت مسجل الدخول. تتم مزامنة مفضلتك وتقدمك مع حسابك تلقائياً.', textAlign: TextAlign.center)),
                          const SizedBox(height: 24),
                          FutureBuilder<bool>(
                              future: Sync.isAdmin(u),
                              builder: (c, a) => a.data == true
                                  ? Padding(padding: const EdgeInsets.only(bottom: 12), child: FilledButton.icon(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                                      icon: const Icon(Icons.admin_panel_settings), label: const Text('لوحة الإدارة')))
                                  : const SizedBox()),
                          FilledButton.tonalIcon(
                              onPressed: () => FirebaseAuth.instance.signOut(),
                              icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
                        ])
                      : ListView(key: const ValueKey('out'), padding: const EdgeInsets.all(24), children: [
                          Icon(Icons.person_outline, size: 72, color: cs.primary),
                          const SizedBox(height: 8),
                          Center(child: Text(register ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                              style: Theme.of(context).textTheme.titleLarge)),
                          const SizedBox(height: 20),
                          TextField(controller: email, keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined))),
                          const SizedBox(height: 12),
                          TextField(controller: pass, obscureText: hide,
                              decoration: InputDecoration(labelText: 'كلمة المرور', border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => hide = !hide)))),
                          if (info != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(info!, style: TextStyle(color: cs.error))),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: busy ? null : _go,
                              child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(register ? 'إنشاء الحساب' : 'دخول')),
                          TextButton(onPressed: () => setState(() { register = !register; info = null; }),
                              child: Text(register ? 'لدي حساب بالفعل' : 'ليس لدي حساب؟ أنشئ حساباً')),
                          if (!register) TextButton(onPressed: _reset, child: const Text('نسيت كلمة المرور')),
                          const SizedBox(height: 8),
                          const Text('الحساب اختياري. عند تسجيل الدخول تُزامَن مفضلتك وتقدمك فقط مع حسابك عبر Firebase.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        ]),
                );
              }),
    );
  }
}
