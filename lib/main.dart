import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'data/store.dart';
import 'data/quran.dart';
import 'screens/home.dart';
import 'screens/quran_screens.dart';
import 'screens/prayer_screens.dart';
import 'screens/adhkar_screens.dart';
import 'screens/more.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.i.init();
  runApp(const IslamicLifeApp());
}

ThemeData _theme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: emerald,
    brightness: b,
    primary: dark ? const Color(0xFF3FB68B) : emerald,
    secondary: gold,
    surface: dark ? const Color(0xFF0F1B2D) : const Color(0xFFFBFAF5),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface, centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? const Color(0xFF16263D) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: gold.withOpacity(0.25)))),
  );
}

class IslamicLifeApp extends StatelessWidget {
  const IslamicLifeApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Store.i,
        builder: (context, _) => MaterialApp(
          title: 'Islamic Life - حياتك الإسلامية',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: Store.i.themeMode,
          home: const Shell(),
        ),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  @override
  void initState() {
    super.initState();
    QuranData.load().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(goTo: (i) => setState(() => _tab = i)),
      const QuranIndexScreen(),
      const PrayerScreen(),
      const AdhkarScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250), child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'القرآن'),
          NavigationDestination(icon: Icon(Icons.access_time), label: 'الصلاة'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'الأذكار'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'المزيد'),
        ],
      ),
    );
  }
}
