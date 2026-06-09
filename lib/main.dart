import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final serverUrl = prefs.getString('server_url') ?? '';
  runApp(TVHClientApp(hasServer: serverUrl.isNotEmpty));
}

class TVHClientApp extends StatelessWidget {
  final bool hasServer;
  const TVHClientApp({super.key, required this.hasServer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TVH Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E2E),
          elevation: 2,
        ),
      ),
      home: hasServer ? const HomeScreen() : const SetupScreen(),
    );
  }
}
