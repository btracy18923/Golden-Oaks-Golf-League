import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'monday_player_selection_screen.dart';
import 'monday_player_scores_screen.dart';
import 'monday_player_profile_screen.dart';
import 'monday_golf_course_screen.dart';
import '../admin_screen.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/UI/parent_screen.dart';

class MondayParentScreen extends StatefulWidget {
  const MondayParentScreen({super.key});

  @override
  State<MondayParentScreen> createState() => _MondayParentScreenState();
}

class _MondayParentScreenState extends State<MondayParentScreen> {
  String? selectedGolfCourse;
  List<Map<String, dynamic>> golfCourses = [];
  bool isLoadingCourses = true;
  
  // Editable league settings
  double skatsAnte = 5.00;
  double closestPin = 4.00;
  double mulligans = 2.00;
  
  // Controllers for edit fields
  final TextEditingController _skatsAnteController = TextEditingController();
  final TextEditingController _closestPinController = TextEditingController();
  final TextEditingController _mulligansController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _loadGolfCourses();
    _skatsAnteController.text = skatsAnte.toStringAsFixed(2);
    _closestPinController.text = closestPin.toStringAsFixed(2);
    _mulligansController.text = mulligans.toStringAsFixed(2);
    
    // Set the initial Players Ante value in the league service
    LeaguePurseService.setPlayersAnte(skatsAnte);
    // Set the initial Closest Pin amount in the league service
    LeaguePurseService.setClosestPinAmount(closestPin);
    // Set the initial Mulligan amount in the league service
    LeaguePurseService.setMulliganAmount(mulligans);
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Monday League
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }
  
  @override
  void dispose() {
    _skatsAnteController.dispose();
    _closestPinController.dispose();
    _mulligansController.dispose();
    super.dispose();
  }

  Future<void> _loadGolfCourses() async {
    try {
      final courses = await DatabaseHelper().getAllGolfCourses();
      setState(() {
        golfCourses = courses;
        isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCourses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading golf courses: $e')),
        );
      }
    }
  }
  
  void navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  /// Captures parent screen data and navigates to player selection
  void _navigateToPlayerSelection() {
    // Capture data in the retention service before navigation
    ScreenDataRetentionService().captureParentScreenData(
      playersAnte: skatsAnte,
      closestPinAmount: closestPin,
      mulliganAmount: mulligans,
      selectedGolfCourse: selectedGolfCourse,
    );
    
    // Navigate to player selection screen
    navigateToScreen(MondayPlayerSelectionScreen(playersAnte: skatsAnte));
  }
  
  void _editValue(String title, TextEditingController controller, Function(double) onSave) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  border: const OutlineInputBorder(),
                  prefixText: '\$',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value >= 0) {
                  onSave(value);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
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
      body: Column(
        children: [
          // League Info Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16.0 : 8.0),
              child: ParentScreenUI(
                selectedGolfCourse: selectedGolfCourse,
                golfCourses: golfCourses,
                isLoadingCourses: isLoadingCourses,
                skatsAnte: skatsAnte,
                closestPin: closestPin,
                mulligans: mulligans,
                leagueTitle: 'MONDAY LEAGUE',
                anteLabel: 'Players Ante ',
                onSkatsAnteEdit: () => _editValue('Players Ante', _skatsAnteController, (value) {
                  setState(() {
                    skatsAnte = value;
                    _skatsAnteController.text = value.toStringAsFixed(2);
                    LeaguePurseService.setPlayersAnte(value);
                  });
                }),
                onClosestPinEdit: () => _editValue('Closest Pin', _closestPinController, (value) {
                  setState(() {
                    closestPin = value;
                    _closestPinController.text = value.toStringAsFixed(2);
                    LeaguePurseService.setClosestPinAmount(value);
                  });
                }),
                onMulligansEdit: () => _editValue('Mulligans', _mulligansController, (value) {
                  setState(() {
                    mulligans = value;
                    _mulligansController.text = value.toStringAsFixed(2);
                    LeaguePurseService.setMulliganAmount(value);
                  });
                }),
                onGolfCourseChanged: (String? newValue) {
                  setState(() {
                    selectedGolfCourse = newValue;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Navigation Buttons Footer - Full Width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4), // Reduced by 50%
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(0),
            ),
            child: _buildFooterButtons(screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons(double screenWidth) {
    // 6" - 6.5" phones in landscape: width ~820-920px, exclude larger tablets (>950px)
    final is6InchPhoneLandscape = screenWidth <= 950;
    // 8" tablets: width between 600-1000px
    final is8InchTablet = screenWidth >= 600 && screenWidth <= 1000;
    
    final baseButtons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        selectedGolfCourse != null ? Colors.green[300]! : Colors.grey[400]!,
        selectedGolfCourse != null ? () => _navigateToPlayerSelection() : null,
        isCompact: is6InchPhoneLandscape,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.green[200]!,
        () => navigateToScreen(const MondayPlayerScoresScreen()),
        isCompact: is6InchPhoneLandscape,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.green[300]!,
        () => navigateToScreen(const MondayPlayerProfileScreen()),
        isCompact: is6InchPhoneLandscape,
      ),
      _buildNavigationButton(
        'Golf Courses',
        Icons.golf_course,
        Colors.green[100]!,
        () => navigateToScreen(const MondayGolfCourseScreen()),
        isCompact: is6InchPhoneLandscape,
      ),
    ];
    
    // Add Administration button only if NOT 6" phone/tablet or 8" tablet
    final buttons = (is6InchPhoneLandscape || is8InchTablet)
      ? baseButtons
      : [
          ...baseButtons,
          _buildNavigationButton(
            'Administration',
            Icons.settings,
            Colors.green[100]!,
            () => navigateToScreen(AdminScreen(currentLeague: League.monday)),
            isCompact: is6InchPhoneLandscape,
          ),
        ];

    if (is6InchPhoneLandscape) {
      // Single row for phone landscape
      return Row(
        children: buttons.map((button) => Expanded(child: button)).toList(),
      );
    } else {
      // Default wrap layout for other screen sizes
      return Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: buttons,
      );
    }
  }

  Widget _buildNavigationButton(String title, IconData icon, Color bgColor, VoidCallback? onPressed, {bool isCompact = false}) {
    final isDisabled = onPressed == null;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 1 : 4, 
        vertical: isCompact ? 1 : 2, // Reduced by 50%
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: isDisabled ? Colors.grey[600] : Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 3 : 6, // Reduced by 50%
            horizontal: isCompact ? 4 : 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isDisabled ? Colors.grey[500]! : Colors.black, 
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: isCompact ? 14 : 18, // Reduced by ~20%
              color: isDisabled ? Colors.grey[600] : null,
            ),
            SizedBox(height: isCompact ? 0.5 : 1), // Reduced by 50%
            Text(
              title,
              style: TextStyle(
                fontSize: isCompact ? 9 : 11, // Reduced by ~15%
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.grey[600] : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}