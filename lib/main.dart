import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/database_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabase();
  runApp(const HomeStashApp());
}

class HomeStashApp extends StatefulWidget {
  const HomeStashApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  State<HomeStashApp> createState() => _HomeStashAppState();
}

class _HomeStashAppState extends State<HomeStashApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: HomeStashApp.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: '家庭储物管家',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          home: SplashScreen(
            nextScreen: const HomeScreen(),
          ),
        );
      },
    );
  }
}
