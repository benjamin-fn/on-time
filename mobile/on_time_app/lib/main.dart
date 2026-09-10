import 'package:flutter/material.dart';

import 'models/user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final savedUser = await authService.getSavedUser();

  runApp(
    OnTimeApp(
      savedUser: savedUser,
    ),
  );
}

class OnTimeApp extends StatelessWidget {
  final User? savedUser;

  const OnTimeApp({
    super.key,
    required this.savedUser,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'On Time',
      theme: AppTheme.lightTheme,
      home: savedUser == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}