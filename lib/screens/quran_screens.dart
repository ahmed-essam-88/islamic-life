import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/store.dart';
import '../data/prayer.dart' show ar;

class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({super.key});
  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> {
  final _q = TextEditingController();
  int _mode = 0; // 0 surahs, 1 juz, 2 bookmarks, 3 memorization

  @override
  Widget build(BuildContext context) {
    if (!QuranData.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final d = QuranData.i;
    final query = _q.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث عن آية أو كلمة',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (query.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('السور')),
                ButtonSegment(value: 1, label: Text('الأجزاء')),
                ButtonSegment(value: 2, label: Text('العلامات')),
                ButtonSegment(value: 3, label: Text('الحفظ')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
        Expanded(child: query.isNotEmpty ? _search(d, query) : _body(d)),
      ]),
    );
  }

  Widget _search(QuranData d, String q) {
    final res = d.search(q);
    if (res.isEmpty) return const Center(child: Text('لا توجد نتائج'));
    return ListView.builder(
      itemCount: res.length,
      itemBuilder: (c, i) {
        final a = res[i];
        final s = d.surahs[a.surah - 1];
        return ListTile(
          title: Text(a.text,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 2)),
          subtitle: Text('سورة ${s.name.replaceFirst('سُورَةُ ', '')} - آية ${ar(a.inSurah)}'),
          onTap: () => open(context, a.surah, a.inSurah),
        );
      },
    );
  }

  Widget _body(QuranData d) {
    switch (_mode) {
      case 1:
        return ListView.builder(
          itemCount: 30,
          itemBuilder: (c, i) {
            final j = i + 1;
            Ayah? first;
            for (final s in d.surahs) {
              for (final a in s.ayahs) {
                if (a.juz == j) { first = a; break; }
              }
              if (first != null) break;
            }
            final f = first!;
            return ListTile(
              leading: CircleAvatar(child: Text(ar(j))),
              title: Text('الجزء ${ar(j)}'),
              subtitle: Text('يبدأ من ${d.surahs[f.surah - 1].name} آية ${ar(f.inSurah)}'),
              onTap: () => open(context, f.surah, f.inSurah),
            );
          },
        );
      case 2:
        final bm = Store.i.bookmarks.toList()..sort((a, b) {
            final x = a.split(':').map(int.parse).toList();
            final y = b.split(':').map(int.parse).toList();
            return x[0] != y[0] ? x[0] - y[0] : x[1] - y[1];
          });
        if (bm.isEmpty) {
          return const Center(child: Text('لا توجد علامات بعد. اضغط على أيقونة العلامة داخل أي آية.'));
        }
        return ListView(children: [
          for (final k in bm) _ayahTile(d, k),
        ]);
      case 3:
        final mem = Store.i.memorized;
        final total = 6236;
        final pct = mem.length / total;
        return ListView(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('محفوظ: ${ar(mem.length)} آية من ${ar(total)}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: pct, minHeight: 8),
              const SizedBox(height: 8),
              const Text('علّم الآيات التي حفظتها من داخل المصحف، ثم اختبر نفسك.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: mem.isEmpty ? null : () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MemorizationQuiz())),
                icon: const Icon(Icons.quiz),
                label: const Text('اختبر حفظك'),
              ),
            ]),
          ),
          for (final s in d.surahs)
            if (s.ayahs.any((a) => mem.contains('${s.number}:${a.inSurah}')))
              ListTile(
                title: Text(s.name),
                trailing: Text('${ar(s.ayahs.where((a) => mem.contains('${s.number}:${a.inSurah}')).length)} / ${ar(s.ayahCount)}'),
                onTap: () => open(context, s.number, 1),
              ),
        ]);
      default:
        final last = Store.i.lastRead;
        return ListView.builder(
          itemCount: d.surahs.length + 1,
          itemBuilder: (c, i) {
            if (i == 0) {
              return Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: ListTile(
                  leading: const Icon(Icons.bookmark_added),
                  title: const Text('متابعة القراءة'),
                  subtitle: Text('${d.surahs[last[0] - 1].name} - آية ${ar(last[1])}'),
                  onTap: () => open(context, last[0], last[1]),
                ),
              );
            }
            final s = d.surahs[i - 1];
            return ListTile(
              leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  child: Text(ar(s.number))),
              title: Text(s.name, style: const TextStyle(fontSize: 20)),
              subtitle: Text('${s.revelation == 'Meccan' ? 'مكية' : 'مدنية'} - ${ar(s.ayahCount)} آية'),
              onTap: () => open(context, s.number, 1),
            );
          },
        );
    }
  }

  Widget _ayahTile(QuranData d, String k) {
    final p = k.split(':').map(int.parse).toList();
    final s = d.surahs[p[0] - 1];
    final a = s.ayahs[p[1] - 1];
    return ListTile(
      title: Text(a.text, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 2)),
      subtitle: Text('${s.name} - آية ${ar(a.inSurah)}'),
      onTap: () => open(context, p[0], p[1]),
    );
  }

  void open(BuildContext c, int s, int a) => Navigator.push(
      c, MaterialPageRoute(builder: (_) => SurahReader(surah: s, startAyah: a)))
      .then((_) => setState(() {}));
}

