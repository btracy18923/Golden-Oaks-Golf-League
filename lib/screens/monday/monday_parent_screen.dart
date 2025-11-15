import 'package:flutter/material.dart';
import 'monday_player_selection_screen.dart';
import 'monday_player_scores_screen.dart';
import 'monday_player_profile_screen.dart';
import '../admin_screen.dart';
import '../../models/league.dart';

class MondayParentScreen extends StatefulWidget {
  const MondayParentScreen({super.key});

  @override
  State<MondayParentScreen> createState() => _MondayParentScreenState();
}

class _MondayParentScreenState extends State<MondayParentScreen> {
  
  void navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League - Golden Oaks Golf',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          const Icon(
            Icons.storage,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // League Info Section
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  // Left Side - League Info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // League Title
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green[300],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'MONDAY LEAGUE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Monday League Settings
                        Row(
                          children: [
                            // Skats Ante
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Skats Ante',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '\$5.00',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Closest Pin
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Closest Pin',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '\$4.00',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Mulligans
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Mulligans',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '\$2.00',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Right Side - Golden Oaks Image
                  Expanded(
                    flex: 7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/GoldenOaks.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.park,
                                size: 120,
                                color: Colors.green[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Navigation Buttons Footer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  _buildNavigationButton(
                    'Player Selection',
                    Icons.people,
                    Colors.green[300]!,
                    () => navigateToScreen(const MondayPlayerSelectionScreen()),
                  ),
                  _buildNavigationButton(
                    'Player Scores',
                    Icons.score,
                    Colors.green[200]!,
                    () => navigateToScreen(const MondayPlayerScoresScreen()),
                  ),
                  _buildNavigationButton(
                    'Player Profiles',
                    Icons.person,
                    Colors.green[250]!,
                    () => navigateToScreen(const MondayPlayerProfileScreen()),
                  ),
                  _buildNavigationButton(
                    'Administration',
                    Icons.settings,
                    Colors.green[100]!,
                    () => navigateToScreen(AdminScreen(currentLeague: League.monday)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 2),
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