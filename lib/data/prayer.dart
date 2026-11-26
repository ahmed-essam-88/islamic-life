import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'store.dart';

class City {
  final String name;
  final double lat, lon;
  const City(this.name, this.lat, this.lon);
}

const cities = [
  City('القاهرة', 30.0444, 31.2357),
  City('الإسكندرية', 31.2001, 29.9187),
  City('الجيزة', 30.0131, 31.2089),
  City('أسوان', 24.0889, 32.8998),
  City('مكة المكرمة', 21.3891, 39.8579),
  City('المدينة المنورة', 24.5247, 39.5692),
  City('الرياض', 24.7136, 46.6753),
  City('جدة', 21.4858, 39.1925),
  City('دبي', 25.2048, 55.2708),
  City('الكويت', 29.3759, 47.9774),
  City('الدوحة', 25.2854, 51.5310),
  City('عمّان', 31.9454, 35.9284),
  City('القدس', 31.7683, 35.2137),
  City('بغداد', 33.3152, 44.3661),
  City('بيروت', 33.8938, 35.5018),
  City('دمشق', 33.5138, 36.2765),
  City('الخرطوم', 15.5007, 32.5599),
  City('طرابلس', 32.8872, 13.1913),
  City('تونس', 36.8065, 10.1815),
  City('الجزائر', 36.7538, 3.0588),
  City('الرباط', 34.0209, -6.8416),
  City('إسطنبول', 41.0082, 28.9784),
  City('لندن', 51.5072, -0.1276),
  City('نيويورك', 40.7128, -74.0060),
];

const methods = <String, String>{
  'egyptian': 'الهيئة المصرية العامة للمساحة',
  'muslim_world_league': 'رابطة العالم الإسلامي',
  'umm_al_qura': 'أم القرى (مكة)',
  'karachi': 'جامعة العلوم الإسلامية بكراتشي',
  'north_america': 'الجمعية الإسلامية لأمريكا الشمالية',
  'kuwait': 'الكويت',
  'qatar': 'قطر',
  'dubai': 'دبي',
  'turkey': 'ديانت تركيا',
};

CalculationParameters paramsFor(String m, bool hanafi) {
  final p = switch (m) {
    'muslim_world_league' => CalculationMethod.muslim_world_league.getParameters(),
    'umm_al_qura' => CalculationMethod.umm_al_qura.getParameters(),
    'karachi' => CalculationMethod.karachi.getParameters(),
    'north_america' => CalculationMethod.north_america.getParameters(),
    'kuwait' => CalculationMethod.kuwait.getParameters(),
    'qatar' => CalculationMethod.qatar.getParameters(),
    'dubai' => CalculationMethod.dubai.getParameters(),
    'turkey' => CalculationMethod.turkey.getParameters(),
    _ => CalculationMethod.egyptian.getParameters(),
  };
  p.madhab = hanafi ? Madhab.hanafi : Madhab.shafi;
  return p;
}

class Place {
  final double lat, lon;
  final String name;
  Place(this.lat, this.lon, this.name);
}

/// Manual city if chosen, else GPS with permission, else null.
Future<Place?> resolvePlace() async {
  final c = Store.i.city;
  if (c != null) return Place(c['lat'], c['lon'], c['name']);
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return null;
    final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low));
    return Place(pos.latitude, pos.longitude, 'موقعك الحالي');
  } catch (_) {
    return null;
  }
}

PrayerTimes timesFor(Place p, DateTime day) => PrayerTimes(
    Coordinates(p.lat, p.lon),
    DateComponents(day.year, day.month, day.day),
    paramsFor(Store.i.calcMethod, Store.i.hanafi));

const kaaba = (lat: 21.4225, lon: 39.8262);

double qiblaBearing(double lat, double lon) =>
    Qibla(Coordinates(lat, lon)).direction;

double distanceToKaabaKm(double lat, double lon) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(kaaba.lat - lat), dLon = rad(kaaba.lon - lon);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat)) * math.cos(rad(kaaba.lat)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

const prayerNames = {
  Prayer.fajr: 'الفجر',
  Prayer.sunrise: 'الشروق',
  Prayer.dhuhr: 'الظهر',
  Prayer.asr: 'العصر',
  Prayer.maghrib: 'المغرب',
  Prayer.isha: 'العشاء',
};

const arDigits = '٠١٢٣٤٥٦٧٨٩';
String ar(Object n) =>
    n.toString().replaceAllMapped(RegExp(r'\d'), (m) => arDigits[int.parse(m[0]!)]);

String hm(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '${ar(h)}:${ar(m)} ${t.hour >= 12 ? 'م' : 'ص'}';
}
