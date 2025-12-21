import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'dart:math';
import '../popup_utils.dart';
import '../main_menu_screen.dart';
import '../../services/database_helper.dart';
import '../../services/ante_manager.dart';
import '../../services/closest_pin_manager.dart';
import '../../services/mulligan_manager.dart';
import '../../services/csv_payout_service.dart';
import '../../services/group_csv_payout_service.dart';
import '../../services/payout_validation_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../models/league.dart';

// Helper class to track positions in the groups grid
class Position {
  final int groupIndex;
  final int playerIndex;
  
  Position(this.groupIndex, this.playerIndex);
}

class WednesdayAutoProcessGroupsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialPlayers;
  final List<List<Map<String, dynamic>?>>? initialGroups;
  final String? initialLeague;
  final List<Map<String, dynamic>>? selectedPlayers;
  final List<List<Map<String, dynamic>?>>? groups;
  final String? selectedLeague;
  final Map<String, TextEditingController>? grossControllers;
  final Map<String, TextEditingController>? groupControllers;

  const WednesdayAutoProcessGroupsScreen({
    Key? key,
    this.initialPlayers,
    this.initialGroups,
    this.initialLeague,
    this.selectedPlayers,
    this.groups,
    this.selectedLeague,
    this.grossControllers,
    this.groupControllers,
  }) : super(key: key);

  @override
  _WednesdayAutoProcessGroupsScreenState createState() => _WednesdayAutoProcessGroupsScreenState();
}

// Wrapper widget for navigation with data
class AutoProcessGroupsScreenWithData extends StatelessWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  final List<List<Map<String, dynamic>?>> groups;
  final String leagueType;

  const AutoProcessGroupsScreenWithData({
    Key? key,
    required this.selectedPlayers,
    required this.groups,
    required this.leagueType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WednesdayAutoProcessGroupsScreen(
      initialPlayers: selectedPlayers,
      initialGroups: groups,
      initialLeague: leagueType,
    );
  }
}

// Wrapper widget for automatic wildcard filling
class AutoProcessGroupsScreenWithWildcards extends StatelessWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  final List<List<Map<String, dynamic>?>> groups;
  final String selectedLeague;
  final Map<String, TextEditingController> grossControllers;
  final Map<String, TextEditingController> groupControllers;

  const AutoProcessGroupsScreenWithWildcards({
    Key? key,
    required this.selectedPlayers,
    required this.groups,
    required this.selectedLeague,
    required this.grossControllers,
    required this.groupControllers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WednesdayAutoProcessGroupsScreen(
      selectedPlayers: selectedPlayers,
      groups: groups,
      selectedLeague: selectedLeague,
      grossControllers: grossControllers,
      groupControllers: groupControllers,
    );
  }
}

class _WednesdayAutoProcessGroupsScreenState extends State<WednesdayAutoProcessGroupsScreen> {
  // Hard-coded Wednesday league - no selection needed  
  String selectedLeague = 'wednesday';
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
    
