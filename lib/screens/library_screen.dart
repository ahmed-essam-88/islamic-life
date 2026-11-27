import 'package:flutter/material.dart';
import 'hadith_screens.dart';
import 'names_screen.dart';
import 'quran_screens.dart';
import 'fiqh_screens.dart';
import 'ramadan_seerah.dart';
import 'adhkar_screens.dart';
import 'prophets_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Widget)>[
      (Icons.menu_book, 'القرآن الكريم والتفسير الميسر', 'المصحف العثماني، التفسير الميسر، ترجمة صحيح انترناشيونال', const QuranIndexScreen()),
      (Icons.auto_stories, 'كتب الحديث', 'تسعة كتب، الأربعون النووية، مع درجات الأحاديث عند توفرها', const HadithLibraryScreen()),
      (Icons.spa, 'الأذكار وحصن المسلم', 'أذكار الصباح والمساء وأدعية حصن المسلم', const AdhkarScreen()),
      (Icons.star_border, 'أسماء الله الحسنى', 'الأسماء مع المعاني', const NamesScreen()),
      (Icons.balance, 'الفقه والعبادات', 'ملخصات مبسطة للأبواب الأساسية', const FiqhScreen()),
      (Icons.groups, 'قصص الأنبياء', 'قصص 25 نبياً مع مواضعها في القرآن', const ProphetsScreen()),
      (Icons.timeline, 'السيرة النبوية', 'خط زمني للسيرة والخلفاء الراشدين', const SeerahScreen()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة الإسلامية')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length + 1,
        itemBuilder: (c, i) {
          if (i == items.length) {
            return const Padding(padding: EdgeInsets.all(16),
                child: Text('نعرض فقط المحتوى المتاح بترخيص حر. الكتب الكلاسيكية الكاملة المحمية بحقوق النشر غير مضمّنة. المحتوى غير مراجَع من عالم شرعي، فارجع لأهل العلم.',
                    style: TextStyle(fontSize: 12)));
          }
          final it = items[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + i * 80),
            builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
            child: Card(child: ListTile(
              leading: Icon(it.$1, color: Theme.of(c).colorScheme.primary),
              title: Text(it.$2), subtitle: Text(it.$3),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(c, PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: it.$4))),
            )),
          );
        },
      ),
    );
  }
}
