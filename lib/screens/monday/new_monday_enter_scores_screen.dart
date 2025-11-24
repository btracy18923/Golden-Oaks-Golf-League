import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/factories/auto_fill_factory.dart';
import '../../models/league.dart';

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
  /// Randomly shuffles players before filling groups starting with Group 1, ensuring each group has at least 3 players
  /// Uses player last names and SK numbers from the selected players list
  void _populateGroupsWithSelectedPlayers() {
    if (widget.selectedPlayers != null && widget.selectedPlayers!.isNotEmpty) {
      // Clear existing groups
      for (int i = 0; i < groups.length; i++) {
        groups[i].clear();
      }

      final totalPlayers = widget.selectedPlayers!.length;
      
      // Handle edge cases
      if (totalPlayers < 4) {
        // If less than 4 players, put all in Group 1
        for (var player in widget.selectedPlayers!) {
          groups[0].add(PlayerData(
            name: player['last'] ?? '',
            skNumber: player['skat_number']?.toString() ?? '',
          ));
        }
        return;
      }
      
      if (totalPlayers == 5) {
        // Special case: 5 players - put 3 in first group, 2 in second group
        List<Map<String, dynamic>> shuffledPlayers = List.from(widget.selectedPlayers!);
        final random = Random();
        shuffledPlayers.shuffle(random);
        
        // Add first 3 players to Group 1
        for (int i = 0; i < 3; i++) {
          groups[0].add(PlayerData(
            name: shuffledPlayers[i]['last'] ?? '',
            skNumber: shuffledPlayers[i]['skat_number']?.toString() ?? '',
          ));
        }
        
        // Add remaining 2 players to Group 2
        for (int i = 3; i < 5; i++) {
          groups[1].add(PlayerData(
            name: shuffledPlayers[i]['last'] ?? '',
            skNumber: shuffledPlayers[i]['skat_number']?.toString() ?? '',
          ));
        }
        return;
      }

      // Create a copy of selected players and randomly shuffle them
      List<Map<String, dynamic>> shuffledPlayers = List.from(widget.selectedPlayers!);
      final random = Random();
      shuffledPlayers.shuffle(random);

      // Calculate optimal group distribution ensuring 3+ players per group
      int numGroups;
      if (totalPlayers <= 4) {
        numGroups = 1;
      } else if (totalPlayers <= 8) {
        numGroups = 2;
      } else if (totalPlayers <= 12) {
        numGroups = 3;
      } else if (totalPlayers <= 16) {
        numGroups = 4;
      } else if (totalPlayers <= 20) {
        numGroups = 5;
      } else if (totalPlayers <= 24) {
        numGroups = 6;
      } else if (totalPlayers <= 28) {
        numGroups = 7;
      } else if (totalPlayers <= 32) {
        numGroups = 8;
      } else if (totalPlayers <= 36) {
        numGroups = 9;
      } else {
        numGroups = 10;
      }

      // Distribute players evenly across calculated number of groups
      int playersPerGroup = totalPlayers ~/ numGroups;
      int remainingPlayers = totalPlayers % numGroups;
      
      int playerIndex = 0;
      for (int groupIndex = 0; groupIndex < numGroups; groupIndex++) {
        int playersInThisGroup = playersPerGroup;
        
        // Distribute remaining players to first groups
        if (groupIndex < remainingPlayers) {
          playersInThisGroup++;
        }
        
        // Add players to this group
        for (int i = 0; i < playersInThisGroup; i++) {
          if (playerIndex < shuffledPlayers.length) {
            var player = shuffledPlayers[playerIndex];
            groups[groupIndex].add(PlayerData(
              name: player['last'] ?? '',
              skNumber: player['skat_number']?.toString() ?? '',
            ));
            playerIndex++;
          }
        }
      }
    }
  }

  /// Auto fills SKATS data with random values between 30-40 for all players
  void _handleAutoFill() {
    print("Auto Fill button pressed!");
    print("Groups before auto fill: ${groups.map((g) => g.map((p) => "${p.name}: ${p.skats}").toList()).toList()}");
    
    setState(() {
      final autoFillService = AutoFillFactory.create(League.monday);
      groups = autoFillService.autoFillData(groups);
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
