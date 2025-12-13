import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wednesday_player_selection_screen.dart';
import 'wednesday_player_scores_screen.dart';
import 'wednesday_player_profile_screen.dart';
import 'wednesday_admin_screen.dart';
import '../../models/league.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/device_detection_service.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayParentScreen extends StatefulWidget {
  const WednesdayParentScreen({super.key});

  @override
  State<WednesdayParentScreen> createState() => _WednesdayParentScreenState();
}

class _WednesdayParentScreenState extends State<WednesdayParentScreen> {
  // Wednesday always plays at Golden Oaks - fixed course
  static const String fixedGolfCourse = 'Golden Oaks';

  // Editable league settings - will be loaded from LeaguePurseService
  late double playersAnte;
  late double closestPin;
  late double mulligans;

  // Controllers for edit fields
  final TextEditingController _playersAnteController = TextEditingController();
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
    _keypadController = CustomKeypadService.createController();

    // Load values from LeaguePurseService if they exist, otherwise use defaults
    playersAnte = LeaguePurseService.playersAnte;
    closestPin = LeaguePurseService.closestPinAmount;
    mulligans = LeaguePurseService.mulliganAmount;

    // If values are still at defaults (first time), initialize with reasonable defaults
    if (playersAnte == 5.0 && closestPin == 4.0 && mulligans == 2.0) {
      // Use hardcoded defaults only on first launch
      playersAnte = 5.00;
      closestPin = 1.00;
      mulligans = 2.00;

      // Save these defaults to LeaguePurseService
      LeaguePurseService.setPlayersAnte(playersAnte);
      LeaguePurseService.setClosestPinAmount(closestPin);
      LeaguePurseService.setMulliganAmount(mulligans);
    }

    _playersAnteController.text = playersAnte.toStringAsFixed(2);
    _closestPinController.text = closestPin.toStringAsFixed(2);
    _mulligansController.text = mulligans.toStringAsFixed(2);
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use unified device detection service
      final is8InchTablet = DeviceDetectionService.is8Tablet(context);

