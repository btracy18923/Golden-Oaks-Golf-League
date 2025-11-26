import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/league.dart';
import '../services/ante_manager.dart';
import '../services/percentage_manager.dart';
import '../services/closest_pin_manager.dart';
import '../services/mulligan_manager.dart';
import 'monday/monday_parent_screen.dart';
import 'monday/monday_player_selection_screen.dart';
import 'wednesday/wednesday_parent_screen.dart';
import 'wednesday/wednesday_player_selection_screen.dart';
import 'admin_screen.dart';
import 'csv_import_screen.dart';
import 'firebase_test_screen.dart';
import 'test_keypad_screen.dart';

class UnifiedMainMenuScreen extends StatefulWidget {
  const UnifiedMainMenuScreen({super.key});

  @override
  State<UnifiedMainMenuScreen> createState() => _UnifiedMainMenuScreenState();
}

class _UnifiedMainMenuScreenState extends State<UnifiedMainMenuScreen> {
  League? currentLeague;
  final TextEditingController _anteController = TextEditingController(text: '\$5.00');
  final TextEditingController _closestPinController = TextEditingController(text: '\$4.00');
  final TextEditingController _newFieldController = TextEditingController(text: '\$1.00');
  final TextEditingController _mondayMulligansController = TextEditingController(text: '\$2.00');
  final TextEditingController _individualPercentController = TextEditingController(text: '40%');
  final TextEditingController _groupPercentController = TextEditingController(text: '60%');
  final FocusNode _anteFocusNode = FocusNode();
  final FocusNode _closestPinFocusNode = FocusNode();
  final FocusNode _newFieldFocusNode = FocusNode();
  final FocusNode _mondayMulligansFocusNode = FocusNode();
  final FocusNode _individualPercentFocusNode = FocusNode();
  final FocusNode _groupPercentFocusNode = FocusNode();

  void _formatCurrency() {
    String text = _anteController.text;
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double amount = double.tryParse(numericText) ?? 0.0;
      String formatted = '\$${amount.toStringAsFixed(2)}';
      
      if (formatted != _anteController.text) {
        _anteController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      
      AnteManager().setAnteAmount(amount);
    } else if (text.isEmpty) {
      String defaultAmount = currentLeague == League.monday ? '\$5.00' : '\$5.00';
      double defaultValue = currentLeague == League.monday ? 5.0 : 5.0;
      
      _anteController.value = TextEditingValue(
        text: defaultAmount,
        selection: TextSelection.collapsed(offset: defaultAmount.length),
      );
      
      AnteManager().setAnteAmount(defaultValue);
    }
    
    _anteFocusNode.unfocus();
  }

  void _formatClosestPinCurrency() {
    String text = _closestPinController.text;
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double amount = double.tryParse(numericText) ?? 0.0;
      String formatted = '\$${amount.toStringAsFixed(2)}';
      
      if (formatted != _closestPinController.text) {
        _closestPinController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      
      ClosestPinManager().setClosestPinAmount(amount);
    } else if (text.isEmpty) {
      String defaultAmount = currentLeague == League.monday ? '\$4.00' : '\$1.00';
      double defaultValue = currentLeague == League.monday ? 4.0 : 1.0;
      
      _closestPinController.value = TextEditingValue(
        text: defaultAmount,
        selection: TextSelection.collapsed(offset: defaultAmount.length),
      );
      
      ClosestPinManager().setClosestPinAmount(defaultValue);
    }
    
    _closestPinFocusNode.unfocus();
  }

  void _formatNewFieldCurrency() {
    String text = _newFieldController.text;
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double amount = double.tryParse(numericText) ?? 0.0;
      String formatted = '\$${amount.toStringAsFixed(2)}';
      
      if (formatted != _newFieldController.text) {
        _newFieldController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    } else if (text.isEmpty) {
      String defaultAmount = '\$1.00';
      
      _newFieldController.value = TextEditingValue(
        text: defaultAmount,
        selection: TextSelection.collapsed(offset: defaultAmount.length),
      );
    }
    
    _newFieldFocusNode.unfocus();
  }

