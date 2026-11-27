import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/hadith.dart';
import '../data/prayer.dart' show ar;
import '../data/store.dart';
import '../theme.dart';

class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({super.key});
  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> {
  final _q = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final res = q.isEmpty ? <(HadithBook, Hadith)>[] : searchLoaded(q);
    return Scaffold(
      appBar: AppBar(title: const Text('الحديث الشريف'), actions: [
        IconButton(icon: const Icon(Icons.favorite), tooltip: 'المفضلة',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithFavorites()))),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث في الكتب المحمّلة',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(
          child: q.isNotEmpty
              ? (res.isEmpty
                  ? const Center(child: Text('لا نتائج في الكتب المحمّلة. حمّل الكتاب أولًا بفتحه.'))
                  : ListView(children: [for (final r in res) HadithTile(book: r.$1, h: r.$2)]))
              : ListView(children: [
                  for (final b in hadithBooks)
                    ListTile(
                      leading: const Icon(Icons.auto_stories, color: emerald),
                      title: Text(b.name),
                      subtitle: FutureBuilder<bool>(
                        future: isDownloaded(b),
                        builder: (c, s) => Text(s.data == true ? 'جاهز للقراءة بدون إنترنت' : 'يُحمَّل عند أول فتح'),
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HadithBookScreen(book: b))).then((_) => setState(() {})),
                    ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('المصدر: hadith-api (fawazahmed0). مسند أحمد غير متوفر في هذه المصدر فلم يُدرَج.'),
                  ),
                ]),
        ),
      ]),
    );
  }
}

class HadithBookScreen extends StatelessWidget {
  final HadithBook book;
  const HadithBookScreen({super.key, required this.book});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(book.name)),
        body: FutureBuilder<HadithData>(
          future: loadBook(book),
          builder: (c, s) {
            if (s.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('تعذر تحميل الكتاب. تحقق من الإنترنت وحاول مرة أخرى.', textAlign: TextAlign.center)));
            }
            if (!s.hasData) {
              return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('جارٍ التحميل لأول مرة (يُحفظ للقراءة بدون إنترنت)')]));
            }
            final d = s.data!;
            final secs = <String>[];
            for (final h in d.items) {
              if (secs.isEmpty || secs.last != h.section) secs.add(h.section);
            }
            return ListView(children: [
              Padding(padding: const EdgeInsets.all(12), child: Text(book.note)),
              for (final sec in secs)
                ListTile(
                  title: Text(sec.isEmpty ? 'الكتاب' : sec, textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                  subtitle: Text('${ar(d.items.where((h) => h.section == sec).length)} حديث'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HadithListScreen(book: book, data: d, section: sec))),
                ),
            ]);
          },
        ),
      );
}

class HadithListScreen extends StatelessWidget {
  final HadithBook book;
  final HadithData data;
  final String section;
  const HadithListScreen({super.key, required this.book, required this.data, required this.section});
  @override
  Widget build(BuildContext context) {
    final items = data.items.where((h) => h.section == section).toList();
    return Scaffold(
      appBar: AppBar(title: Text(section.isEmpty ? book.name : section, textDirection: TextDirection.ltr)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (c, i) => HadithTile(book: book, h: items[i]),
      ),
    );
  }
}

class HadithTile extends StatelessWidget {
  final HadithBook book;
  final Hadith h;
  const HadithTile({super.key, required this.book, required this.h});
  @override
  Widget build(BuildContext context) {
    final key = 'h:${book.id}:${h.number}';
    return ListenableBuilder(
      listenable: Store.i,
      builder: (c, _) {
        final fav = Store.i.favDhikr.contains(key);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.text, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 2.1)),
              const SizedBox(height: 8),
              Text('${book.name} - حديث رقم ${ar(h.number)}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
              if (h.section.isNotEmpty) Text('الباب: ${h.section}', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              if (h.grades.isEmpty)
                Text(book.id == 'bukhari' || book.id == 'muslim' ? 'الدرجة: من الصحيحين' : 'الدرجة: غير متوفرة في المصدر', style: Theme.of(context).textTheme.bodySmall)
              else
                for (final g in h.grades) Text('الدرجة: ${g.$2} (${g.$1})', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.bodySmall),
              Row(children: [
                IconButton(icon: Icon(fav ? Icons.favorite : Icons.favorite_border), onPressed: () => Store.i.toggleFavDhikr(key)),
                IconButton(icon: const Icon(Icons.copy), onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${h.text}\n\n${book.name} - حديث رقم ${h.number}'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
                }),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class HadithFavorites extends StatelessWidget {
  const HadithFavorites({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الأحاديث المفضلة')),
        body: FutureBuilder<List<(HadithBook, Hadith)>>(
          future: () async {
            final out = <(HadithBook, Hadith)>[];
            for (final k in Store.i.favDhikr.where((k) => k.startsWith('h:'))) {
              final p = k.split(':');
              final b = hadithBooks.firstWhere((b) => b.id == p[1]);
              try {
                final d = await loadBook(b);
                out.add((b, d.items.firstWhere((h) => h.number.toString() == p[2])));
              } catch (_) {}
            }
            return out;
          }(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (s.data!.isEmpty) return const Center(child: Text('لا أحاديث مفضلة بعد.'));
            return ListView(children: [for (final r in s.data!) HadithTile(book: r.$1, h: r.$2)]);
          },
        ),
      );
}
