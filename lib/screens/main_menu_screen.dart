import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/league.dart';
import '../services/database_helper.dart';
import '../services/ante_manager.dart';
import '../services/percentage_manager.dart';
import '../services/closest_pin_manager.dart';
import 'player_selection_screen.dart';
import 'player_profile_screen.dart';
import 'player_scores_screen.dart';
import 'golf_course_info_screen.dart';
import 'admin_screen.dart';

class UnifiedMainMenuScreen extends StatefulWidget {
  const UnifiedMainMenuScreen({super.key});

  @override
  State<UnifiedMainMenuScreen> createState() => _UnifiedMainMenuScreenState();
}

class _UnifiedMainMenuScreenState extends State<UnifiedMainMenuScreen> {
  League? currentLeague;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _anteController = TextEditingController(text: '\$5.00');
  final TextEditingController _closestPinController = TextEditingController(text: '\$1.00');
  final TextEditingController _newFieldController = TextEditingController(text: '\$1.00');
  final TextEditingController _individualPercentController = TextEditingController(text: '40%');
  final TextEditingController _groupPercentController = TextEditingController(text: '60%');
  final FocusNode _anteFocusNode = FocusNode();
  final FocusNode _closestPinFocusNode = FocusNode();
  final FocusNode _newFieldFocusNode = FocusNode();
  final FocusNode _individualPercentFocusNode = FocusNode();
  final FocusNode _groupPercentFocusNode = FocusNode();

  void _formatCurrency() {
    String text = _anteController.text;
    // Remove all non-numeric characters except decimal point
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double amount = double.tryParse(numericText) ?? 0.0;
      String formatted = '\$${amount.toStringAsFixed(2)}';
      
      // Only update if the text has actually changed to avoid cursor issues
      if (formatted != _anteController.text) {
        _anteController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      
      // Update the global ante manager
      AnteManager().setAnteAmount(amount);
    } else if (text.isEmpty) {
      // Only set default if completely empty
      String defaultAmount = currentLeague == League.monday ? '\$12.00' : '\$5.00';
      double defaultValue = currentLeague == League.monday ? 12.0 : 5.0;
      
      _anteController.value = TextEditingValue(
        text: defaultAmount,
        selection: TextSelection.collapsed(offset: defaultAmount.length),
      );
      
      // Update the global ante manager
      AnteManager().setAnteAmount(defaultValue);
    }
    
    // Remove focus after formatting
    _anteFocusNode.unfocus();
  }

  void _formatClosestPinCurrency() {
    String text = _closestPinController.text;
    // Remove all non-numeric characters except decimal point
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double amount = double.tryParse(numericText) ?? 0.0;
      String formatted = '\$${amount.toStringAsFixed(2)}';
      
      // Only update if the text has actually changed to avoid cursor issues
      if (formatted != _closestPinController.text) {
        _closestPinController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      
      // Save to closest pin manager
      ClosestPinManager().setClosestPinAmount(amount);
    } else if (text.isEmpty) {
      // Only set default if completely empty
      String defaultAmount = '\$1.00';
      
      _closestPinController.value = TextEditingValue(
        text: defaultAmount,
        selection: TextSelection.collapsed(offset: defaultAmount.length),
      );
      
      // Save default to closest pin manager
      ClosestPinManager().setClosestPinAmount(1.0);
    }
    
    // Remove focus after formatting
    _closestPinFocusNode.unfocus();
  }

  void _formatNewFieldCurrency() {
    String text = _newFieldController.text;
    // Remove all non-numeric characters except decimal point
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double amount = double.tryParse(numericText) ?? 0.0;
      String formatted = '\$${amount.toStringAsFixed(2)}';
      
      // Only update if the text has actually changed to avoid cursor issues
      if (formatted != _newFieldController.text) {
        _newFieldController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    } else if (text.isEmpty) {
      // Only set default if completely empty
      String defaultAmount = '\$1.00';
      
      _newFieldController.value = TextEditingValue(
        text: defaultAmount,
        selection: TextSelection.collapsed(offset: defaultAmount.length),
      );
    }
    
    // Remove focus after formatting
    _newFieldFocusNode.unfocus();
  }

  void _onNewFieldTap() {
    // Clear the field and focus when tapped
    _newFieldController.clear();
    _newFieldFocusNode.requestFocus();
  }

  void _onAnteTap() {
    // Clear the field and focus when tapped
    _anteController.clear();
    _anteFocusNode.requestFocus();
  }

  void _onClosestPinTap() {
    // Clear the field and focus when tapped
    _closestPinController.clear();
    _closestPinFocusNode.requestFocus();
  }

  void _formatIndividualPercent() {
    String text = _individualPercentController.text;
    // Remove all non-numeric characters except decimal point
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double percent = double.tryParse(numericText) ?? 40.0;
      // Ensure percent is between 0 and 100
      percent = percent.clamp(0.0, 100.0);
      
      String formatted = '${percent.toStringAsFixed(0)}%';
      _individualPercentController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      
      // Update group percent to balance to 100%
      double groupPercent = 100.0 - percent;
      String groupFormatted = '${groupPercent.toStringAsFixed(0)}%';
      _groupPercentController.value = TextEditingValue(
        text: groupFormatted,
        selection: TextSelection.collapsed(offset: groupFormatted.length),
      );
      
      // Save to percentage manager
      PercentageManager().setIndividualPercent(percent);
    } else {
      // If empty, set default values
      _individualPercentController.value = TextEditingValue(
        text: '40%',
        selection: TextSelection.collapsed(offset: 3),
      );
      _groupPercentController.value = TextEditingValue(
        text: '60%',
        selection: TextSelection.collapsed(offset: 3),
      );
      // Save defaults to percentage manager
      PercentageManager().setIndividualPercent(40.0);
    }
    
