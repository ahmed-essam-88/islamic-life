import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Ayah {
  final int number, inSurah, juz, page, hizbQuarter, surah;
  final String text;
  final bool sajda;
  Ayah(this.number, this.inSurah, this.juz, this.page, this.hizbQuarter,
      this.surah, this.text, this.sajda);
}

class Surah {
  final int number, ayahCount;
  final String name, englishName, revelation;
  final List<Ayah> ayahs;
  Surah(this.number, this.name, this.englishName, this.revelation,
      this.ayahCount, this.ayahs);
}

class QuranData {
  final List<Surah> surahs;
  final Map<int, Map<int, String>> tafsir; // surah -> ayah -> text
  final Map<int, Map<int, String>> translation;
  QuranData(this.surahs, this.tafsir, this.translation);
  static QuranData? _i;
  static QuranData get i => _i!;
  static bool get loaded => _i != null;

  static Future<void> load() async {
    if (_i != null) return;
    final raw = await Future.wait([
      rootBundle.loadString('assets/data/quran-uthmani.json'),
      rootBundle.loadString('assets/data/ar.muyassar.json'),
      rootBundle.loadString('assets/data/en.sahih.json'),
    ]);
    _i = await compute(_parse, raw);
  }

  static QuranData _parse(List<String> raw) {
    final q = jsonDecode(raw[0])['data']['surahs'] as List;
    final t = jsonDecode(raw[1])['data']['surahs'] as List;
    final e = jsonDecode(raw[2])['data']['surahs'] as List;
    final surahs = <Surah>[];
    final tafsir = <int, Map<int, String>>{};
    final trans = <int, Map<int, String>>{};
    for (var s = 0; s < q.length; s++) {
      final n = q[s]['number'] as int;
      final ayahs = <Ayah>[];
      for (final a in q[s]['ayahs']) {
        var text = (a['text'] as String).replaceAll('\uFEFF', '');
        final inS = a['numberInSurah'] as int;
        if (inS == 1 && n != 1 && n != 9) {
          final words = text.split(' ');
          text = words.skip(4).join(' ');
        }
        ayahs.add(Ayah(a['number'], inS, a['juz'], a['page'],
            a['hizbQuarter'], n, text.trim(), a['sajda'] != false));
      }
      surahs.add(Surah(n, q[s]['name'], q[s]['englishName'],
          q[s]['revelationType'], ayahs.length, ayahs));
      tafsir[n] = {
        for (final a in t[s]['ayahs']) a['numberInSurah'] as int: a['text']
      };
      trans[n] = {
        for (final a in e[s]['ayahs']) a['numberInSurah'] as int: a['text']
      };
    }
    return QuranData(surahs, tafsir, trans);
  }

  /// Search by normalized Arabic text (diacritics removed).
  List<Ayah> search(String query, {int limit = 100}) {
    final nq = normalize(query);
    if (nq.isEmpty) return [];
    final out = <Ayah>[];
    for (final s in surahs) {
      for (final a in s.ayahs) {
        if (normalize(a.text).contains(nq)) {
          out.add(a);
          if (out.length >= limit) return out;
        }
      }
    }
    return out;
  }

  static String normalize(String s) => s
      .replaceAll(RegExp('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
      .replaceAll(RegExp('[\u0622\u0623\u0625\u0671]'), '\u0627')
      .replaceAll('\u0649', '\u064A')
      .trim();
}
