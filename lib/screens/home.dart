import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../data/prayer.dart';
import '../data/quran.dart';
import '../data/store.dart';
import '../theme.dart';
import 'adhkar_screens.dart';
import 'prayer_screens.dart';
import 'quran_screens.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) goTo;
  const HomeScreen({super.key, required this.goTo});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerInfo? _info;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    loadPrayerInfo().then((i) => mounted ? setState(() => _info = i) : null);
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'نهارك مبارك';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    HijriCalendar.setLocal('ar');
    final h = HijriCalendar.now();
    final now = DateTime.now();
    final i = _info;
    final upcoming = _upcoming(h);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('السلام عليكم، $_greeting', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('${ar(h.hDay)} ${hijriMonths[h.hMonth - 1]} ${ar(h.hYear)} هـ  -  ${ar(now.day)}/${ar(now.month)}/${ar(now.year)} م',
              style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 14),
          _prayerCard(i),
          const SizedBox(height: 14),
          Row(children: [
            _quick(Icons.menu_book, 'القرآن', () => widget.goTo(1)),
            _quick(Icons.favorite, 'الأذكار', () => widget.goTo(3)),
            _quick(Icons.explore, 'القبلة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()))),
            _quick(Icons.calendar_month, 'التقويم', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen()))),
          ]),
          const SizedBox(height: 14),
          if (QuranData.loaded) ...[
            _continueReading(),
            _ayahOfDay(),
          ],
          FutureBuilder<List<Category>>(
            future: loadAdhkar(),
            builder: (c, s) {
              if (!s.hasData) return const SizedBox();
              final cats = s.data!.skip(1).toList();
              final day = now.difference(DateTime(now.year)).inDays;
              final cat = cats[day % cats.length];
              final d = cat.items.first;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ذكر اليوم - ${cat.title}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(d.text, style: const TextStyle(fontSize: 18, height: 1.9), maxLines: 6, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text('المصدر: ${d.source}', style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              );
            },
          ),
          if (upcoming != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.event, color: gold),
                title: Text('المناسبة القادمة: ${upcoming.$1}'),
                subtitle: Text('بعد ${ar(upcoming.$2)} يوم تقريبًا'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen())),
              ),
            ),
        ]),
      ),
    );
  }

  (String, int)? _upcoming(HijriCalendar h) {
    (String, int)? best;
    final cal = HijriCalendar();
    for (final e in occasions.entries) {
      var y = h.hYear;
      if (e.key.$1 < h.hMonth || (e.key.$1 == h.hMonth && e.key.$2 < h.hDay)) y++;
      final g = cal.hijriToGregorian(y, e.key.$1, e.key.$2);
      final days = g.difference(DateTime.now()).inDays + 1;
      if (days >= 0 && (best == null || days < best.$2)) best = (e.value.split(' (').first, days);
    }
    return best;
  }

  Widget _prayerCard(PrayerInfo? i) {
    if (i == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.location_off),
          title: const Text('مواقيت الصلاة'),
          subtitle: const Text('اختر مدينتك أو اسمح بالموقع'),
          onTap: () => widget.goTo(2),
        ),
      );
    }
    final n = i.next;
    final nt = i.nextTime ?? i.times.fajr;
    return InkWell(
      onTap: () => widget.goTo(2),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [emerald, navy], begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(children: [
          Text('${prayerNames[n] ?? 'الفجر'} بعد', style: const TextStyle(color: Colors.white70)),
          Text(countdown(nt.difference(DateTime.now())), style: const TextStyle(color: gold, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha])
              Column(children: [
                Text(prayerNames[p]!, style: TextStyle(color: p == n ? gold : Colors.white70, fontSize: 12)),
                Text(hm(i.times.timeForPrayer(p)!), style: TextStyle(color: p == n ? Colors.white : Colors.white70, fontSize: 12, fontWeight: p == n ? FontWeight.bold : null)),
              ]),
          ]),
        ]),
      ),
    );
  }

  Widget _quick(IconData ic, String label, VoidCallback f) => Expanded(
        child: InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: [
              CircleAvatar(radius: 26, backgroundColor: emerald.withOpacity(0.12), child: Icon(ic, color: emerald)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _continueReading() {
    final l = Store.i.lastRead;
    final s = QuranData.i.surahs[l[0] - 1];
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bookmark_added, color: emerald),
        title: const Text('متابعة قراءة القرآن'),
        subtitle: Text('${s.name} - آية ${ar(l[1])}'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReader(surah: l[0], startAyah: l[1]))),
      ),
    );
  }

  Widget _ayahOfDay() {
    final d = QuranData.i;
    final now = DateTime.now();
    // Deterministic pick per calendar day over the whole Quran.
    final idx = ((now.year * 366 + now.difference(DateTime(now.year)).inDays) * 2654435761) % 6236;
    var k = idx.toInt();
    late Surah s;
    late Ayah a;
    for (final x in d.surahs) {
      if (k < x.ayahCount) { s = x; a = x.ayahs[k]; break; }
      k -= x.ayahCount;
    }
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReader(surah: s.number, startAyah: a.inSurah))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('آية اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(a.text, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, height: 2.2)),
            Text('${s.name} - آية ${ar(a.inSurah)}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}
