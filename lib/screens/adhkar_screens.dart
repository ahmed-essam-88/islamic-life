import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/prayer.dart' show ar;
import '../data/store.dart';
import '../theme.dart';

class Dhikr {
  final String id, text, source, fadl;
  final int count;
  Dhikr(this.id, this.text, this.count, this.source, this.fadl);
}

class Category {
  final String id, title, origin;
  final List<Dhikr> items;
  Category(this.id, this.title, this.items, this.origin);
}

List<Category>? _cache;

Future<List<Category>> loadAdhkar() async {
  if (_cache != null) return _cache!;
  final out = <Category>[];
  final seen = jsonDecode(await rootBundle.loadString('assets/data/adhkar_seen.json')) as List;
  out.add(Category('seen', 'أذكار الصباح والمساء', [
    for (final e in seen)
      Dhikr('seen${e['order']}', e['content'], (e['count'] as num).toInt(), e['source'] ?? '', e['fadl'] ?? '')
  ], 'Seen-Arabic/Morning-And-Evening-Adhkar-DB (MIT)'));
  final hisn = jsonDecode(await rootBundle.loadString('assets/data/hisn.json')) as Map<String, dynamic>;
  var n = 0;
  for (final e in hisn.entries) {
    if (e.key == 'المقدمة') continue;
    final texts = ((e.value['text'] ?? []) as List).map((x) => x.toString()).toList();
    if (texts.isEmpty) continue;
    out.add(Category('hisn${n++}', e.key, [
      for (var k = 0; k < texts.length; k++) Dhikr('hisn$n-$k', texts[k], 1, 'حصن المسلم - سعيد بن علي القحطاني', '')
    ], 'حصن المسلم (rn0x/hisn_almuslim_json)'));
  }
  return _cache = out;
}

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الأذكار والأدعية'), actions: [
          IconButton(icon: const Icon(Icons.fingerprint), tooltip: 'المسبحة',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen()))),
        ]),
        body: FutureBuilder<List<Category>>(
          future: loadAdhkar(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final cats = s.data!;
            return ListView.builder(
              itemCount: cats.length + 1,
              itemBuilder: (c, i) {
                if (i == 0) {
                  return Card(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: ListTile(
                      leading: const Icon(Icons.favorite, color: gold),
                      title: const Text('المفضلة'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen(cats: cats))),
                    ),
                  );
                }
                final cat = cats[i - 1];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: emerald.withOpacity(0.12), child: Text(ar(i))),
                  title: Text(cat.title),
                  subtitle: Text('${ar(cat.items.length)} ذكر'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(cat: cat))),
                );
              },
            );
          },
        ),
      );
}

class CategoryScreen extends StatelessWidget {
  final Category cat;
  const CategoryScreen({super.key, required this.cat});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(cat.title)),
        body: ListenableBuilder(
          listenable: Store.i,
          builder: (c, _) => ListView(padding: const EdgeInsets.all(12), children: [
            for (final d in cat.items) DhikrCard(d: d),
            Padding(padding: const EdgeInsets.all(8), child: Text('المصدر: ${cat.origin}', style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ),
      );
}

class FavoritesScreen extends StatelessWidget {
  final List<Category> cats;
  const FavoritesScreen({super.key, required this.cats});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المفضلة')),
        body: ListenableBuilder(
          listenable: Store.i,
          builder: (c, _) {
            final fav = Store.i.favDhikr;
            final items = [for (final k in cats) ...k.items.where((d) => fav.contains(d.id))];
            if (items.isEmpty) return const Center(child: Text('لم تضف أذكارًا للمفضلة بعد.'));
            return ListView(padding: const EdgeInsets.all(12), children: [for (final d in items) DhikrCard(d: d)]);
          },
        ),
      );
}

class DhikrCard extends StatelessWidget {
  final Dhikr d;
  const DhikrCard({super.key, required this.d});
  @override
  Widget build(BuildContext context) {
    final st = Store.i;
    final done = st.dhikrCount(d.id);
    final complete = done >= d.count;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.text, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 2.1)),
          if (d.fadl.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('الفضل: ${d.fadl}', style: Theme.of(context).textTheme.bodySmall)),
          if (d.source.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('المصدر: ${d.source}', style: Theme.of(context).textTheme.bodySmall)),
          Row(children: [
            IconButton(icon: Icon(st.favDhikr.contains(d.id) ? Icons.favorite : Icons.favorite_border), onPressed: () => st.toggleFavDhikr(d.id)),
            IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: d.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ'))); }),
            const Spacer(),
            if (d.count > 1 || true)
              FilledButton.tonal(
                onPressed: complete ? () => st.setDhikrCount(d.id, 0) : () { HapticFeedback.lightImpact(); st.setDhikrCount(d.id, done + 1); },
                child: Text(complete ? 'تم ✓ (إعادة)' : '${ar(done)} / ${ar(d.count)}'),
              ),
          ]),
        ]),
      ),
    );
  }
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});
  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  int _n = 0;
  int _target = 33;
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.92, upperBound: 1)..value = 1;

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.mediumImpact();
    _a.reverse().then((_) => _a.forward());
    setState(() { _n++; Store.i.tasbihTotal = Store.i.tasbihTotal + 1; });
    if (_n == _target) HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المسبحة')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, children: [
              for (final t in [33, 99, 100]) ChoiceChip(label: Text(ar(t)), selected: _target == t, onSelected: (_) => setState(() { _target = t; _n = 0; })),
            ]),
            const SizedBox(height: 30),
            ScaleTransition(
              scale: _a,
              child: GestureDetector(
                onTap: _tap,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [emerald, navy]), border: Border.all(color: gold, width: 4)),
                  alignment: Alignment.center,
                  child: Text(ar(_n), style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('الهدف ${ar(_target)}  -  إجمالي كل الأوقات: ${ar(Store.i.tasbihTotal)}'),
            TextButton(onPressed: () => setState(() => _n = 0), child: const Text('إعادة')),
          ]),
        ),
      );
}
