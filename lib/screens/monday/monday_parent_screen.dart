import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'monday_player_selection_screen.dart';
import 'monday_player_scores_screen.dart';
import 'monday_player_profile_screen.dart';
import 'monday_golf_course_screen.dart';
import 'monday_admin_screen.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/UI/parent_screen_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/device_detection_service.dart';
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

  // Editable league settings - will be loaded from LeaguePurseService
  late double skatsAnte;
  late double closestPin;
  late double mulligans;
  
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

    // Load values from LeaguePurseService for Monday league - these persist during the app session
    skatsAnte = LeaguePurseService.getPlayersAnte(league: League.monday);
    closestPin = LeaguePurseService.getClosestPinAmount(league: League.monday);
    mulligans = LeaguePurseService.getMulliganAmount(league: League.monday);

    _skatsAnteController.text = skatsAnte.toStringAsFixed(2);
    _closestPinController.text = closestPin.toStringAsFixed(2);
    _mulligansController.text = mulligans.toStringAsFixed(2);
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use unified device detection service
      final is8InchTablet = DeviceDetectionService.is8Tablet(context);
      
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
          LeaguePurseService.setPlayersAnte(amount, league: League.monday);
        });
        break;
      case 'closestPin':
        setState(() {
          closestPin = amount;
          _closestPinController.text = amount.toStringAsFixed(2);
          LeaguePurseService.setClosestPinAmount(amount, league: League.monday);
        });
        break;
      case 'mulligans':
        setState(() {
          mulligans = amount;
          _mulligansController.text = amount.toStringAsFixed(2);
          LeaguePurseService.setMulliganAmount(amount, league: League.monday);
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
          LeaguePurseService.setClosestPinAmount(closestPin, league: League.monday);
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
        toolbarHeight: 56,
        title: Text(
          'Monday League - Golden Oaks Golf - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                builder: (context) => const MondayAdminScreen(currentLeague: League.monday),
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
              _buildFooterButtons(),
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
        toolbarHeight: 60,
        title: Text(
          'Monday League - Golden Oaks Golf - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                builder: (context) => const MondayAdminScreen(currentLeague: League.monday),
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
              _buildFooterButtons(),
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
        toolbarHeight: 64,
        title: Text(
          'Monday League - Golden Oaks Golf - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
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
                builder: (context) => const MondayAdminScreen(currentLeague: League.monday),
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
              _buildFooterButtons(),
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

  Widget _buildFooterButtons() {
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[300]!,
      children: [
        Expanded(
          flex: 2,
          child: ButtonBarUIService.buildActionButton(
            context,
            text: 'Player Selection',
            color: selectedGolfCourse != null ? Colors.green[300]! : Colors.grey[400]!,
            onPressed: selectedGolfCourse != null ? () => _navigateToPlayerSelection() : null,
          ),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Player Profiles',
          color: Colors.green[100]!,
          onPressed: () => navigateToScreen(const MondayPlayerProfileScreen()),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Player Scores',
          color: Colors.green[100]!,
          onPressed: () => navigateToScreen(const MondayPlayerScoresScreen()),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Golf Courses',
          color: Colors.green[100]!,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MondayGolfCourseScreen(league: League.monday)),
            );
            // Reload golf courses when returning from golf course screen
            _loadGolfCourses();
          },
        ),
      ],
    );
  }
}