    // Initialize with data if provided (either from initialPlayers or selectedPlayers)
    if (widget.selectedPlayers != null && 
        widget.groups != null && 
        widget.selectedLeague != null) {
      // Direct data passed in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setPlayersDirectly(
          widget.selectedPlayers!,
          widget.groups!,
          widget.selectedLeague!,
          widget.grossControllers ?? {},
          widget.groupControllers ?? {},
        );
      });
    } else if (widget.initialPlayers != null && 
        widget.initialGroups != null && 
        widget.initialLeague != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setPlayers(
          widget.initialPlayers!,
          widget.initialGroups!,
          widget.initialLeague!,
        );
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

  Future<void> setPlayersDirectly(
    List<Map<String, dynamic>> players, 
    List<List<Map<String, dynamic>?>> playerGroups, 
    String leagueType,
    Map<String, TextEditingController> grossCtrls,
    Map<String, TextEditingController> groupCtrls
  ) async {
    // Create mutable copies of player data and clear specific fields
    var processedSelectedPlayers = players.map((player) {
      var cleanedPlayer = Map<String, dynamic>.from(player);
      // Clear HC, Gross, Pos, and $$$ data, keep Last Name and Net
      cleanedPlayer.remove('handicap'); // Clear HC
      cleanedPlayer.remove('gross_score'); // Clear Gross
      cleanedPlayer.remove('pos'); // Clear Pos
      cleanedPlayer.remove('place'); // Clear place (alternate for pos)
      cleanedPlayer.remove('winnings'); // Clear $$$
      cleanedPlayer.remove('prize_money'); // Clear prize money (alternate for $$$)
      // Keep 'last' (Last Name) and 'net_score' (Net)
      return cleanedPlayer;
    }).toList();
    
    // Collect all non-null players from all groups
    List<Map<String, dynamic>> allPlayers = [];
    for (var group in playerGroups) {
      for (var player in group) {
        if (player != null) {
          var cleanedPlayer = Map<String, dynamic>.from(player);
          // Clear HC, Gross, Pos, and $$$ data, keep Last Name and Net
          cleanedPlayer.remove('handicap'); // Clear HC
          cleanedPlayer.remove('gross_score'); // Clear Gross
          cleanedPlayer.remove('pos'); // Clear Pos
          cleanedPlayer.remove('place'); // Clear place (alternate for pos)
          cleanedPlayer.remove('winnings'); // Clear $$$
          cleanedPlayer.remove('prize_money'); // Clear prize money (alternate for $$$)
          // Keep 'last' (Last Name) and 'net_score' (Net)
          allPlayers.add(cleanedPlayer);
        }
      }
    }
    
    // RANDOMLY REDISTRIBUTE PLAYERS
    allPlayers.shuffle(); // Randomly shuffle all players
    
    // Create new groups with randomly redistributed players (4 players per group)
    List<List<Map<String, dynamic>?>> newGroups = [];
    int playerIndex = 0;
    for (int groupIndex = 0; groupIndex < 9; groupIndex++) { // Create 9 groups
      List<Map<String, dynamic>?> group = [];
      for (int slotIndex = 0; slotIndex < 4; slotIndex++) { // 4 slots per group
        if (playerIndex < allPlayers.length) {
          group.add(allPlayers[playerIndex]);
          playerIndex++;
        } else {
          group.add(null); // Empty slot
        }
      }
      newGroups.add(group);
    }
    
    // Calculate average Net scores and prepare for group ranking
    List<Map<String, dynamic>> groupRankings = [];
    
    for (int groupIndex = 0; groupIndex < newGroups.length; groupIndex++) {
      var group = newGroups[groupIndex];
      List<int> netScores = [];
      List<Map<String, dynamic>> playersInGroup = [];
      
      // Collect net scores from players in this group
      for (var player in group) {
        if (player != null && player['net_score'] != null) {
          try {
            int netScore = player['net_score'] is int 
                ? player['net_score'] 
                : int.parse(player['net_score'].toString());
            netScores.add(netScore);
            playersInGroup.add(player);
          } catch (e) {
            // Skip players with invalid net scores
          }
        }
      }
      
      // Calculate average net score for this group
      if (netScores.isNotEmpty) {
        double averageNet = netScores.reduce((a, b) => a + b) / netScores.length;
        
        // Assign the average net score to the AVG column for all players in this group
        for (var player in playersInGroup) {
          player['avg_net'] = averageNet.toStringAsFixed(1); // Round to 1 decimal place
        }
        
        // Store group data for ranking
        groupRankings.add({
          'group_index': groupIndex,
          'group_number': groupIndex + 1,
          'average_net': averageNet,
          'players': playersInGroup,
        });
      }
    }
    
    // Sort groups by average net score (lowest score = best place)
    groupRankings.sort((a, b) => a['average_net'].compareTo(b['average_net']));
    
    // Assign places and calculate prize distribution
    await _assignGroupPlacesAndPrizes(groupRankings);
    
    setState(() {
      selectedPlayers = processedSelectedPlayers;
      groups = newGroups;
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
      
      // Clear controllers since we're removing gross score data
      grossControllers.clear();
      groupControllers.clear();
      
      // Clear focus nodes
      grossFocusNodes.clear();
      groupFocusNodes.clear();
      
      updateTitleInformation();
    });
    
    // Add a small delay to ensure UI is built, then fill wildcards
    Future.delayed(Duration(milliseconds: 500), () async {
      await _fillAllIncompleteGroupsWithWildcards();
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
      for (var controller in groupControllers.values) {
        controller.dispose();
      }
      for (var node in groupFocusNodes.values) {
        node.dispose();
      }
      grossControllers.clear();
      grossFocusNodes.clear();
      groupControllers.clear();
      groupFocusNodes.clear();
      
      updateTitleInformation();
    });
  }

  Future<void> updateTitleInformation() async {
    double anteAmount = AnteManager().currentAnteAmount;
    double closestPinAmount = ClosestPinManager().currentClosestPinAmount;
    
    int numPlayers = 0;
    for (var group in groups) {
      numPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    // Calculate using different formulas based on whether groups are processed and league type
    double purseAmount;
    
    // For Wednesday league Auto Process Groups Screen, ALWAYS use Team Total from CSV
    try {
      // Use CSV "Team Total" amount for Auto Process Groups Screen
      Map<String, double> groupPayoutData = await GroupCsvPayoutService().getPayoutAmounts(numPlayers);
      purseAmount = groupPayoutData['team_total'] ?? 0.0;
    } catch (e) {
      // If CSV fails, set to 0 since we rely on CSV data
      purseAmount = 0.0;
    }
    
    // Calculate closest pin purse: Closest Pin x # of Selected Players
    double closestPinPurseAmount = closestPinAmount * numPlayers;
    
    // DO NOT CALCULATE - ONLY use stored adjusted mulligan purse from individual processing
    String leagueStr = selectedLeague == 'monday' ? 'monday' : 'wednesday';
    double? storedAdjustedAmount = await DatabaseHelper().getAdjustedMulliganPurse(leagueStr);
    
    if (storedAdjustedAmount != null) {
      
    } else {
      
    }
    
    if (_mulliganPurseBalanced) {
      
    }
    
    // ONLY use stored amount - never calculate
    if (!_mulliganPurseBalanced && storedAdjustedAmount != null) {
      _adjustedMulliganPurse = storedAdjustedAmount;
      _mulliganPurseBalanced = true; // Mark as balanced since we're using stored amount
    } else if (!_mulliganPurseBalanced && storedAdjustedAmount == null) {
      // Set to 0 to make the error obvious
      _adjustedMulliganPurse = 0.0;
    }
    
    setState(() {
      // Update display text values
      _playersPurseDisplayText = '\$${purseAmount.toStringAsFixed(2)}';
      _closestPinPurseDisplayText = '\$${closestPinPurseAmount.toStringAsFixed(2)}';
      // Always use the adjusted mulligan purse (which is set from stored amount)
      _mulliganPurseDisplayText = '\$${_adjustedMulliganPurse.toStringAsFixed(2)}';
      
      anteText = "(\$${anteAmount.toStringAsFixed(2)} per player)";
    });
  }



  Future<String> getDatabasePath() async {
    return path.join(await getDatabasesPath(), 'GoldenOaks.db');
  }

  Future<void> _assignGroupPlacesAndPrizes(List<Map<String, dynamic>> groupRankings) async {
    if (groupRankings.isEmpty) return;
    
    try {
      // Get total number of players for CSV lookup
      int totalPlayers = 0;
      for (var groupData in groupRankings) {
        List<Map<String, dynamic>> players = groupData['players'];
        totalPlayers += players.length;
      }
      
      // Load individual prize amounts from Group_Payouts.csv
      Map<String, double> payouts = await GroupCsvPayoutService().getPayoutAmounts(totalPlayers);
      
      // Extract individual team amounts for each place
      Map<int, double> individualTeamAmounts = {
        1: payouts['1st_team_ind'] ?? 0.0,
        2: payouts['2nd_team_ind'] ?? 0.0,
        3: payouts['3rd_team_ind'] ?? 0.0,
        4: payouts['4th_team_ind'] ?? 0.0,
      };
      
      // Assign places and prize money to each group
      for (int rankIndex = 0; rankIndex < groupRankings.length; rankIndex++) {
        int place = rankIndex + 1; // 1st place, 2nd place, etc.
        var groupData = groupRankings[rankIndex];
        List<Map<String, dynamic>> players = groupData['players'];
        
        // Get individual team amount for this place (each player gets the same amount)
        double individualTeamAmount = individualTeamAmounts[place] ?? 0.0;
        int roundedIndividualAmount = individualTeamAmount.round();
        
        // Assign place and prize money to each player in this group
        for (var player in players) {
          player['pos'] = place.toString(); // Group place (1, 2, 3, 4...)
          player['prize_money'] = roundedIndividualAmount.toString(); // Individual team amount from CSV
        }
      }
    } catch (e) {
      // Continue without prize assignment if CSV fails
    }
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
            groupsProcessed ? "Auto Process:" : "Auto Process:",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 30),
          Text(
            groupsProcessed ? "Total Group Purse = $_playersPurseDisplayText" : "Total Players' Purse = $_playersPurseDisplayText",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 30),
          Text(
            "Total Closest Pin Purse = $_closestPinPurseDisplayText",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
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
        ],
      ),
    );
  }

  Widget _buildSectionContainer(int sectionIndex) {
    List<Widget> sectionWidgets = [];

    // Each section contains 5 groups (groups 1-5, 6-10)
    for (int groupOffset = 0; groupOffset < 5; groupOffset++) {
      int groupNum = sectionIndex * 5 + groupOffset + 1;
      
      // Group header - positioned for Auto Process Groups layout (with Group# column)
      double headerCenter = selectedLeague == 'wednesday' ? 150.0 : 120.0; // Center with Group# column added
      
      sectionWidgets.add(Container(
        height: 30,
        child: Stack(
          children: [
            Positioned(
              left: headerCenter - 80, // Offset to center the text (approximate half width)
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
    
    // HC header - REMOVED for Auto Process Groups Screen
    // Gross header - REMOVED for Auto Process Groups Screen
    
    // Group# header - NOW ALWAYS SHOWN in Auto Process Groups Screen
    headers.add(Container(
      width: 60,
      child: Text('Group#', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ));
    
    // Net header (Wednesday only)
    if (selectedLeague == 'wednesday') {
      headers.add(Container(
        width: 40,
        child: Text('Net', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      
      // AVG header - ALWAYS SHOWN in Auto Process Groups Screen
      headers.add(Container(
        width: 50,
        child: Text('AVG', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      
      headers.add(Container(
        width: 50,
        child: Text('Pos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ));
      headers.add(Container(
        width: 80,
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
      // Handicap - REMOVED for Auto Process Groups Screen
      // Gross score input - REMOVED for Auto Process Groups Screen
      
      // Group# field - NOW ALWAYS SHOWN in Auto Process Groups Screen
      rowWidgets.add(Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(border: Border.all()),
        child: Center(child: Text((groupIndex + 1).toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ));
      
      // Net score (Wednesday only)
      if (selectedLeague == 'wednesday') {
        rowWidgets.add(_buildNetScoreLabel(player));
        
        // AVG column - ALWAYS SHOWN in Auto Process Groups Screen
        rowWidgets.add(Container(
          width: 50,
          height: 40,
          decoration: BoxDecoration(border: Border.all()),
          child: Center(child: Text(player['avg_net']?.toString() ?? '', style: TextStyle(fontSize: 16))),
        ));
        
        rowWidgets.add(Container(
          width: 50,
          height: 40,
          decoration: BoxDecoration(border: Border.all()),
          child: Center(child: Text(player['pos']?.toString() ?? '', style: TextStyle(fontSize: 16))),
        ));
        rowWidgets.add(Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(border: Border.all()),
          child: Center(child: Text(_formatCurrency(player['prize_money']?.toString() ?? ''), style: TextStyle(fontSize: 14))),
        ));
      }
      
    } else {
      // Empty placeholders - HC and Gross REMOVED for Auto Process Groups Screen
      
      // Group# placeholder - NOW ALWAYS SHOWN in Auto Process Groups Screen
      rowWidgets.add(_buildEmptyPlaceholder(60)); // Group# placeholder
      
      if (selectedLeague == 'wednesday') {
        rowWidgets.add(_buildEmptyPlaceholder(40)); // Net placeholder
        
        // AVG placeholder - ALWAYS SHOWN in Auto Process Groups Screen
        rowWidgets.add(_buildEmptyPlaceholder(50)); // AVG placeholder
        
        rowWidgets.add(_buildEmptyPlaceholder(50)); // Pos placeholder
        rowWidgets.add(_buildEmptyPlaceholder(80)); // $$$ placeholder
      }
      
    }
    
    return Container(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: rowWidgets,
        ),
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
          
          if (value.length == 2) {
            // Move focus to next row after 2-digit number entry
            // Only move focus if this controller's focus node currently has focus
            if (focusNode.hasFocus) {
              _moveFocusToNextRow(controller);
            }
          }
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

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    try {
      double amount = double.parse(value);
      return '\$${amount.toStringAsFixed(2)}';
    } catch (e) {
      return value;
    }
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
    bool autoProcessEnabled = individualsProcessingComplete;
    Color autoProcessColor = autoProcessEnabled ? Colors.green[300]! : Colors.grey[400]!;

    String manualProcessText = 'Manual Process Groups';
    Color manualProcessColor = Colors.grey[400]!;

    if (selectedForSwap.length == 1) {
      String displayName = _getDisplayName(selectedForSwap[0]);
      manualProcessText = 'Selected: $displayName\nClick another item';
    } else if (selectedForSwap.length == 2) {
      String displayName1 = _getDisplayName(selectedForSwap[0]);
      String displayName2 = _getDisplayName(selectedForSwap[1]);
      manualProcessText = 'SWAP:\n$displayName1 <-> $displayName2';
      manualProcessColor = _getLeagueColor();
    }

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[200]!,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: "Return to Main Menu",
          color: Colors.lightBlue[100]!,
          onPressed: _returnToMainMenu,
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: "Process Individuals",
          color: selectedLeague == 'wednesday'
              ? const Color(0xFFFFD700) // Light gold
              : const Color(0xFFB3FFB3),
          onPressed: _processIndividuals,
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: "Auto Process Groups",
          color: autoProcessColor,
          onPressed: autoProcessEnabled ? () async => await _autoCompleteGroupsAndNavigateToPayout() : null,
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: manualProcessText,
          color: manualProcessColor,
          onPressed: _manualProcessGroups,
          maxLines: 2,
        ),
      ],
    );
  }

  Color _getLeagueColor() {
    return Color(0xFFFFD700); // Light gold for Wednesday
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
      }
      
      if (currentPlayerKey == null) {
        return;
      }
      
      // Parse the player key to find current position
      List<String> keyParts = currentPlayerKey.split('_');
      String playerName = keyParts[0];
      String inputType = keyParts[1]; // 'gross'
      
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
      
      // Find next gross input
      String? nextPlayerKey = _findNextGrossInput(currentGroupIndex, currentRowIndex, inputType);
      
      if (nextPlayerKey != null) {
        FocusNode? nextFocusNode = grossFocusNodes[nextPlayerKey];
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
    
    // If currently on gross input, move to next player's gross
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

  void _moveFocusToNextGrossInput(TextEditingController currentController) {
    try {
      int currentIndex = scoreEntryOrder.indexOf(currentController);
      int nextGrossIndex;
      
      nextGrossIndex = currentIndex + 1;
      
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
      
      // Manual Process Groups functionality removed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manual Process Groups screen was removed')),
      );
      final result = null;

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
    
    // Navigate to Auto Process Groups screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WednesdayAutoProcessGroupsScreen(
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
        builder: (context) => WednesdayAutoProcessGroupsScreen(
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

  Future<void> _autoCompleteGroupsAndNavigateToPayout() async {
    // Close the keyboard
    FocusScope.of(context).unfocus();
    
    // STEP 1: Fill incomplete groups with wildcards BEFORE any processing
    await _fillAllIncompleteGroupsWithWildcards();
    
    // STEP 2: Navigate to payout (normal group processing will happen there)
    await _navigateToPlayerPayout();
  }

  int _findLastGroupWithPlayers() {
    // Find the highest group index that contains at least one player
    for (int i = groups.length - 1; i >= 0; i--) {
      if (groups[i].any((player) => player != null)) {
        return i;
      }
    }
    return -1; // No groups with players found
  }

  Future<void> _addWildcardPlayersToLastGroup(int lastGroupIndex, int playersNeeded) async {
    // Collect all selected players (non-wildcards) from all groups
    List<Map<String, dynamic>> availablePlayers = [];
    
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['is_wild_card'] != true) {
          availablePlayers.add(player);
        }
      }
    }
    
    if (availablePlayers.isEmpty) {
      PopupUtils.showWarning(context, "Process Error", "No available players to add as wildcards!");
      return;
    }
    
    if (availablePlayers.length < playersNeeded) {
      PopupUtils.showWarning(context, "Process Error", "Not enough unique players to fill with wildcards!");
      return;
    }
    
    // Shuffle the available players and take the first N needed (ensures no duplicates)
    List<Map<String, dynamic>> shuffledPlayers = List.from(availablePlayers);
    shuffledPlayers.shuffle();
    
    for (int i = 0; i < playersNeeded; i++) {
      // Find next empty slot in the last group
      int emptySlotIndex = _findEmptySlotInGroup(lastGroupIndex);
      
      if (emptySlotIndex == -1) {
        break; // No more empty slots
      }
      
      // Take the next unique player from the shuffled list
      Map<String, dynamic> selectedPlayer = shuffledPlayers[i];
      
      // Create a wildcard copy of the player
      Map<String, dynamic> wildcardPlayer = Map<String, dynamic>.from(selectedPlayer);
      wildcardPlayer['is_wild_card'] = true;
      wildcardPlayer['manual_group'] = lastGroupIndex + 1; // Groups are 1-indexed
      
      // Clear group-specific data from original group (will be recalculated for new group)
      wildcardPlayer['group_place'] = null;
      wildcardPlayer['group_winnings'] = null;
      wildcardPlayer['is_group_tied'] = null;
      wildcardPlayer['group_tie_count'] = null;
      wildcardPlayer['avg_net'] = null; // Clear old group average
      wildcardPlayer['pos'] = null; // Clear old position
      wildcardPlayer['place'] = null; // Clear old place
      wildcardPlayer['prize_money'] = null; // Clear old prize money
      wildcardPlayer['winnings'] = null; // Clear old winnings
      // Keep scoring data (net_score, gross_score, etc.) for group average calculation
      
      // Add the wildcard player to the last group
      setState(() {
        groups[lastGroupIndex][emptySlotIndex] = wildcardPlayer;
      });
    }
  }

  int _findEmptySlotInGroup(int groupIndex) {
    // Find the first empty slot in the specified group
    List<Map<String, dynamic>?> group = groups[groupIndex];
    for (int i = 0; i < group.length; i++) {
      if (group[i] == null) {
        return i;
      }
    }
    return -1; // No empty slots found
  }

  Future<void> _fillAllIncompleteGroupsWithWildcards() async {
    // Find the last group with players
    int lastGroupIndex = _findLastGroupWithPlayers();
    
    if (lastGroupIndex == -1) {
      return;
    }
    
    // Check if the last group has fewer than 4 players
    List<Map<String, dynamic>?> lastGroup = groups[lastGroupIndex];
    int playersInLastGroup = lastGroup.where((player) => player != null).length;
    
    if (playersInLastGroup < 4) {
      int playersNeeded = 4 - playersInLastGroup;
      await _addWildcardPlayersToLastGroup(lastGroupIndex, playersNeeded);
      
      // CRITICAL: Clear ALL position and payout data from ALL players after adding wildcards
      await _clearAllPositionAndPayoutData();
      
      // Recalculate group averages for all groups
      await _recalculateAllGroupAverages();
      
      // Calculate group positions and payouts based on averages
      await _calculateGroupPositionsAndPayouts();
    }
  }

  Future<void> _clearAllPositionAndPayoutData() async {
    setState(() {
      for (var group in groups) {
        for (var player in group) {
          if (player != null) {
            // Clear all position and payout related data
            player['pos'] = null;
            player['place'] = null;
            player['prize_money'] = null;
            player['group_winnings'] = null;
            player['group_place'] = null;
            player['is_group_tied'] = null;
            player['group_tie_count'] = null;
            player['winnings'] = null;
            // Keep only: first, last, handicap, gross_score, net_score, manual_group, is_wild_card
          }
        }
      }
    });
  }

  Future<void> _recalculateAllGroupAverages() async {
    setState(() {
      for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        List<Map<String, dynamic>?> group = groups[groupIndex];
        List<Map<String, dynamic>> validPlayers = group.where((player) => player != null).cast<Map<String, dynamic>>().toList();
        
        if (validPlayers.isNotEmpty) {
          double groupAverage = _calculateGroupAverageNetScore(groupIndex);
          double formattedAverage = double.parse(groupAverage.toStringAsFixed(1)); // Format to 1 decimal place
          
          // Set the formatted average for all players in this group
          for (var player in validPlayers) {
            player['avg_net'] = formattedAverage;
          }
        }
      }
    });
  }

  Future<void> _calculateGroupPositionsAndPayouts() async {
    
    // Collect all groups with their averages
    List<Map<String, dynamic>> groupRankings = [];
    for (int i = 0; i < groups.length; i++) {
      List<Map<String, dynamic>?> group = groups[i];
      List<Map<String, dynamic>> validPlayers = group.where((player) => player != null).cast<Map<String, dynamic>>().toList();
      
      if (validPlayers.isNotEmpty) {
        double average = validPlayers.first['avg_net']?.toDouble() ?? 0.0;
        groupRankings.add({
          'groupIndex': i,
          'average': average,
          'players': validPlayers,
        });
      }
    }
    
    // Sort groups by average (lowest average = best position)
    groupRankings.sort((a, b) => a['average'].compareTo(b['average']));
    
    // Get payout amounts from CSV based on original selected players (not including wildcards)
    int originalPlayers = 0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['is_wild_card'] != true) {
          originalPlayers++;
        }
      }
    }
    
    try {
      Map<String, double> groupPayouts = await GroupCsvPayoutService().getPayoutAmounts(originalPlayers);
      
      double teamTotal = groupPayouts['team_total'] ?? 0.0;
      double firstTeam = groupPayouts['1st_team_ind'] ?? 0.0;
      double secondTeam = groupPayouts['2nd_team_ind'] ?? 0.0;
      double thirdTeam = groupPayouts['3rd_team_ind'] ?? 0.0;
      double fourthTeam = groupPayouts['4th_team_ind'] ?? 0.0;
      
      List<double> payouts = [firstTeam, secondTeam, thirdTeam, fourthTeam];
      
      // Assign positions and payouts
      setState(() {
        for (int i = 0; i < groupRankings.length && i < 4; i++) {
          var groupData = groupRankings[i];
          List<Map<String, dynamic>> players = groupData['players'];
          int position = i + 1;
          double individualPayout = i < payouts.length ? payouts[i] : 0.0; // CSV already has per-player amounts
          double groupTotalPayout = individualPayout * players.length;
          
          // Set position and payout for all players in this group
          for (var player in players) {
            player['pos'] = position;
            player['group_place'] = position;
            player['group_winnings'] = individualPayout;
            player['prize_money'] = individualPayout;
          }
        }
      });
      
    } catch (e) {
      // Fallback - just assign positions without payouts
      setState(() {
        for (int i = 0; i < groupRankings.length; i++) {
          var groupData = groupRankings[i];
          List<Map<String, dynamic>> players = groupData['players'];
          int position = i + 1;
          
          for (var player in players) {
            player['pos'] = position;
            player['group_place'] = position;
            player['group_winnings'] = 0.0;
            player['prize_money'] = 0.0;
          }
        }
      });
    }
  }

  Future<void> _calculateGroupWinnings(List<Map<String, dynamic>> groupScores) async {
    
    // Get group purse directly from CSV
    try {
      Map<String, double> groupPayoutData = await GroupCsvPayoutService().getPayoutAmounts(selectedPlayers.length);
      double groupPurse = groupPayoutData['team_total'] ?? 0.0;

      // Assign rankings
      for (int i = 0; i < groupScores.length; i++) {
        groupScores[i]['place'] = i + 1;
      }

      // Get payout structure based on number of groups
      Map<int, double> payoutStructure = _getGroupPayoutStructure(groupScores.length);

      // Calculate winnings for each group
      for (var group in groupScores) {
        int place = group['place'];
        double payoutRatio = payoutStructure[place] ?? 0.0;
        group['group_winnings'] = (groupPurse * payoutRatio / 100.0);
      }
    } catch (e) {
      // If CSV fails, set all group winnings to 0
      for (var group in groupScores) {
        group['group_winnings'] = 0.0;
      }
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
                League.wednesday
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

  void _processIndividuals() async {
    // Close the keyboard
    FocusScope.of(context).unfocus();
    
    List<Map<String, dynamic>> playerScores = _collectPlayerScores();
    
    if (playerScores.isEmpty) {
      PopupUtils.showWarning(context, "Process Error", "No player scores available to process!");
      return;
    }
    
    try {
      // Process individuals inline
      await _calculateIndividualWinnings(playerScores);
      
      // Update players in groups with calculated pos and prize_money values
      for (var playerScore in playerScores) {
        for (var group in groups) {
          for (int i = 0; i < group.length; i++) {
            var player = group[i];
            if (player != null && 
                player['first'] == playerScore['first'] && 
                player['last'] == playerScore['last']) {
              player['pos'] = playerScore['pos'] ?? '';
              player['prize_money'] = playerScore['prize_money'] ?? '';
              break;
            }
          }
        }
      }
      
      // Clear focus from all input fields and hide keyboard
      FocusScope.of(context).unfocus();
      
      // Clear focus from all gross input controllers
      for (var focusNode in grossFocusNodes.values) {
        focusNode.unfocus();
      }
      
      setState(() {
        individualsProcessingComplete = true;
      });
      
      await updateTitleInformation();
      
      await PopupUtils.showSuccess(context, "Process Complete", "Individual standings and payouts have been calculated successfully!");
      
    } catch (e) {
      await PopupUtils.showError(context, "Process Error", "Failed to process individuals: $e");
    }
  }

  Future<void> _calculateIndividualWinnings(List<Map<String, dynamic>> playerScores) async {
    // Sort players by score
    if (selectedLeague == 'wednesday') {
      playerScores.sort((a, b) => a['net_score'].compareTo(b['net_score']));
    } else {
      playerScores.sort((a, b) => a['gross_score'].compareTo(b['gross_score']));
    }
    
    // Get payout amounts from CSV
    List<double> payoutList = await CsvPayoutService().getPayoutList(playerScores.length);
    
    // Group players by their scores to identify ties
    List<List<Map<String, dynamic>>> tieGroups = [];
    int currentIndex = 0;
    
    while (currentIndex < playerScores.length) {
      List<Map<String, dynamic>> tiedPlayers = [playerScores[currentIndex]];
      dynamic currentScore = selectedLeague == 'wednesday' 
          ? playerScores[currentIndex]['net_score'] 
          : playerScores[currentIndex]['gross_score'];
      
      // Find all players with the same score
      for (int i = currentIndex + 1; i < playerScores.length; i++) {
        dynamic compareScore = selectedLeague == 'wednesday'
            ? playerScores[i]['net_score']
            : playerScores[i]['gross_score'];
        
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

    // Set pos and prize_money for display
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
  }

  List<Map<String, dynamic>> _collectPlayerScores() {
    List<Map<String, dynamic>> playerScores = [];
    Set<String> addedPlayers = {}; // Track players already added
    
    // Collect scores from all groups
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          String playerKey = '${player['last']}_gross';
          String playerIdentifier = '${player['first']}_${player['last']}';
          TextEditingController? controller = grossControllers[playerKey];
          
          // Only add if player hasn't been added already and has a score
          if (controller != null && controller.text.isNotEmpty && !addedPlayers.contains(playerIdentifier)) {
            var playerData = Map<String, dynamic>.from(player);
            
            try {
              playerData['gross_score'] = int.parse(controller.text);
              
              if (selectedLeague == 'wednesday') {
                double handicap = playerData['handicap']?.toDouble() ?? 0.0;
                playerData['net_score'] = playerData['gross_score'] - handicap.round();
              }
              
              playerScores.add(playerData);
              addedPlayers.add(playerIdentifier); // Mark as added
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
      // If CSV fails, set payouts to zero since we rely on CSV data
      payoutAmounts = [0.0, 0.0, 0.0, 0.0];
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

  Future<void> _balanceMulliganPurse(List<Map<String, dynamic>> players) async {
    // Calculate total actual payouts
    double totalActualPayouts = 0.0;
    for (var player in players) {
      double winnings = player['winnings']?.toDouble() ?? 0.0;
      totalActualPayouts += winnings;
    }
    
    // Get the total number of selected players (not just those with scores)
    int totalSelectedPlayers = 0;
    for (var group in groups) {
      totalSelectedPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    // Get the expected total from CSV using total selected players
    try {
      Map<String, double> payoutData = await CsvPayoutService().getPayoutAmounts(totalSelectedPlayers);
      double expectedTotal = payoutData['total_individual'] ?? 0.0;
      
      // Calculate the overage (actual - expected)
      double overage = totalActualPayouts - expectedTotal;
      
      // Get current mulligan purse amount (what's currently displayed)
      double currentMulliganPurse = _adjustedMulliganPurse;
      
      // Simply subtract the overage from current amount
      _adjustedMulliganPurse = currentMulliganPurse - overage;
      
      // Mark that balancing has been done
      _mulliganPurseBalanced = true;
      
    } catch (e) {
      // Error handling - keep original amount if CSV lookup fails
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
    
    if (!groupsProcessed || selectedLeague != 'wednesday') {
      return;
    }
    
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
    
    // Get actual prize amounts from CSV
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

    PayoutValidationResult? validationResult = await validateGroupProcessingResults();
    if (validationResult != null && validationResult.requiresAdjustment) {
      // Update the adjusted mulligan purse based on validation results
      _adjustedMulliganPurse = validationResult.adjustedMulliganPurse;
      
      // Show validation message to user via SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationResult.description),
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      // Update display of mulligan purse
      setState(() {
        _mulliganPurseDisplayText = '\$${_adjustedMulliganPurse.toStringAsFixed(2)}';
      });
    }
    
    // Save the adjusted mulligan purse after group processing (Step 7)
    await _saveAdjustedMulliganPurse(_adjustedMulliganPurse);
    
    // After calculating group winnings, save them to the database
    await _saveGroupWinningsToDatabase();
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
    }
  }

  Future<void> _balanceMulliganPurseForGroups() async {
    // Calculate total actual group payouts
    double totalActualGroupPayouts = 0.0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          double groupWinnings = player['group_winnings']?.toDouble() ?? 0.0;
          totalActualGroupPayouts += groupWinnings;
        }
      }
    }
    
    // Get total number of selected players (excluding wild cards)
    int totalSelectedPlayers = 0;
    for (var group in groups) {
      totalSelectedPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
    }
    
    // Get expected group total from CSV payout data
    try {
      Map<String, double> groupPayoutData = await GroupCsvPayoutService().getPayoutAmounts(totalSelectedPlayers);
      double expectedGroupTotal = groupPayoutData['groups_total'] ?? 0.0;
      
      // Calculate overage/underage (actual - expected)
      double groupOverage = totalActualGroupPayouts - expectedGroupTotal;
      
      // Adjust the mulligan purse by subtracting the group overage
      // This ensures the total payout pool remains consistent
      _adjustedMulliganPurse = _adjustedMulliganPurse - groupOverage;
      
      // Mark that balancing has been done (or update existing balance)
      _mulliganPurseBalanced = true;
      
      // Update the display
      setState(() {
        _mulliganPurseDisplayText = '\$${_adjustedMulliganPurse.toStringAsFixed(2)}';
      });
      
    } catch (e) {
      // If CSV lookup fails, keep the current mulligan purse amount
      // This prevents errors from breaking the balancing system
    }
  }

  Future<void> _saveGroupWinningsToDatabase() async {
    if (!groupsProcessed || selectedLeague != 'wednesday') {
      return;
    }

    final dbHelper = DatabaseHelper();
    int playersProcessed = 0;
    
    // Update group winnings for each player in the database
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          
          if (player['group_winnings'] != null && player['group_winnings'] > 0) {
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
                int rowsUpdated = await dbHelper.updateGroupWinnings(
                  playerId, 
                  roundedGroupWinnings.toDouble(), 
                  League.wednesday
                );

                playersProcessed++;
              } else {
              }
            } catch (e) {
              //print("DEBUG: Error saving group winnings for ${player['first']} ${player['last']}: $e");
            }
          } else {
            //print("DEBUG: Player has no group winnings or winnings is 0");
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
        
        // Wednesday League: save to wednesday_scores table  
        scoreData['golf_course'] = 'The Hideout'; // Golf Course for Wednesday League
        scoreData['single_winnings'] = roundedWinnings.toDouble(); // Single Winnings from Enter Scores Screen
        
        // Round group winnings to whole dollars
        double groupWinnings = (player['group_winnings'] ?? 0.0).toDouble();
        int roundedGroupWinnings = groupWinnings.round();
        scoreData['group_winnings'] = roundedGroupWinnings.toDouble(); // Group Winnings from Enter Scores Screen
        
        // Save to the appropriate league table (this will automatically limit to 20 scores and lock the row)
        await dbHelper.insertScoreLeague(scoreData, League.wednesday);
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
          'place': player['place'],
          'winnings': roundedWinnings,
        });
      }
    }
    
    if (playerResults.isNotEmpty) {
      // Determine ante amount
      double anteAmount = AnteManager().currentAnteAmount;
      
      // Save to legacy game system
      await dbHelper.saveGameResults(
        league: League.wednesday,
        anteAmount: anteAmount,
        playerResults: playerResults,
      );

      await validateGroupProcessingResults();
    }
  }

  Future<PayoutValidationResult?> validateGroupProcessingResults() async {
    try {
      // Get total number of selected players (excluding wild cards)
      int totalSelectedPlayers = 0;
      for (var group in groups) {
        totalSelectedPlayers += group.where((player) => player != null && player['is_wild_card'] != true).length;
      }
      
      // Get current mulligan purse amount
      double currentMulliganPurse = MulliganManager().currentMulliganAmount * totalSelectedPlayers;
      
      League currentLeague = selectedLeague == 'monday' ? League.monday : League.wednesday;

      // Check for stored adjusted amount from individual processing
      String leagueStr = currentLeague == League.monday ? 'monday' : 'wednesday';
      double? storedAdjustedAmount = await DatabaseHelper().getAdjustedMulliganPurse(leagueStr);
      
      // Validate group payouts using the centralized service
      PayoutValidationResult result = await PayoutValidationService().validateGroupPayouts(
        groups: groups,
        league: currentLeague,
        totalSelectedPlayers: totalSelectedPlayers,
        currentMulliganPurse: currentMulliganPurse,
      );
      
      
      return result;
    } catch (e) {
      return null;
    }
  }
}