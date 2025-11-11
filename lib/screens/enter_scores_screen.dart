import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'dart:math';
import 'popup_utils.dart';
import 'main_menu_screen.dart';
import 'auto_process_groups_screen.dart';
import 'manual_process_groups_screen.dart';
import '../services/database_helper.dart';
import '../services/ante_manager.dart';
import '../services/percentage_manager.dart';
import '../services/closest_pin_manager.dart';
import '../services/mulligan_manager.dart';
import '../services/csv_payout_service.dart';
import '../services/group_csv_payout_service.dart';
import '../services/payout_validation_service.dart';
import '../models/league.dart';

// Helper class to track positions in the groups grid
class Position {
  final int groupIndex;
  final int playerIndex;
  
  Position(this.groupIndex, this.playerIndex);
}

class EnterScoresScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialPlayers;
  final List<List<Map<String, dynamic>?>>? initialGroups;
  final String? initialLeague;

  const EnterScoresScreen({
    Key? key,
    this.initialPlayers,
    this.initialGroups,
    this.initialLeague,
  }) : super(key: key);

  @override
  _EnterScoresScreenState createState() => _EnterScoresScreenState();
}

// Wrapper widget for navigation with data
class EnterScoresScreenWithData extends StatelessWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  final List<List<Map<String, dynamic>?>> groups;
  final String leagueType;

  const EnterScoresScreenWithData({
    Key? key,
    required this.selectedPlayers,
    required this.groups,
    required this.leagueType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnterScoresScreen(
      initialPlayers: selectedPlayers,
      initialGroups: groups,
      initialLeague: leagueType,
    );
  }
}

class _EnterScoresScreenState extends State<EnterScoresScreen> {
  String selectedLeague = 'monday';
  List<List<Map<String, dynamic>?>> groups = [];
  List<Map<String, dynamic>> selectedPlayers = [];
  List<String> selectedForSwap = [];
  Map<String, Widget> playerNameButtons = {};
  Map<String, Map<String, dynamic>> scoreEntries = {};
  List<TextEditingController> scoreEntryOrder = [];
  List<Widget> gridRows = [];
  List<FocusNode> focusNodes = [];
  Map<String, TextEditingController> grossControllers = {};
  Map<String, FocusNode> grossFocusNodes = {};
  Map<String, TextEditingController> skatsControllers = {};
  Map<String, FocusNode> skatsFocusNodes = {};
  Map<String, TextEditingController> diffControllers = {};
  Map<String, FocusNode> diffFocusNodes = {};
  Map<String, TextEditingController> groupControllers = {};
  Map<String, FocusNode> groupFocusNodes = {};
  bool _isMovingFocus = false;
  int _groupAssignmentSequence = 1; // Track current group number for assignment
  int _playersInCurrentGroup = 0; // Track how many players in current group
  bool _initialAssignmentComplete = false; // Track if all players have initial assignments
  bool _groupAssignmentsLocked = false; // Track if assignments are locked for wildcard mode

  // Display values
  String _playersPurseDisplayText = "\$0.00";
  String _closestPinPurseDisplayText = "\$0.00";
  String _mulliganPurseDisplayText = "\$0.00";
  double _adjustedMulliganPurse = 0.0;
  bool _mulliganPurseBalanced = false;

  // Individual processing variables
  double totalPurse = 0.0;
  int individualPercent = 40;
  int groupPercent = 60;
  double individualPurse = 0.0;
  double groupPurse = 0.0;
  bool winnersCalculated = false;
  bool groupsProcessed = false; // Track if groups have been processed
  bool individualsProcessingComplete = false; // Track if Process Individuals is fully complete
  
  // Closest Pin variables
  String? closestPinWinnerName;
  double closestPinWinnings = 0.0;

  // Title labels
  String anteText = "";

