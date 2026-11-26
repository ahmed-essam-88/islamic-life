import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:hijri/hijri_calendar.dart';
import '../data/prayer.dart';
import '../data/store.dart';
import '../theme.dart';

/// Shared view-model: place + today's times + next prayer.
class PrayerInfo {
  final Place place;
  final PrayerTimes times;
  PrayerInfo(this.place, this.times);
  Prayer get next => times.nextPrayer();
  DateTime? get nextTime => times.timeForPrayer(next);
}

Future<PrayerInfo?> loadPrayerInfo() async {
  final p = await resolvePlace();
  if (p == null) return null;
  final now = DateTime.now();
  var t = timesFor(p, now);
  if (t.nextPrayer() == Prayer.none) {
    t = timesFor(p, now.add(const Duration(days: 1)));
  }
  return PrayerInfo(p, t);
}

String countdown(Duration d) {
  if (d.isNegative) return '٠٠:٠٠:٠٠';
  String two(int n) => ar(n.toString().padLeft(2, '0'));
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  PrayerInfo? _info;
  bool _loading = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _load();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
    Store.i.addListener(_load);
  }

  @override
  void dispose() {
    _t?.cancel();
    Store.i.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final i = await loadPrayerInfo();
    if (mounted) setState(() { _info = i; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final i = _info;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(icon: const Icon(Icons.explore), tooltip: 'القبلة',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()))),
          IconButton(icon: const Icon(Icons.tune), onPressed: _settings),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : i == null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_off, size: 48),
                    const SizedBox(height: 12),
                    const Text('تعذر تحديد موقعك. اسمح بالوصول للموقع أو اختر مدينتك يدويًا.', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _settings, child: const Text('اختيار المدينة')),
                  ]),
                ))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  _hero(i),
                  const SizedBox(height: 12),
                  for (final p in [Prayer.fajr, Prayer.sunrise, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha])
                    _row(i, p),
                  const SizedBox(height: 8),
                  Text('طريقة الحساب: ${methods[Store.i.calcMethod]} - العصر: ${Store.i.hanafi ? 'حنفي' : 'جمهور'}',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('الحساب محلي على جهازك (مكتبة adhan) ولا يحتاج إنترنت.',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
    );
  }

  Widget _hero(PrayerInfo i) {
    final n = i.next;
    final nt = i.nextTime ?? i.times.fajr;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [emerald, navy], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        Text(i.place.name, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text('الصلاة القادمة: ${prayerNames[n] ?? 'الفجر'}', style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 6),
        Text(countdown(nt.difference(DateTime.now())),
            style: const TextStyle(color: gold, fontSize: 44, fontWeight: FontWeight.bold)),
        Text(hm(nt), style: const TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _row(PrayerInfo i, Prayer p) {
    final t = i.times.timeForPrayer(p)!;
    final isNext = i.next == p;
    return Card(
      color: isNext ? emerald.withOpacity(0.12) : null,
      child: ListTile(
        title: Text(prayerNames[p]!, style: TextStyle(fontSize: 18, fontWeight: isNext ? FontWeight.bold : null)),
        trailing: Text(hm(t), style: const TextStyle(fontSize: 18)),
        leading: Icon(isNext ? Icons.notifications_active : Icons.access_time, color: isNext ? emerald : null),
      ),
    );
  }

  void _settings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (c, setS) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('طريقة الحساب'),
            DropdownButton<String>(
              isExpanded: true,
              value: Store.i.calcMethod,
              items: [for (final e in methods.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) { Store.i.calcMethod = v!; setS(() {}); },
            ),
            SwitchListTile(
              title: const Text('العصر بالمذهب الحنفي'),
              value: Store.i.hanafi,
              onChanged: (v) { Store.i.hanafi = v; setS(() {}); },
            ),
            const Text('المدينة'),
            DropdownButton<int>(
              isExpanded: true,
              value: () {
                final c = Store.i.city;
                if (c == null) return -1;
                return cities.indexWhere((x) => x.name == c['name']);
              }(),
              items: [
                const DropdownMenuItem(value: -1, child: Text('موقعي الحالي (GPS)')),
                for (var k = 0; k < cities.length; k++) DropdownMenuItem(value: k, child: Text(cities[k].name)),
              ],
              onChanged: (v) {
                Store.i.setCity(v == null || v < 0 ? null : {'name': cities[v].name, 'lat': cities[v].lat, 'lon': cities[v].lon});
                setS(() {});
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  Place? _place;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    resolvePlace().then((p) => mounted ? setState(() { _place = p; _loading = false; }) : null);
  }

  @override
  Widget build(BuildContext context) {
    final p = _place;
    return Scaffold(
      appBar: AppBar(title: const Text('اتجاه القبلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('نحتاج موقعك لحساب القبلة. اسمح بالموقع أو اختر مدينة من شاشة الصلاة.', textAlign: TextAlign.center)))
              : _compass(p),
    );
  }

  Widget _compass(Place p) {
    final bearing = qiblaBearing(p.lat, p.lon);
    final km = distanceToKaabaKm(p.lat, p.lon);
    return Column(children: [
      const SizedBox(height: 16),
      Text(p.name),
      Text('المسافة التقريبية إلى الكعبة: ${ar(km.round())} كم'),
      Text('زاوية القبلة من الشمال: ${ar(bearing.round())}°'),
      Expanded(
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (c, snap) {
            final heading = snap.data?.heading;
            final noSensor = heading == null;
            final angle = ((bearing - (heading ?? 0)) * math.pi / 180);
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 280, height: 280,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold, width: 3)),
                    ),
                    Transform.rotate(
                      angle: angle,
                      child: const Column(children: [
                        Icon(Icons.navigation, size: 90, color: emerald),
                        Text('🕋', style: TextStyle(fontSize: 28)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                if (noSensor)
                  const Padding(padding: EdgeInsets.all(16), child: Text('لا يوجد حساس بوصلة متاح هنا. السهم يشير للقبلة بالنسبة للشمال (الأعلى = الشمال). على الهاتف سيدور السهم مع حركتك.', textAlign: TextAlign.center))
                else
                  const Text('وجّه أعلى الهاتف حتى يشير السهم للأعلى'),
              ]),
            );
          },
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('لمعايرة البوصلة: حرّك هاتفك على شكل رقم ٨ في الهواء، وابتعد عن المعادن والمغناطيس.', textAlign: TextAlign.center),
      ),
    ]);
  }
}

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});
  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

const hijriMonths = ['مُحرَّم', 'صَفَر', 'رَبيع الأول', 'رَبيع الآخر', 'جُمادى الأولى', 'جُمادى الآخرة', 'رَجَب', 'شَعبان', 'رَمَضان', 'شَوَّال', 'ذو القَعدة', 'ذو الحِجّة'];
const sacred = {1, 7, 11, 12};

/// Fixed-date occasions on the Hijri calendar (month, day) -> name.
const occasions = <(int, int), String>{
  (1, 1): 'رأس السنة الهجرية',
  (1, 10): 'يوم عاشوراء',
  (3, 12): 'المولد النبوي (على قول الجمهور)',
  (7, 27): 'الإسراء والمعراج (على المشهور)',
  (8, 15): 'ليلة النصف من شعبان (لم يثبت في تخصيصها دليل صحيح)',
  (9, 1): 'بداية شهر رمضان',
  (9, 27): 'ليلة القدر (يُرجى في الوتر من العشر الأواخر)',
  (10, 1): 'عيد الفطر',
  (12, 9): 'يوم عرفة',
  (12, 10): 'عيد الأضحى',
};

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late HijriCalendar _cur;
  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('ar');
    _cur = HijriCalendar.now();
  }

  void _shift(int d) {
    var m = _cur.hMonth + d, y = _cur.hYear;
    if (m > 12) { m = 1; y++; }
    if (m < 1) { m = 12; y--; }
    setState(() => _cur = HijriCalendar()..hYear = y..hMonth = m..hDay = 1);
  }

  @override
  Widget build(BuildContext context) {
    final first = HijriCalendar()..hYear = _cur.hYear..hMonth = _cur.hMonth..hDay = 1;
    final startG = first.hijriToGregorian(first.hYear, first.hMonth, 1);
    final len = first.getDaysInMonth(first.hYear, first.hMonth);
    final lead = startG.weekday % 7; // Sunday = 0
    final today = HijriCalendar.now();
    const wd = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الهجري')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shift(-1)),
          Column(children: [
            Text('${hijriMonths[_cur.hMonth - 1]} ${ar(_cur.hYear)} هـ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (sacred.contains(_cur.hMonth)) const Text('من الأشهر الحرم', style: TextStyle(color: gold)),
          ]),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shift(1)),
        ]),
        Row(children: [for (final w in wd) Expanded(child: Center(child: Text(w, style: const TextStyle(color: gold, fontWeight: FontWeight.bold))))]),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var k = 0; k < lead; k++) const SizedBox(),
            for (var d = 1; d <= len; d++) () {
              final g = startG.add(Duration(days: d - 1));
              final isToday = today.hYear == _cur.hYear && today.hMonth == _cur.hMonth && today.hDay == d;
              final occ = occasions[(_cur.hMonth, d)];
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? emerald : (occ != null ? gold.withOpacity(0.2) : null),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(ar(d), style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? Colors.white : null)),
                  Text(ar(g.day), style: TextStyle(fontSize: 10, color: isToday ? Colors.white70 : Colors.grey)),
                ]),
              );
            }(),
          ],
        ),
        const Divider(height: 24),
        const Text('مناسبات هذا الشهر', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final e in occasions.entries.where((e) => e.key.$1 == _cur.hMonth))
          ListTile(leading: const Icon(Icons.star, color: gold), title: Text(e.value), subtitle: Text('${ar(e.key.$2)} ${hijriMonths[e.key.$1 - 1]}')),
        if (!occasions.keys.any((k) => k.$1 == _cur.hMonth))
          const Padding(padding: EdgeInsets.all(8), child: Text('لا مناسبات ثابتة في هذا الشهر. الصيام المستحب: الاثنين والخميس والأيام البيض (١٣ و١٤ و١٥).')),
        const SizedBox(height: 8),
        Text('التاريخ الهجري محسوب بالتقويم الرياضي (أم القرى)، وقد يختلف يومًا عن الرؤية الفعلية. تُراجَع المناسبات المختلف فيها مع دار الإفتاء.',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
