import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_helper.dart';
import 'screens/main_menu_screen.dart';
import 'firebase_options.dart';

//Version 4, November 16, 2025
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with explicit configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    print('Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    print('Platform: ${DefaultFirebaseOptions.currentPlatform.apiKey.substring(0, 10)}...');
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('Error type: ${e.runtimeType}');
    
    // Continue app startup even if Firebase fails
    print('Continuing without Firebase - local database only');
  }
  
  // Initialize local database
  try {
    await DatabaseHelper().database;
  } catch (e) {
    print('Database initialization failed: $e');
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