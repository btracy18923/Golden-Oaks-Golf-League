import 'package:flutter/material.dart';
import '../models/league.dart';
import 'player_profile_screen.dart';
import 'player_scores_screen.dart';
import 'golf_course_info_screen.dart';

class AdminScreen extends StatelessWidget {
  final League? currentLeague;
  
  const AdminScreen({super.key, this.currentLeague});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration Screen'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            const Icon(Icons.settings, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Match Settings & Administration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Admin buttons
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAdminButton(
                      'Player Profile',
                      Icons.person,
                      currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                      () => _navigateToScreen(context, PlayerProfileScreen(league: currentLeague)),
                    ),
                    _buildAdminButton(
                      'Player Scores',
                      Icons.score,
                      currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                      () => _navigateToScreen(context, PlayerScoresScreen(league: currentLeague)),
                    ),
                    _buildAdminButton(
                      'Golf Course Info',
                      Icons.golf_course,
                      currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                      () => _navigateToScreen(context, GolfCourseInfoScreen(league: currentLeague)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAdminButton(
                      'Return to Main Menu',
                      Icons.home,
                      currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                      () => Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Additional administrative functions will be added here',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToScreen(BuildContext context, Widget screen) {
    if (currentLeague == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a league first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  
  Widget _buildAdminButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}