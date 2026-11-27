import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../data/prayer.dart';
import '../data/store.dart';
import '../theme.dart';

class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});
  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  Place? _place;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    resolvePlace().then((p) => mounted ? setState(() { _place = p; _loading = false; }) : null);
  }

  @override
  Widget build(BuildContext context) {
    final h = HijriCalendar.now();
    final cal = HijriCalendar();
    var y = h.hYear;
    var start = cal.hijriToGregorian(y, 9, 1);
    final len = cal.getDaysInMonth(y, 9);
    final inRamadan = h.hMonth == 9;
    if (!inRamadan && DateTime.now().isAfter(start.add(Duration(days: len)))) {
      y++;
      start = cal.hijriToGregorian(y, 9, 1);
    }
    final daysLeft = start.difference(DateTime.now()).inDays + 1;
    return Scaffold(
      appBar: AppBar(title: const Text('رمضان والمواسم')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [emerald, navy]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Text(inRamadan ? 'نحن في شهر رمضان ${ar(h.hYear)} هـ' : 'رمضان ${ar(y)} هـ', style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 6),
            Text(inRamadan ? 'اليوم ${ar(h.hDay)} من رمضان' : '${ar(daysLeft)} يوم تقريبًا', style: const TextStyle(color: gold, fontSize: 34, fontWeight: FontWeight.bold)),
            if (!inRamadan) Text('يبدأ تقريبًا ${ar(start.day)}/${ar(start.month)}/${ar(start.year)} م (حسب التقويم الرياضي)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('إمساكية رمضان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (_loading) const Center(child: CircularProgressIndicator())
        else if (_place == null) const Text('اختر مدينتك من شاشة الصلاة لعرض الإمساكية.')
        else ...[
          Text('${_place!.name} - الإمساك عند الفجر والإفطار عند المغرب. التواريخ الميلادية تقديرية حتى تثبت الرؤية.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: gold.withValues(alpha: 0.3)),
            children: [
              TableRow(decoration: BoxDecoration(color: emerald.withValues(alpha: 0.12)), children: const [
                Padding(padding: EdgeInsets.all(8), child: Text('اليوم', textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.all(8), child: Text('التاريخ', textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.all(8), child: Text('الإمساك (الفجر)', textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.all(8), child: Text('الإفطار (المغرب)', textAlign: TextAlign.center)),
              ]),
              for (var d = 0; d < len; d++) () {
                final day = start.add(Duration(days: d));
                final t = timesFor(_place!, day);
                final today = inRamadan && h.hDay == d + 1;
                return TableRow(decoration: today ? BoxDecoration(color: gold.withValues(alpha: 0.25)) : null, children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(ar(d + 1), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${ar(day.day)}/${ar(day.month)}', textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(6), child: Text(hm(t.fajr), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(6), child: Text(hm(t.maghrib), textAlign: TextAlign.center)),
                ]);
              }(),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const Text('متابعة ختم القرآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ListenableBuilder(
          listenable: Store.i,
          builder: (c, _) {
            final done = [for (var j = 1; j <= 30; j++) if (Store.i.favDhikr.contains('j:$j')) j];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أتممت ${ar(done.length)} من ٣٠ جزءًا'),
              LinearProgressIndicator(value: done.length / 30, minHeight: 8),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (var j = 1; j <= 30; j++)
                  FilterChip(
                    label: Text(ar(j)),
                    selected: done.contains(j),
                    onSelected: (_) => Store.i.toggleFavDhikr('j:$j'),
                  ),
              ]),
            ]);
          },
        ),
        const SizedBox(height: 20),
        const Text('مناسبات وعبادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        for (final e in const [
          ('ليلة القدر', 'خير من ألف شهر. تُلتمس في الوتر من العشر الأواخر، قال ﷺ: «تحرَّوا ليلة القدر في الوتر من العشر الأواخر من رمضان» (صحيح البخاري ٢٠١٧).'),
          ('العشر الأواخر', 'كان النبي ﷺ يعتكف العشر الأواخر من رمضان (متفق عليه).'),
          ('زكاة الفطر', 'صاع من طعام على كل مسلم، تُخرَج قبل صلاة العيد (صحيح البخاري ١٥٠٣). قدر الصاع بالجرامات ومقدارها نقدًا يُسأل فيه دار الإفتاء في بلدك.'),
          ('عيد الفطر وعيد الأضحى', 'يُصلَّى العيد ويُكبَّر فيه. عيد الفطر في ١ شوال، وعيد الأضحى في ١٠ ذي الحجة.'),
          ('يوم عرفة (٩ ذي الحجة)', 'يُستحب صيامه لغير الحاج، وفيه «يكفِّر السنة الماضية والباقية» (صحيح مسلم ١١٦٢).'),
          ('العشر من ذي الحجة', 'قال ﷺ: «ما من أيام العمل الصالح فيها أحب إلى الله من هذه الأيام» يعني العشر (صحيح البخاري ٩٦٩).'),
          ('الأشهر الحرم', 'ذو القعدة وذو الحجة والمحرم ورجب. قال تعالى: ﴿مِنْهَا أَرْبَعَةٌ حُرُمٌ﴾ [التوبة: ٣٦].'),
          ('الصيام المستحب', 'الاثنين والخميس، والأيام البيض (١٣ و١٤ و١٥ من كل شهر هجري)، وست من شوال، وعاشوراء مع التاسع.'),
        ])
          Card(child: ListTile(title: Text(e.$1), subtitle: Text(e.$2))),
        Text('المراجع: الصحيحان كما هو مذكور. المحتوى لم يُراجَع شرعيًا بعد.', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _Event {
  final String when, title, detail;
  const _Event(this.when, this.title, this.detail);
}

const _timeline = <_Event>[
  _Event('نحو ٥٧١م (عام الفيل)', 'مولد النبي ﷺ', 'وُلد في مكة يتيمًا. يوم المولد المشهور ١٢ ربيع الأول، وفيه خلاف بين أهل السير.'),
  _Event('نحو ٦١٠م (قبل الهجرة بـ١٣ سنة)', 'بدء الوحي', 'نزل جبريل عليه السلام بـ ﴿اقْرَأْ﴾ في غار حراء وللنبي ﷺ أربعون سنة.'),
  _Event('٣ سنوات بعد البعثة', 'الجهر بالدعوة', 'أمره الله بإنذار عشيرته الأقربين.'),
  _Event('٥ بعد البعثة', 'الهجرة إلى الحبشة', 'هاجر جماعة من الصحابة إلى النجاشي فرارًا بدينهم.'),
  _Event('١٠ بعد البعثة', 'عام الحزن والطائف', 'وفاة أبي طالب وخديجة رضي الله عنها، ثم الخروج إلى الطائف.'),
  _Event('١ هـ / ٦٢٢م', 'الهجرة إلى المدينة', 'بداية التقويم الهجري، وبناء المسجد النبوي والمؤاخاة بين المهاجرين والأنصار.'),
  _Event('٢ هـ', 'غزوة بدر الكبرى', 'في ١٧ رمضان، وسُمّي يومها يوم الفرقان.'),
  _Event('٣ هـ', 'غزوة أحد', 'في شوال، عند جبل أحد قرب المدينة.'),
  _Event('٥ هـ', 'غزوة الخندق (الأحزاب)', 'حُفر الخندق حول المدينة بمشورة سلمان الفارسي رضي الله عنه.'),
  _Event('٦ هـ', 'صلح الحديبية', 'صلح مع قريش وبيعة الرضوان.'),
  _Event('٧ هـ', 'غزوة خيبر', 'فتح حصون خيبر.'),
  _Event('٨ هـ', 'فتح مكة', 'في رمضان، ودخل النبي ﷺ مكة وعفا عن أهلها وطهّر الكعبة من الأصنام. وفي العام نفسه غزوة حنين.'),
  _Event('٩ هـ', 'غزوة تبوك', 'آخر غزوات النبي ﷺ، وعام الوفود.'),
  _Event('١٠ هـ', 'حجة الوداع', 'خطب ﷺ في عرفة، ونزل ﴿الْيَوْمَ أَكْمَلْتُ لَكُمْ دِينَكُمْ﴾ [المائدة: ٣].'),
  _Event('١١ هـ', 'وفاة النبي ﷺ', 'في ١٢ ربيع الأول في المدينة، وعمره ثلاث وستون سنة.'),
  _Event('١١ - ١٣ هـ', 'خلافة أبي بكر الصديق', 'حروب الردة وجمع القرآن في صحف.'),
  _Event('١٣ - ٢٣ هـ', 'خلافة عمر بن الخطاب', 'فتوح الشام والعراق ومصر وفارس، ووضع التقويم الهجري.'),
  _Event('٢٣ - ٣٥ هـ', 'خلافة عثمان بن عفان', 'جمع المصحف على رسم واحد ونسخه إلى الأمصار.'),
  _Event('٣٥ - ٤٠ هـ', 'خلافة علي بن أبي طالب', 'آخر الخلفاء الراشدين.'),
];

class SeerahScreen extends StatelessWidget {
  const SeerahScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('السيرة النبوية والخلفاء')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (var i = 0; i < _timeline.length; i++)
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Column(children: [
                  Container(width: 14, height: 14, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: gold, shape: BoxShape.circle)),
                  if (i < _timeline.length - 1) Expanded(child: Container(width: 2, color: gold.withValues(alpha: 0.4))),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_timeline[i].when, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
                      Text(_timeline[i].title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_timeline[i].detail, style: const TextStyle(height: 1.7)),
                    ]),
                  ),
                ),
              ]),
            ),
          Text('مراجع: السيرة النبوية لابن هشام، الرحيق المختوم للمباركفوري، وصحيح البخاري (كتاب المغازي). بعض التواريخ بالميلادي تقريبية، وعدد من التفاصيل فيه خلاف بين أهل السير. المحتوى لم يُراجَع شرعيًا بعد. سيُوسَّع هذا القسم (الصحابة والعلماء والحضارة).',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}
