import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'quran.dart' show QuranData;

class HadithBook {
  final String id, name, note;
  final bool bundled;
  const HadithBook(this.id, this.name, this.note, {this.bundled = false});
}

const hadithBooks = [
  HadithBook('bukhari', 'صحيح البخاري', 'الصحيحان: تلقتهما الأمة بالقبول، وأحاديث أصولهما صحيحة.'),
  HadithBook('muslim', 'صحيح مسلم', 'الصحيحان: تلقتهما الأمة بالقبول، وأحاديث أصولهما صحيحة.'),
  HadithBook('abudawud', 'سنن أبي داود', 'فيه الصحيح والحسن والضعيف: انظر الدرجة تحت كل حديث.'),
  HadithBook('tirmidhi', 'جامع الترمذي', 'فيه الصحيح والحسن والضعيف: انظر الدرجة تحت كل حديث.'),
  HadithBook('nasai', 'سنن النسائي', 'فيه الصحيح والحسن والضعيف: انظر الدرجة تحت كل حديث.'),
  HadithBook('ibnmajah', 'سنن ابن ماجه', 'فيه الصحيح والحسن والضعيف: انظر الدرجة تحت كل حديث.'),
  HadithBook('malik', 'موطأ الإمام مالك', 'الدرجات من التخريج المرفق إن وُجد.'),
  HadithBook('nawawi', 'الأربعون النووية', 'متن الأربعين للإمام النووي (بالإضافة إلى حديثين)، وتخريجها في الأصل.', bundled: true),
  HadithBook('qudsi', 'الأحاديث القدسية (الأربعون)', 'مجموعة الأربعين القدسية.'),
];

class Hadith {
  final int number;
  final String text, section;
  final List<(String, String)> grades;
  Hadith(this.number, this.text, this.section, this.grades);
}

class HadithData {
  final List<Hadith> items;
  final List<String> sections;
  HadithData(this.items, this.sections);
}

HadithData _parse(String raw) {
  final j = jsonDecode(raw) as Map<String, dynamic>;
  final secs = (j['metadata']['sections'] as Map).map((k, v) => MapEntry(int.parse(k), v.toString()));
  final out = <Hadith>[];
  for (final h in j['hadiths'] as List) {
    if ((h['text'] as String).trim().isEmpty) continue;
    final book = (h['reference']?['book'] ?? 0) as int;
    out.add(Hadith(
      (h['hadithnumber'] as num).toInt(),
      (h['text'] as String).trim(),
      secs[book] ?? '',
      [for (final g in (h['grades'] ?? []) as List) (g['name'].toString(), g['grade'].toString())],
    ));
  }
  final names = secs.entries.where((e) => e.key != 0 && e.value.isNotEmpty).map((e) => e.value).toList();
  return HadithData(out, names);
}

final _mem = <String, HadithData>{};
const _cdn = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

Future<File?> _file(String id) async {
  if (kIsWeb) return null;
  final d = await getApplicationDocumentsDirectory();
  return File('${d.path}/hadith_$id.json');
}

Future<bool> isDownloaded(HadithBook b) async {
  if (b.bundled || _mem.containsKey(b.id)) return true;
  final f = await _file(b.id);
  return f != null && f.existsSync();
}

/// Loads a book: bundled asset, local cache, or one-time download (then cached for offline use).
Future<HadithData> loadBook(HadithBook b) async {
  if (_mem.containsKey(b.id)) return _mem[b.id]!;
  String raw;
  if (b.bundled) {
    raw = await rootBundle.loadString('assets/data/hadith_${b.id}.json');
  } else {
    final f = await _file(b.id);
    if (f != null && f.existsSync()) {
      raw = await f.readAsString();
    } else {
      final r = await http.get(Uri.parse('$_cdn/ara-${b.id}.min.json'));
      if (r.statusCode != 200) throw Exception('download failed ${r.statusCode}');
      raw = utf8.decode(r.bodyBytes);
      jsonDecode(raw); // validate before caching
      if (f != null) await f.writeAsString(raw);
    }
  }
  return _mem[b.id] = await compute(_parse, raw);
}

List<(HadithBook, Hadith)> searchLoaded(String q, {int limit = 60}) {
  final nq = QuranData.normalize(q);
  final out = <(HadithBook, Hadith)>[];
  if (nq.isEmpty) return out;
  for (final b in hadithBooks) {
    final d = _mem[b.id];
    if (d == null) continue;
    for (final h in d.items) {
      if (QuranData.normalize(h.text).contains(nq)) {
        out.add((b, h));
        if (out.length >= limit) return out;
      }
    }
  }
  return out;
}
