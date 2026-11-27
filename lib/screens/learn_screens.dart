import 'package:flutter/material.dart';
import '../data/lessons.dart';
import '../data/prayer.dart' show ar;
import '../data/store.dart';
import '../theme.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('التعلم الإسلامي')),
        body: ListenableBuilder(
          listenable: Store.i,
          builder: (c, _) {
            final done = lessons.where((l) => Store.i.favDhikr.contains('l:${l.id}')).length;
            return ListView(padding: const EdgeInsets.all(12), children: [
              Text('أنجزت ${ar(done)} من ${ar(lessons.length)} دروس'),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: done / lessons.length, minHeight: 8),
              const SizedBox(height: 12),
              for (final l in lessons)
                Card(
                  child: ListTile(
                    leading: Icon(Store.i.favDhikr.contains('l:${l.id}') ? Icons.check_circle : Icons.school, color: emerald),
                    title: Text(l.title),
                    subtitle: Text('المستوى: ${l.level}'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(l: l))),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('الدروس مكتوبة من مراجع معروفة مذكورة في كل درس، ولم تُراجَع بعد من عالم شرعي.', style: Theme.of(context).textTheme.bodySmall),
              ),
            ]);
          },
        ),
      );
}

class LessonScreen extends StatelessWidget {
  final Lesson l;
  const LessonScreen({super.key, required this.l});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(l.title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final p in l.body)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(p, style: const TextStyle(fontSize: 18, height: 1.9))),
          Text('المصدر: ${l.source}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.quiz),
            label: const Text('ابدأ الاختبار'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(l: l))),
          ),
        ]),
      );
}

class QuizScreen extends StatefulWidget {
  final Lesson l;
  const QuizScreen({super.key, required this.l});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _i = 0, _score = 0;
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final qs = widget.l.quiz;
    if (_i >= qs.length) {
      final pass = _score >= (qs.length * 0.6).ceil();
      if (pass && !Store.i.favDhikr.contains('l:${widget.l.id}')) Store.i.toggleFavDhikr('l:${widget.l.id}');
      return Scaffold(
        appBar: AppBar(title: const Text('النتيجة')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(pass ? Icons.emoji_events : Icons.refresh, size: 64, color: gold),
            Text('${ar(_score)} من ${ar(qs.length)}', style: const TextStyle(fontSize: 28)),
            Text(pass ? 'أحسنت! أنجزت الدرس' : 'راجع الدرس وحاول مرة أخرى'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
          ]),
        ),
      );
    }
    final q = qs[_i];
    return Scaffold(
      appBar: AppBar(title: Text('سؤال ${ar(_i + 1)} من ${ar(qs.length)}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(q.q, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (var k = 0; k < q.options.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _picked == null ? null : (k == q.answer ? Colors.green.withValues(alpha: 0.2) : (k == _picked ? Colors.red.withValues(alpha: 0.2) : null)),
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: _picked != null ? null : () => setState(() { _picked = k; if (k == q.answer) _score++; }),
                child: Text(q.options[k], style: const TextStyle(fontSize: 18)),
              ),
            ),
          const Spacer(),
          if (_picked != null)
            FilledButton(onPressed: () => setState(() { _i++; _picked = null; }), child: Text(_i == qs.length - 1 ? 'إنهاء' : 'التالي')),
        ]),
      ),
    );
  }
}
