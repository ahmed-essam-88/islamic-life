import 'package:flutter/material.dart';
import '../data/store.dart';
import '../theme.dart';
import 'adhkar_screens.dart';
import 'prayer_screens.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المزيد')),
        body: ListView(children: [
          ListTile(leading: const Icon(Icons.calendar_month), title: const Text('التقويم الهجري والمناسبات'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen()))),
          ListTile(leading: const Icon(Icons.explore), title: const Text('اتجاه القبلة'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()))),
          ListTile(leading: const Icon(Icons.fingerprint), title: const Text('المسبحة'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen()))),
          const Divider(),
          ListenableBuilder(
            listenable: Store.i,
            builder: (c, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('المظهر'),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
                    ButtonSegment(value: ThemeMode.light, label: Text('نهاري')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('ليلي')),
                  ],
                  selected: {Store.i.themeMode},
                  onSelectionChanged: (s) => Store.i.themeMode = s.first,
                ),
              ]),
            ),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.verified_outlined), title: const Text('المصادر والمراجعة'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourcesScreen()))),
        ]),
      );
}

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المصادر')),
        body: ListView(padding: const EdgeInsets.all(16), children: const [
          Text('كل المحتوى الديني مأخوذ من مصادر خارجية معروفة ولم يُولَّد بالذكاء الاصطناعي. لم تتم مراجعته شرعيًا بعد من جهة علمية، فيُرجى الرجوع لأهل العلم في المسائل المهمة.'),
          SizedBox(height: 16),
          Text('القرآن الكريم: نص المصحف العثماني عبر AlQuran Cloud (api.alquran.cloud)، المطابق لنص مشروع Tanzil.'),
          SizedBox(height: 8),
          Text('التفسير الميسر: مجمع الملك فهد لطباعة المصحف الشريف، عبر AlQuran Cloud.'),
          SizedBox(height: 8),
          Text('الترجمة الإنجليزية: Saheeh International، عبر AlQuran Cloud.'),
          SizedBox(height: 8),
          Text('التلاوة: everyayah.com.'),
          SizedBox(height: 8),
          Text('أذكار الصباح والمساء: Seen-Arabic/Morning-And-Evening-Adhkar-DB (رخصة MIT).'),
          SizedBox(height: 8),
          Text('حصن المسلم: سعيد بن علي القحطاني، بنسخة JSON من rn0x/hisn_almuslim_json.'),
          SizedBox(height: 8),
          Text('مواقيت الصلاة والقبلة: مكتبة adhan (حساب فلكي محلي). التقويم الهجري: مكتبة hijri (أم القرى).'),
        ]),
      );
}
