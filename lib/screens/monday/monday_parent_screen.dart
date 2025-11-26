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
import '../../services/UI/custom_keypad_service.dart';

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
  
  // Custom keypad controller for amount editing
  late CustomKeypadController _keypadController;
  
  // Currently focused field for amount editing
  String? _currentEditField; // 'ante', 'closestPin', 'mulligans'

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _loadGolfCourses();
    _keypadController = CustomKeypadService.createController();
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
  
  /// Shows keypad for editing amount field
  void _showKeypadForAmount(String fieldType) {
    _currentEditField = fieldType;
    
    // Set current input based on field type
    String currentValue = '';
    switch (fieldType) {
      case 'ante':
        currentValue = skatsAnte.toStringAsFixed(2);
        break;
      case 'closestPin':
        currentValue = closestPin.toStringAsFixed(2);
        break;
      case 'mulligans':
        currentValue = mulligans.toStringAsFixed(2);
        break;
    }
    
    // Remove decimal point and leading zeros for input
    currentValue = currentValue.replaceAll('.', '').replaceAll(RegExp(r'^0+'), '');
    if (currentValue.isEmpty) currentValue = '0';
    
    _keypadController.setInput(currentValue);
    setState(() {
      _keypadController.show();
    });
  }
  
  /// Hides keypad for amount editing
  void _hideKeypadForAmount() {
    setState(() {
      _keypadController.hide();
      _currentEditField = null;
    });
  }
  
  /// Handles keypad input for amount fields
  void _handleAmountKeypadInput(String key) {
    if (_currentEditField == null) return;
    
    if (key == 'backspace') {
      String? newInput = _keypadController.handleKeyPress(key);
      if (newInput != null) {
        setState(() {
          // Live update display while typing
        });
      }
    } else if (key == 'enter') {
      // Apply current input and hide keypad
      String currentInput = _keypadController.currentInput;
      if (currentInput.isNotEmpty) {
        _applyAmountInput(currentInput);
      }
      _hideKeypadForAmount();
    } else {
      // Handle digit input
      String? newInput = _keypadController.handleKeyPress(key);
      if (newInput != null) {
        setState(() {
          // Live update display while typing  
        });
      }
    }
  }
  
  /// Applies the amount input to the appropriate field
  void _applyAmountInput(String input) {
    if (_currentEditField == null) return;
    
    // Convert input to dollars (divide by 100 since input is in cents)
    double amount = double.tryParse(input) ?? 0.0;
    amount = amount / 100.0;
    
    // Ensure minimum value
    if (amount < 0.01) amount = 0.01;
    
    switch (_currentEditField) {
      case 'ante':
        setState(() {
          skatsAnte = amount;
          _skatsAnteController.text = amount.toStringAsFixed(2);
          LeaguePurseService.setPlayersAnte(amount);
        });
        break;
      case 'closestPin':
        setState(() {
          closestPin = amount;
          _closestPinController.text = amount.toStringAsFixed(2);
          LeaguePurseService.setClosestPinAmount(amount);
        });
        break;
      case 'mulligans':
        setState(() {
          mulligans = amount;
          _mulligansController.text = amount.toStringAsFixed(2);
          LeaguePurseService.setMulliganAmount(amount);
        });
        break;
    }
  }
  
  /// Gets the display value for amount field during editing
  String _getAmountDisplayValue(String fieldType, double originalValue) {
    if (_currentEditField == fieldType && _keypadController.isVisible) {
      // Show input as currency during editing
      String input = _keypadController.currentInput;
      if (input.isEmpty) return '\$0.00';
      
      double amount = double.tryParse(input) ?? 0.0;
      amount = amount / 100.0;
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '\$${originalValue.toStringAsFixed(2)}';
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
      body: Stack(
        children: [
          // Main content
          Column(
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
                    onSkatsAnteEdit: () => _showKeypadForAmount('ante'),
                    onClosestPinEdit: () => _showKeypadForAmount('closestPin'),
                    onMulligansEdit: () => _showKeypadForAmount('mulligans'),
                    onGolfCourseChanged: (String? newValue) {
                      setState(() {
                        selectedGolfCourse = newValue;
                      });
                    },
                    // Pass additional parameters for custom keypad display
                    skatsAnteDisplayValue: _getAmountDisplayValue('ante', skatsAnte),
                    closestPinDisplayValue: _getAmountDisplayValue('closestPin', closestPin),
                    mulligansDisplayValue: _getAmountDisplayValue('mulligans', mulligans),
                    isEditingAmount: _keypadController.isVisible,
                    currentEditField: _currentEditField,
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
          // Custom keypad overlay - positioned over the button bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomKeypadService.buildCustomKeypad(
              context: context,
              onKeyPress: _handleAmountKeypadInput,
              isVisible: _keypadController.isVisible,
            ),
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
        'Player Profiles',
        Icons.person,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerProfileScreen()),
        isCompact: is6InchPhoneLandscape,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerScoresScreen()),
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
        children: [
          Expanded(flex: 2, child: buttons[0]), // Player Selection - 2x wider
          Expanded(flex: 1, child: buttons[1]), // Player Scores
          Expanded(flex: 1, child: buttons[2]), // Player Profiles  
          Expanded(flex: 1, child: buttons[3]), // Golf Courses
        ],
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