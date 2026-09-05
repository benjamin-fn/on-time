import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const OnTimeApp());
}

class OnTimeApp extends StatelessWidget {
  const OnTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'On Time',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}