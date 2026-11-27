import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../data/notifications.dart';
import '../data/store.dart';
import 'hadith_screens.dart';
import 'names_screen.dart';
import 'learn_screens.dart';
import 'adhkar_screens.dart';
import 'prayer_screens.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المزيد')),
        body: ListView(children: [
          ListTile(leading: const Icon(Icons.auto_stories), title: const Text('الحديث الشريف'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithLibraryScreen()))),
          ListTile(leading: const Icon(Icons.star_border), title: const Text('أسماء الله الحسنى'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NamesScreen()))),
          ListTile(leading: const Icon(Icons.school), title: const Text('التعلم الإسلامي'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearnScreen()))),
          ListTile(leading: const Icon(Icons.calendar_month), title: const Text('التقويم الهجري والمناسبات'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen()))),
          ListTile(leading: const Icon(Icons.explore), title: const Text('اتجاه القبلة'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()))),
          ListTile(leading: const Icon(Icons.fingerprint), title: const Text('المسبحة'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen()))),
          ListTile(leading: const Icon(Icons.notifications_active), title: const Text('الإشعارات والتنبيهات'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()))),
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

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: ListenableBuilder(
          listenable: Store.i,
          builder: (c, _) {
            final s = Store.i;
            Future<void> apply(String k, bool v) async {
              if (v) {
                final ok = await Notifs.requestPermission();
                if (!ok && !kIsWeb && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم السماح بالإشعارات. فعّلها من إعدادات الهاتف.')));
                }
              }
              s.setFlag(k, v);
              await Notifs.reschedule();
            }
            return ListView(children: [
              if (kIsWeb) const Padding(padding: EdgeInsets.all(16), child: Text('الإشعارات تعمل على تطبيق الأندرويد فقط.')),
              SwitchListTile(title: const Text('تنبيه عند دخول وقت الصلاة'), subtitle: const Text('يحتاج تحديد موقعك أو اختيار مدينة'), value: s.flag('n_prayer'), onChanged: (v) => apply('n_prayer', v)),
              ListTile(
                title: const Text('تنبيه قبل الصلاة'),
                trailing: DropdownButton<int>(
                  value: s.intVal('n_before', 0),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('بدون')),
                    DropdownMenuItem(value: 5, child: Text('٥ دقائق')),
                    DropdownMenuItem(value: 10, child: Text('١٠ دقائق')),
                    DropdownMenuItem(value: 15, child: Text('١٥ دقيقة')),
                    DropdownMenuItem(value: 30, child: Text('٣٠ دقيقة')),
                  ],
                  onChanged: (v) { s.setInt('n_before', v!); Notifs.reschedule(); },
                ),
              ),
              SwitchListTile(title: const Text('أذكار الصباح والمساء'), subtitle: const Text('٦:٣٠ صباحًا و٥:٣٠ مساءً'), value: s.flag('n_adhkar'), onChanged: (v) => apply('n_adhkar', v)),
              SwitchListTile(title: const Text('تذكير ورد القرآن'), subtitle: const Text('٩:٠٠ مساءً'), value: s.flag('n_quran'), onChanged: (v) => apply('n_quran', v)),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('ملاحظة: التنبيهات محلية على جهازك. قد يتأخر وصولها دقائق في وضع توفير البطارية. صوت الأذان الكامل غير مضمّن بعد لعدم توفر تسجيل مرخّص؛ الإشعار بصوت النظام.'),
              ),
            ]);
          },
        ),
      );
}
