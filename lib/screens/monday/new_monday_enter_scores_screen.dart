import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/enter_scores_UI_service.dart';
import '../../services/auto_fill_service.dart';

class NewMondayEnterScoresScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? selectedPlayers;
  
  const NewMondayEnterScoresScreen({Key? key, this.selectedPlayers}) : super(key: key);

  @override
  _NewMondayEnterScoresScreenState createState() => _NewMondayEnterScoresScreenState();
}

class _NewMondayEnterScoresScreenState extends State<NewMondayEnterScoresScreen> {
  List<List<PlayerData>> groups = [
    [],
    [],
    [],
    [],
    [],
    [],
    [],
    [],
    [],
    []
  ];


  @override
  void initState() {
    super.initState();
    _populateGroupsWithSelectedPlayers();
    
    // Set orientation preferences based on device type after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EnterScoresUIService.setOrientationForDevice(context);
    });
  }
  
  @override
  void dispose() {
    // Don't reset orientation here since we handle it in the Return button
    // This prevents brief portrait flash when returning to player selection
    super.dispose();
  }

  /// Populates the group rows with randomly shuffled selected players from monday_player_selection_screen
  /// Randomly shuffles players before filling groups starting with Group 1, adding up to 4 players per group
  /// Uses player last names and SK numbers from the selected players list
  void _populateGroupsWithSelectedPlayers() {
    if (widget.selectedPlayers != null && widget.selectedPlayers!.isNotEmpty) {
      // Clear existing groups
      for (int i = 0; i < groups.length; i++) {
        groups[i].clear();
      }

      // Create a copy of selected players and randomly shuffle them
      List<Map<String, dynamic>> shuffledPlayers = List.from(widget.selectedPlayers!);
      final random = Random();
      shuffledPlayers.shuffle(random);

      // Populate groups starting with Group 1 (index 0)
      int currentGroupIndex = 0;
      int playersInCurrentGroup = 0;
      
      for (var player in shuffledPlayers) {
        // If current group is full (4 players), move to next group
        if (playersInCurrentGroup >= 4) {
          currentGroupIndex++;
          playersInCurrentGroup = 0;
          
          // Stop if we've filled all 10 groups
          if (currentGroupIndex >= 10) break;
        }
        
        // Add player to current group using last name and SKAT number from database
        groups[currentGroupIndex].add(PlayerData(
          name: player['last'] ?? '',
          skNumber: player['skat_number']?.toString() ?? '', // Using skat_number field from player profile database
        ));
        
        playersInCurrentGroup++;
      }
    }
  }

  /// Auto fills SKATS data with random values between 30-40 for all players
  void _handleAutoFill() {
    print("Auto Fill button pressed!");
    print("Groups before auto fill: ${groups.map((g) => g.map((p) => "${p.name}: ${p.skats}").toList()).toList()}");
    
    setState(() {
      groups = AutoFillService.autoFillSkats(groups);
    });
    
    print("Groups after auto fill: ${groups.map((g) => g.map((p) => "${p.name}: ${p.skats}").toList()).toList()}");
  }

  /// Handles the Return button press with proper orientation management
  void _handleReturn() {
    // Set landscape orientation before popping to prevent brief portrait flash
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Navigator.pop(context);
  }

//************************************************************************************************
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          EnterScoresUIService.buildPurseHeader(context),
          EnterScoresUIService.buildGroupsGrid(context, groups),
          EnterScoresUIService.buildBottomButtons(
            context,
            onReturn: _handleReturn,
            onAutoFill: _handleAutoFill,
          ),
        ],
      ),
    );
  }

}