  @override
  void initState() {
    super.initState();
    
    // Load CSV payout data
    CsvPayoutService().loadPayoutData().catchError((e) {
      // Error loading payout data - will use fallback calculations
    });
    
    // Load Group CSV payout data
    GroupCsvPayoutService().loadPayoutData().catchError((e) {
      // Error loading group payout data - will use fallback calculations
    });
    
    // Initialize with data if provided
    if (widget.initialPlayers != null && 
        widget.initialGroups != null && 
        widget.initialLeague != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setPlayers(
          widget.initialPlayers!,
          widget.initialGroups!,
          widget.initialLeague!,
        );
        // Position keypad in lower right corner by focusing on last player's gross score
        _setInitialFocusToLowerRight();
      });
    }
  }

  @override
  void dispose() {
    // Dispose gross controllers and focus nodes
    for (var controller in grossControllers.values) {
      controller.dispose();
    }
    for (var node in grossFocusNodes.values) {
      node.dispose();
    }
    // Dispose skats controllers and focus nodes
    for (var controller in skatsControllers.values) {
      controller.dispose();
    }
    for (var node in skatsFocusNodes.values) {
      node.dispose();
    }
    // Dispose group controllers and focus nodes
    for (var controller in groupControllers.values) {
      controller.dispose();
    }
    for (var node in groupFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void setLeague(String leagueType) {
    setState(() {
      selectedLeague = leagueType;
      updateTitleInformation();
    });
  }

  void setPlayers(List<Map<String, dynamic>> players, List<List<Map<String, dynamic>?>> playerGroups, String leagueType) {
    setState(() {
      // Create mutable copies of player data to avoid read-only QueryRow issues
      selectedPlayers = players.map((player) => Map<String, dynamic>.from(player)).toList();
      groups = playerGroups.map((group) => 
        group.map((player) => player != null ? Map<String, dynamic>.from(player) : null).toList()
      ).toList();
      selectedLeague = leagueType;
      selectedForSwap.clear();
      playerNameButtons.clear();
      scoreEntries.clear();
      groupsProcessed = false; // Reset groups processed state
      individualsProcessingComplete = false; // Reset individuals processing state
      _mulliganPurseBalanced = false; // Reset mulligan purse balancing flag
      _groupAssignmentSequence = 1; // Reset group assignment sequence
      _playersInCurrentGroup = 0; // Reset players in current group counter
      _initialAssignmentComplete = false; // Reset initial assignment tracking
      _groupAssignmentsLocked = false; // Reset assignment lock
      
      // Dispose old controllers and focus nodes
      for (var controller in grossControllers.values) {
        controller.dispose();
      }
      for (var node in grossFocusNodes.values) {
        node.dispose();
      }
      for (var controller in skatsControllers.values) {
        controller.dispose();
      }
      for (var node in skatsFocusNodes.values) {
        node.dispose();
      }
      for (var controller in groupControllers.values) {
        controller.dispose();
      }
      for (var node in groupFocusNodes.values) {
        node.dispose();
      }
      grossControllers.clear();
      grossFocusNodes.clear();
      skatsControllers.clear();
      skatsFocusNodes.clear();
      groupControllers.clear();
      groupFocusNodes.clear();
      
      updatePlayerSkatNumbers();
      updateTitleInformation();
    });
  }

  // Method to position keypad in lower right corner initially
  void _setInitialFocusToLowerRight() {
    // Wait a bit for the UI to be fully built
    Future.delayed(Duration(milliseconds: 500), () {
      if (groups.isNotEmpty) {
        // Find the last non-null player in the last group
        for (int groupIndex = groups.length - 1; groupIndex >= 0; groupIndex--) {
          for (int playerIndex = groups[groupIndex].length - 1; playerIndex >= 0; playerIndex--) {
            var player = groups[groupIndex][playerIndex];
            if (player != null) {
              // Focus on the gross score field of the last player (lower right area)
              String playerKey = '${player['last']}_gross';
              FocusNode? focusNode = grossFocusNodes[playerKey];
              if (focusNode != null && focusNode.canRequestFocus) {
                FocusScope.of(context).requestFocus(focusNode);
                return; // Exit once we've set focus
              }
            }
          }
        }
      }
    });
  }

  Future<void> updateTitleInformation() async {
    double anteAmount = AnteManager().currentAnteAmount;
    double closestPinAmount = ClosestPinManager().currentClosestPinAmount;
    double mulliganAmount = MulliganManager().currentMulliganAmount;
    
    int numPlayers = 0;
    for (var group in groups) {
      numPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    // Calculate using different formulas based on whether groups are processed and league type
    double purseAmount;
    
    if (selectedLeague == 'wednesday') {
      // For Wednesday league, use CSV amounts
      try {
        if (groupsProcessed) {
          // Use CSV "Groups Total" amount for group processing
          Map<String, double> groupPayoutData = await GroupCsvPayoutService().getPayoutAmounts(numPlayers);
          purseAmount = groupPayoutData['groups_total'] ?? 0.0;
        } else {
          // Use CSV "Total Individual" amount for individual processing
          Map<String, double> payoutData = await CsvPayoutService().getPayoutAmounts(numPlayers);
          purseAmount = payoutData['total_individual'] ?? 0.0;
        }
      } catch (e) {
        // Fallback to old calculation if CSV fails
        if (groupsProcessed) {
          double groupPercent = PercentageManager().groupPercent;
          purseAmount = anteAmount * numPlayers * (groupPercent / 100);
        } else {
          double individualPercent = PercentageManager().individualPercent;
          purseAmount = anteAmount * numPlayers * (individualPercent / 100);
        }
      }
    } else {
      // For Monday league, use simple calculation: Skats Ante x Number of Selected Players
      purseAmount = anteAmount * numPlayers;
    }
    
    // Calculate closest pin purse: Closest Pin x # of Selected Players
    double closestPinPurseAmount = closestPinAmount * numPlayers;
    
    // Calculate mulligan purse: Mulligan x # of Selected Players
    double mulliganPurseAmount = mulliganAmount * numPlayers;
    
    // Initialize adjusted mulligan purse only if balancing hasn't been done yet
    if (!_mulliganPurseBalanced) {
      _adjustedMulliganPurse = mulliganPurseAmount;
    }
    
    setState(() {
      // Update display text values
      _playersPurseDisplayText = '\$${purseAmount.toStringAsFixed(2)}';
      _closestPinPurseDisplayText = '\$${closestPinPurseAmount.toStringAsFixed(2)}';
      // Use adjusted mulligan purse if balancing has been done, otherwise use base amount
      _mulliganPurseDisplayText = _mulliganPurseBalanced ? '\$${_adjustedMulliganPurse.toStringAsFixed(2)}' : '\$${mulliganPurseAmount.toStringAsFixed(2)}';
      
      anteText = "(\$${anteAmount.toStringAsFixed(2)} per player)";
    });
  }


  Future<void> updatePlayerSkatNumbers() async {
    try {
      final dbPath = await getDatabasePath();
      final database = await openDatabase(dbPath);
      
      for (var group in groups) {
        for (var player in group) {
          if (player != null) {
            final result = await database.query(
              'players',
              columns: ['skat_number'],
              where: 'first = ? AND last = ? AND league = ?',
              whereArgs: [player['first'], player['last'], selectedLeague],
            );
            
            if (result.isNotEmpty) {
              player['skat_number'] = result.first['skat_number'] ?? '';
            }
          }
        }
      }
      
      await database.close();
    } catch (e) {
      // Continue with existing data if database query fails
    }
  }

  Future<String> getDatabasePath() async {
    return path.join(await getDatabasesPath(), 'GoldenOaks.db');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTitleContainer(),
            Expanded(child: _buildPayoutContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleContainer() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.05,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Row(
        children: [
          Text(
            selectedLeague == 'monday' 
              ? (groupsProcessed ? "Process Groups:" : "Enter Skats:")
              : (groupsProcessed ? "Process Groups:" : "Enter Scores:"),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 30),
          Text(
            selectedLeague == 'monday'
              ? (groupsProcessed ? "Total Group Purse = $_playersPurseDisplayText" : "Skat Purse = $_playersPurseDisplayText")
              : (groupsProcessed ? "Total Group Purse = $_playersPurseDisplayText" : "Total Players' Purse = $_playersPurseDisplayText"),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 30),
          Text(
            selectedLeague == 'monday'
              ? "Closest Pin Purse = $_closestPinPurseDisplayText"
              : "Total Closest Pin Purse = $_closestPinPurseDisplayText",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (selectedLeague == 'monday') ...[
            SizedBox(width: 30),
            Text(
              "Mulligan Purse = $_mulliganPurseDisplayText",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
          if (selectedLeague == 'wednesday') ...[
            SizedBox(width: 30),
            Text(
              "Total Mulligan Purse = $_mulliganPurseDisplayText",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildPayoutContent() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildSectionContainer(0)),
          SizedBox(width: 10),
          Expanded(child: _buildSectionContainer(1)),
          SizedBox(width: 10),
          Expanded(child: _buildSectionContainer(2)),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(int sectionIndex) {
    List<Widget> sectionWidgets = [];
    
    // Each section contains 3 groups (groups 1-3, 4-6, 7-9)
    for (int groupOffset = 0; groupOffset < 3; groupOffset++) {
      int groupNum = sectionIndex * 3 + groupOffset + 1;
      
      // Group header - positioned at center of main columns
      double columnCenter = selectedLeague == 'wednesday' ? 175.0 : 70.0; // Center position for headers
      
      sectionWidgets.add(Container(
        height: 30,
        child: Stack(
          children: [
            Positioned(
              left: columnCenter - 80, // Offset to center the text (approximate half width)
              child: Text(
                '------Group $groupNum------',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ));
      
      // Add column headers for first group in each section
      if (groupOffset == 0) {
        sectionWidgets.add(_buildColumnHeaders());
      }
      
      // Group rows
      List<Map<String, dynamic>?> groupData = [];
      if (groupNum <= groups.length) {
        groupData = groups[groupNum - 1];
      }
      
      // Always show 4 rows per group
      for (int rowIndex = 0; rowIndex < 4; rowIndex++) {
        Map<String, dynamic>? player = rowIndex < groupData.length ? groupData[rowIndex] : null;
        sectionWidgets.add(_buildPlayerRow(player, groupNum - 1, rowIndex));
      }
      
      sectionWidgets.add(SizedBox(height: 10)); // Space between groups
    }
    
    return SingleChildScrollView(
      child: Column(
        children: sectionWidgets,
      ),
    );
  }

  Widget _buildColumnHeaders() {
    List<Widget> headers = [];
    
    // Name header
    headers.add(Container(
      width: 120,
      child: Text('Name', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ));
    
    // HC header (Wednesday only, and only if groups not processed)
    if (selectedLeague == 'wednesday' && !groupsProcessed) {
      headers.add(Container(
        width: 50,
        child: Text('HC', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
    }
    
    // Gross header (only if groups not processed and not Monday league)
    if (!groupsProcessed && selectedLeague != 'monday') {
      headers.add(Container(
        width: 60,
        child: Text('Gross', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
    }
    
    // Group# header (Wednesday only, and only if groups are processed)
    if (selectedLeague == 'wednesday' && groupsProcessed) {
      headers.add(Container(
        width: 60,
        child: Text('Group#', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
    }
    
    // Net header (Wednesday only)
    if (selectedLeague == 'wednesday') {
      headers.add(Container(
        width: 40,
        child: Text('Net', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      
      // AVG header (only when groups are processed)
      if (groupsProcessed) {
        headers.add(Container(
          width: 50,
          child: Text('AVG', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ));
      }
      
      headers.add(Container(
        width: 50,
        child: Text('Pos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      headers.add(Container(
        width: 80,
        child: Text('\$\$\$', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
    }
    
    // SKAT headers (Monday only, and only if groups not processed)
    if (selectedLeague == 'monday' && !groupsProcessed) {
      headers.add(Container(
        width: 70,
        child: Text('SKAT#', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      headers.add(Container(
        width: 70,
        child: Text('SKATS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      headers.add(Container(
        width: 70,
        child: Text('DIFF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      headers.add(Container(
        width: 70,
        child: Text('\$\$\$', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
    }
    
    return Container(
      height: 25,
      child: Row(
        children: headers,
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic>? player, int groupIndex, int rowIndex) {
    List<Widget> rowWidgets = [];
    
    // Name field
    if (player != null) {
      rowWidgets.add(_buildPlayerNameButton(player, groupIndex));
    } else {
      rowWidgets.add(_buildEmptySlotButton(groupIndex, rowIndex));
    }
    
    if (player != null) {
      // Handicap (Wednesday only, and only if groups not processed)
      if (selectedLeague == 'wednesday' && !groupsProcessed) {
        rowWidgets.add(Container(
          width: 50,
          height: 40,
          decoration: BoxDecoration(border: Border.all()),
          child: Center(child: Text(player['handicap'] != null ? player['handicap'].toStringAsFixed(1) : '', style: TextStyle(fontSize: 16))),
        ));
      }
      
      // Gross score input (only if groups not processed and not Monday league)
      if (!groupsProcessed && selectedLeague != 'monday') {
        rowWidgets.add(_buildScoreInput(player));
      }
      
      // Group# field (Wednesday only, and only if groups are processed)
      if (selectedLeague == 'wednesday' && groupsProcessed) {
        rowWidgets.add(_buildGroupNumberInput(player, groupIndex));
      }
      
      // Net score (Wednesday only)
      if (selectedLeague == 'wednesday') {
        rowWidgets.add(_buildNetScoreLabel(player));
        
        // AVG column (only when groups are processed)
        if (groupsProcessed) {
          rowWidgets.add(_buildAvgLabel(groupIndex));
        }
        
        rowWidgets.add(_buildPlaceLabel(player, groupIndex));
        rowWidgets.add(_buildIndWinLabel(player));
      }
      
      // SKAT fields (Monday only, and only if groups not processed)
      if (selectedLeague == 'monday' && !groupsProcessed) {
        rowWidgets.add(Container(
          width: 70,
          height: 40,
          decoration: BoxDecoration(border: Border.all()),
          child: Center(child: Text(player['skat_number']?.toString() ?? '', style: TextStyle(fontSize: 20))),
        ));
        rowWidgets.add(_buildSkatsInput(player));
        rowWidgets.add(_buildDiffInput(player));
        rowWidgets.add(Container(
          width: 70,
          height: 40,
          decoration: BoxDecoration(border: Border.all()),
          child: Center(child: Text(
            player['skat_winnings'] != null ? '\$${player['skat_winnings'].toStringAsFixed(2)}' : '',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          )),
        ));
      }
    } else {
      // Empty placeholders
      if (selectedLeague == 'wednesday' && !groupsProcessed) {
        rowWidgets.add(_buildEmptyPlaceholder(50)); // HC placeholder
      }
      if (!groupsProcessed && selectedLeague != 'monday') {
        rowWidgets.add(_buildEmptyPlaceholder(60)); // Gross placeholder
      }
      
      // Group# placeholder (Wednesday only, and only if groups are processed)
      if (selectedLeague == 'wednesday' && groupsProcessed) {
        rowWidgets.add(_buildEmptyPlaceholder(60)); // Group# placeholder
      }
      
      if (selectedLeague == 'wednesday') {
        rowWidgets.add(_buildEmptyPlaceholder(50)); // Net placeholder
        
        // AVG placeholder (only when groups are processed)
        if (groupsProcessed) {
          rowWidgets.add(_buildEmptyPlaceholder(50)); // AVG placeholder
        }
        
        rowWidgets.add(_buildEmptyPlaceholder(50)); // Pos placeholder
        rowWidgets.add(_buildEmptyPlaceholder(80)); // $$$ placeholder
      }
      
      if (selectedLeague == 'monday' && !groupsProcessed) {
        rowWidgets.add(_buildEmptyPlaceholder(70)); // SKAT# placeholder
        rowWidgets.add(_buildEmptyPlaceholder(70)); // SKATS placeholder
        rowWidgets.add(_buildEmptyPlaceholder(70)); // DIFF placeholder
        rowWidgets.add(_buildEmptyPlaceholder(70)); // $$$ placeholder
      }
    }
    
    return Container(
      height: 40,
      child: Row(
        children: rowWidgets,
      ),
    );
  }

  Widget _buildPlayerNameButton(Map<String, dynamic> player, int groupIndex) {
    String playerLast = player['last'] ?? '';
    bool isSelected = selectedForSwap.contains(playerLast);
    bool isWildCard = player['is_wild_card'] == true;
    
    return GestureDetector(
      onTap: () => _onPlayerNameClick(playerLast, groupIndex),
      child: Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow : Colors.white,
          border: Border.all(),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              if (isWildCard) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.black, width: 0.5),
                  ),
                  child: Text(
                    'WC',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  playerLast,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlotButton(int groupIndex, int rowIndex) {
    String slotKey = 'empty_${groupIndex + 1}_$rowIndex';
    bool isSelected = selectedForSwap.contains(slotKey);
    
    return GestureDetector(
      onTap: () => _onEmptySlotClick(slotKey, groupIndex, rowIndex),
      child: Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow : Colors.white,
          border: Border.all(),
        ),
      ),
    );
  }

  Widget _buildScoreInput(Map<String, dynamic> player) {
    String playerKey = '${player['last']}_gross';
    
    // Get or create controller and focus node for this player
    TextEditingController controller = grossControllers[playerKey] ?? TextEditingController();
    FocusNode focusNode = grossFocusNodes[playerKey] ?? FocusNode();
    
    // Store them if they're new
    if (!grossControllers.containsKey(playerKey)) {
      grossControllers[playerKey] = controller;
      grossFocusNodes[playerKey] = focusNode;
    }
    
    String grossText = '';
    if (player['gross_score'] != null) {
      grossText = player['gross_score'].toString();
    }
    
    // Only set text if it's different to avoid cursor jumping
    if (controller.text != grossText) {
      controller.text = grossText;
    }
    
    Color inputColor = selectedLeague == 'wednesday' 
        ? Color(0xFFFFD700) // Light gold
        : Color(0xFFB3FFB3); // Light green
    
    return Container(
      width: 60,
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 2,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
        onChanged: (value) {
          // Mark that results need to be recalculated (but don't clear immediately)
          if (winnersCalculated) {
            setState(() {
              winnersCalculated = false;
              individualsProcessingComplete = false;
            });
          }
          
          // Calculate Net score for Wednesday league (only after 2 digits entered)
          if (selectedLeague == 'wednesday') {
            if (value.isNotEmpty && value.length >= 2) {
              try {
                int grossScore = int.parse(value);
                player['gross_score'] = grossScore; // Store gross score
                double handicap = player['handicap']?.toDouble() ?? 0.0;
                int netScore = grossScore - handicap.round();
                player['net_score'] = netScore;
                
                setState(() {}); // Refresh to show Net score
              } catch (e) {
                // Handle invalid input
                player['net_score'] = null;
                setState(() {});
              }
            } else if (value.isNotEmpty && value.length == 1) {
              // Store gross score but don't calculate net yet
              try {
                int grossScore = int.parse(value);
                player['gross_score'] = grossScore;
                player['net_score'] = null; // Clear net score until 2nd digit
                setState(() {});
              } catch (e) {
                // Handle invalid input
                player['gross_score'] = null;
                player['net_score'] = null;
                setState(() {});
              }
            } else {
              // Clear both gross and net scores when input is empty
              player['gross_score'] = null;
              player['net_score'] = null;
              
              // Recalculate group winnings if groups are processed
              if (groupsProcessed) {
                unawaited(_calculateGroupWinningsLegacy());
              }
              
              setState(() {});
            }
          } else {
            // For Monday league, just store the gross score
            if (value.isNotEmpty) {
              try {
                int grossScore = int.parse(value);
                player['gross_score'] = grossScore;
              } catch (e) {
                // Handle invalid input
              }
            } else {
              player['gross_score'] = null;
            }
          }
          
          if (value.length == 2) {
            // Move focus to next row after 2-digit number entry
            // Only move focus if this controller's focus node currently has focus
            if (focusNode.hasFocus) {
              _moveFocusToNextRow(controller);
            }
          }
          
          // Check if all gross scores are now filled and auto-calculate if so
          _checkAndAutoCalculateWednesday();
        },
        onSubmitted: (value) {
          _moveFocusToNextGrossInput(controller);
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: inputColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildNetScoreLabel(Map<String, dynamic> player) {
    String netText = '';
    if (player['net_score'] != null) {
      netText = player['net_score'].toString();
    }
    
    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(border: Border.all()),
      child: Center(child: Text(netText, style: TextStyle(fontSize: 16))),
    );
  }

  Widget _buildAvgLabel(int groupIndex) {
    String avgText = '';
    double groupAverage = _calculateGroupAverageNetScore(groupIndex);
    if (groupAverage > 0) {
      avgText = groupAverage.toStringAsFixed(1);
    }
    
    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(border: Border.all()),
      child: Center(child: Text(avgText, style: TextStyle(fontSize: 16))),
    );
  }

  Widget _buildPlaceLabel(Map<String, dynamic> player, int groupIndex) {
    String placeText = player['pos'] ?? '';
    
    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(border: Border.all()),
      child: Center(child: Text(placeText, style: TextStyle(fontSize: 16))),
    );
  }

  Widget _buildIndWinLabel(Map<String, dynamic> player) {
    String indText = player['prize_money'] ?? '';
    
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(border: Border.all()),
      child: Center(child: Text(indText, style: TextStyle(fontSize: 14))),
    );
  }

  Widget _buildSkatsInput(Map<String, dynamic> player) {
    String playerKey = '${player['last']}_skats';
    
    // Get or create controller and focus node for this player
    TextEditingController controller = skatsControllers[playerKey] ?? TextEditingController();
    FocusNode focusNode = skatsFocusNodes[playerKey] ?? FocusNode();
    
    // Store them if they're new
    if (!skatsControllers.containsKey(playerKey)) {
      skatsControllers[playerKey] = controller;
      skatsFocusNodes[playerKey] = focusNode;
    }
    
    String skatsText = '';
    if (player['skats_score'] != null) {
      skatsText = player['skats_score'].toString();
    }
    
    // Only set text if it's different to avoid cursor jumping
    if (controller.text != skatsText) {
      controller.text = skatsText;
    }
    
    return Container(
      width: 70,
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
        onChanged: (value) {
          // Mark that results need to be recalculated (but don't clear immediately)
          if (winnersCalculated) {
            setState(() {
              winnersCalculated = false;
              individualsProcessingComplete = false;
            });
          }
          
          // Store SKATS score
          if (value.isNotEmpty) {
            try {
              int skatsScore = int.parse(value);
              player['skats_score'] = skatsScore;
            } catch (e) {
              // Handle invalid input
            }
          } else {
            player['skats_score'] = null;
          }
          
          if (value.length == 2) {
            // Calculate DIFF (SKATS - SKAT#) and populate DIFF field
            _calculateAndSetDiff(player);
            
            // Check if all SKATS scores are entered and calculate $$$ if so
            if (_areAllSkatsScoresEntered()) {
              _calculateAndDistributeSkatAmounts();
            }
            
            // Move focus to next row after 2-digit number entry
            // Only move focus if this controller's focus node currently has focus
            if (focusNode.hasFocus) {
              _moveFocusToNextRow(controller);
            }
          }
        },
        onSubmitted: (value) {
          _moveFocusToNextRow(controller);
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xFFB3FFB3), // Light green
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  void _calculateAndSetDiff(Map<String, dynamic> player) {
    // Get SKAT# and SKATS values
    int? skatNumber = player['skat_number'];
    int? skatsScore = player['skats_score'];
    
    if (skatNumber != null && skatsScore != null) {
      // Calculate DIFF = SKATS - SKAT#
      int diffValue = skatsScore - skatNumber;
      
      // Store the calculated DIFF
      player['diff_score'] = diffValue;
      
      // Update the DIFF input field
      String playerKey = '${player['last']}_diff';
      TextEditingController? diffController = diffControllers[playerKey];
      if (diffController != null) {
        diffController.text = diffValue.toString();
      }
    }
  }

  Widget _buildDiffInput(Map<String, dynamic> player) {
    String playerKey = '${player['last']}_diff';
    
    // Get or create controller and focus node for this player
    TextEditingController controller = diffControllers[playerKey] ?? TextEditingController();
    FocusNode focusNode = diffFocusNodes[playerKey] ?? FocusNode();
    
    // Store them if they're new
    if (!diffControllers.containsKey(playerKey)) {
      diffControllers[playerKey] = controller;
      diffFocusNodes[playerKey] = focusNode;
    }
    
    String diffText = '';
    if (player['diff_score'] != null) {
      int diffScore = player['diff_score'];
      diffText = diffScore > 0 ? '+${diffScore.toString()}' : diffScore.toString();
    }
    
    // Only set text if it's different to avoid cursor jumping
    if (controller.text != diffText) {
      controller.text = diffText;
    }
    
    return Container(
      width: 70,
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
        onChanged: (value) {
          // Mark that results need to be recalculated (but don't clear immediately)
          if (winnersCalculated) {
            setState(() {
              winnersCalculated = false;
              individualsProcessingComplete = false;
            });
          }
          
          // Store DIFF score
          if (value.isNotEmpty) {
            try {
              int diffScore = int.parse(value);
              player['diff_score'] = diffScore;
            } catch (e) {
              // Handle invalid input
            }
          } else {
            player['diff_score'] = null;
          }
          
          if (value.length == 2) {
            // Move focus to next row after 2-digit number entry
            // Only move focus if this controller's focus node currently has focus
            if (focusNode.hasFocus) {
              _moveFocusToNextRow(controller);
            }
          }
        },
        onSubmitted: (value) {
          _moveFocusToNextRow(controller);
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xFFFFD700), // Light gold
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildGroupNumberInput(Map<String, dynamic> player, int groupIndex) {
    String groupText = '';
    
    if (player['manual_group'] != null) {
      groupText = player['manual_group'].toString();
    }
    
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: Color(0xFFFFD700), // Wednesday League gold color
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Center(
        child: Text(
          groupText,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _assignGroupNumber(String playerLast) {
    // Find the player in the groups
    Map<String, dynamic>? targetPlayer;
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['last'] == playerLast) {
          targetPlayer = player;
          break;
        }
      }
      if (targetPlayer != null) break;
    }
    
    if (targetPlayer == null) return;
    
    // Check if we're in wildcard mode (initial assignments complete but not all groups full)
    if (_initialAssignmentComplete && _groupAssignmentsLocked) {
      _handleWildcardAssignment(targetPlayer);
      return;
    }
    
    // If player already has a group number, remove it and recalculate sequence
    if (targetPlayer['manual_group'] != null) {
      // Don't allow removal if assignments are locked
      if (_groupAssignmentsLocked) {
        return;
      }
      
      targetPlayer['manual_group'] = null;
      targetPlayer['is_wild_card'] = false;
      _recalculateGroupSequence();
      setState(() {});
      return;
    }
    
    // Regular assignment - assign to current sequence group
    // First check if current sequence group already has 4 players
    int currentGroupCount = _countPlayersInGroup(_groupAssignmentSequence);
    
    if (currentGroupCount >= 4) {
      // Current group is full, move to next available group
      _groupAssignmentSequence++;
      _playersInCurrentGroup = 0;
      
      // Find next available group that isn't full
      while (_groupAssignmentSequence <= 9 && _countPlayersInGroup(_groupAssignmentSequence) >= 4) {
        _groupAssignmentSequence++;
      }
      
      // If we've exceeded group 9, show error
      if (_groupAssignmentSequence > 9) {
        PopupUtils.showWarning(context, "All Groups Full", "All groups already have 4 players assigned.");
        return;
      }
    }
    
    targetPlayer['manual_group'] = _groupAssignmentSequence;
    targetPlayer['is_wild_card'] = false;
    
    _playersInCurrentGroup++;
    
    // If current group is full (4 players), move to next group
    if (_playersInCurrentGroup >= 4) {
      _groupAssignmentSequence++;
      _playersInCurrentGroup = 0;
    }
    
    setState(() {});
    
    // Check if initial assignment is complete
    _checkInitialAssignmentComplete();
    
    // Check if all players now have group numbers assigned
    _checkAndRearrangeGroups();
  }
  
  void _handleWildcardAssignment(Map<String, dynamic> targetPlayer) {
    // Find the last group (highest group number) that has players
    int lastGroupNumber = _findLastGroupNumber();
    
    if (lastGroupNumber == 0) {
      return; // No groups found
    }
    
    // Count players in the last group
    int lastGroupCount = _countPlayersInGroup(lastGroupNumber);
    
    if (lastGroupCount >= 4) {
      PopupUtils.showWarning(context, "Last Group Full", "The last group already has 4 players. No wildcard needed.");
      return;
    }
    
    // Check if this player is already a wildcard in the last group
    if (targetPlayer['is_wild_card'] == true && targetPlayer['manual_group'] == lastGroupNumber) {
      // Remove wildcard status and move player back to original position
      _removeWildcardPlayer(targetPlayer);
    } else {
      // Add as wildcard to last group and physically move the player
      _movePlayerToLastGroup(targetPlayer, lastGroupNumber);
    }
    
    setState(() {});
    
    // Check if all groups are now complete
    _checkAndRearrangeGroups();
  }
  
  int _findLastIncompleteGroup() {
    // Find the last group (highest group number) that has less than 4 players
    for (int groupNumber = 9; groupNumber >= 1; groupNumber--) {
      int playersInGroup = _countPlayersInGroup(groupNumber);
      if (playersInGroup > 0 && playersInGroup < 4) {
        return groupNumber;
      }
    }
    return 0; // No incomplete groups found
  }
  
  void _copyPlayerToTargetGroup(Map<String, dynamic> targetPlayer, int targetGroupNumber) {
    // Find the target group's display position and an empty slot
    int targetGroupDisplayIndex = _findGroupDisplayIndex(targetGroupNumber);
    int emptySlotIndex = -1;
    
    if (targetGroupDisplayIndex != -1) {
      for (int i = 0; i < groups[targetGroupDisplayIndex].length; i++) {
        if (groups[targetGroupDisplayIndex][i] == null) {
          emptySlotIndex = i;
          break;
        }
      }
    }
    
    if (targetGroupDisplayIndex == -1) {
      return;
    }
    
    if (emptySlotIndex == -1) {
      return;
    }
    
    // COPY the original player data (original player stays in their original position)
    Map<String, dynamic> wildcardCopy = Map<String, dynamic>.from(targetPlayer);
    
    // Mark the COPY as wildcard with the target group number
    wildcardCopy['manual_group'] = targetGroupNumber;
    wildcardCopy['is_wild_card'] = true;
    
    // PASTE the wildcard copy in the empty slot of the target group
    // This creates a wildcard duplicate while keeping the original player in place
    groups[targetGroupDisplayIndex][emptySlotIndex] = wildcardCopy;
  }
  
  void _movePlayerToLastGroup(Map<String, dynamic> targetPlayer, int lastGroupNumber) {
    // Find the last group's display position and an empty slot
    int lastGroupDisplayIndex = _findGroupDisplayIndex(lastGroupNumber);
    int emptySlotIndex = -1;
    
    if (lastGroupDisplayIndex != -1) {
      for (int i = 0; i < groups[lastGroupDisplayIndex].length; i++) {
        if (groups[lastGroupDisplayIndex][i] == null) {
          emptySlotIndex = i;
          break;
        }
      }
    }
    
    if (lastGroupDisplayIndex == -1) {
      return;
    }
    
    if (emptySlotIndex == -1) {
      return;
    }
    
    // Create a copy of the player data for the wildcard
    Map<String, dynamic> wildcardCopy = Map<String, dynamic>.from(targetPlayer);
    
    // Mark the copy as wildcard with the last group number
    wildcardCopy['manual_group'] = lastGroupNumber;
    wildcardCopy['is_wild_card'] = true;
    
    // Place the wildcard copy in the empty slot of the last group
    groups[lastGroupDisplayIndex][emptySlotIndex] = wildcardCopy;
  }
  
  void _removeWildcardPlayer(Map<String, dynamic> targetPlayer) {
    // Find the wildcard copy in the last group and remove it
    // The original player stays in their original position
    int lastGroupNumber = targetPlayer['manual_group'];
    int lastGroupDisplayIndex = _findGroupDisplayIndex(lastGroupNumber);
    
    if (lastGroupDisplayIndex != -1) {
      for (int playerIndex = 0; playerIndex < groups[lastGroupDisplayIndex].length; playerIndex++) {
        var player = groups[lastGroupDisplayIndex][playerIndex];
        if (player != null && 
            player['last'] == targetPlayer['last'] && 
            player['is_wild_card'] == true) {
          // Remove the wildcard copy from the last group
          groups[lastGroupDisplayIndex][playerIndex] = null;
          break;
        }
      }
    }
  }
  
  int _findGroupDisplayIndex(int groupNumber) {
    // Count players from the target group in each display group
    Map<int, int> groupCounts = {};
    
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      int count = 0;
      for (var player in groups[groupIndex]) {
        if (player != null && 
            player['manual_group'] == groupNumber && 
            player['is_wild_card'] != true) {
          count++;
        }
      }
      if (count > 0) {
        groupCounts[groupIndex] = count;
      }
    }
    
    if (groupCounts.isEmpty) {
      return -1;
    }
    
    // Find the display group with the most players from the target group
    int bestDisplayIndex = groupCounts.entries.reduce((a, b) => 
        a.value > b.value ? a : b).key;
    
    return bestDisplayIndex;
  }
  
  int _findLastGroupNumber() {
    int lastGroup = 0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['manual_group'] != null && player['is_wild_card'] != true) {
          if (player['manual_group'] > lastGroup) {
            lastGroup = player['manual_group'];
          }
        }
      }
    }
    return lastGroup;
  }
  
  void _checkInitialAssignmentComplete() {
    // Count players without group assignments (excluding wildcards)
    int unassignedCount = 0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null && (player['manual_group'] == null || player['is_wild_card'] == true)) {
          if (player['is_wild_card'] != true) {
            unassignedCount++;
          }
        }
      }
    }
    
    if (unassignedCount == 0 && !_initialAssignmentComplete) {
      setState(() {
        _initialAssignmentComplete = true;
        _groupAssignmentsLocked = true;
      });
      
      // Check if we need wildcards
      int lastGroupNumber = _findLastGroupNumber();
      if (lastGroupNumber > 0) {
        int lastGroupCount = _countPlayersInGroup(lastGroupNumber);
        if (lastGroupCount < 4) {
          int neededWildcards = 4 - lastGroupCount;
          PopupUtils.showInfo(context, "Wildcard Mode", "All players assigned! Click $neededWildcards player name(s) to fill the last group as wildcards.");
        }
      }
    }
  }
  
  int _countPlayersInGroup(int groupNumber) {
    int count = 0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['manual_group'] == groupNumber) {
          count++;
        }
      }
    }
    return count;
  }
  
  int? _findIncompleteGroup() {
    // This function is no longer used with the new wildcard strategy
    return null;
  }
  
  void _recalculateGroupSequence() {
    // Count players in current sequence groups
    Map<int, int> groupCounts = {};
    
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['manual_group'] != null && player['is_wild_card'] != true) {
          int groupNum = player['manual_group'];
          groupCounts[groupNum] = (groupCounts[groupNum] ?? 0) + 1;
        }
      }
    }
    
    // Find the current group being filled
    _groupAssignmentSequence = 1;
    _playersInCurrentGroup = 0;
    
    for (int i = 1; i <= 9; i++) {
      int count = groupCounts[i] ?? 0;
      if (count < 4) {
        _groupAssignmentSequence = i;
        _playersInCurrentGroup = count;
        break;
      }
    }
  }
  
  void _checkAndRearrangeGroups() {
    // Count total players and players with group numbers
    List<Map<String, dynamic>> allPlayers = [];
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          allPlayers.add(player);
        }
      }
    }
    
    // Check if all players have group numbers
    bool allAssigned = allPlayers.every((player) => player['manual_group'] != null);
    
    if (allAssigned && allPlayers.isNotEmpty) {
      // Check if all groups have exactly 4 players (final groups are complete)
      bool allGroupsComplete = _areAllGroupsComplete();
      
      if (allGroupsComplete) {
        _rearrangePlayersByGroupNumber(allPlayers);
      }
    }
  }
  
  bool _areAllGroupsComplete() {
    // Get all unique group numbers that have been assigned
    Set<int> assignedGroups = {};
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['manual_group'] != null) {
          assignedGroups.add(player['manual_group']);
        }
      }
    }
    
    // Check if each assigned group has exactly 4 players
    for (int groupNum in assignedGroups) {
      int count = _countPlayersInGroup(groupNum);
      if (count != 4) {
        return false; // Found a group that doesn't have exactly 4 players
      }
    }
    
    return true; // All assigned groups have exactly 4 players
  }
  
  void _rearrangePlayersByGroupNumber(List<Map<String, dynamic>> allPlayers) {
    // Sort players by group number
    allPlayers.sort((a, b) {
      int groupA = a['manual_group'] ?? 999;
      int groupB = b['manual_group'] ?? 999;
      return groupA.compareTo(groupB);
    });
    
    // Clear all groups
    for (var group in groups) {
      group.clear();
      // Fill with nulls to maintain 4 slots per group
      for (int i = 0; i < 4; i++) {
        group.add(null);
      }
    }
    
    // Redistribute players according to their group numbers
    Map<int, List<Map<String, dynamic>>> groupedPlayers = {};
    for (var player in allPlayers) {
      int groupNum = player['manual_group'];
      if (!groupedPlayers.containsKey(groupNum)) {
        groupedPlayers[groupNum] = [];
      }
      groupedPlayers[groupNum]!.add(player);
    }
    
    // Place players in their assigned groups
    List<int> sortedGroupNumbers = groupedPlayers.keys.toList()..sort();
    int currentGroupIndex = 0;
    
    for (int groupNum in sortedGroupNumbers) {
      if (currentGroupIndex >= groups.length) break;
      
      List<Map<String, dynamic>> playersInGroup = groupedPlayers[groupNum]!;
      for (int i = 0; i < playersInGroup.length && i < 4; i++) {
        groups[currentGroupIndex][i] = playersInGroup[i];
      }
      currentGroupIndex++;
    }
    
    setState(() {
      // Trigger UI refresh
    });
    
    PopupUtils.showSuccess(context, "Groups Rearranged", "Players have been rearranged according to their group numbers!");
  }

  Widget _buildEmptyPlaceholder(double width) {
    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(border: Border.all()),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.grey[200]),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: selectedLeague == 'monday' 
            ? [
                _buildFooterButton("Closest Pin", Color(0xFFB3FFB3), _processIndividuals),
                _buildFooterButton("Main Menu", Colors.lightBlue[100]!, _returnToMainMenu),
                _buildFooterButton("Auto Fill", Colors.orange[200]!, _autoFillGrossScores),
              ]
            : [
                _buildFooterButton("Auto Fill", Colors.orange[200]!, _autoFillGrossScores),
                _buildFooterButton("Main Menu", Colors.lightBlue[100]!, _returnToMainMenu),
                _buildFooterButton("Individuals", Colors.grey[300]!, _processIndividuals),
                _buildConditionalProcessGroupsButton(),
                _buildSwapButton(),
              ],
        ),
      ),
    );
  }

  Widget _buildConditionalProcessGroupsButton() {
    bool isEnabled = individualsProcessingComplete;
    Color buttonColor = isEnabled ? Colors.green[300]! : Colors.grey[400]!;
    
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: ElevatedButton(
          onPressed: isEnabled ? () async => await _navigateToPlayerPayout() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: isEnabled ? Colors.black : Colors.grey[600],
            padding: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            "Auto Process Groups", 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
            ), 
            textAlign: TextAlign.center
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton(String text, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildFooterButtonCustom(String text, Color color, VoidCallback onPressed, double fontSize) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildSwapButton() {
    String buttonText = 'Manual Process Groups';
    bool isEnabled = false;
    Color buttonColor = Colors.grey[400]!;
    
    if (selectedForSwap.length == 1) {
      String displayName = _getDisplayName(selectedForSwap[0]);
      buttonText = 'Selected: $displayName\nClick another item';
    } else if (selectedForSwap.length == 2) {
      String displayName1 = _getDisplayName(selectedForSwap[0]);
      String displayName2 = _getDisplayName(selectedForSwap[1]);
      buttonText = 'SWAP:\n$displayName1 <-> $displayName2';
      isEnabled = true;
      buttonColor = _getLeagueColor();
    }
    
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: ElevatedButton(
          onPressed: _manualProcessGroups,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(buttonText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Color _getLeagueColor() {
    return selectedLeague == 'monday' 
        ? Color(0xFFB3FFB3) // Light green
        : Color(0xFFFFD700); // Light gold
  }

  String _getDisplayName(String selectedItem) {
    if (selectedItem.startsWith('empty_')) {
      List<String> parts = selectedItem.split('_');
      String groupNum = parts[1];
      String rowNum = parts[2];
      return 'Empty G${groupNum}R${int.parse(rowNum) + 1}';
    } else {
      return selectedItem;
    }
  }

  void _handleGrossScoreInput(TextEditingController controller, String lastName, String value) {
    // Always store the gross score value
    var playerData = scoreEntries[lastName]?['player_data'];
    if (playerData != null) {
      if (value.isNotEmpty) {
        try {
          int grossScore = int.parse(value);
          playerData['gross_score'] = grossScore;
          
          if (selectedLeague == 'wednesday') {
            // Calculate and display net score for Wednesday league
            double handicap = playerData['handicap']?.toDouble() ?? 0.0;
            int netScore = grossScore - handicap.round();
            playerData['net_score'] = netScore;
          }
          
          setState(() {}); // Refresh to show updates
        } catch (e) {
          // Handle invalid input
        }
      } else {
        // Clear scores when input is empty
        playerData['gross_score'] = null;
        if (selectedLeague == 'wednesday') {
          playerData['net_score'] = null;
        }
        setState(() {});
      }
    }
  }

  void _handleSkatsInput(TextEditingController controller, String value) {
    if (value.isNotEmpty && value.length == 2) {
      _moveFocusToNextRow(controller);
    }
  }

  void _moveFocusToNextInput(TextEditingController currentController) {
    try {
      int currentIndex = scoreEntryOrder.indexOf(currentController);
      if (currentIndex != -1 && currentIndex + 1 < scoreEntryOrder.length) {
        FocusScope.of(context).requestFocus(focusNodes[currentIndex + 1]);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _moveFocusToNextRow(TextEditingController currentController) {
    if (_isMovingFocus) {
      return;
    }
    
    _isMovingFocus = true;
    try {
      // Find which player this controller belongs to
      String? currentPlayerKey;
      for (var entry in grossControllers.entries) {
        if (entry.value == currentController) {
          currentPlayerKey = entry.key;
          break;
        }
      }
      
      if (currentPlayerKey == null) {
        // Try SKATS controllers for Monday league
        for (var entry in skatsControllers.entries) {
          if (entry.value == currentController) {
            currentPlayerKey = entry.key;
            break;
          }
        }
      }
      
      if (currentPlayerKey == null) {
        return;
      }
      
      // Parse the player key to find current position
      List<String> keyParts = currentPlayerKey.split('_');
      String playerName = keyParts[0];
      String inputType = keyParts[1]; // 'gross' or 'skats'
      
      // Find current player's position in groups
      int currentGroupIndex = -1;
      int currentRowIndex = -1;
      
      for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        for (int rowIndex = 0; rowIndex < groups[groupIndex].length; rowIndex++) {
          var player = groups[groupIndex][rowIndex];
          if (player != null && player['last'] == playerName) {
            currentGroupIndex = groupIndex;
            currentRowIndex = rowIndex;
            break;
          }
        }
        if (currentGroupIndex != -1) break;
      }
      
      if (currentGroupIndex == -1) {
        return;
      }
      
      // Find next input (could be gross or skats)
      String? nextPlayerKey = _findNextGrossInput(currentGroupIndex, currentRowIndex, inputType);
      
      if (nextPlayerKey != null) {
        FocusNode? nextFocusNode;
        // Check if it's a skats key or gross key
        if (nextPlayerKey.contains('_skats')) {
          nextFocusNode = skatsFocusNodes[nextPlayerKey];
        } else {
          nextFocusNode = grossFocusNodes[nextPlayerKey];
        }
        
        if (nextFocusNode != null && nextFocusNode.canRequestFocus) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      } else {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      // Handle error silently
    } finally {
      // Reset the flag after a short delay
      Future.delayed(Duration(milliseconds: 100), () {
        _isMovingFocus = false;
      });
    }
  }
  
  String? _findNextGrossInput(int currentGroupIndex, int currentRowIndex, String currentInputType) {
    // For Monday League, alternate between Gross and SKATS
    if (selectedLeague == 'monday' && !groupsProcessed) {
      if (currentInputType == 'gross') {
        // Move from Gross to SKATS of same player
        var currentPlayer = groups[currentGroupIndex][currentRowIndex];
        if (currentPlayer != null) {
          String skatsKey = '${currentPlayer['last']}_skats';
          if (skatsFocusNodes.containsKey(skatsKey)) {
            return skatsKey;
          }
        }
      } else if (currentInputType == 'skats') {
        // Move from SKATS to next player's SKATS
        return _findNextPlayerSkats(currentGroupIndex, currentRowIndex + 1);
      }
    }
    
    // For Wednesday League or processed groups, move to next player's gross
    return _findNextPlayerGross(currentGroupIndex, currentRowIndex + 1);
  }
  
  String? _findNextPlayerGross(int startGroupIndex, int startRowIndex) {
    // Start from current position and look for next player
    for (int groupIndex = startGroupIndex; groupIndex < groups.length; groupIndex++) {
      int startRow = (groupIndex == startGroupIndex) ? startRowIndex : 0;
      
      for (int rowIndex = startRow; rowIndex < groups[groupIndex].length; rowIndex++) {
        var player = groups[groupIndex][rowIndex];
        if (player != null) {
          String playerKey = '${player['last']}_gross';
          if (grossFocusNodes.containsKey(playerKey)) {
            return playerKey;
          }
        }
      }
    }
    return null;
  }

  String? _findNextPlayerSkats(int startGroupIndex, int startRowIndex) {
    // Start from current position and look for next player with SKATS field
    for (int groupIndex = startGroupIndex; groupIndex < groups.length; groupIndex++) {
      int startRow = (groupIndex == startGroupIndex) ? startRowIndex : 0;
      
      for (int rowIndex = startRow; rowIndex < groups[groupIndex].length; rowIndex++) {
        var player = groups[groupIndex][rowIndex];
        if (player != null) {
          String playerKey = '${player['last']}_skats';
          if (skatsFocusNodes.containsKey(playerKey)) {
            return playerKey;
          }
        }
      }
    }
    return null;
  }

  void _moveFocusToNextGrossInput(TextEditingController currentController) {
    try {
      int currentIndex = scoreEntryOrder.indexOf(currentController);
      int nextGrossIndex;
      
      if (selectedLeague == 'monday') {
        if (currentIndex % 2 == 0) {
          nextGrossIndex = currentIndex + 2;
        } else {
          nextGrossIndex = currentIndex + 1;
        }
      } else {
        nextGrossIndex = currentIndex + 1;
      }
      
      if (nextGrossIndex < scoreEntryOrder.length) {
        FocusScope.of(context).requestFocus(focusNodes[nextGrossIndex]);
      } else {
        // No more inputs available, unfocus
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _onPlayerNameClick(String playerLast, int groupIndex) {
    // If groups are processed, handle group number assignment
    if (groupsProcessed && selectedLeague == 'wednesday') {
      _assignGroupNumber(playerLast);
      return;
    }
    
    // Original swap functionality when groups not processed
    setState(() {
      if (selectedForSwap.contains(playerLast)) {
        selectedForSwap.remove(playerLast);
      } else {
        if (selectedForSwap.length < 2) {
          selectedForSwap.add(playerLast);
        } else {
          selectedForSwap.clear();
          selectedForSwap.add(playerLast);
        }
      }
    });
  }

  void _onEmptySlotClick(String slotKey, int groupIndex, int rowIndex) {
    setState(() {
      if (selectedForSwap.contains(slotKey)) {
        selectedForSwap.remove(slotKey);
      } else {
        if (selectedForSwap.length < 2) {
          selectedForSwap.add(slotKey);
        } else {
          selectedForSwap.clear();
          selectedForSwap.add(slotKey);
        }
      }
    });
  }

  void _performSwap() {
    if (selectedForSwap.length != 2) {
      PopupUtils.showWarning(context, "Invalid Selection", "Please select exactly 2 items to swap.");
      return;
    }
    
    try {
      String item1 = selectedForSwap[0];
      String item2 = selectedForSwap[1];
      
      // Find positions of both items
      Position? pos1 = _findItemPosition(item1);
      Position? pos2 = _findItemPosition(item2);
      
      if (pos1 == null || pos2 == null) {
        PopupUtils.showError(context, "Swap Error", "Could not locate selected items.");
        return;
      }
      
      // Perform the swap
      setState(() {
        Map<String, dynamic>? temp = groups[pos1.groupIndex][pos1.playerIndex];
        groups[pos1.groupIndex][pos1.playerIndex] = groups[pos2.groupIndex][pos2.playerIndex];
        groups[pos2.groupIndex][pos2.playerIndex] = temp;
        
        // Clear selection
        selectedForSwap.clear();
        
        // Clear any previous winnings since positions changed
        if (winnersCalculated) {
          _clearPreviousWinnings();
          winnersCalculated = false;
          individualsProcessingComplete = false;
        }
      });
      
      PopupUtils.showSuccess(context, "Success", "Players swapped successfully!");
      
    } catch (e) {
      PopupUtils.showError(context, "Swap Error", "Failed to swap players: $e");
      setState(() {
        selectedForSwap.clear();
      });
    }
  }

  void _manualProcessGroups() async {
    if (selectedForSwap.length == 2) {
      // Perform swap if two items are selected
      _performSwap();
    } else {
      FocusScope.of(context).unfocus();
      
      // Check if there are any players to process
      List<Map<String, dynamic>> playerScores = _collectPlayerScores();
      
      if (playerScores.isEmpty) {
        PopupUtils.showWarning(context, "Process Error", "No player scores available for manual group processing!");
        return;
      }
      
      // Navigate to Manual Process Groups screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManualProcessGroupsScreen(
            selectedPlayers: selectedPlayers,
            groups: groups,
            selectedLeague: selectedLeague,
            grossControllers: grossControllers,
              groupControllers: groupControllers,
          ),
        ),
      );

      // Handle result from the Manual Process Groups screen
      if (result != null) {
        if (result['groupsProcessed'] == true) {
          setState(() {
            groupsProcessed = true;
          });
        }
        
        // Update groups if they were modified
        if (result['updatedGroups'] != null) {
          setState(() {
            groups = result['updatedGroups'];
          });
        }
        
        await updateTitleInformation();
      }
    }
  }

  Future<void> _processGroupsManually() async {
    try {
      // Calculate group scores using individual scores
      List<Map<String, dynamic>> groupScores = [];

      for (int i = 0; i < groups.length; i++) {
        final group = groups[i];
        int totalScore = 0;
        List<String> playerNames = [];
        bool hasValidScore = false;

        // Calculate from individual scores
        for (var player in group) {
          if (player != null) {
            playerNames.add('${player['first']} ${player['last']}');
            
            String playerKey = '${player['last']}_gross';
            TextEditingController? grossController = grossControllers[playerKey];
            
            if (grossController != null && grossController.text.isNotEmpty) {
              try {
                totalScore += int.parse(grossController.text);
                hasValidScore = true;
              } catch (e) {
                // Skip invalid scores
              }
            }
          }
        }

        if (hasValidScore && playerNames.isNotEmpty) {
          groupScores.add({
            'group_number': i + 1,
            'total_score': totalScore,
            'player_names': playerNames,
            'players': group.where((p) => p != null).toList(),
          });
        }
      }

      if (groupScores.isEmpty) {
        PopupUtils.showWarning(context, "Process Error", "No valid group scores found to process!");
        return;
      }

      // Sort groups by total score (best score first)
      groupScores.sort((a, b) => a['total_score'].compareTo(b['total_score']));

      // Calculate group winnings
      await _calculateGroupWinnings(groupScores);

      // Save results to database
      await _saveGroupResultsToDatabase(groupScores);

      setState(() {
        groupsProcessed = true;
      });
      
      await updateTitleInformation();

      PopupUtils.showSuccess(
        context, 
        "Success", 
        "Groups processed manually! ${groupScores.length} groups ranked and payouts calculated."
      );
    } catch (e) {
      setState(() {
        groupsProcessed = false;
      });
      PopupUtils.showError(context, "Process Error", "Failed to process groups: $e");
    }
  }

  Future<void> _navigateToPlayerPayout() async {
    FocusScope.of(context).unfocus();
    
    // Check if there are any players to process
    List<Map<String, dynamic>> playerScores = _collectPlayerScores();
    
    if (playerScores.isEmpty) {
      PopupUtils.showWarning(context, "Process Error", "No player scores available to process groups!");
      return;
    }
    
    // Randomly distribute players for groups
    List<Map<String, dynamic>> randomizedPlayers = List.from(selectedPlayers);
    randomizedPlayers.shuffle();
    
    // Navigate to Auto Process Groups screen with wildcard auto-filling
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoProcessGroupsScreen(
          selectedPlayers: randomizedPlayers,
          groups: groups,
          selectedLeague: selectedLeague,
          grossControllers: grossControllers,
          groupControllers: groupControllers,
        ),
      ),
    );

    // Handle result from the Auto Process Groups screen
    if (result != null && result['groupsProcessed'] == true) {
      setState(() {
        groupsProcessed = true;
      });
      await updateTitleInformation();
    }
  }

  Future<void> _autoProcessGroups() async {
    // Close the keyboard
    FocusScope.of(context).unfocus();
    
    // Check if there are any players to process
    List<Map<String, dynamic>> playerScores = _collectPlayerScores();
    
    if (playerScores.isEmpty) {
      PopupUtils.showWarning(context, "Process Error", "No player scores available for group processing!");
      return;
    }
    
    // Navigate to Auto Process Groups screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoProcessGroupsScreen(
          selectedPlayers: selectedPlayers,
          groups: groups,
          selectedLeague: selectedLeague,
          grossControllers: grossControllers,
          groupControllers: groupControllers,
        ),
      ),
    );

    // Handle result from the Auto Process Groups screen
    if (result != null) {
      if (result['groupsProcessed'] == true) {
        setState(() {
          groupsProcessed = true;
        });
      }
      
      await updateTitleInformation();
    }
  }

  Future<void> _calculateGroupWinnings(List<Map<String, dynamic>> groupScores) async {
    double anteAmount = AnteManager().currentAnteAmount;
    int playerCount = selectedPlayers.length;
    double totalPurse = anteAmount * playerCount;
    
    int groupPercent = PercentageManager().groupPercent.round();
    double groupPurse = totalPurse * (groupPercent / 100.0);

    // Assign rankings
    for (int i = 0; i < groupScores.length; i++) {
      groupScores[i]['place'] = i + 1;
    }

    // Get payout structure based on number of groups
    Map<int, double> payoutStructure = _getGroupPayoutStructure(groupScores.length);

    // Calculate winnings for each group
    for (var group in groupScores) {
      int place = group['place'];
      double percentage = payoutStructure[place] ?? 0.0;
      group['group_winnings'] = (groupPurse * percentage / 100.0);
    }
  }

  Map<int, double> _getGroupPayoutStructure(int groupCount) {
    if (groupCount <= 2) {
      return {1: 100.0};
    } else if (groupCount <= 4) {
      return {1: 60.0, 2: 40.0};
    } else if (groupCount <= 6) {
      return {1: 50.0, 2: 30.0, 3: 20.0};
    } else {
      return {1: 40.0, 2: 30.0, 3: 20.0, 4: 10.0};
    }
  }

  Future<void> _saveGroupResultsToDatabase(List<Map<String, dynamic>> groupScores) async {
    final dbHelper = DatabaseHelper();

    for (var group in groupScores) {
      List<Map<String, dynamic>?> players = group['players'];
      double groupWinnings = group['group_winnings']?.toDouble() ?? 0.0;

      // Distribute group winnings equally among all players in the group
      double individualGroupShare = players.isNotEmpty ? groupWinnings / players.length : 0.0;

      for (var player in players) {
        if (player != null) {
          try {
            final db = await dbHelper.database;
            final playerRecords = await db.query(
              'players',
              where: 'first = ? AND last = ? AND league = ?',
              whereArgs: [player['first'], player['last'], selectedLeague],
              limit: 1,
            );

            if (playerRecords.isNotEmpty) {
              var playerRecord = playerRecords.first;
              await dbHelper.updateGroupWinnings(
                playerRecord['id'] as int, 
                individualGroupShare, 
                selectedLeague == 'monday' ? League.monday : League.wednesday
              );
            }
          } catch (e) {
            // Continue with other players if one fails
          }
        }
      }
    }
  }
  
  Position? _findItemPosition(String item) {
    // Handle empty slots
    if (item.startsWith('empty_')) {
      List<String> parts = item.split('_');
      if (parts.length >= 3) {
        int groupNum = int.tryParse(parts[1]) ?? 0;
        int rowNum = int.tryParse(parts[2]) ?? 0;
        return Position(groupNum - 1, rowNum); // Convert to 0-based indexing
      }
      return null;
    }
    
    // Handle player names
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
        var player = groups[groupIndex][playerIndex];
        if (player != null && player['last'] == item) {
          return Position(groupIndex, playerIndex);
        }
      }
    }
    
    return null;
  }

  void _clearPreviousWinnings() {
    // Clear all previous winnings and places
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          player['winnings'] = null;
          player['place'] = null;
          player['is_tied'] = null;
          player['tie_count'] = null;
          player['close_pin_winnings'] = null;
        }
      }
    }
    
    // Clear closest pin variables
    setState(() {
      closestPinWinnerName = null;
      closestPinWinnings = 0.0;
    });
  }

  Future<String?> _showClosestPinPlayerSelection(List<Map<String, dynamic>> players) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Name of Player for Closest Pin (${players.length} players)'),
          content: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height - adaptive
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 columns
                childAspectRatio: players.length <= 16 ? 2.5 : 2.0, // Smaller boxes for more players
                crossAxisSpacing: 6.0, // Reduced spacing for more players
                mainAxisSpacing: 6.0, // Reduced spacing for more players
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final fullName = '${player['first']} ${player['last']}';
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(fullName);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Text(
                          fullName,
                          style: TextStyle(
                            fontSize: players.length <= 16 ? 12 : 10, // Smaller font for more players
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showClosestPinConfirmation(String playerName) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Closest Pin Winner'),
          content: Text('Are you sure $playerName won the Closest Pin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _processClosestPin(List<Map<String, dynamic>> players) async {
    while (true) {
      // Show player selection popup
      String? selectedPlayer = await _showClosestPinPlayerSelection(players);
      
      if (selectedPlayer == null) {
        // User cancelled selection
        return false;
      }
      
      // Show confirmation popup
      bool confirmed = await _showClosestPinConfirmation(selectedPlayer);
      
      if (confirmed) {
        // Calculate closest pin winnings
        double closestPinAmount = ClosestPinManager().currentClosestPinAmount;
        double totalClosestPinWinnings = closestPinAmount * players.length;
        
        // Store the winner and amount
        setState(() {
          closestPinWinnerName = selectedPlayer;
          closestPinWinnings = totalClosestPinWinnings;
        });
        
        // Show success message and wait for user to acknowledge
        await PopupUtils.showSuccess(
          context, 
          "Closest Pin Winner", 
          "$selectedPlayer won the Closest Pin for \$${totalClosestPinWinnings.toStringAsFixed(2)}!"
        );
        
        return true;
      }
      
      // If not confirmed (user pressed "No"), loop back to player selection
      // The while(true) loop will automatically show the player selection again
    }
  }

  Future<void> _savePlayerScoresToDatabase(List<Map<String, dynamic>> players) async {
    
    try {
      String today = DateTime.now().toIso8601String().split('T')[0]; // Get today's date in YYYY-MM-DD format
      
      DatabaseHelper dbHelper = DatabaseHelper();
      
      for (int i = 0; i < players.length; i++) {
        var player = players[i];
        String playerName = '${player['first']} ${player['last']}';
        
        // Get Close Pin winnings (use existing closestPinWinnings variable and winner name)
        double playerClosePinWinnings = 0.0;
        if (closestPinWinnerName != null && playerName == closestPinWinnerName) {
          playerClosePinWinnings = closestPinWinnings;
        }
        
        // Get SKATS score and SKAT winnings from the player data after individual processing
        int skatsScore = 0;
        double skatWinnings = 0.0;
        
        // Get SKATS score from the controllers or player data
        String playerKey = '${player['first']}_${player['last']}';
        String skatsKey = '${player['last']}_skats';
        
        if (skatsControllers.containsKey(skatsKey)) {
          if (skatsControllers[skatsKey]!.text.isNotEmpty) {
            skatsScore = int.tryParse(skatsControllers[skatsKey]!.text) ?? 0;
          }
        } else if (skatsControllers.containsKey(playerKey)) {
          if (skatsControllers[playerKey]!.text.isNotEmpty) {
            skatsScore = int.tryParse(skatsControllers[playerKey]!.text) ?? 0;
          }
        } else if (player.containsKey('skats_score')) {
          skatsScore = player['skats_score'] ?? 0;
        }
        
        // Get individual winnings from prize_money field (this comes from Process Individuals)
        if (player.containsKey('prize_money') && player['prize_money'] != null) {
          String prizeMoneyStr = player['prize_money'].toString();
          skatWinnings = double.tryParse(prizeMoneyStr.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0;
        }
        
        // Get gross score from controllers or player data
        int grossScore = 0;
        String grossKey = '${player['last']}_gross';
        
        if (grossControllers.containsKey(grossKey)) {
          if (grossControllers[grossKey]!.text.isNotEmpty) {
            grossScore = int.tryParse(grossControllers[grossKey]!.text) ?? 0;
          }
        } else if (grossControllers.containsKey(playerKey)) {
          if (grossControllers[playerKey]!.text.isNotEmpty) {
            grossScore = int.tryParse(grossControllers[playerKey]!.text) ?? 0;
          }
        } else if (player.containsKey('gross_score')) {
          grossScore = player['gross_score'] ?? 0;
        }
        
        Map<String, dynamic> scoreData = {
          'player_id': player['id'],
          'name': playerName,
          'date_played': today,
          'golf_course': 'TBD',
          'handicap': player['handicap'],
          'skat_number': player['skat_number'],
          'gross_score': grossScore,
          'skats_score': skatsScore,
          'close_pin_winnings': playerClosePinWinnings,
          'skat_winnings': skatWinnings,
        };
        
        int insertResult = await dbHelper.insertScoreLeague(scoreData, League.monday);
      }
      
    } catch (e) {
      // Handle error silently or show user-friendly message
    }
  }

  Widget _buildPlayerClickColumn(
    List<Map<String, dynamic>> playerScores, 
    int columnIndex,
    Map<String, int> playerValues,
    StateSetter setState,
    VoidCallback onTotalChanged,
    int targetTotal
  ) {
    // Divide players into 3 columns
    int playersPerColumn = (playerScores.length / 3).ceil();
    int startIndex = columnIndex * playersPerColumn;
    int endIndex = (startIndex + playersPerColumn).clamp(0, playerScores.length);
    
    if (startIndex >= playerScores.length) {
      return Container(); // Empty column if no more players
    }
    
    List<Map<String, dynamic>> columnPlayers = playerScores.sublist(startIndex, endIndex);
    
    // Update total using callback
    void updateLocalTotal() {
      setState(() {
        onTotalChanged();
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Players in this column
        ...columnPlayers.map((player) {
          String playerName = player['last'] ?? 'Unknown';
          
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                // Player name with increased width for longer names - clickable to increment
                SizedBox(
                  width: 120, // Increased width to accommodate 5 more letters (was 80, now 120)
                  child: GestureDetector(
                    onTap: () {
                      // Increment the player's value when name is clicked
                      int currentValue = playerValues[playerName] ?? 0;
                      int currentTotal = playerValues.values.fold(0, (sum, value) => sum + value);
                      int newTotal = currentTotal + 1;
                      
                      // Check both individual limit (5) and total limit (targetTotal)
                      if (currentValue < 5 && newTotal <= targetTotal) {
                        setState(() {
                          int newValue = currentValue + 1;
                          playerValues[playerName] = newValue;
                        });
                        updateLocalTotal();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        playerName,
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8), // Padding between name and value display
                // Value display (read-only, shows current value)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      playerValues[playerName]! > 0 ? playerValues[playerName]!.toString() : '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<bool?> _showWinningsPopup(List<Map<String, dynamic>> playerScores, Map<String, int> playerValues) async {
    int totalSelectedPlayers = playerScores.length;
    double prizePerPoint = 1.00 * totalSelectedPlayers; // $1.00 * number of selected players
    
    // Filter players who actually have values > 0
    List<Map<String, dynamic>> winnersData = [];
    
    for (var player in playerScores) {
      String playerName = player['last'] ?? 'Unknown';
      int playerValue = playerValues[playerName] ?? 0;
      
      if (playerValue > 0) {
        double winnings = playerValue * prizePerPoint;
        winnersData.add({
          'name': playerName,
          'value': playerValue,
          'winnings': winnings,
        });
      }
    }
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Closest Pin Winners - ${selectedLeague == 'monday' ? 'Monday' : 'Wednesday'} League',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (winnersData.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No winners selected',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  )
                else ...[
                  Text(
                    'Value × (\$1.00 × $totalSelectedPlayers players) = Value × \$${prizePerPoint.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ...winnersData.map((winner) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Fixed width for player name
                          SizedBox(
                            width: 80,
                            child: Text(
                              winner['name'],
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Calculation part - always starts at same position
                          Text(
                            '${winner['value']} × \$${prizePerPoint.toStringAsFixed(2)} = \$${winner['winnings'].toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 12),
                  Container(
                    height: 1,
                    width: 200,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Total Paid: \$${winnersData.fold(0.0, (sum, winner) => sum + winner['winnings']).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Calculate and distribute SKAT amounts for Monday League
                _calculateAndDistributeSkatAmounts();
                Navigator.of(context).pop(true); // Return true to indicate SKAT calculation was performed
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showPlayersCheckboxDialog(List<Map<String, dynamic>> playerScores) async {
    Map<String, int> playerValues = {};
    int runningTotal = 0;
    
    // Get the Closest Pin amount (target total)
    double closestPinAmount = ClosestPinManager().currentClosestPinAmount;
    int targetTotal = closestPinAmount.round(); // Convert to integer for comparison
    
    // Initialize player values
    for (var player in playerScores) {
      String playerName = player['last'] ?? 'Unknown';
      playerValues[playerName] = 0;
    }
    
    // Centralized function to update total - NO auto-close
    void updateTotal() {
      int newTotal = playerValues.values.fold(0, (sum, value) => sum + value);
      runningTotal = newTotal;
      
      // Just update the UI, no auto-close
      // Let user manually click Continue when ready
    }
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                children: [
                  Text(
                    'Process Individuals - ${selectedLeague == 'monday' ? 'Monday' : 'Wednesday'} League',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Target: \$${targetTotal.toStringAsFixed(0)} | Current Total: $runningTotal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: runningTotal == targetTotal ? Colors.green : Colors.blue),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Create 3 columns of players
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column 1
                        Expanded(
                          child: _buildPlayerClickColumn(playerScores, 0, playerValues, setState, updateTotal, targetTotal),
                        ),
                        SizedBox(width: 8),
                        // Column 2
                        Expanded(
                          child: _buildPlayerClickColumn(playerScores, 1, playerValues, setState, updateTotal, targetTotal),
                        ),
                        SizedBox(width: 8),
                        // Column 3
                        Expanded(
                          child: _buildPlayerClickColumn(playerScores, 2, playerValues, setState, updateTotal, targetTotal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear all player values and reset total
                    setState(() {
                      for (var player in playerScores) {
                        String playerName = player['last'] ?? 'Unknown';
                        playerValues[playerName] = 0;
                      }
                      runningTotal = 0;
                    });
                  },
                  child: Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Show winnings popup - this will handle returning to Enter Scores screen
                    bool? skatCalculated = await _showWinningsPopup(playerScores, playerValues);
                    // After showing winnings, close this dialog and return true to indicate completion
                    Navigator.of(context).pop(true);
                    // If SKAT calculation was performed, trigger UI refresh
                    if (skatCalculated == true && mounted) {
                      setState(() {
                        // Force UI update to show new SKAT amounts in $$$ column
                      });
                    }
                  },
                  child: Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processIndividuals() async {
    try {
      // Close the keyboard
      FocusScope.of(context).unfocus();
      
      if (selectedLeague == 'monday') {
        // For Monday League, use the checkbox dialog for closest pin processing
        List<Map<String, dynamic>> playerScores = _collectPlayerScores();
        
        if (playerScores.isEmpty) {
          await PopupUtils.showWarning(context, "Process Error", "No player scores available to process!");
          return;
        }
        
        // Use the checkbox dialog method for Monday League
        bool? closestPinCompleted = await _showPlayersCheckboxDialog(playerScores);
        
        if (closestPinCompleted != true) {
          // User cancelled closest pin selection
          return;
        }
        
        // Set individuals processing as complete
        setState(() {
          individualsProcessingComplete = true;
        });
        
        // Collect all players for saving to database
        List<Map<String, dynamic>> allPlayers = [];
        for (var group in groups) {
          for (var player in group) {
            if (player != null) {
              allPlayers.add(player);
            }
          }
        }
        
        // Save scores to Player Scores table for Monday League
        await _savePlayerScoresToDatabase(allPlayers);
      } else {
        // For Wednesday League, collect player scores and calculate positions/winnings
        List<Map<String, dynamic>> playerScores = _collectPlayerScores();
        
        if (playerScores.isEmpty) {
          await PopupUtils.showWarning(context, "Process Error", "No player scores available to process!");
          return;
        }
        
        List<Map<String, dynamic>> allPlayers = [];
        for (var group in groups) {
          for (var player in group) {
            if (player != null) {
              allPlayers.add(player);
            }
          }
        }
        
        // Process closest pin winner using existing method
        bool closestPinCompleted = await _processClosestPin(allPlayers);
        
        if (!closestPinCompleted) {
          // User cancelled closest pin selection
          return;
        }
        
        // Calculate positions and prize money for Wednesday League
        await _calculateWednesdayWinnings(playerScores);
        
        // Update player data with pos and prize_money fields
        for (var player in playerScores) {
          double winnings = (player['winnings'] ?? 0.0).toDouble();
          int roundedWinnings = winnings.round();
          
          if (roundedWinnings > 0) {
            int place = player['place'] ?? 0;
            bool isTied = player['is_tied'] ?? false;
            
            if (isTied) {
              player['pos'] = 'T${place}';
            } else {
              player['pos'] = place.toString();
            }
            player['prize_money'] = '\$${roundedWinnings}';
          } else {
            player['pos'] = '';
            player['prize_money'] = '';
          }
        }
        
        // Update the groups data with calculated values
        for (var updatedPlayer in playerScores) {
          for (var group in groups) {
            for (int i = 0; i < group.length; i++) {
              var player = group[i];
              if (player != null && 
                  player['first'] == updatedPlayer['first'] && 
                  player['last'] == updatedPlayer['last']) {
                player['pos'] = updatedPlayer['pos'];
                player['prize_money'] = updatedPlayer['prize_money'];
                break;
              }
            }
          }
        }
        
        // Set individuals processing as complete
        setState(() {
          individualsProcessingComplete = true;
        });
      }
      
      await updateTitleInformation();
    } catch (e) {
      // Handle error silently or show user-friendly message
    }
  }

  List<Map<String, dynamic>> _collectPlayerScores() {
    List<Map<String, dynamic>> playerScores = [];
    Set<String> addedPlayers = {}; // Track players already added
    
    // Collect scores from all groups
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          String playerIdentifier = '${player['first']}_${player['last']}';
          
          // Only add if player hasn't been added already
          if (!addedPlayers.contains(playerIdentifier)) {
            var playerData = Map<String, dynamic>.from(player);
            bool hasValidScore = false;
            
            try {
              if (selectedLeague == 'wednesday') {
                // For Wednesday League, check gross scores
                String playerKey = '${player['last']}_gross';
                TextEditingController? controller = grossControllers[playerKey];
                
                if (controller != null && controller.text.isNotEmpty) {
                  playerData['gross_score'] = int.parse(controller.text);
                  double handicap = playerData['handicap']?.toDouble() ?? 0.0;
                  playerData['net_score'] = playerData['gross_score'] - handicap.round();
                  hasValidScore = true;
                }
              } else {
                // For Monday League, check SKATS scores
                String skatsKey = '${player['last']}_skats';
                TextEditingController? skatsController = skatsControllers[skatsKey];
                
                if (skatsController != null && skatsController.text.isNotEmpty) {
                  playerData['skats_score'] = int.parse(skatsController.text);
                  hasValidScore = true;
                  
                  // Also collect DIFF score for Monday League if available
                  String diffKey = '${player['last']}_diff';
                  TextEditingController? diffController = diffControllers[diffKey];
                  if (diffController != null && diffController.text.isNotEmpty) {
                    playerData['diff_score'] = int.parse(diffController.text);
                  }
                  
                  // Also collect gross score if available for Monday League
                  String grossKey = '${player['last']}_gross';
                  TextEditingController? grossController = grossControllers[grossKey];
                  if (grossController != null && grossController.text.isNotEmpty) {
                    playerData['gross_score'] = int.parse(grossController.text);
                  }
                }
              }
              
              if (hasValidScore) {
                playerScores.add(playerData);
                addedPlayers.add(playerIdentifier); // Mark as added
              }
            } catch (e) {
              // Skip invalid scores
            }
          }
        }
      }
    }
    
    return playerScores;
  }

  List<Map<String, dynamic>> _collectAllSelectedPlayers() {
    List<Map<String, dynamic>> allPlayers = [];
    Set<String> addedPlayers = {}; // Track players already added to avoid duplicates
    
    // Collect all players from all groups (regardless of whether they have scores)
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          String playerIdentifier = '${player['first']}_${player['last']}';
          
          // Only add if player hasn't been added already
          if (!addedPlayers.contains(playerIdentifier)) {
            var playerData = Map<String, dynamic>.from(player);
            allPlayers.add(playerData);
            addedPlayers.add(playerIdentifier); // Mark as added
          }
        }
      }
    }
    
    return allPlayers;
  }

  Future<void> _calculateWinnings(List<Map<String, dynamic>> players) async {
    if (players.isEmpty) return;
    
    // Sort by net score (lowest wins)
    players.sort((a, b) {
      int netA = a['net_score'] ?? a['gross_score'] ?? 999;
      int netB = b['net_score'] ?? b['gross_score'] ?? 999;
      return netA.compareTo(netB);
    });
    
    // Get payout amounts from CSV based on number of players
    int numPlayers = players.length;
    List<double> payoutAmounts;
    
    try {
      payoutAmounts = await CsvPayoutService().getPayoutList(numPlayers);
    } catch (e) {
      // Fallback to old percentage system
      double anteAmount = AnteManager().currentAnteAmount;
      double closestPinAmount = ClosestPinManager().currentClosestPinAmount;
      double adjustedAnteAmount = anteAmount - closestPinAmount;
      double totalPurse = players.length * adjustedAnteAmount;
      double individualPurse = totalPurse * PercentageManager().individualPercentDecimal;
      List<double> prizePercentages = [0.50, 0.30, 0.20];
      payoutAmounts = prizePercentages.map((p) => individualPurse * p).toList();
    }
    
    // Handle ties by grouping players with same scores
    List<List<Map<String, dynamic>>> tieGroups = [];
    List<int> currentTieGroup = [];
    
    // Find the highest paying position to determine who gets paid
    int maxPayingPosition = 0;
    for (int i = 0; i < payoutAmounts.length; i++) {
      if (payoutAmounts[i] > 0) {
        maxPayingPosition = i + 1;
      }
    }
    
    // Find the score of the last paying position to include ties
    int lastPayingScore = 999;
    if (players.length >= maxPayingPosition) {
      lastPayingScore = players[maxPayingPosition - 1]['net_score'] ?? players[maxPayingPosition - 1]['gross_score'] ?? 999;
    }
    
    // Include all players who are tied with someone in paying positions
    for (int i = 0; i < players.length; i++) {
      int currentScore = players[i]['net_score'] ?? players[i]['gross_score'] ?? 999;
      
      // Only include players who are tied with someone in paying positions
      if (i < maxPayingPosition || currentScore <= lastPayingScore) {
        if (currentTieGroup.isEmpty) {
          currentTieGroup.add(i);
        } else {
          int previousScore = players[currentTieGroup.first]['net_score'] ?? players[currentTieGroup.first]['gross_score'] ?? 999;
          
          if (currentScore == previousScore) {
            currentTieGroup.add(i);
          } else {
            // Process the completed tie group
            tieGroups.add(currentTieGroup.map((idx) => players[idx]).toList());
            currentTieGroup = [i];
          }
        }
      }
    }
    
    // Add the last group
    if (currentTieGroup.isNotEmpty) {
      tieGroups.add(currentTieGroup.map((idx) => players[idx]).toList());
    }
    
    // Calculate winnings for each tie group
    int currentPlace = 1;
    for (var tieGroup in tieGroups) {
      if (currentPlace > payoutAmounts.length) break;
      
      // Calculate places this tie group covers
      int numTied = tieGroup.length;
      int endPlace = currentPlace + numTied - 1;
      
      // Calculate total prize money for these places
      double totalTieMoney = 0.0;
      for (int place = currentPlace; place <= endPlace && place <= payoutAmounts.length; place++) {
        if (place - 1 < payoutAmounts.length) {
          totalTieMoney += payoutAmounts[place - 1];
        }
      }
      
      // Only assign winnings if there's money to distribute
      if (totalTieMoney > 0) {
        // Divide equally among tied players and round to nearest dollar
        double perPlayerWinnings = (totalTieMoney / numTied).roundToDouble();
        
        // Assign winnings and place info
        for (var player in tieGroup) {
          player['winnings'] = perPlayerWinnings;
          player['place'] = currentPlace;
          player['is_tied'] = numTied > 1;
          player['tie_count'] = numTied;
        }
      }
      
      currentPlace += numTied;
    }
    
    // Update the actual player objects in the groups with winnings and places
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          var matchingPlayer = players.firstWhere(
            (p) => p['last'] == player['last'] && p['first'] == player['first'],
            orElse: () => {},
          );
          
          if (matchingPlayer.isNotEmpty) {
            player['winnings'] = matchingPlayer['winnings'] ?? 0.0;
            player['place'] = matchingPlayer['place'];
            player['is_tied'] = matchingPlayer['is_tied'] ?? false;
            player['tie_count'] = matchingPlayer['tie_count'] ?? 1;
            player['net_score'] = matchingPlayer['net_score'];
            player['gross_score'] = matchingPlayer['gross_score'];
          }
        }
      }
    }
  }

  Future<void> _saveAdjustedMulliganPurse(double adjustedAmount) async {
    try {
      final db = await DatabaseHelper().database;
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      
      // Save or update the adjusted mulligan purse for the current date and league
      await db.execute('''
        INSERT OR REPLACE INTO adjusted_mulligan_purse 
        (date, league, adjusted_amount, created_at) 
        VALUES (?, ?, ?, ?)
      ''', [currentDate, selectedLeague, adjustedAmount, DateTime.now().toIso8601String()]);
      
    } catch (e) {
      // Log error but don't fail the operation
      // Failed to save adjusted mulligan purse: $e
    }
  }

  Future<void> _balanceMulliganPurse(List<Map<String, dynamic>> players) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.checkPlayersTableExists();
    
    // Get the total number of selected players (not just those with scores)
    int totalSelectedPlayers = 0;
    for (var group in groups) {
      totalSelectedPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    League currentLeague = selectedLeague == 'monday' ? League.monday : League.wednesday;
    
    try {
      PayoutValidationResult result = await PayoutValidationService().validateIndividualPayouts(
        players: players,
        league: currentLeague,
        totalSelectedPlayers: totalSelectedPlayers,
        currentMulliganPurse: _adjustedMulliganPurse,
      );
      
      if (result.requiresAdjustment) {
        _adjustedMulliganPurse = result.adjustedMulliganPurse;
        
        // Show validation message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.description),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      
      // ALWAYS save the current mulligan purse amount (adjusted or original)
      // This ensures Auto Process Groups uses the correct amount for this session
      await _saveAdjustedMulliganPurse(_adjustedMulliganPurse);
      
      // Mark that balancing has been done
      _mulliganPurseBalanced = true;
      
      
      // Update display
      setState(() {
        _mulliganPurseDisplayText = '\$${_adjustedMulliganPurse.toStringAsFixed(2)}';
      });
      
    } catch (e) {
      // Error handling - keep original amount if validation service fails
    }
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  bool _areAllSkatsScoresEntered() {
    // Only check for Monday League
    if (selectedLeague != 'monday') return false;
    
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['is_wild_card'] != true) {
          if (player['skats_score'] == null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _calculateAndDistributeSkatAmounts() {
    // Only process for Monday League
    if (selectedLeague != 'monday') return;
    
    // Calculate the number of selected players (same logic as in updateTitleInformation)
    int numSelectedPlayers = 0;
    for (var group in groups) {
      numSelectedPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    // If no selected players, no SKAT distribution
    if (numSelectedPlayers <= 0) {
      // Clear any existing SKAT winnings for all players
      for (var group in groups) {
        for (var player in group) {
          if (player != null) {
            player['skat_winnings'] = 0.0;
          }
        }
      }
      return;
    }
    
    // Get SKAT purse amount (same calculation as in updateTitleInformation)
    double anteAmount = AnteManager().currentAnteAmount;
    double skatPurse = anteAmount * numSelectedPlayers;
    
    // Add up all positive DIFF values
    double totalPositiveDiffs = 0.0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          // Get DIFF value from player data (stored as diff_score)
          var diffScore = player['diff_score'];
          double diffValue = 0.0;
          
          if (diffScore != null) {
            diffValue = diffScore.toDouble();
          }
          
          if (diffValue > 0) {
            totalPositiveDiffs += diffValue;
          }
        }
      }
    }
    
    // If no positive DIFFs, clear all winnings
    if (totalPositiveDiffs <= 0) {
      for (var group in groups) {
        for (var player in group) {
          if (player != null) {
            player['skat_winnings'] = 0.0;
          }
        }
      }
      return;
    }
    
    // Calculate SKAT value: divide SKAT purse by total positive DIFFs
    double skatValue = skatPurse / totalPositiveDiffs;
    
    // Distribute SKAT amounts to players based on their DIFF values
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          // Get DIFF value from player data (stored as diff_score)
          var diffScore = player['diff_score'];
          double diffValue = 0.0;
          
          if (diffScore != null) {
            diffValue = diffScore.toDouble();
          }
          
          if (diffValue > 0) {
            // For positive DIFF: multiply DIFF by SKAT value and round
            double skatAmount = diffValue * skatValue;
            player['skat_winnings'] = skatAmount.roundToDouble();
          } else {
            // For negative or zero DIFF: post $0.00
            player['skat_winnings'] = 0.0;
          }
        }
      }
    }
    
    // After SKAT calculations are complete, trigger individuals processing for Monday League
    Future.delayed(Duration(milliseconds: 500), () {
      _processIndividuals();
    });
  }

  void _returnToMainMenu() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => UnifiedMainMenuScreen()),
    );
  }

  Future<void> _redistributePlayersRandomly() async {
    // Collect all players from all groups
    List<Map<String, dynamic>?> allPlayers = [];
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          allPlayers.add(player);
        }
      }
    }

    if (allPlayers.isEmpty) {
      PopupUtils.showWarning(context, "No Players", "No players found to redistribute!");
      return;
    }

    // Clear all groups
    for (var group in groups) {
      group.clear();
      // Fill with nulls to maintain 4 slots per group
      for (int i = 0; i < 4; i++) {
        group.add(null);
      }
    }

    // Shuffle players randomly
    final random = Random();
    for (int i = allPlayers.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      var temp = allPlayers[i];
      allPlayers[i] = allPlayers[j];
      allPlayers[j] = temp;
    }

    // Clear all wild card flags before redistribution
    for (var player in allPlayers) {
      if (player != null) {
        player['is_wild_card'] = false;
      }
    }

    // Redistribute players across groups
    int playerIndex = 0;
    for (int groupIndex = 0; groupIndex < groups.length && playerIndex < allPlayers.length; groupIndex++) {
      for (int slotIndex = 0; slotIndex < 4 && playerIndex < allPlayers.length; slotIndex++) {
        groups[groupIndex][slotIndex] = allPlayers[playerIndex];
        playerIndex++;
      }
    }

    // Balance groups to ensure all have 4 players
    _balanceGroups();

    setState(() {
      // Clear any previous selections and winnings since positions changed
      selectedForSwap.clear();
      if (winnersCalculated) {
        _clearPreviousWinnings();
        winnersCalculated = false;
      }
      // Set groups as processed to hide HC and Gross columns
      groupsProcessed = true;
    });
    
    // Update the title information to reflect group processing
    updateTitleInformation();
    
    // Calculate group winnings when groups are first processed
    await _calculateGroupWinningsLegacy();

    PopupUtils.showSuccess(context, "Groups Processed", "Players have been randomly redistributed and balanced across groups!\nHC and Gross columns have been removed.");
  }

  void _balanceGroups() {
    final random = Random();
    
    // Find groups with less than 4 players
    List<int> incompleteGroups = [];
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      int playerCount = groups[groupIndex].where((player) => player != null).length;
      if (playerCount < 4) {
        incompleteGroups.add(groupIndex);
      }
    }
    
    // If no incomplete groups, no balancing needed
    if (incompleteGroups.isEmpty) {
      return;
    }
    
    // Calculate how many players we need to move
    int playersNeeded = 0;
    for (int groupIndex in incompleteGroups) {
      int currentCount = groups[groupIndex].where((p) => p != null).length;
      playersNeeded += (4 - currentCount);
    }
    
    // Collect all players from all groups into one pool (excluding already marked wild cards)
    List<Map<String, dynamic>> availablePlayers = [];
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['is_wild_card'] != true) {
          availablePlayers.add(player);
        }
      }
    }
    
    // If we don't have enough non-WC players to balance, we can't proceed
    if (availablePlayers.length < playersNeeded) {
      return;
    }
    
    // Randomly select players from the entire pool to be duplicated as Wild Cards
    availablePlayers.shuffle(random);
    List<Map<String, dynamic>> playersToMakeWildcards = availablePlayers.take(playersNeeded).toList();
    
    // Create wildcard copies and place them in incomplete groups
    int playerIndex = 0;
    for (int groupIndex in incompleteGroups) {
      // Fill this group up to 4 players
      while (playerIndex < playersToMakeWildcards.length) {
        int currentPlayerCount = groups[groupIndex].where((p) => p != null).length;
        if (currentPlayerCount >= 4) {
          break; // This group is now full
        }
        
        // Find empty slot in this group
        bool placed = false;
        for (int slotIndex = 0; slotIndex < groups[groupIndex].length; slotIndex++) {
          if (groups[groupIndex][slotIndex] == null) {
            var originalPlayer = playersToMakeWildcards[playerIndex];
            
            // Create a copy of the player for the wildcard
            var wildcardPlayer = Map<String, dynamic>.from(originalPlayer);
            wildcardPlayer['is_wild_card'] = true;
            
            groups[groupIndex][slotIndex] = wildcardPlayer;
            playerIndex++;
            placed = true;
            break;
          }
        }
        
        // If we couldn't place the player, break to avoid infinite loop
        if (!placed) {
          break;
        }
      }
    }
  }


  double _calculateGroupAverageNetScore(int groupIndex) {
    if (groupIndex >= groups.length) return 0.0;
    
    List<Map<String, dynamic>?> group = groups[groupIndex];
    List<int> netScores = [];
    
    for (var player in group) {
      if (player != null && player['net_score'] != null) {
        netScores.add(player['net_score'] as int);
      }
    }
    
    if (netScores.isEmpty) return 0.0;
    
    double average = netScores.reduce((a, b) => a + b) / netScores.length;
    return average;
  }

  Future<void> _calculateGroupWinningsLegacy() async {
    if (!groupsProcessed || selectedLeague != 'wednesday') return;
    
    // Clear previous group winnings
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          player['group_place'] = null;
          player['group_winnings'] = 0.0;
          player['is_group_tied'] = false;
          player['group_tie_count'] = 1;
        }
      }
    }
    
    // Calculate group averages and create ranking data
    List<Map<String, dynamic>> groupRankings = [];
    for (int i = 0; i < groups.length; i++) {
      List<Map<String, dynamic>?> group = groups[i];
      List<Map<String, dynamic>> validPlayers = group.where((player) => player != null).cast<Map<String, dynamic>>().toList();
      
      if (validPlayers.isNotEmpty) {
        double average = _calculateGroupAverageNetScore(i);
        if (average > 0) {
          groupRankings.add({
            'groupIndex': i,
            'average': average,
            'players': validPlayers,
          });
        }
      }
    }
    
    if (groupRankings.isEmpty) return;
    
    // Sort groups by average (lowest average wins)
    groupRankings.sort((a, b) => a['average'].compareTo(b['average']));
    
    // Calculate group purse using CSV data
    int numPlayers = 0;
    for (var group in groups) {
      numPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    // Get group payout amounts from CSV
    Map<String, double> groupPayouts = await GroupCsvPayoutService().getPayoutAmounts(numPlayers);
    double totalGroupPurse = groupPayouts['groups_total'] ?? 0.0;
    
    // Get actual prize amounts from CSV (not percentages)
    List<double> prizeAmounts = [
      groupPayouts['1st'] ?? 0.0,
      groupPayouts['2nd'] ?? 0.0,
      groupPayouts['3rd'] ?? 0.0,
      groupPayouts['4th'] ?? 0.0,
    ];
    
    // Handle ties and assign prizes
    List<List<Map<String, dynamic>>> tieGroups = [];
    Map<double, List<Map<String, dynamic>>> averageToGroups = {};
    
    // Group by average score
    for (var groupData in groupRankings) {
      double avg = groupData['average'];
      if (!averageToGroups.containsKey(avg)) {
        averageToGroups[avg] = [];
      }
      averageToGroups[avg]!.add(groupData);
    }
    
    // Create tie groups in order
    List<double> sortedAverages = averageToGroups.keys.toList()..sort();
    for (double avg in sortedAverages) {
      tieGroups.add(averageToGroups[avg]!);
    }
    
    // Distribute winnings
    int currentPosition = 1;
    int logicalPosition = 1; // Track the logical place (1st, 2nd, 3rd, 4th)
    for (var tieGroup in tieGroups) {
      if (logicalPosition > 4) break; // Pay top 4 positions based on CSV data
      
      // Calculate prize pool for this tie group using actual dollar amounts
      double totalPrizeForTieGroup = 0.0;
      int positionsInTieGroup = tieGroup.length;
      
      for (int i = 0; i < positionsInTieGroup && (currentPosition + i) <= 4; i++) {
        int prizeIndex = (currentPosition + i) - 1;
        if (prizeIndex < prizeAmounts.length) {
          totalPrizeForTieGroup += prizeAmounts[prizeIndex];
        }
      }
      
      // Calculate individual group winnings (split among tied groups)
      double groupWinnings = totalPrizeForTieGroup / tieGroup.length;
      
      // Distribute to each group in the tie
      for (var groupData in tieGroup) {
        List<Map<String, dynamic>> playersInGroup = groupData['players'];
        
        // Calculate per-player winnings (split equally among players in the group)
        double playerWinnings = groupWinnings / playersInGroup.length;
        
        // Assign winnings and position to all players in the group
        for (var player in playersInGroup) {
          player['group_place'] = logicalPosition; // Use logical position
          player['group_winnings'] = playerWinnings;
          player['is_group_tied'] = tieGroup.length > 1;
          player['group_tie_count'] = tieGroup.length;
        }
      }
      
      currentPosition += tieGroup.length;
      logicalPosition++; // Increment logical position for next place
    }
    
    // Balance mulligan purse for group overage/underage (Wednesday league only)
    if (selectedLeague == 'wednesday') {
      await _balanceMulliganPurseForGroups();
    }
    
    // After calculating group winnings, save them to the database
    _saveGroupWinningsToDatabase();
  }

  Future<void> _balanceMulliganPurseForGroups() async {
    // Get total number of selected players (excluding wild cards)
    int totalSelectedPlayers = 0;
    for (var group in groups) {
      totalSelectedPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    League currentLeague = selectedLeague == 'monday' ? League.monday : League.wednesday;
    
    try {
      PayoutValidationResult result = await PayoutValidationService().validateGroupPayouts(
        groups: groups,
        league: currentLeague,
        totalSelectedPlayers: totalSelectedPlayers,
        currentMulliganPurse: _adjustedMulliganPurse,
      );
      
      if (result.requiresAdjustment) {
        _adjustedMulliganPurse = result.adjustedMulliganPurse;
        
        // Show validation message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.description),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      
      // Mark that balancing has been done (or update existing balance)
      _mulliganPurseBalanced = true;
      
      // Update the display
      setState(() {
        _mulliganPurseDisplayText = '\$${_adjustedMulliganPurse.toStringAsFixed(2)}';
      });
      
    } catch (e) {
      // If validation service fails, keep the current mulligan purse amount
      // This prevents errors from breaking the balancing system
    }
  }

  Future<void> _saveGroupWinningsToDatabase() async {
    if (!groupsProcessed || selectedLeague != 'wednesday') return;
    
    final dbHelper = DatabaseHelper();
    
    // Update group winnings for each player in the database
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['group_winnings'] != null) {
          try {
            // Find the player's ID from the database
            final db = await dbHelper.database;
            final playerRecords = await db.query(
              'players',
              where: 'first = ? AND last = ? AND league = ?',
              whereArgs: [player['first'], player['last'], selectedLeague],
              limit: 1,
            );
            
            if (playerRecords.isNotEmpty) {
              var playerRecord = playerRecords.first;
              int playerId = playerRecord['id'] as int;
              
              // Round group winnings to whole dollars
              double groupWinnings = (player['group_winnings'] as double? ?? 0.0);
              int roundedGroupWinnings = groupWinnings.round();
              
              // Update the group winnings in the most recent record only
              await dbHelper.updateGroupWinnings(
                playerId, 
                roundedGroupWinnings.toDouble(), 
                League.wednesday
              );
            }
          } catch (e) {
            // Error saving group winnings - continue with other players
          }
        }
      }
    }
  }

  Future<void> _saveResultsToDatabase(List<Map<String, dynamic>> playerScores) async {
    final dbHelper = DatabaseHelper();
    
    // Add closest pin winnings to the appropriate player
    if (closestPinWinnerName != null && closestPinWinnings > 0) {
      for (var player in playerScores) {
        String playerFullName = '${player['first']} ${player['last']}';
        if (playerFullName == closestPinWinnerName) {
          // Add closest pin winnings to the player's data (only to close_pin_winnings field)
          player['close_pin_winnings'] = closestPinWinnings;
          break;
        }
      }
    }
    
    for (var player in playerScores) {
      // Find the player's ID from the database
      final db = await dbHelper.database;
      final playerRecords = await db.query(
        'players',
        where: 'first = ? AND last = ? AND league = ?',
        whereArgs: [player['first'], player['last'], selectedLeague],
        limit: 1,
      );
      
      if (playerRecords.isNotEmpty) {
        var playerRecord = playerRecords.first;
        String playerName = '${player['first']} ${player['last']}';
        
        // Round winnings to whole dollars
        double winnings = (player['winnings'] ?? 0.0).toDouble();
        int roundedWinnings = winnings.round();
        
        // Prepare score data for Player's Scores Screen table
        Map<String, dynamic> scoreData = {
          'player_id': playerRecord['id'],
          'name': player['last'], // Use only Last Name
          'date_played': DateTime.now().toIso8601String().split('T')[0], // Today's Date
          'handicap': playerRecord['handicap'] ?? 0.0, // HC from Player's Profile
          'gross_score': player['gross_score'], // Gross from Enter Scores Screen
          'close_pin_winnings': player['close_pin_winnings']?.toDouble() ?? 0.0,
        };
        
        if (selectedLeague == 'monday') {
          // Monday League: save to monday_scores table
          scoreData['golf_course'] = 'TBD'; // Golf Course - could be configurable later
          scoreData['skat_number'] = playerRecord['skat_number'] ?? 0;
          scoreData['skats_score'] = player['skats_score'] ?? 0;
          scoreData['skat_winnings'] = roundedWinnings.toDouble(); // Single Winnings
        } else {
          // Wednesday League: save to wednesday_scores table  
          scoreData['golf_course'] = 'The Hideout'; // Golf Course for Wednesday League
          scoreData['single_winnings'] = roundedWinnings.toDouble(); // Single Winnings from Enter Scores Screen
          
          // Round group winnings to whole dollars
          double groupWinnings = (player['group_winnings'] ?? 0.0).toDouble();
          int roundedGroupWinnings = groupWinnings.round();
          scoreData['group_winnings'] = roundedGroupWinnings.toDouble(); // Group Winnings from Enter Scores Screen
        }
        
        // Save to the appropriate league table (this will automatically limit to 20 scores and lock the row)
        League league = selectedLeague == 'monday' ? League.monday : League.wednesday;
        await dbHelper.insertScoreLeague(scoreData, league);
      }
    }
    
    // Also save to the legacy game system for compatibility
    List<Map<String, dynamic>> playerResults = [];
    
    for (var player in playerScores) {
      final db = await dbHelper.database;
      final playerRecords = await db.query(
        'players',
        where: 'first = ? AND last = ? AND league = ?',
        whereArgs: [player['first'], player['last'], selectedLeague],
        limit: 1,
      );
      
      if (playerRecords.isNotEmpty) {
        var playerRecord = playerRecords.first;
        
        // Find the group number for this player
        int groupNumber = 1;
        for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
          for (var groupPlayer in groups[groupIndex]) {
            if (groupPlayer != null && 
                groupPlayer['first'] == player['first'] && 
                groupPlayer['last'] == player['last']) {
              groupNumber = groupIndex + 1;
              break;
            }
          }
        }
        
        // Round winnings to whole dollars
        double winnings = (player['winnings'] ?? 0.0).toDouble();
        int roundedWinnings = winnings.round();
        
        playerResults.add({
          'id': playerRecord['id'],
          'first': player['first'],
          'last': player['last'],
          'group_number': groupNumber,
          'gross_score': player['gross_score'],
          'net_score': player['net_score'],
          'skats_score': player['skats_score'],
          'place': player['place'],
          'winnings': roundedWinnings,
        });
      }
    }
    
    if (playerResults.isNotEmpty) {
      // Determine league and ante amount
      League league = selectedLeague == 'monday' ? League.monday : League.wednesday;
      double anteAmount = AnteManager().currentAnteAmount;
      
      // Save to legacy game system
      await dbHelper.saveGameResults(
        league: league,
        anteAmount: anteAmount,
        playerResults: playerResults,
      );
    }
  }

  // Auto-fill method for testing - fills all Gross widgets with random scores 35-55 and calculates Net scores
  // For Monday League, also fills SKATS with random scores 30-40
  void _autoFillGrossScores() {
    final random = Random();
    
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          // For Monday League, only fill SKATS scores
          if (selectedLeague == 'monday' && !groupsProcessed) {
            String skatsKey = '${player['last']}_skats';
            String diffKey = '${player['last']}_diff';
            
            // Get or create SKATS controller if it doesn't exist
            if (!skatsControllers.containsKey(skatsKey)) {
              skatsControllers[skatsKey] = TextEditingController();
            }
            
            // Get or create SKATS focus node if it doesn't exist
            if (!skatsFocusNodes.containsKey(skatsKey)) {
              skatsFocusNodes[skatsKey] = FocusNode();
            }
            
            // Get or create DIFF controller if it doesn't exist
            if (!diffControllers.containsKey(diffKey)) {
              diffControllers[diffKey] = TextEditingController();
            }
            
            // Get or create DIFF focus node if it doesn't exist
            if (!diffFocusNodes.containsKey(diffKey)) {
              diffFocusNodes[diffKey] = FocusNode();
            }
            
            // Generate random SKATS score between 30 and 40
            int randomSkatsScore = 30 + random.nextInt(11); // 11 to include 40 (30 + 0 to 10)
            
            // Set the SKATS score in the controller
            skatsControllers[skatsKey]!.text = randomSkatsScore.toString();
            
            // Update the player's skats_score in the data structure
            player['skats_score'] = randomSkatsScore;
            
            // Calculate DIFF (SKATS - SKAT#)
            if (player['skat_number'] != null) {
              int skatNumber = player['skat_number'] is int 
                  ? player['skat_number'] as int
                  : int.tryParse(player['skat_number'].toString()) ?? 0;
              int diffScore = randomSkatsScore - skatNumber;
              
              // Set the DIFF score in the controller
              diffControllers[diffKey]!.text = diffScore.toString();
              
              // Update the player's diff_score in the data structure
              player['diff_score'] = diffScore;
            }
          } 
          // For Wednesday League, fill gross scores
          else if (selectedLeague == 'wednesday' && !groupsProcessed) {
            String playerKey = '${player['last']}_gross';
            
            // Get or create controller if it doesn't exist
            if (!grossControllers.containsKey(playerKey)) {
              grossControllers[playerKey] = TextEditingController();
            }
            
            // Get or create focus node if it doesn't exist
            if (!grossFocusNodes.containsKey(playerKey)) {
              grossFocusNodes[playerKey] = FocusNode();
            }
            
            // Generate random score between 35 and 55
            int randomScore = 35 + random.nextInt(21); // 21 to include 55 (35 + 0 to 20)
            
            // Set the score in the controller
            grossControllers[playerKey]!.text = randomScore.toString();
            
            // Update the player's gross_score in the data structure
            player['gross_score'] = randomScore;
            
            // Calculate and set net score (Gross - Handicap = Net)
            if (player['handicap'] != null) {
              double handicap = player['handicap'] is int 
                  ? (player['handicap'] as int).toDouble() 
                  : player['handicap'] as double;
              int netScore = randomScore - handicap.round();
              player['net_score'] = netScore;
            }
          }
        }
      }
    }
    
    // For Monday League, calculate SKAT winnings after filling scores
    if (selectedLeague == 'monday') {
      _calculateAndDistributeSkatAmounts();
    }
    
    // Refresh the UI to show the new scores
    setState(() {});
    
    // For Wednesday League, automatically process individuals after auto fill
    if (selectedLeague == 'wednesday') {
      // Small delay to ensure UI updates complete
      Future.delayed(Duration(milliseconds: 100), () {
        _processIndividuals();
      });
    }
  }

  // Check if all gross scores are filled for Wednesday League
  bool _areAllGrossScoresFilled() {
    if (selectedLeague != 'wednesday') return false;
    
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          String playerKey = '${player['last']}_gross';
          
          // Check if controller exists and has a value
          if (!grossControllers.containsKey(playerKey)) {
            return false;
          }
          
          if (grossControllers[playerKey]!.text.trim().isEmpty) {
            return false;
          }
          
          // Validate the score is a reasonable number
          int? score = int.tryParse(grossControllers[playerKey]!.text.trim());
          if (score == null || score < 10 || score > 99) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  // Automatically calculate positions and prize money when all scores are filled
  void _checkAndAutoCalculateWednesday() {
    if (selectedLeague == 'wednesday' && !individualsProcessingComplete && _areAllGrossScoresFilled()) {
      // Small delay to ensure UI updates complete
      Future.delayed(Duration(milliseconds: 200), () {
        _processIndividuals();
      });
    }
  }

  // Calculate positions and winnings for Wednesday League based on net scores
  Future<void> _calculateWednesdayWinnings(List<Map<String, dynamic>> playerScores) async {
    // Import the CSV payout service
    CsvPayoutService csvPayoutService = CsvPayoutService();
    
    // Sort players by net score (lowest first)
    playerScores.sort((a, b) => a['net_score'].compareTo(b['net_score']));
    
    // Get payout amounts from CSV based on number of players
    List<double> payoutList = await csvPayoutService.getPayoutList(playerScores.length);
    
    // Group players by their net scores to identify ties
    List<List<Map<String, dynamic>>> tieGroups = [];
    int currentIndex = 0;
    
    while (currentIndex < playerScores.length) {
      List<Map<String, dynamic>> tiedPlayers = [playerScores[currentIndex]];
      int currentScore = playerScores[currentIndex]['net_score'];
      
      // Find all players with the same net score
      for (int i = currentIndex + 1; i < playerScores.length; i++) {
        int compareScore = playerScores[i]['net_score'];
        
        if (compareScore == currentScore) {
          tiedPlayers.add(playerScores[i]);
        } else {
          break;
        }
      }
      
      tieGroups.add(tiedPlayers);
      currentIndex += tiedPlayers.length;
    }
    
    // Assign places and winnings based on tie groups
    int currentPlace = 1;
    
    for (var tieGroup in tieGroups) {
      int groupSize = tieGroup.length;
      
      if (groupSize == 1) {
        // No tie - regular placement
        var player = tieGroup[0];
        player['place'] = currentPlace;
        player['is_tied'] = false;
        
        if (currentPlace <= payoutList.length) {
          player['winnings'] = payoutList[currentPlace - 1];
        } else {
          player['winnings'] = 0.0;
        }
      } else {
        // Tie - calculate shared winnings
        double totalWinnings = 0.0;
        
        // Sum up the winnings for all positions involved in the tie
        for (int i = 0; i < groupSize; i++) {
          int position = currentPlace + i;
          if (position <= payoutList.length) {
            totalWinnings += payoutList[position - 1];
          }
        }
        
        // Divide evenly among tied players
        double sharedWinnings = totalWinnings / groupSize;
        
        // Assign to all tied players
        for (var player in tieGroup) {
          player['place'] = currentPlace;
          player['is_tied'] = true;
          player['tie_count'] = groupSize;
          player['winnings'] = sharedWinnings;
        }
      }
      
      currentPlace += groupSize;
    }
  }



}