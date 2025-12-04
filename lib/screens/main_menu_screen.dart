import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/league.dart';
import '../services/ante_manager.dart';
import '../services/percentage_manager.dart';
import '../services/closest_pin_manager.dart';
import '../services/mulligan_manager.dart';
import '../services/device_detection_service.dart';
import 'monday/monday_parent_screen.dart';
import 'wednesday/wednesday_parent_screen.dart';
import 'firebase_test_screen.dart';
import 'admin_screen.dart';
import '../widgets/responsive_wrapper.dart';

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


  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet8: _buildTablet8Layout(),
      tablet10: _buildTablet10Layout(),
    );
  }

  Widget _buildPhoneLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Golden Oaks Golf League - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildTablet8Layout() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Golden Oaks Golf League - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
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
                    flex: 6,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTablet10Layout() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Golden Oaks Golf League - ${DeviceDetectionService.getDeviceName(context)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
          ],
        ),
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
        
      ],
    );
  }

  Widget _buildLeagueSelection(BuildContext context, bool isPhone) {
    // Use unified device detection service for consistent classification
    final is10Tablet = DeviceDetectionService.is10Tablet(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Your League:',
          style: TextStyle(
            fontSize: isPhone ? 18 : 24,
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
                          : Colors.green[200],
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
                      'Monday League',
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
                          : Colors.orange[200],
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
                      'Wednesday League',
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
                            : Colors.green[200],
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.all(is10Tablet ? 40 : 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Monday \n League',
                        style: TextStyle(
                          fontSize: 24,
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
                            : Colors.orange[200],
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.all(is10Tablet ? 40 : 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Wednesday League',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        
        if (currentLeague != null) ...[
          SizedBox(height: isPhone ? 8 : 12),
          
          Container(
            padding: EdgeInsets.all(isPhone ? 8 : 12),
            decoration: BoxDecoration(
              color: currentLeague == League.monday 
                  ? Colors.green[300] 
                  : Colors.orange[300],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Text(
              'Active League: ${currentLeague!.name.toUpperCase()}',
              style: TextStyle(
                fontSize: isPhone ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
        
        // Compact league buttons - horizontal layout with square aspect ratio
        Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 2),
                child: AspectRatio(
                  aspectRatio: 2.0,
                  child: ElevatedButton(
                    onPressed: selectMondayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLeague == League.monday 
                          ? Colors.green[300] 
                          : Colors.green[200],
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 2),
                child: AspectRatio(
                  aspectRatio: 2.0,
                  child: ElevatedButton(
                    onPressed: selectWednesdayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLeague == League.wednesday 
                          ? Colors.orange[300] 
                          : Colors.orange[200],
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (currentLeague != null) ...[
          const SizedBox(height: 6),
          
          // Compact status
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: currentLeague == League.monday 
                  ? Colors.green[300] 
                  : Colors.orange[300],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
            ),
            child: Text(
              currentLeague!.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
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