  void _onNewFieldTap() {
    _newFieldController.clear();
    _newFieldFocusNode.requestFocus();
  }

  void _onAnteTap() {
    _anteController.clear();
    _anteFocusNode.requestFocus();
  }

  void _onClosestPinTap() {
    _closestPinController.clear();
    _closestPinFocusNode.requestFocus();
  }

  void _formatMondayMulligansCurrency() {
    String text = _mondayMulligansController.text;
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double amount = double.tryParse(numericText) ?? 0.0;
      String formatted = '\$${amount.toStringAsFixed(2)}';
      
      if (formatted != _mondayMulligansController.text) {
        _mondayMulligansController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    } else if (text.isEmpty) {
      String defaultAmount = '\$2.00';
      
      _mondayMulligansController.value = TextEditingValue(
        text: defaultAmount,
        selection: TextSelection.collapsed(offset: defaultAmount.length),
      );
    }
    
    _mondayMulligansFocusNode.unfocus();
  }

  void _onMondayMulligansTap() {
    _mondayMulligansController.clear();
    _mondayMulligansFocusNode.requestFocus();
  }


  double get currentAnteAmount {
    String text = _anteController.text;
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    return double.tryParse(numericText) ?? (currentLeague == League.monday ? 5.0 : 5.0);
  }

  @override
  void initState() {
    super.initState();
    
    // Lock all devices to landscape mode only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    // Keep landscape mode locked - don't reset orientation constraints
    
    _anteController.dispose();
    _closestPinController.dispose();
    _newFieldController.dispose();
    _mondayMulligansController.dispose();
    _individualPercentController.dispose();
    _groupPercentController.dispose();
    _anteFocusNode.dispose();
    _closestPinFocusNode.dispose();
    _newFieldFocusNode.dispose();
    _mondayMulligansFocusNode.dispose();
    _individualPercentFocusNode.dispose();
    _groupPercentFocusNode.dispose();
    super.dispose();
  }

