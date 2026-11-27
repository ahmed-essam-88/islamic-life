import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProphetsScreen extends StatefulWidget {
  const ProphetsScreen({super.key});
  @override
  State<ProphetsScreen> createState() => _ProphetsScreenState();
}

class _ProphetsScreenState extends State<ProphetsScreen> {
  List<dynamic>? _d;
  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/data/prophets.json').then((v) => setState(() => _d = jsonDecode(v)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('قصص الأنبياء')),
        body: _d == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _d!.length + 1,
                itemBuilder: (c, i) {
                  if (i == _d!.length) {
                    return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'المصدر: مجموعة بيانات مفتوحة mohammed-2-5/islamic-library-data (قصص 25 نبياً مذكورين في القرآن) مع الإحالة إلى مواضع الآيات. لا يوجد ملف ترخيص صريح للنصوص، ومصدر الصياغة غير موثق. المحتوى غير مراجَع من عالم شرعي، فارجع لكتب التفسير والسيرة المعتمدة.',
                            style: TextStyle(fontSize: 12)));
                  }
                  final p = _d![i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(p['name']),
                      subtitle: Text(p['summary'], maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ProphetStory(p: p))),
                    ),
                  );
                },
              ),
      );
}

class ProphetStory extends StatelessWidget {
  final dynamic p;
  const ProphetStory({super.key, required this.p});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(p['name'])),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(p['summary'], style: TextStyle(color: Theme.of(context).hintColor, height: 1.8)),
          for (final ch in p['chapters']) ...[
            const SizedBox(height: 18),
            Text(ch['t'], style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(ch['c'], style: const TextStyle(fontSize: 17, height: 2)),
            if ((ch['r'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('مواضع في القرآن: ${(ch['r'] as List).join(' ، ')}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              ),
            const Divider(),
          ],
          const Text('غير مراجَع من عالم شرعي. المصدر: islamic-library-data (مفتوح).', style: TextStyle(fontSize: 12)),
        ]),
      );
}