const reciters = {
  'Alafasy_128kbps': 'مشاري العفاسي',
  'Abdul_Basit_Murattal_192kbps': 'عبد الباسط عبد الصمد (مرتل)',
  'Husary_128kbps': 'محمود خليل الحصري',
  'Minshawy_Murattal_128kbps': 'محمد صديق المنشاوي (مرتل)',
  'Abdurrahmaan_As-Sudais_192kbps': 'عبد الرحمن السديس',
  'Maher_AlMuaiqly_128kbps': 'ماهر المعيقلي',
  'Ghamadi_40kbps': 'سعد الغامدي',
};

class SurahReader extends StatefulWidget {
  final int surah, startAyah;
  const SurahReader({super.key, required this.surah, this.startAyah = 1});
  @override
  State<SurahReader> createState() => _SurahReaderState();
}

class _SurahReaderState extends State<SurahReader> {
  final _player = AudioPlayer();
  final _scroll = ScrollController();
  String _reciter = 'Alafasy_128kbps';
  double _speed = 1.0;
  int _repeat = 1; // times each ayah is repeated
  int _playing = 0; // ayah number in surah, 0 = none
  bool _showTranslation = false;
  bool _stop = false;
  late final Surah s = QuranData.i.surahs[widget.surah - 1];
  final _keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final k = _keys[widget.startAyah];
      if (k?.currentContext != null && widget.startAyah > 1) {
        Scrollable.ensureVisible(k!.currentContext!);
      }
    });
  }

  @override
  void dispose() {
    _stop = true;
    _player.dispose();
    super.dispose();
  }

  String _url(int ayah) =>
      'https://everyayah.com/data/$_reciter/${s.number.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

  Future<void> _playFrom(int ayah) async {
    _stop = false;
    for (var a = ayah; a <= s.ayahCount && !_stop; a++) {
      for (var r = 0; r < _repeat && !_stop; r++) {
        if (!mounted) return;
        setState(() => _playing = a);
        final k = _keys[a];
        if (k?.currentContext != null) {
          Scrollable.ensureVisible(k!.currentContext!,
              duration: const Duration(milliseconds: 300));
        }
        try {
          await _player.setUrl(_url(a));
          await _player.setSpeed(_speed);
          await _player.play();
          await _player.processingStateStream
              .firstWhere((st) => st == ProcessingState.completed || _stop);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('تعذر تشغيل الصوت. تأكد من الاتصال بالإنترنت.')));
          }
          _stop = true;
        }
      }
    }
    if (mounted) setState(() => _playing = 0);
  }

  Future<void> _halt() async {
    _stop = true;
    await _player.stop();
    if (mounted) setState(() => _playing = 0);
  }

  void _details(Ayah a) {
    final d = QuranData.i;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (c, sc) => ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
          Text(a.text, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 26, height: 2.2)),
          const Divider(),
          const Text('التفسير الميسر', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(d.tafsir[s.number]![a.inSurah] ?? '', style: const TextStyle(fontSize: 17, height: 1.9)),
          const SizedBox(height: 4),
          Text('المصدر: التفسير الميسر - مجمع الملك فهد لطباعة المصحف الشريف (عبر AlQuran Cloud)',
              style: Theme.of(context).textTheme.bodySmall),
          const Divider(),
          const Text('Translation (Saheeh International)', style: TextStyle(fontWeight: FontWeight.bold)),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(d.translation[s.number]![a.inSurah] ?? '', style: const TextStyle(fontSize: 16, height: 1.6)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Store.i;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          IconButton(
            tooltip: 'الترجمة',
            icon: Icon(_showTranslation ? Icons.translate : Icons.translate_outlined),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
          IconButton(icon: const Icon(Icons.tune), onPressed: _settings),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (c, _) => ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (s.number != 1 && s.number != 9)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 28)),
              ),
            for (final a in s.ayahs) _ayah(a, store),
          ],
        ),
      ),
      bottomSheet: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            IconButton(
              icon: Icon(_playing == 0 ? Icons.play_circle : Icons.stop_circle, size: 36),
              onPressed: () => _playing == 0 ? _playFrom(widget.startAyah) : _halt(),
            ),
            Expanded(child: Text(
                _playing == 0 ? reciters[_reciter]! : '${reciters[_reciter]} - آية ${ar(_playing)}',
                overflow: TextOverflow.ellipsis)),
            Text('×${_speed}  تكرار ${ar(_repeat)}'),
          ]),
        ),
      ),
    );
  }

  Widget _ayah(Ayah a, Store store) {
    final key = _keys.putIfAbsent(a.inSurah, () => GlobalKey());
    final bm = store.isBookmarked(s.number, a.inSurah);
    final mem = store.memorized.contains('${s.number}:${a.inSurah}');
    final active = _playing == a.inSurah;
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? gold.withOpacity(0.18) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () {
            store.setLastRead(s.number, a.inSurah);
            _details(a);
          },
          child: Text.rich(TextSpan(children: [
            TextSpan(text: a.text, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: store.quranFont, height: 2.2)),
            TextSpan(text: ' \u06DD${ar(a.inSurah)} ',
                style: TextStyle(fontFamily: 'AmiriQuran', fontSize: store.quranFont, color: gold)),
          ])),
        ),
        if (_showTranslation)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(QuranData.i.translation[s.number]![a.inSurah] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        Row(children: [
          if (a.sajda) const Padding(padding: EdgeInsets.only(left: 8), child: Text('۩ سجدة', style: TextStyle(color: gold))),
          const Spacer(),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.play_arrow), onPressed: () { store.setLastRead(s.number, a.inSurah); _playFrom(a.inSurah); }),
          IconButton(visualDensity: VisualDensity.compact, icon: Icon(bm ? Icons.bookmark : Icons.bookmark_border), onPressed: () => store.toggleBookmark(s.number, a.inSurah)),
          IconButton(visualDensity: VisualDensity.compact, icon: Icon(mem ? Icons.check_circle : Icons.check_circle_outline), tooltip: 'حفظتها', onPressed: () => store.setMemorized(s.number, a.inSurah, !mem)),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.menu_book_outlined), onPressed: () => _details(a)),
        ]),
        const Divider(height: 1),
      ]),
    );
  }

  void _settings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, setS) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('القارئ'),
            DropdownButton<String>(
              isExpanded: true,
              value: _reciter,
              items: [for (final e in reciters.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) { setState(() => _reciter = v!); setS(() {}); },
            ),
            Text('سرعة التلاوة: ×$_speed'),
            Slider(min: 0.5, max: 2.0, divisions: 6, value: _speed,
                onChanged: (v) { setState(() => _speed = v); setS(() {}); _player.setSpeed(v); }),
            Text('تكرار كل آية: ${ar(_repeat)} (للحفظ)'),
            Slider(min: 1, max: 10, divisions: 9, value: _repeat.toDouble(),
                onChanged: (v) { setState(() => _repeat = v.round()); setS(() {}); }),
            Text('حجم الخط: ${Store.i.quranFont.round()}'),
            Slider(min: 18, max: 42, value: Store.i.quranFont,
                onChanged: (v) { Store.i.quranFont = v; setS(() {}); }),
          ]),
        ),
      ),
    );
  }
}