  void selectMondayLeague() async {
    AnteManager().setAnteAmount(5.0);
    ClosestPinManager().setClosestPinAmount(4.0);
    MulliganManager().setMulliganAmount(2.0);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MondayParentScreen()),
    );
  }

  void selectWednesdayLeague() async {
    AnteManager().setAnteAmount(5.0);
    ClosestPinManager().setClosestPinAmount(1.0);
    MulliganManager().setMulliganAmount(1.0);
    PercentageManager().setIndividualPercent(40.0);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WednesdayParentScreen()),
    );
  }

  void navigateToScreen(Widget screen) {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    
    // Define breakpoints based on logical pixel dimensions (Flutter's dp units)
    // Your 6.5" phone: 820.57 × 411.43 logical pixels in landscape
    // 8" tablet: Estimated ~533 × 800 logical pixels in landscape (800×1200 physical / 1.5 density)
    // 10" tablet: Larger than both
    final isLandscape = orientation == Orientation.landscape;
    final is6Point5Phone = isLandscape && screenWidth >= 750 && screenWidth < 900; // 6.5" phone range
    final is8Tablet = isLandscape && screenWidth >= 500 && screenWidth < 750; // 8" tablet range  
    final is10Tablet = isLandscape && screenWidth >= 900; // 10" tablets (larger screens)
    
    // Debug output to verify device detection
    print('DEVICE DEBUG: Screen ${screenWidth}x$screenHeight, Landscape: $isLandscape');
    print('DEVICE DEBUG: 6.5" Phone: $is6Point5Phone, 8" Tablet: $is8Tablet, 10" Tablet: $is10Tablet');
    
    // For backwards compatibility, keep these variables
    final isPhone = is6Point5Phone;
    final isTablet8 = is8Tablet;
    final isTablet10 = is10Tablet;
    final isPortrait = orientation == Orientation.portrait;
    
    // Hide status bar for 6" phones
    if (isPhone) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Golden Oaks Golf League',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isPhone ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Icon(
            Icons.storage,
            color: Colors.white,
            size: isPhone ? 24 : 28,
          ),
          SizedBox(width: isPhone ? 12 : 16),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isPhone ? 8.0 : 16.0),
        child: isPhone 
          ? (isPortrait ? _buildPhoneLayout(context) : _buildPhoneLandscapeLayout(context))
          : (isTablet8 && isPortrait)
            ? _buildTabletPortraitLayout(context)
            : _buildTabletLayout(context, isTablet10, isTablet8),
      ),
    );
  }

  Widget _buildPhoneLandscapeLayout(BuildContext context) {
    return Column(
      children: [
        // Top area - League selection, config, and image
        Expanded(
          child: Row(
            children: [
              // Left side - League selection and configuration
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildLeagueSelectionCompact(context),
                      
                      const SizedBox(height: 6),
                      
                      if (currentLeague != null) _buildLeagueConfigurationCompact(context),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Right side - Image only
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/GoldenOaks.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.park,
                              size: 40,
                              color: Colors.green[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Bottom row - Admin Functions
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5, // All 5 buttons in one row
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 3.0, // 50% height reduction
            children: [
              _buildCompactAdminButton('Firebase', Icons.cloud_upload, Colors.red[200]!, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FirebaseTestScreen()))),
              _buildCompactAdminButton('CSV', Icons.upload_file, Colors.blue[200]!, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CsvImportScreen()))),
              _buildCompactAdminButton('Players', Icons.people, 
                currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                () => navigateToScreen(currentLeague == League.monday ? const MondayPlayerSelectionScreen() : const WednesdayPlayerSelectionScreen())),
              _buildCompactAdminButton('Admin', Icons.settings, 
                currentLeague == League.monday ? Colors.green[100]! : currentLeague == League.wednesday ? Colors.orange[100]! : Colors.grey[200]!,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen(currentLeague: currentLeague)))),
              _buildCompactAdminButton('Speech', Icons.keyboard_voice, Colors.purple[200]!, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TestKeypadScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      children: [
        // League Selection and Configuration - Fixed at top
        _buildLeagueSelection(context, true),
        
        const SizedBox(height: 12),
        
        if (currentLeague != null) _buildLeagueConfiguration(context, true),
        
        if (currentLeague != null) const SizedBox(height: 12),
        
        // Golden Oaks Image - Fill remaining space
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/GoldenOaks.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.park,
                        size: 100,
                        color: Colors.green[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Admin Functions - Fixed at bottom
        _buildAdminFunctionsPhone(context),
      ],
    );
  }

  Widget _buildTabletPortraitLayout(BuildContext context) {
    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: Column(
            children: [
              // League Selection Section
              _buildLeagueSelection(context, false),
              
              const SizedBox(height: 16),
              
              // League Configuration (if league selected)
              if (currentLeague != null) _buildLeagueConfiguration(context, false),
              
              const SizedBox(height: 16),
              
              // Golden Oaks Image - Fill remaining space
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/GoldenOaks.png',
                      fit: BoxFit.contain,
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
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
        
        // Admin Functions - Single Row at Bottom
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5, // 5 columns for single row
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0, // Square buttons
            children: [
              _buildAdminButton(
                'Firebase Upload',
                Icons.cloud_upload,
                Colors.red[200]!,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FirebaseTestScreen()),
                ),
              ),
              _buildAdminButton(
                'CSV Import',
                Icons.upload_file,
                Colors.blue[200]!,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CsvImportScreen()),
                ),
              ),
              _buildAdminButton(
                'Player Selection',
                Icons.people,
                currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                () => navigateToScreen(
                  currentLeague == League.monday 
                    ? const MondayPlayerSelectionScreen()
                    : const WednesdayPlayerSelectionScreen(),
                ),
              ),
              _buildAdminButton(
                'Administration',
                Icons.settings,
                currentLeague == League.monday ? Colors.green[100]! : currentLeague == League.wednesday ? Colors.orange[100]! : Colors.grey[200]!,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminScreen(currentLeague: currentLeague)),
                ),
              ),
              _buildAdminButton(
                'Test Speech',
                Icons.keyboard_voice,
                Colors.purple[200]!,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestKeypadScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isTablet10, bool isTablet8) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLeagueSelection(context, false),
                      if (currentLeague != null) ...[
                        const SizedBox(height: 16),
                        _buildLeagueConfiguration(context, false),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
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
        
        _buildAdminFunctionsTablet(context, isTablet10, isTablet8),
      ],
    );
  }

  Widget _buildLeagueSelection(BuildContext context, bool isPhone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Your League:',
          style: TextStyle(
            fontSize: isPhone ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isPhone ? 12 : 16),
        
        isPhone 
          ? Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: selectMondayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLeague == League.monday 
                          ? Colors.green[300] 
                          : Colors.green[100],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Monday Group',
                      style: TextStyle(
                        fontSize: isPhone ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectWednesdayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLeague == League.wednesday 
                          ? Colors.orange[300] 
                          : Colors.orange[100],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Wednesday Group',
                      style: TextStyle(
                        fontSize: isPhone ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: selectMondayLeague,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentLeague == League.monday 
                            ? Colors.green[300] 
                            : Colors.green[100],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Monday Group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: selectWednesdayLeague,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentLeague == League.wednesday 
                            ? Colors.orange[300] 
                            : Colors.orange[100],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Wednesday Group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        
        SizedBox(height: isPhone ? 8 : 12),
        
        Container(
          padding: EdgeInsets.all(isPhone ? 8 : 12),
          decoration: BoxDecoration(
            color: currentLeague == League.monday 
                ? Colors.green[300] 
                : currentLeague == League.wednesday 
                    ? Colors.orange[300] 
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: Text(
            currentLeague != null 
                ? 'Active League: ${currentLeague!.name.toUpperCase()}'
                : 'No League Selected',
            style: TextStyle(
              fontSize: isPhone ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueConfiguration(BuildContext context, bool isPhone) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(isPhone ? 8 : 12),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Text(
                  currentLeague == League.monday ? 'Skats Ante' : 'Player\'s Ante',
                  style: TextStyle(
                    fontSize: isPhone ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              flex: 1,
              child: Container(
                height: isPhone ? 40 : 48,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _anteController,
                  focusNode: _anteFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                  ],
                  style: TextStyle(
                    fontSize: isPhone ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  onTap: _onAnteTap,
                  onEditingComplete: _formatCurrency,
                  enabled: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isPhone ? 12 : 16),
        
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(isPhone ? 8 : 12),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Text(
                  'Closest Pin',
                  style: TextStyle(
                    fontSize: isPhone ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              flex: 1,
              child: Container(
                height: isPhone ? 40 : 48,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _closestPinController,
                  focusNode: _closestPinFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                  ],
                  style: TextStyle(
                    fontSize: isPhone ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  onTap: _onClosestPinTap,
                  onEditingComplete: _formatClosestPinCurrency,
                  enabled: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (currentLeague == League.monday) ...[
          SizedBox(height: isPhone ? 8 : 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(isPhone ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Mulligans',
                    style: TextStyle(
                      fontSize: isPhone ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Expanded(
                flex: 1,
                child: Container(
                  height: isPhone ? 40 : 48,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _mondayMulligansController,
                    focusNode: _mondayMulligansFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                    ],
                    style: TextStyle(
                      fontSize: isPhone ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    onTap: _onMondayMulligansTap,
                    onEditingComplete: _formatMondayMulligansCurrency,
                    enabled: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        
        if (currentLeague == League.wednesday) ...[
          SizedBox(height: isPhone ? 8 : 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(isPhone ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.orange[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Mulligans',
                    style: TextStyle(
                      fontSize: isPhone ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Expanded(
                flex: 1,
                child: Container(
                  height: isPhone ? 40 : 48,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _newFieldController,
                    focusNode: _newFieldFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                    ],
                    style: TextStyle(
                      fontSize: isPhone ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    onTap: _onNewFieldTap,
                    onEditingComplete: _formatNewFieldCurrency,
                    enabled: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdminFunctionsPhone(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // First row - 3 buttons
          SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: _buildPhoneGridButton(
                    'Firebase Upload',
                    Icons.cloud_upload,
                    Colors.red[200]!,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FirebaseTestScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildPhoneGridButton(
                    'CSV Import',
                    Icons.upload_file,
                    Colors.blue[200]!,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CsvImportScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildPhoneGridButton(
                    'Player Selection',
                    Icons.people,
                    currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                    () => navigateToScreen(
                      currentLeague == League.monday 
                        ? const MondayPlayerSelectionScreen()
                        : const WednesdayPlayerSelectionScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Second row - 2 buttons
          SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: _buildPhoneGridButton(
                    'Administration',
                    Icons.settings,
                    currentLeague == League.monday ? Colors.green[100]! : currentLeague == League.wednesday ? Colors.orange[100]! : Colors.grey[200]!,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminScreen(currentLeague: currentLeague)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildPhoneGridButton(
                    'Test Speech',
                    Icons.keyboard_voice,
                    Colors.purple[200]!,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TestKeypadScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFunctionsTablet(BuildContext context, bool isTablet10, bool isTablet8) {
    return Container(
      padding: EdgeInsets.all(isTablet8 ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: isTablet10 ? 5 : (isTablet8 ? 5 : 3),
        mainAxisSpacing: isTablet8 ? 4 : 8,
        crossAxisSpacing: isTablet8 ? 4 : 8,
        childAspectRatio: isTablet10 ? 1.2 : (isTablet8 ? 3.0 : 1.0),
        children: [
          _buildAdminButton(
            'Firebase Upload',
            Icons.cloud_upload,
            Colors.red[200]!,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FirebaseTestScreen()),
            ),
          ),
          _buildAdminButton(
            'CSV Import',
            Icons.upload_file,
            Colors.blue[200]!,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CsvImportScreen()),
            ),
          ),
          _buildAdminButton(
            'Player Selection',
            Icons.people,
            currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
            () => navigateToScreen(
              currentLeague == League.monday 
                ? const MondayPlayerSelectionScreen()
                : const WednesdayPlayerSelectionScreen(),
            ),
          ),
          _buildAdminButton(
            'Administration',
            Icons.settings,
            currentLeague == League.monday ? Colors.green[100]! : currentLeague == League.wednesday ? Colors.orange[100]! : Colors.grey[200]!,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminScreen(currentLeague: currentLeague)),
            ),
          ),
          _buildAdminButton(
            'Test Speech',
            Icons.keyboard_voice,
            Colors.purple[200]!,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TestKeypadScreen()),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPhoneGridButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueSelectionCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select League:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        
        // Compact league buttons - stacked for narrow space
        Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              child: ElevatedButton(
                onPressed: selectMondayLeague,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLeague == League.monday 
                      ? Colors.green[300] 
                      : Colors.green[100],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'Monday',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectWednesdayLeague,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLeague == League.wednesday 
                      ? Colors.orange[300] 
                      : Colors.orange[100],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'Wednesday',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Compact status
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: currentLeague == League.monday 
                ? Colors.green[300] 
                : currentLeague == League.wednesday 
                    ? Colors.orange[300] 
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.black,
              width: 1,
            ),
          ),
          child: Text(
            currentLeague != null 
                ? currentLeague!.name.toUpperCase()
                : 'No League',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueConfigurationCompact(BuildContext context) {
    return Column(
      children: [
        // Compact ante section
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  currentLeague == League.monday ? 'Ante' : 'Ante',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: TextField(
                  controller: _anteController,
                  focusNode: _anteFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]'))],
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  onTap: _onAnteTap,
                  onEditingComplete: _formatCurrency,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Compact closest pin section
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: const Text(
                  'Pin',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: TextField(
                  controller: _closestPinController,
                  focusNode: _closestPinFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]'))],
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  onTap: _onClosestPinTap,
                  onEditingComplete: _formatClosestPinCurrency,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactAdminButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}