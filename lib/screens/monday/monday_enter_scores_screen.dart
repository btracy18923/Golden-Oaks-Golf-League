import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/factories/auto_fill_factory.dart';
import '../../services/shared/swap_service.dart';
import '../../services/shared/league_purse_service.dart';
import '../../models/league.dart';

class MondayEnterScoresScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? selectedPlayers;
  final double? playersAnte;
  
  const MondayEnterScoresScreen({Key? key, this.selectedPlayers, this.playersAnte}) : super(key: key);

  @override
  _MondayEnterScoresScreenState createState() => _MondayEnterScoresScreenState();
}

class _MondayEnterScoresScreenState extends State<MondayEnterScoresScreen> {
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

  // Swap service instance
  final SwapService _swapService = SwapService();


  @override
  void initState() {
    super.initState();
    _populateGroupsWithSelectedPlayers();
    
    // Set the Players Ante value if it was passed as a parameter
    if (widget.playersAnte != null) {
      LeaguePurseService.setPlayersAnte(widget.playersAnte!);
    }
    
    // Load secondary purse amounts (Closest Pin, Mulligan) without overwriting Players Ante
    LeaguePurseService.loadSecondaryPurseAmounts();
    
    // Calculate Skat Purse based on selected players count
    if (widget.selectedPlayers != null) {
      LeaguePurseService.calculateSkatPurseFromCount(widget.selectedPlayers!.length);
      // Calculate Closest Pin Purse based on selected players count
      LeaguePurseService.calculateClosestPinPurseFromCount(widget.selectedPlayers!.length);
      // Calculate Mulligan Purse based on selected players count
      LeaguePurseService.calculateMulliganPurseFromCount(widget.selectedPlayers!.length);
    }
    
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

  /// Handles the swap players functionality
  void _handleSwapPlayers() {
    print("Swap Players button pressed!");
    final updatedGroups = _swapService.handleSwapButtonPress(context, groups);
    if (updatedGroups != null) {
      setState(() {
        groups = updatedGroups;
      });
      print("Players swapped successfully");
    }
  }

  /// Handles player tap for swap selection
  void _onPlayerTap(int groupIndex, int playerIndex, PlayerData player) {
    print("Player tapped: ${player.name}");
    setState(() {
      _swapService.handlePlayerSelection(player.name);
    });
  }

  /// Handles empty slot tap for swap selection
  void _onEmptySlotTap(int groupIndex, int playerIndex) {
    String slotKey = 'empty_${groupIndex + 1}_$playerIndex';
    print("Empty slot tapped: $slotKey");
    setState(() {
      _swapService.handleEmptySlotSelection(slotKey);
    });
  }

  /// Checks if a player is selected for swapping
  bool _isPlayerSelected(PlayerData player) {
    return _swapService.isPlayerSelected(player.name);
  }

  /// Checks if an empty slot is selected for swapping
  bool _isEmptySlotSelected(int groupIndex, int playerIndex) {
    String slotKey = 'empty_${groupIndex + 1}_$playerIndex';
    return _swapService.isEmptySlotSelected(slotKey);
  }

  /// Gets the color for the SWAP button based on selection state
  Color _getSwapButtonColor() {
    if (_swapService.selectionCount == 2) {
      return Colors.green[400]!; // Medium green when 2nd player is selected
    } else {
      return Colors.grey[400]!; // Grey for default state and after swap is completed
    }
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

  /// Builds bottom buttons with dynamic SWAP button text
  Widget _buildBottomButtonsWithSwap() {
    final deviceType = EnterScoresUIService.getDeviceType(context);
    final padding = EnterScoresUIService.getResponsivePadding(deviceType);
    
    return Container(
      color: Colors.grey[300],
      padding: EdgeInsets.all(padding.left / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCustomButton(context, 'Return', Colors.blue[200]!, _handleReturn),
          _buildCustomButton(context, 'Closest Pin', Colors.green[200]!, () {}),
          _buildCustomButton(context, 'Auto Fill', Colors.orange[200]!, _handleAutoFill),
          _buildCustomButton(context, _swapService.getSwapButtonText(), _getSwapButtonColor(), _handleSwapPlayers),
        ],
      ),
    );
  }

  /// Builds a custom button with dynamic text support
  Widget _buildCustomButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    final deviceType = EnterScoresUIService.getDeviceType(context);
    final fontSize = EnterScoresUIService.getResponsiveFontSize(deviceType, isHeader: true);
    final padding = EnterScoresUIService.getResponsivePadding(deviceType);
    
    // Adjust button text for smaller screens
    String displayText = text;
    if (deviceType == DeviceType.phone6_5) {
      if (text == 'Closest Pin') displayText = 'ClosePin';
      if (text.startsWith('SWAP') && text != 'SWAP Players') displayText = 'SWAP'; // Keep swap service text short on phones
    }
    
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding.left / 2),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(vertical: padding.top / 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
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
          EnterScoresUIService.buildPurseHeader(context, League.monday),
          EnterScoresUIService.buildGroupsGrid(
            context, 
            groups,
            onPlayerTap: _onPlayerTap,
            onEmptySlotTap: _onEmptySlotTap,
            isPlayerSelected: _isPlayerSelected,
            isEmptySlotSelected: _isEmptySlotSelected,
          ),
          _buildBottomButtonsWithSwap(),
        ],
      ),
    );
  }

}
