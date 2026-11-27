import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_life/data/quran.dart';
import 'package:islamic_life/data/prayer.dart';
import 'package:islamic_life/screens/adhkar_screens.dart';
import 'package:islamic_life/screens/names_screen.dart';
import 'package:islamic_life/data/hadith.dart';
import 'package:islamic_life/data/lessons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('quran integrity', () async {
    await QuranData.load();
    final d = QuranData.i;
    expect(d.surahs.length, 114);
    expect(d.surahs.fold<int>(0, (a, s) => a + s.ayahCount), 6236);
    expect(d.surahs[0].ayahCount, 7);
    expect(d.surahs[1].ayahCount, 286);
    // bismillah stripped from first ayah of surah 2, kept as ayah of Fatiha
    expect(QuranData.normalize(d.surahs[1].ayahs[0].text), 'الم');
    expect(d.surahs[0].ayahs[0].text.contains('بِسْمِ'), true);
    expect(d.tafsir[2]![255]!.isNotEmpty, true);
    expect(d.translation[112]![1]!.isNotEmpty, true);
    expect(d.surahs.last.ayahs.last.juz, 30);
    expect(d.search('الله الصمد').any((a) => a.surah == 112), true);
    expect(d.surahs.expand((s) => s.ayahs).where((a) => a.sajda).length, 15);
  });
  test('qibla', () {
    // Cairo ~136 deg; Alexandria ~ 135 deg
    final b = qiblaBearing(30.0444, 31.2357);
    expect(b, closeTo(136, 2));
    expect(distanceToKaabaKm(30.0444, 31.2357), closeTo(1287, 20));
  });
  test('adhkar', () async {
    final c = await loadAdhkar();
    expect(c.length > 20, true);
    expect(c.first.items.isNotEmpty, true);
  });
  test('names, hadith, lessons', () async {
    final n = await loadNames();
    expect(n.length, 99);
    expect(n[0].refs.isNotEmpty, true);
    final h = await loadBook(hadithBooks.firstWhere((b) => b.id == 'nawawi'));
    expect(h.items.length, 42);
    expect(h.items.first.text.contains('الْأَعْمَالُ بِالنِّيَّاتِ') || h.items.first.text.contains('بِالنِّيَّاتِ'), true);
    for (final l in lessons) {
      for (final q in l.quiz) {
        expect(q.answer >= 0 && q.answer < q.options.length, true);
      }
    }
  });
}
