import 'package:flutter/material.dart';
import '../data/fiqh.dart';
import '../theme.dart';

class FiqhScreen extends StatefulWidget {
  const FiqhScreen({super.key});
  @override
  State<FiqhScreen> createState() => _FiqhScreenState();
}

class _FiqhScreenState extends State<FiqhScreen> {
  final _q = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final topics = [
      for (final t in fiqhTopics)
        if (q.isEmpty || t.title.contains(q) || t.items.any((i) => i.title.contains(q) || i.text.contains(q))) t
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('الفقه والعبادات')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        TextField(
          controller: _q,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: 'ابحث في الفقه', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: const Text('هذا ملخص تعليمي للمسائل المتفق عليها، وتُعرض المسائل الخلافية بأقوال المذاهب منسوبة لأصحابها. ليس فتوى، ولم يُراجَع بعد من عالم شرعي. في المسائل الخاصة بك اسأل دار الإفتاء أو عالمًا موثوقًا.'),
        ),
        const SizedBox(height: 8),
        for (final t in topics)
          Card(
            child: ExpansionTile(
              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in t.items) ...[
                  Text(i.title, style: const TextStyle(color: emerald, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(i.text, style: const TextStyle(fontSize: 16, height: 1.8)),
                  const SizedBox(height: 4),
                  Text('المصدر: ${i.source}', style: Theme.of(context).textTheme.bodySmall),
                  const Divider(),
                ],
              ],
            ),
          ),
      ]),
    );
  }
}
