import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/prayer.dart' show ar;
import '../data/quran.dart';
import '../data/store.dart';
import '../theme.dart';

class AllahName {
  final int n;
  final String name, translit, meaning, desc;
  final List<(int, int)> refs;
  AllahName(this.n, this.name, this.translit, this.meaning, this.desc, this.refs);
}

List<AllahName>? _names;
Future<List<AllahName>> loadNames() async {
  if (_names != null) return _names!;
  final j = jsonDecode(await rootBundle.loadString('assets/data/names.json'));
  return _names = [
    for (final e in j['data'])
      AllahName(e['number'], e['name'], e['transliteration'], e['meaning'], e['desc'], [
        for (final m in RegExp(r'\((\d+):(\d+)\)').allMatches(e['found'] ?? ''))
          (int.parse(m[1]!), int.parse(m[2]!))
      ])
  ];
}

class NamesScreen extends StatelessWidget {
  const NamesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('أسماء الله الحسنى')),
        body: FutureBuilder<List<AllahName>>(
          future: loadNames(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            return ListenableBuilder(
              listenable: Store.i,
              builder: (c, _) {
                final learned = Store.i.favDhikr.where((k) => k.startsWith('n:')).length;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Text('حفظت ${ar(learned)} من ٩٩'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: learned / 99, minHeight: 8),
                    ]),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3, padding: const EdgeInsets.all(8), childAspectRatio: 1.1,
                      children: [
                        for (final n in s.data!)
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NameDetail(n: n))),
                            child: Card(
                              color: Store.i.favDhikr.contains('n:${n.n}') ? emerald.withValues(alpha: 0.15) : null,
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(n.name, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24)),
                                Text(ar(n.n), style: const TextStyle(fontSize: 11, color: gold)),
                              ]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]);
              },
            );
          },
        ),
      );
}

class NameDetail extends StatelessWidget {
  final AllahName n;
  const NameDetail({super.key, required this.n});
  @override
  Widget build(BuildContext context) {
    final q = QuranData.loaded ? QuranData.i : null;
    return Scaffold(
      appBar: AppBar(title: Text('الاسم ${ar(n.n)}')),
      body: ListenableBuilder(
        listenable: Store.i,
        builder: (c, _) {
          final done = Store.i.favDhikr.contains('n:${n.n}');
          return ListView(padding: const EdgeInsets.all(16), children: [
            Center(child: Text(n.name, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 52, color: emerald))),
            Center(child: Text(n.translit, textDirection: TextDirection.ltr)),
            const SizedBox(height: 12),
            Directionality(textDirection: TextDirection.ltr, child: Text('${n.meaning}\n\n${n.desc}', style: const TextStyle(fontSize: 16, height: 1.6))),
            const Divider(height: 28),
            const Text('الأدلة من القرآن الكريم', style: TextStyle(fontWeight: FontWeight.bold)),
            if (q != null)
              for (final r in n.refs)
                if (r.$1 >= 1 && r.$1 <= 114 && r.$2 >= 1 && r.$2 <= q.surahs[r.$1 - 1].ayahCount)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(q.surahs[r.$1 - 1].ayahs[r.$2 - 1].text, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 2)),
                    subtitle: Text('${q.surahs[r.$1 - 1].name} - آية ${ar(r.$2)}'),
                  ),
            const SizedBox(height: 8),
            Text('المصدر: anno143/99-Names-of-Allah-Asma-ul-Husna-JSON-Dataset (المراجع تم التحقق منها آليًا مع نص تنزيل). المعاني بالإنجليزية فقط، وتحتاج مراجعة شرعية. الأدلة من السنة غير مضمّنة بعد.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Store.i.toggleFavDhikr('n:${n.n}'),
              icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(done ? 'حفظته' : 'علّمه كمحفوظ'),
            ),
          ]);
        },
      ),
    );
  }
}