      // Lock to landscape mode for Wednesday League (matching Monday pattern)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Hide status bar for 8" tablets
      if (is8InchTablet) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }

      // Print debug info
      DeviceDetectionService.printDebugInfo(context);
    });
  }

  @override
  void dispose() {
    _playersAnteController.dispose();
    _closestPinController.dispose();
    _mulligansController.dispose();
    super.dispose();
  }

  void navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Navigates to player selection screen
  void _navigateToPlayerSelection() {
    navigateToScreen(const WednesdayPlayerSelectionScreen());
  }

  /// Shows keypad for editing amount field
  void _showKeypadForAmount(String fieldType) {
    _currentEditField = fieldType;

    // Set current input to whole dollar amount (highlighted for replacement)
    String currentValue = '';
    switch (fieldType) {
      case 'ante':
        currentValue = playersAnte.toInt().toString();
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
      _keypadController.clear();
      _keypadController.setInput('0');
      setState(() {});
    } else if (key == 'enter') {
      // Apply current input and hide keypad
      String currentInput = _keypadController.currentInput;
      if (currentInput.isNotEmpty) {
        _applyAmountInput(currentInput);
      }
      _hideKeypadForAmount();
    } else {
      // Handle digit input - replace the current value with single digit
      if (RegExp(r'^\d$').hasMatch(key)) {
        _keypadController.clear();
        _keypadController.setInput(key);
        setState(() {});
      }
    }
  }

  /// Applies the amount input to the appropriate field
  void _applyAmountInput(String input) {
    if (_currentEditField == null) return;

    // Convert input to dollars
    double amount = double.tryParse(input) ?? 0.0;
    if (amount < 0.0) amount = 0.0;

    switch (_currentEditField) {
      case 'ante':
        setState(() {
          playersAnte = amount;
          _playersAnteController.text = amount.toStringAsFixed(2);
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
        title: Text(
          'Wednesday League - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WednesdayAdminScreen(currentLeague: League.wednesday),
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
                  child: _buildPhoneContent(),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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
        title: Text(
          'Wednesday League - Golden Oaks Golf - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WednesdayAdminScreen(currentLeague: League.wednesday),
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
                  child: _buildTabletContent(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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
          'Wednesday League - Golden Oaks Golf - ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WednesdayAdminScreen(currentLeague: League.wednesday),
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
                  child: _buildTablet10Content(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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

  // Phone content layout
  Widget _buildPhoneContent() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left Column: Settings widgets
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactAnteWidget(),
                    const SizedBox(height: 4),
                    _buildCompactClosestPinWidget(),
                    const SizedBox(height: 4),
                    _buildCompactMulligansWidget(),
                    const SizedBox(height: 4),
                    _buildEmptySpacerWidget(),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Right Column: GoldenOaks Image
              Expanded(
                flex: 3,
                child: _buildGoldenOaksImage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tablet content layout (8")
  Widget _buildTabletContent() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left column with settings
              Flexible(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabletAnteWidget(),
                    const SizedBox(height: 8),
                    _buildTabletClosestPinWidget(),
                    const SizedBox(height: 8),
                    _buildTabletMulligansWidget(),
                    const SizedBox(height: 8),
                    _buildTabletEmptySpacerWidget(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Side - Golden Oaks Image
              Flexible(
                flex: 6,
                child: _buildGoldenOaksImage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tablet 10" content layout
  Widget _buildTablet10Content() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left column with settings
              Flexible(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTablet10AnteWidget(),
                      const SizedBox(height: 12),
                      _buildTablet10ClosestPinWidget(),
                      const SizedBox(height: 12),
                      _buildTablet10MulligansWidget(),
                      const SizedBox(height: 12),
                      _buildTablet10EmptySpacerWidget(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Right Side - Golden Oaks Image
              Flexible(
                flex: 6,
                child: _buildGoldenOaksImage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Compact widgets for phone
  Widget _buildCompactAnteWidget() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.orange[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Players Ante ',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: GestureDetector(
                  onTap: () => _showKeypadForAmount('ante'),
                  child: Center(
                    child: Text(
                      _getAmountDisplayValue('ante', playersAnte),
                      style: ResponsiveTypography.displayStyle(context,
                        fontWeight: FontWeight.bold,
                        color: (_keypadController.isVisible && _currentEditField == 'ante') ? Colors.blue : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactClosestPinWidget() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.orange[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Closest Pin   ',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: GestureDetector(
                  onTap: () => _showKeypadForAmount('closestPin'),
                  child: Center(
                    child: Text(
                      _getAmountDisplayValue('closestPin', closestPin),
                      style: ResponsiveTypography.displayStyle(context,
                        fontWeight: FontWeight.bold,
                        color: (_keypadController.isVisible && _currentEditField == 'closestPin') ? Colors.blue : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMulligansWidget() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.orange[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Mulligans      ',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: GestureDetector(
                  onTap: () => _showKeypadForAmount('mulligans'),
                  child: Center(
                    child: Text(
                      _getAmountDisplayValue('mulligans', mulligans),
                      style: ResponsiveTypography.displayStyle(context,
                        fontWeight: FontWeight.bold,
                        color: (_keypadController.isVisible && _currentEditField == 'mulligans') ? Colors.blue : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty spacer widget for phone (replaces removed Select Course)
  Widget _buildEmptySpacerWidget() {
    return Expanded(
      flex: 4,
      child: Container(),
    );
  }

  // Tablet widgets (8")
  Widget _buildTabletAnteWidget() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Players Ante      ',
            style: ResponsiveTypography.labelStyle(context,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showKeypadForAmount('ante'),
                child: Text(
                  _getAmountDisplayValue('ante', playersAnte),
                  style: ResponsiveTypography.displayStyle(context,
                    fontWeight: FontWeight.bold,
                    color: (_keypadController.isVisible && _currentEditField == 'ante') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTabletClosestPinWidget() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Closest Pin        ',
            style: ResponsiveTypography.labelStyle(context,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showKeypadForAmount('closestPin'),
                child: Text(
                  _getAmountDisplayValue('closestPin', closestPin),
                  style: ResponsiveTypography.displayStyle(context,
                    fontWeight: FontWeight.bold,
                    color: (_keypadController.isVisible && _currentEditField == 'closestPin') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTabletMulligansWidget() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Mulligans           ',
            style: ResponsiveTypography.labelStyle(context,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showKeypadForAmount('mulligans'),
                child: Text(
                  _getAmountDisplayValue('mulligans', mulligans),
                  style: ResponsiveTypography.displayStyle(context,
                    fontWeight: FontWeight.bold,
                    color: (_keypadController.isVisible && _currentEditField == 'mulligans') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Empty spacer widget for 8" tablet (replaces removed Select Course)
  Widget _buildTabletEmptySpacerWidget() {
    return Container(
      height: 90,
    );
  }

  // Tablet 10" widgets
  Widget _buildTablet10AnteWidget() {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Players Ante      ',
            style: ResponsiveTypography.labelStyle(context,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showKeypadForAmount('ante'),
                child: Text(
                  _getAmountDisplayValue('ante', playersAnte),
                  style: ResponsiveTypography.displayStyle(context,
                    fontWeight: FontWeight.bold,
                    color: (_keypadController.isVisible && _currentEditField == 'ante') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTablet10ClosestPinWidget() {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Closest Pin        ',
            style: ResponsiveTypography.labelStyle(context,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showKeypadForAmount('closestPin'),
                child: Text(
                  _getAmountDisplayValue('closestPin', closestPin),
                  style: ResponsiveTypography.displayStyle(context,
                    fontWeight: FontWeight.bold,
                    color: (_keypadController.isVisible && _currentEditField == 'closestPin') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTablet10MulligansWidget() {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Mulligans           ',
            style: ResponsiveTypography.labelStyle(context,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showKeypadForAmount('mulligans'),
                child: Text(
                  _getAmountDisplayValue('mulligans', mulligans),
                  style: ResponsiveTypography.displayStyle(context,
                    fontWeight: FontWeight.bold,
                    color: (_keypadController.isVisible && _currentEditField == 'mulligans') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Empty spacer widget for 10" tablet (replaces removed Select Course)
  Widget _buildTablet10EmptySpacerWidget() {
    return Container(
      height: 120,
    );
  }

  Widget _buildGoldenOaksImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/GoldenOaks.png',
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Center(
              child: Icon(
                Icons.park,
                size: 60,
                color: Colors.orange[600],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneFooterButtons() {
    final buttons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        Colors.orange[300]!,
        () => _navigateToPlayerSelection(),
        isCompact: true,
        is8InchTablet: false,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.orange[100]!,
        () => navigateToScreen(const WednesdayPlayerProfileScreen()),
        isCompact: true,
        is8InchTablet: false,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.orange[100]!,
        () => navigateToScreen(const WednesdayPlayerScoresScreen()),
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
      ],
    );
  }

  Widget _buildTablet8FooterButtons() {
    final buttons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        Colors.orange[300]!,
        () => _navigateToPlayerSelection(),
        isCompact: false,
        is8InchTablet: true,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.orange[100]!,
        () => navigateToScreen(const WednesdayPlayerProfileScreen()),
        isCompact: false,
        is8InchTablet: true,
        is10InchTablet: false,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.orange[100]!,
        () => navigateToScreen(const WednesdayPlayerScoresScreen()),
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
      ],
    );
  }

  Widget _buildTablet10FooterButtons() {
    final buttons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        Colors.orange[300]!,
        () => _navigateToPlayerSelection(),
        isCompact: false,
        is8InchTablet: false,
        is10InchTablet: true,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.orange[100]!,
        () => navigateToScreen(const WednesdayPlayerProfileScreen()),
        isCompact: false,
        is8InchTablet: false,
        is10InchTablet: true,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.orange[100]!,
        () => navigateToScreen(const WednesdayPlayerScoresScreen()),
        isCompact: false,
        is8InchTablet: false,
        is10InchTablet: true,
      ),
    ];

    return Row(
      children: [
        Expanded(flex: 2, child: buttons[0]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[1]),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: buttons[2]),
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
          vertical: is10InchTablet ? 24 : (is8InchTablet ? 20 : (isCompact ? 3 : 6)),
          horizontal: 2,
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
