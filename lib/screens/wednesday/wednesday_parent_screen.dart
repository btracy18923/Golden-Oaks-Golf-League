import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wednesday_player_selection_screen.dart';
import 'wednesday_player_scores_screen.dart';
import 'wednesday_player_profile_screen.dart';
import 'wednesday_admin_screen.dart';
import '../../models/league.dart';
import '../../config/app_config.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/device_detection_service.dart';
import '../../services/firebase_download_service.dart';
import '../../services/firebase_upload_service.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayParentScreen extends StatefulWidget {
  const WednesdayParentScreen({super.key});

  @override
  State<WednesdayParentScreen> createState() => _WednesdayParentScreenState();
}

class _WednesdayParentScreenState extends State<WednesdayParentScreen> {
  // Wednesday always plays at Golden Oaks - fixed course

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
    _checkAndDownloadWednesdayData();
    _keypadController = CustomKeypadService.createController();
    _loadPersistedAmounts();

    // Load values from LeaguePurseService for Wednesday league - these persist during the app session
    playersAnte = LeaguePurseService.getPlayersAnte(league: League.wednesday);
    closestPin = LeaguePurseService.getClosestPinAmount(league: League.wednesday);
    mulligans = LeaguePurseService.getMulliganAmount(league: League.wednesday);

    _playersAnteController.text = playersAnte.toStringAsFixed(2);
    _closestPinController.text = closestPin.toStringAsFixed(2);
    _mulligansController.text = mulligans.toStringAsFixed(2);
  }

  /// Loads persisted amounts from storage and updates UI
  Future<void> _loadPersistedAmounts() async {
    await LeaguePurseService.loadPersistedAmounts(League.wednesday);

    // Update local variables and controllers with loaded values
    setState(() {
      playersAnte = LeaguePurseService.getPlayersAnte(league: League.wednesday);
      closestPin = LeaguePurseService.getClosestPinAmount(league: League.wednesday);
      mulligans = LeaguePurseService.getMulliganAmount(league: League.wednesday);

      _playersAnteController.text = playersAnte.toStringAsFixed(2);
      _closestPinController.text = closestPin.toStringAsFixed(2);
      _mulligansController.text = mulligans.toStringAsFixed(2);
    });
  }

  /// Always download Wednesday league data from Firebase on screen load (background, silent)
  Future<void> _checkAndDownloadWednesdayData() async {
    try {
      await FirebaseDownloadService().downloadWednesdayLeagueData();
    } catch (e) {
      debugPrint('Background Wednesday sync failed: $e');
    }
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Wednesday League (matching Monday pattern)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

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
          LeaguePurseService.setPlayersAnte(amount, league: League.wednesday);
        });
        break;
      case 'closestPin':
        setState(() {
          closestPin = amount;
          _closestPinController.text = amount.toStringAsFixed(2);
          LeaguePurseService.setClosestPinAmount(amount, league: League.wednesday);
        });
        break;
      case 'mulligans':
        setState(() {
          mulligans = amount;
          _mulligansController.text = amount.toStringAsFixed(2);
          LeaguePurseService.setMulliganAmount(amount, league: League.wednesday);
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
      tablet10: _buildTablet10Layout(),
    );
  }

  Widget _buildPhoneLayout() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Wednesday League - ${AppConfig.versionDate}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: FirebaseUploadService.uploadsEnabled ? Colors.orange[700] : Colors.red[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WednesdayAdminScreen(currentLeague: League.wednesday),
                ),
              );
              if (mounted) setState(() {});
            },
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
        title: Text(
          'Wednesday League - Golden Oaks Golf - ${AppConfig.versionDate}',
          style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.bold),
        ),
        backgroundColor: FirebaseUploadService.uploadsEnabled ? Colors.orange[700] : Colors.red[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WednesdayAdminScreen(currentLeague: League.wednesday),
                ),
              );
              if (mounted) setState(() {});
            },
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
    return const Expanded(
      flex: 4,
      child: SizedBox.expand(),
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
    return const SizedBox(
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

  Widget _buildFooterButtons() {
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[300]!,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Player Selection',
          color: Colors.orange[300]!,
          onPressed: () => _navigateToPlayerSelection(),
          flex: 14,
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Player Profiles',
          color: Colors.orange[100]!,
          onPressed: () => navigateToScreen(const WednesdayPlayerProfileScreen()),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Player Scores',
          color: Colors.orange[100]!,
          onPressed: () => navigateToScreen(const WednesdayPlayerScoresScreen()),
        ),
      ],
    );
  }
}
