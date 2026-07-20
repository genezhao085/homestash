import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HomeStashApp());
}

class HomeStashApp extends StatelessWidget {
  const HomeStashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家庭储物管家',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