    // Remove focus after formatting
    _individualPercentFocusNode.unfocus();
  }

  void _formatGroupPercent() {
    String text = _groupPercentController.text;
    // Remove all non-numeric characters except decimal point
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    
    if (numericText.isNotEmpty) {
      double percent = double.tryParse(numericText) ?? 60.0;
      // Ensure percent is between 0 and 100
      percent = percent.clamp(0.0, 100.0);
      
      String formatted = '${percent.toStringAsFixed(0)}%';
      _groupPercentController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      
      // Update individual percent to balance to 100%
      double individualPercent = 100.0 - percent;
      String individualFormatted = '${individualPercent.toStringAsFixed(0)}%';
      _individualPercentController.value = TextEditingValue(
        text: individualFormatted,
        selection: TextSelection.collapsed(offset: individualFormatted.length),
      );
      
      // Save to percentage manager
      PercentageManager().setGroupPercent(percent);
    } else {
      // If empty, set default values
      _individualPercentController.value = TextEditingValue(
        text: '40%',
        selection: TextSelection.collapsed(offset: 3),
      );
      _groupPercentController.value = TextEditingValue(
        text: '60%',
        selection: TextSelection.collapsed(offset: 3),
      );
      // Save defaults to percentage manager
      PercentageManager().setIndividualPercent(40.0);
    }
    
    // Remove focus after formatting
    _groupPercentFocusNode.unfocus();
  }




  double get currentAnteAmount {
    String text = _anteController.text;
    String numericText = text.replaceAll(RegExp(r'[^\d\.]'), '');
    return double.tryParse(numericText) ?? (currentLeague == League.monday ? 12.0 : 5.0);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _anteController.dispose();
    _closestPinController.dispose();
    _newFieldController.dispose();
    _individualPercentController.dispose();
    _groupPercentController.dispose();
    _anteFocusNode.dispose();
    _closestPinFocusNode.dispose();
    _newFieldFocusNode.dispose();
    _individualPercentFocusNode.dispose();
    _groupPercentFocusNode.dispose();
    super.dispose();
  }

  void selectMondayLeague() async {
    setState(() {
      currentLeague = League.monday;
      _anteController.text = '\$12.00'; // Monday league ante
      _closestPinController.text = '\$1.00'; // Monday league closest pin
      _newFieldController.text = '\$1.00'; // Monday league new field
      AnteManager().setAnteAmount(12.0); // Update global ante manager
      ClosestPinManager().setClosestPinAmount(1.0); // Update closest pin manager
    });
    
  }

  void selectWednesdayLeague() async {
    setState(() {
      currentLeague = League.wednesday;
      _anteController.text = '\$5.00'; // Wednesday league ante
      _closestPinController.text = '\$1.00'; // Wednesday league closest pin
      _newFieldController.text = '\$1.00'; // Wednesday league new field
      AnteManager().setAnteAmount(5.0); // Update global ante manager
      ClosestPinManager().setClosestPinAmount(1.0); // Update closest pin manager
      // Reset percentages to defaults for Wednesday league
      PercentageManager().setIndividualPercent(40.0);
    });
    
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Golden Oaks Golf League',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Database status indicator
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
            // League Selection Section
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  // Left Side - League Selection
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Select Your League:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // League Selection Buttons
                        Row(
                          children: [
                            // Monday Group Button
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
                                      side: BorderSide(
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
                            
                            // Wednesday Group Button
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
                                      side: BorderSide(
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
                        
                        const SizedBox(height: 12),
                        
                        // Current League Status
                        Container(
                          padding: const EdgeInsets.all(12),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // Show Player's Ante and Closest Pin sections only when a league is selected
                        if (currentLeague != null) ...[
                          const SizedBox(height: 12),
                          
                          // Player's Ante Section
                          Row(
                            children: [
                              // Label box
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
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
                                  child: const Text(
                                    'Player\'s Ante',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Input box
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 48,
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
                                    style: const TextStyle(
                                      fontSize: 16,
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
                          
                          const SizedBox(height: 16),
                          
                          // Closest Pin Section
                          Row(
                            children: [
                              // Label box
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
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
                                  child: const Text(
                                    'Closest Pin',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Input box
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 48,
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
                                    style: const TextStyle(
                                      fontSize: 16,
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
                        ],
                        
                        // New Field Section (Wednesday only)
                        if (currentLeague == League.wednesday) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Label box
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Text(
                                    'Mulligans',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Input box
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 48,
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
                                    style: const TextStyle(
                                      fontSize: 16,
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
            
            // Admin Function Buttons Footer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAdminButton(
                    'Player Selection',
                    Icons.people,
                    currentLeague == League.monday ? Colors.green[300]! : currentLeague == League.wednesday ? Colors.orange[300]! : Colors.grey[200]!,
                    () => navigateToScreen(PlayerSelectionScreen(currentLeague: currentLeague)),
                  ),
                  _buildAdminButton(
                    'Administration',
                    Icons.settings,
                    currentLeague == League.monday ? Colors.green[100]! : currentLeague == League.wednesday ? Colors.orange[100]! : Colors.grey[200]!,
                    () => navigateToScreen(AdminScreen(currentLeague: currentLeague)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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