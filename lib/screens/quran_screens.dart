import 'package:flutter/gestures.dart';
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
        // Juz grouped: one expandable card per juz listing its surah parts.
        final parts = <int, List<Ayah>>{};
        for (final sr in d.surahs) {
          int? lastJ;
          for (final a in sr.ayahs) {
            if (a.juz != lastJ) {
              (parts[a.juz] ??= []).add(a);
              lastJ = a.juz;
            }
          }
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: 30,
          itemBuilder: (c, i) {
            final j = i + 1;
            final ps = parts[j] ?? [];
            return Card(
              child: ExpansionTile(
                leading: CircleAvatar(child: Text(ar(j))),
                title: Text('الجزء ${ar(j)}'),
                subtitle: ps.isEmpty ? null : Text('يبدأ من ${d.surahs[ps.first.surah - 1].name} آية ${ar(ps.first.inSurah)}'),
                children: [
                  for (final a in ps)
                    ListTile(
                      dense: true,
                      title: Text('${d.surahs[a.surah - 1].name} - من آية ${ar(a.inSurah)}'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => open(context, a.surah, a.inSurah),
                    ),
                ],
              ),
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

/// Mushaf-style reader: the surah flows as continuous text (in blocks of
/// [_blk] ayahs so playback can scroll). Controls sit at the TOP.
class _SurahReaderState extends State<SurahReader> {
  static const _blk = 6;
  final _player = AudioPlayer();
  String _reciter = 'Alafasy_128kbps';
  double _speed = 1.0;
  int _repeat = 1;
  int _playing = 0;
  int _selected = 0;
  bool _showTranslation = false;
  bool _stop = false;
  late final Surah s = QuranData.i.surahs[widget.surah - 1];
  late final int _blocks = (s.ayahCount + _blk - 1) ~/ _blk;
  final _keys = <int, GlobalKey>{};
  final _taps = <int, TapGestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    _selected = widget.startAyah;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startAyah > 1) _reveal(widget.startAyah, animate: false);
    });
  }

  @override
  void dispose() {
    _stop = true;
    for (final t in _taps.values) {
      t.dispose();
    }
    _player.dispose();
    super.dispose();
  }

  void _reveal(int ayah, {bool animate = true}) {
    final k = _keys[(ayah - 1) ~/ _blk];
    if (k?.currentContext != null) {
      Scrollable.ensureVisible(k!.currentContext!,
          duration: Duration(milliseconds: animate ? 350 : 1), alignment: 0.1);
    }
  }

  String _url(int ayah) =>
      'https://everyayah.com/data/$_reciter/${s.number.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

  Future<void> _playFrom(int ayah) async {
    _stop = false;
    for (var a = ayah; a <= s.ayahCount && !_stop; a++) {
      for (var r = 0; r < _repeat && !_stop; r++) {
        if (!mounted) return;
        setState(() { _playing = a; _selected = a; });
        Store.i.setLastRead(s.number, a);
        _reveal(a);
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

  Future<void> _skip(int d) async {
    final n = ((_playing == 0 ? _selected : _playing) + d).clamp(1, s.ayahCount);
    await _halt();
    await Future.delayed(const Duration(milliseconds: 80));
    _playFrom(n);
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

  void _ayahMenu(Ayah a) {
    setState(() => _selected = a.inSurah);
    Store.i.setLastRead(s.number, a.inSurah);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(12),
              child: Text('${s.name} - آية ${ar(a.inSurah)}', style: const TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.play_arrow), title: const Text('تشغيل من هذه الآية'),
              onTap: () { Navigator.pop(context); _halt().then((_) => _playFrom(a.inSurah)); }),
          ListTile(
              leading: Icon(Store.i.isBookmarked(s.number, a.inSurah) ? Icons.bookmark : Icons.bookmark_border),
              title: const Text('علامة'),
              onTap: () { Store.i.toggleBookmark(s.number, a.inSurah); Navigator.pop(context); }),
          ListTile(
              leading: Icon(Store.i.memorized.contains('${s.number}:${a.inSurah}') ? Icons.check_circle : Icons.check_circle_outline),
              title: const Text('حفظتها'),
              onTap: () {
                final k = '${s.number}:${a.inSurah}';
                Store.i.setMemorized(s.number, a.inSurah, !Store.i.memorized.contains(k));
                Navigator.pop(context);
              }),
          ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('التفسير والترجمة'),
              onTap: () { Navigator.pop(context); _details(a); }),
        ]),
      ),
    );
  }

  Widget _controls() {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.skip_next), tooltip: 'السابقة', onPressed: () => _skip(-1)),
            IconButton.filled(
              iconSize: 30,
              icon: Icon(_playing == 0 ? Icons.play_arrow : Icons.stop),
              onPressed: () => _playing == 0 ? _playFrom(_selected) : _halt(),
            ),
            IconButton(icon: const Icon(Icons.skip_previous), tooltip: 'التالية', onPressed: () => _skip(1)),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _reciter,
                  items: [for (final e in reciters.entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) {
                    setState(() => _reciter = v!);
                    if (_playing != 0) { final n = _playing; _halt().then((_) => _playFrom(n)); }
                  },
                ),
              ),
            ),
          ]),
          Row(children: [
            Text(_playing == 0 ? 'آية ${ar(_selected)}' : 'تُتلى الآن: آية ${ar(_playing)}',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
            const Spacer(),
            ActionChip(
              label: Text('×$_speed'),
              avatar: const Icon(Icons.speed, size: 16),
              onPressed: () {
                const v = [0.75, 1.0, 1.25, 1.5];
                setState(() => _speed = v[(v.indexOf(_speed) + 1) % v.length]);
                _player.setSpeed(_speed);
              },
            ),
            const SizedBox(width: 6),
            ActionChip(
              label: Text('تكرار ${ar(_repeat)}'),
              avatar: const Icon(Icons.repeat, size: 16),
              onPressed: () => setState(() => _repeat = _repeat % 5 + 1),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _block(int bi, Store store) {
    final from = bi * _blk, to = (from + _blk).clamp(0, s.ayahCount);
    final fs = store.quranFont;
    final spans = <InlineSpan>[];
    for (final a in s.ayahs.sublist(from, to)) {
      final active = _playing == a.inSurah;
      final sel = _selected == a.inSurah && _playing == 0;
      final mem = store.memorized.contains('${s.number}:${a.inSurah}');
      final bm = store.isBookmarked(s.number, a.inSurah);
      final rec = _taps.putIfAbsent(a.inSurah, () => TapGestureRecognizer());
      rec.onTap = () => _ayahMenu(a);
      final bg = active
          ? gold.withOpacity(0.38)
          : sel ? gold.withOpacity(0.12) : null;
      spans.add(TextSpan(
        text: '${a.text} ',
        recognizer: rec,
        style: TextStyle(
            fontFamily: 'AmiriQuran', fontSize: fs, height: 2.3,
            backgroundColor: bg,
            color: mem ? Theme.of(context).colorScheme.primary : null),
      ));
      spans.add(TextSpan(
        text: '\u06DD${ar(a.inSurah)}${a.sajda ? ' ۩' : ''} ',
        recognizer: rec,
        style: TextStyle(fontFamily: 'AmiriQuran', fontSize: fs, color: gold, height: 2.3, backgroundColor: bg),
      ));
    }
    return Column(key: _keys.putIfAbsent(bi, () => GlobalKey()), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        child: Text.rich(TextSpan(children: spans), textAlign: TextAlign.justify),
      ),
      if (_showTranslation)
        for (final a in s.ayahs.sublist(from, to))
          Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${a.inSurah}. ${QuranData.i.translation[s.number]![a.inSurah] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          ),
      const SizedBox(height: 6),
    ]);
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
          IconButton(icon: const Icon(Icons.text_fields), tooltip: 'حجم الخط', onPressed: _settings),
        ],
      ),
      body: Column(children: [
        _controls(),
        Expanded(
          child: ListenableBuilder(
            listenable: store,
            builder: (c, _) => ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              children: [
                if (s.number != 1 && s.number != 9)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                        textAlign: TextAlign.center, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 28)),
                  ),
                for (var i = 0; i < _blocks; i++) _block(i, store),
                const Padding(padding: EdgeInsets.all(8),
                    child: Text('اضغط على أي آية للتشغيل أو العلامة أو التفسير.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ),
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