class MemorizationQuiz extends StatefulWidget {
  const MemorizationQuiz({super.key});
  @override
  State<MemorizationQuiz> createState() => _MemorizationQuizState();
}

class _MemorizationQuizState extends State<MemorizationQuiz> {
  late List<String> _pool;
  int _score = 0, _asked = 0;
  String? _key;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _pool = Store.i.memorized.toList()..shuffle();
    _next();
  }

  void _next() {
    if (_pool.isEmpty) { _key = null; return; }
    _key = _pool.removeLast();
    _revealed = false;
  }

  @override
  Widget build(BuildContext context) {
    final d = QuranData.i;
    if (_key == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('اختبار الحفظ')),
        body: Center(child: Text('انتهى الاختبار: ${ar(_score)} من ${ar(_asked)}')),
      );
    }
    final p = _key!.split(':').map(int.parse).toList();
    final s = d.surahs[p[0] - 1];
    final a = s.ayahs[p[1] - 1];
    final nextA = p[1] < s.ayahCount ? s.ayahs[p[1]] : null;
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار الحفظ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text('سورة ${s.name}، آية ${ar(a.inSurah)}'),
          const SizedBox(height: 12),
          const Text('أكمل الآية من حفظك ثم اكشف الإجابة:'),
          const SizedBox(height: 12),
          Text(a.text.split(' ').take((a.text.split(' ').length / 2).ceil()).join(' ') + ' ...',
              style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 28, height: 2.2), textAlign: TextAlign.center),
          if (_revealed) Text(a.text, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 26, height: 2.2, color: emeraldColor), textAlign: TextAlign.center),
          const Spacer(),
          if (!_revealed)
            FilledButton(onPressed: () => setState(() => _revealed = true), child: const Text('اكشف الإجابة'))
          else
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() { _asked++; _next(); }), child: const Text('أخطأت'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => setState(() { _asked++; _score++; _next(); }), child: const Text('أصبت'))),
            ]),
          if (nextA == null) const SizedBox.shrink(),
        ]),
      ),
    );
  }
}

