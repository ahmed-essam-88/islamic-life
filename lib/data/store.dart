import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: bookmarks, progress, settings. Cloud sync comes later.
class Store extends ChangeNotifier {
  static final Store i = Store._();
  Store._();
  late SharedPreferences _p;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  ThemeMode get themeMode =>
      ThemeMode.values[_p.getInt('theme') ?? 0];
  set themeMode(ThemeMode m) {
    _p.setInt('theme', m.index);
    notifyListeners();
  }

  double get quranFont => _p.getDouble('qfont') ?? 26;
  set quranFont(double v) {
    _p.setDouble('qfont', v);
    notifyListeners();
  }

  String get calcMethod => _p.getString('method') ?? 'egyptian';
  set calcMethod(String v) {
    _p.setString('method', v);
    notifyListeners();
  }

  bool get hanafi => _p.getBool('hanafi') ?? false;
  set hanafi(bool v) {
    _p.setBool('hanafi', v);
    notifyListeners();
  }

  // manual city (lat, lon, name); null = use GPS
  Map<String, dynamic>? get city {
    final s = _p.getString('city');
    return s == null ? null : jsonDecode(s);
  }

  void setCity(Map<String, dynamic>? c) {
    if (c == null) {
      _p.remove('city');
    } else {
      _p.setString('city', jsonEncode(c));
    }
    notifyListeners();
  }

  // last read: surah, ayah
  List<int> get lastRead => (_p.getStringList('last') ?? ['1', '1'])
      .map(int.parse)
      .toList();
  void setLastRead(int s, int a) {
    _p.setStringList('last', ['$s', '$a']);
    notifyListeners();
  }

  Set<String> get bookmarks => (_p.getStringList('bm') ?? []).toSet();
  bool isBookmarked(int s, int a) => bookmarks.contains('$s:$a');
  void toggleBookmark(int s, int a) {
    final b = bookmarks;
    if (!b.remove('$s:$a')) b.add('$s:$a');
    _p.setStringList('bm', b.toList());
    notifyListeners();
  }

  // memorization: ayah keys marked as memorized
  Set<String> get memorized => (_p.getStringList('mem') ?? []).toSet();
  void setMemorized(int s, int a, bool v) {
    final m = memorized;
    v ? m.add('$s:$a') : m.remove('$s:$a');
    _p.setStringList('mem', m.toList());
    notifyListeners();
  }

  // dhikr counters per day: key date|id
  int dhikrCount(String id) {
    final d = DateTime.now().toIso8601String().substring(0, 10);
    return _p.getInt('dk|$d|$id') ?? 0;
  }

  void setDhikrCount(String id, int v) {
    final d = DateTime.now().toIso8601String().substring(0, 10);
    _p.setInt('dk|$d|$id', v);
    notifyListeners();
  }

  Set<String> get favDhikr => (_p.getStringList('favdk') ?? []).toSet();
  void toggleFavDhikr(String id) {
    final f = favDhikr;
    if (!f.remove(id)) f.add(id);
    _p.setStringList('favdk', f.toList());
    notifyListeners();
  }

  int get tasbihTotal => _p.getInt('tasbih') ?? 0;
  set tasbihTotal(int v) {
    _p.setInt('tasbih', v);
    notifyListeners();
  }

  bool flag(String k, [bool d = false]) => _p.getBool('f_$k') ?? d;
  void setFlag(String k, bool v) {
    _p.setBool('f_$k', v);
    notifyListeners();
  }

  int intVal(String k, int d) => _p.getInt('i_$k') ?? d;
  void setInt(String k, int v) {
    _p.setInt('i_$k', v);
    notifyListeners();
  }

  // ---- cloud sync helpers ----
  Map<String, dynamic> exportSync() => {
        'bm': bookmarks.toList(),
        'mem': memorized.toList(),
        'favdk': favDhikr.toList(),
        'last': lastRead,
        'tasbih': tasbihTotal,
      };
  /// Merge cloud data into local (union for sets, max for counters).
  void mergeSync(Map<String, dynamic> d) {
    List<String> l(String k) => ((d[k] as List?) ?? []).map((e) => '$e').toList();
    _p.setStringList('bm', {...bookmarks, ...l('bm')}.toList());
    _p.setStringList('mem', {...memorized, ...l('mem')}.toList());
    _p.setStringList('favdk', {...favDhikr, ...l('favdk')}.toList());
    final t = (d['tasbih'] as num?)?.toInt() ?? 0;
    if (t > tasbihTotal) _p.setInt('tasbih', t);
    if (!_p.containsKey('last') && d['last'] is List) {
      _p.setStringList('last', (d['last'] as List).map((e) => '$e').toList());
    }
    notifyListeners();
  }
}
