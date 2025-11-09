import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database only
  try {
    await DatabaseHelper().database;
  } catch (e) {
    // Database initialization failed
  }
  
  runApp(const GoldenOaksGolfApp());
}

class GoldenOaksGolfApp extends StatelessWidget {
  const GoldenOaksGolfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golden Oaks Golf League',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const UnifiedMainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}