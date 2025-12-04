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
import '../../services/UI/parent_screen_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/responsive_typography.dart';
import '../../widgets/responsive_wrapper.dart';

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
      final screenWidth = MediaQuery.of(context).size.width;
      final is8InchTablet = screenWidth >= 600 && screenWidth <= 1000;
      
      // Lock to landscape mode for Monday League
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Hide status bar for 8" tablets
      if (is8InchTablet) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
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
    
    // Set current input to whole dollar amount (highlighted for replacement)
    String currentValue = '';
    switch (fieldType) {
      case 'ante':
        currentValue = skatsAnte.toInt().toString();
        break;
      case 'closestPin':
        currentValue = closestPin.toInt().toString();
        break;
      case 'mulligans':
        currentValue = mulligans.toInt().toString();
        break;
    }
    
    _keypadController.clear(); // Clear for fresh input
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
      // Reset to $0.00 for whole dollar amounts
      _keypadController.clear(); // Clear first to ensure clean state
      _keypadController.setInput('0');
      setState(() {
        // Live update display while typing
      });
    } else if (key == 'enter') {
      // Apply current input and hide keypad
      String currentInput = _keypadController.currentInput;
      if (currentInput.isNotEmpty) {
        _applyAmountInput(currentInput);
      }
      _hideKeypadForAmount();
    } else {
      // Handle digit input - replace the current value with single digit
      if (RegExp(r'^\d$').hasMatch(key)) { // Single digit 0-9
        _keypadController.clear();
        _keypadController.setInput(key);
        setState(() {
          // Live update display while typing  
        });
      }
    }
  }
  
  /// Applies the amount input to the appropriate field
  void _applyAmountInput(String input) {
    if (_currentEditField == null) return;
    
    // Convert input to dollars (input is already in dollars)
    double amount = double.tryParse(input) ?? 0.0;
    
    // Allow $0.00 values
    if (amount < 0.0) amount = 0.0;
    
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
  
  /// Updates Closest Pin amount based on selected golf course Par3s
  Future<void> _updateClosestPinFromGolfCourse(String courseName) async {
    try {
      final courses = await DatabaseHelper().getAllGolfCourses();
      final selectedCourse = courses.firstWhere(
        (course) => course['name'] == courseName,
        orElse: () => <String, dynamic>{},
      );
      
      if (selectedCourse.isNotEmpty && selectedCourse['holes'] != null) {
        final par3s = selectedCourse['holes'] as int;
        final newClosestPin = par3s * 1.00; // Multiply by $1.00
        
        setState(() {
          closestPin = newClosestPin;
          _closestPinController.text = closestPin.toStringAsFixed(2);
          LeaguePurseService.setClosestPinAmount(closestPin);
        });
      }
    } catch (e) {
      // Silently handle errors to avoid interrupting user experience
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating Closest Pin amount: $e')),
        );
      }
    }
  }

  /// Gets the display value for amount field during editing
  String _getAmountDisplayValue(String fieldType, double originalValue) {
    if (_currentEditField == fieldType && _keypadController.isVisible) {
      // Show input as currency during editing
      String input = _keypadController.currentInput;
      if (input.isEmpty) return '\$0.00';
      
      double amount = double.tryParse(input) ?? 0.0;
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '\$${originalValue.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet8: _buildTablet8Layout(),
      tablet10: _buildTablet10Layout(),
    );
  }

  Widget _buildPhoneLayout() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
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
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminScreen(currentLeague: League.monday),
              ),
            ),
            tooltip: 'Administration',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ParentScreenUI(
                    selectedGolfCourse: selectedGolfCourse,
                    golfCourses: golfCourses,
                    isLoadingCourses: isLoadingCourses,
                    skatsAnte: skatsAnte,
                    closestPin: closestPin,
                    mulligans: mulligans,
                    leagueTitle: '',
                    anteLabel: 'Players Ante ',
                    onSkatsAnteEdit: () => _showKeypadForAmount('ante'),
                    onClosestPinEdit: () => _showKeypadForAmount('closestPin'),
                    onMulligansEdit: () => _showKeypadForAmount('mulligans'),
                    onGolfCourseChanged: (String? newValue) async {
                      setState(() {
                        selectedGolfCourse = newValue;
                      });
                      if (newValue != null) {
                        await _updateClosestPinFromGolfCourse(newValue);
                      }
                    },
                    skatsAnteDisplayValue: _getAmountDisplayValue('ante', skatsAnte),
                    closestPinDisplayValue: _getAmountDisplayValue('closestPin', closestPin),
                    mulligansDisplayValue: _getAmountDisplayValue('mulligans', mulligans),
                    isEditingAmount: _keypadController.isVisible,
                    currentEditField: _currentEditField,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(0),
                ),
                child: _buildPhoneFooterButtons(),
              ),
            ],
          ),
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

  Widget _buildTablet8Layout() {
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
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminScreen(currentLeague: League.monday),
              ),
            ),
            tooltip: 'Administration',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ParentScreenUI(
                    selectedGolfCourse: selectedGolfCourse,
                    golfCourses: golfCourses,
                    isLoadingCourses: isLoadingCourses,
                    skatsAnte: skatsAnte,
                    closestPin: closestPin,
                    mulligans: mulligans,
                    leagueTitle: '',
                    anteLabel: 'Players Ante      ',
                    onSkatsAnteEdit: () => _showKeypadForAmount('ante'),
                    onClosestPinEdit: () => _showKeypadForAmount('closestPin'),
                    onMulligansEdit: () => _showKeypadForAmount('mulligans'),
                    onGolfCourseChanged: (String? newValue) async {
                      setState(() {
                        selectedGolfCourse = newValue;
                      });
                      if (newValue != null) {
                        await _updateClosestPinFromGolfCourse(newValue);
                      }
                    },
                    skatsAnteDisplayValue: _getAmountDisplayValue('ante', skatsAnte),
                    closestPinDisplayValue: _getAmountDisplayValue('closestPin', closestPin),
                    mulligansDisplayValue: _getAmountDisplayValue('mulligans', mulligans),
                    isEditingAmount: _keypadController.isVisible,
                    currentEditField: _currentEditField,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(0),
                ),
                child: _buildTablet8FooterButtons(),
              ),
            ],
          ),
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

  Widget _buildTablet10Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Monday League - Golden Oaks Golf',
          style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminScreen(currentLeague: League.monday),
              ),
            ),
            tooltip: 'Administration',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ParentScreenUI(
                    selectedGolfCourse: selectedGolfCourse,
                    golfCourses: golfCourses,
                    isLoadingCourses: isLoadingCourses,
                    skatsAnte: skatsAnte,
                    closestPin: closestPin,
                    mulligans: mulligans,
                    leagueTitle: '',
                    anteLabel: 'Players Ante      ',
                    onSkatsAnteEdit: () => _showKeypadForAmount('ante'),
                    onClosestPinEdit: () => _showKeypadForAmount('closestPin'),
                    onMulligansEdit: () => _showKeypadForAmount('mulligans'),
                    onGolfCourseChanged: (String? newValue) async {
                      setState(() {
                        selectedGolfCourse = newValue;
                      });
                      if (newValue != null) {
                        await _updateClosestPinFromGolfCourse(newValue);
                      }
                    },
                    skatsAnteDisplayValue: _getAmountDisplayValue('ante', skatsAnte),
                    closestPinDisplayValue: _getAmountDisplayValue('closestPin', closestPin),
                    mulligansDisplayValue: _getAmountDisplayValue('mulligans', mulligans),
                    isEditingAmount: _keypadController.isVisible,
                    currentEditField: _currentEditField,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(0),
                ),
                child: _buildTablet10FooterButtons(),
              ),
            ],
          ),
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

  Widget _buildPhoneFooterButtons() {
    final buttons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        selectedGolfCourse != null ? Colors.green[300]! : Colors.grey[400]!,
        selectedGolfCourse != null ? () => _navigateToPlayerSelection() : null,
        isCompact: true,
        is8InchTablet: false,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerProfileScreen()),
        isCompact: true,
        is8InchTablet: false,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerScoresScreen()),
        isCompact: true,
        is8InchTablet: false,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Golf Courses',
        Icons.golf_course,
        Colors.green[100]!,
        () => navigateToScreen(const MondayGolfCourseScreen()),
        isCompact: true,
        is8InchTablet: false,
        is10InchTablet: false,
      ),
    ];

    return Row(
      children: [
        Expanded(flex: 2, child: buttons[0]),
        Expanded(flex: 1, child: buttons[1]),
        Expanded(flex: 1, child: buttons[2]),
        Expanded(flex: 1, child: buttons[3]),
      ],
    );
  }

  Widget _buildTablet8FooterButtons() {
    final buttons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        selectedGolfCourse != null ? Colors.green[300]! : Colors.grey[400]!,
        selectedGolfCourse != null ? () => _navigateToPlayerSelection() : null,
        isCompact: false,
        is8InchTablet: true,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerProfileScreen()),
        isCompact: false,
        is8InchTablet: true,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerScoresScreen()),
        isCompact: false,
        is8InchTablet: true,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Golf Courses',
        Icons.golf_course,
        Colors.green[100]!,
        () => navigateToScreen(const MondayGolfCourseScreen()),
        isCompact: false,
        is8InchTablet: true,
        is10InchTablet: false,
      ),
    ];

    return Row(
      children: [
        Expanded(flex: 2, child: buttons[0]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[1]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[2]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[3]),
      ],
    );
  }

  Widget _buildTablet10FooterButtons() {
    final buttons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        selectedGolfCourse != null ? Colors.green[300]! : Colors.grey[400]!,
        selectedGolfCourse != null ? () => _navigateToPlayerSelection() : null,
        isCompact: false,
        is8InchTablet: false,
        is10InchTablet: true,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerProfileScreen()),
        isCompact: false,
        is8InchTablet: false,
        is10InchTablet: true,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.green[100]!,
        () => navigateToScreen(const MondayPlayerScoresScreen()),
        isCompact: false,
        is8InchTablet: false,
        is10InchTablet: true,
      ),
      _buildNavigationButton(
        'Golf Courses',
        Icons.golf_course,
        Colors.green[100]!,
        () => navigateToScreen(const MondayGolfCourseScreen()),
        isCompact: false,
        is8InchTablet: false,
        is10InchTablet: true,
      ),
    ];

    return Row(
      children: [
        Expanded(flex: 2, child: buttons[0]), // Player Selection - double width
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[1]), // Player Profiles
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[2]), // Player Scores
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[3]), // Golf Courses
      ],
    );
  }

  Widget _buildNavigationButton(String title, IconData icon, Color bgColor, VoidCallback? onPressed, {bool isCompact = false, bool is8InchTablet = false, bool is10InchTablet = false}) {
    final isDisabled = onPressed == null;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: isDisabled ? Colors.grey[600] : Colors.black,
        padding: EdgeInsets.symmetric(
          vertical: is10InchTablet ? 24 : (is8InchTablet ? 20 : (isCompact ? 3 : 6)), // Increased height for 10" tablets
          horizontal: 2, // Force minimal padding for all layouts
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
          Text(
            title,
            style: ResponsiveTypography.buttonStyle(context, 
                fontWeight: FontWeight.w600, 
                color: isDisabled ? Colors.grey[600] : null),
            textAlign: TextAlign.center,
          ),
        ],
        ),
    );
  }
}