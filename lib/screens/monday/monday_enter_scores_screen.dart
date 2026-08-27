import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../services/shared/swap_service.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/payout_validation_service.dart';
import '../../services/database_helper.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/skat_adjustment_service.dart';
import '../../models/league.dart';
import 'monday_results_screen.dart';
import 'monday_closest_pin_screen.dart';

class MondayEnterScoresScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? selectedPlayers;
  final double? playersAnte;
  
  const MondayEnterScoresScreen({super.key, this.selectedPlayers, this.playersAnte});

  @override
  State<MondayEnterScoresScreen> createState() => _MondayEnterScoresScreenState();
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

  // Custom keypad controller
  late CustomKeypadController _keypadController;
  
  // Currently focused player for keypad input
  PlayerData? _currentFocusedPlayer;
  
  // Counter for consecutive backspace key presses (removed)
  // int _consecutiveBackspacePresses = 0;
  
  // Track if players have been shuffled in this session
  bool _shuffledInCurrentSession = false;
  
  // Track if players were previously shuffled (from navigation/storage)
  bool _hasBeenShuffled = false;

  // Track payout amount for display in app bar
  double _payoutAmount = 0.0;

  // Adjust Players overlay state
  bool _showAdjustPlayersOverlay = false;

  // Triple-click delete functionality
  String? _deleteTargetPlayerName;
  int _deleteTargetTapCount = 0;

  // Triple-tap add-player functionality for empty slots
  String? _addTargetSlotKey;
  int _addTargetTapCount = 0;

  // Firebase groupings state
  bool _hasFirebaseGroupings = false;

  // Focus nodes for SKATS input fields - organized by group and player index
  final List<List<FocusNode?>> _skatsFocusNodes = [
    [null, null, null, null], // Group 0 (Group 1)
    [null, null, null, null], // Group 1 (Group 2)
    [null, null, null, null], // Group 2 (Group 3)
    [null, null, null, null], // Group 3 (Group 4)
    [null, null, null, null], // Group 4 (Group 5)
    [null, null, null, null], // Group 5 (Group 6)
    [null, null, null, null], // Group 6 (Group 7)
    [null, null, null, null], // Group 7 (Group 8)
    [null, null, null, null], // Group 8 (Group 9)
    [null, null, null, null], // Group 9 (Group 10)
  ];


  @override
  void initState() {
    super.initState();
    _keypadController = CustomKeypadService.createController();
    _initializeFocusNodes();
    _checkFirebaseGroupings();
    
    // Reset distribution state for fresh calculations
    LeaguePurseService.resetDistributionState();

    // Set the Players Ante value if it was passed as a parameter
    if (widget.playersAnte != null) {
      LeaguePurseService.setPlayersAnte(widget.playersAnte!);
    }

    // Load secondary purse amounts (Closest Pin, Mulligan) without overwriting Players Ante
    LeaguePurseService.loadSecondaryPurseAmounts();

    // Recalculate Skat Purse fresh every time: # of players × Player Ante
    if (widget.selectedPlayers != null && widget.playersAnte != null) {
      double freshSkatPurse = widget.selectedPlayers!.length * widget.playersAnte!;
      LeaguePurseService.setSkatPurse(freshSkatPurse);

      // Only calculate Closest Pin Purse if NOT returning from Closest Pin screen
      // If returning from Closest Pin screen, the purse has already been updated with remaining amount
      if (!ScreenDataRetentionService().hasClosestPinData()) {
        // Calculate Closest Pin Purse: Closest Pin Amount × Number of Players
        double closestPinPurse = LeaguePurseService.closestPinAmount * widget.selectedPlayers!.length;
        LeaguePurseService.setClosestPinPurse(closestPinPurse, isExplicit: false);
      }

      // Calculate Mulligan Purse: Mulligan Amount × Number of Players
      double mulliganPurse = LeaguePurseService.mulliganAmount * widget.selectedPlayers!.length;
      LeaguePurseService.setMulliganPurse(mulliganPurse, isExplicit: false);
    } else if (widget.selectedPlayers != null) {
      // Fallback to existing method if playersAnte is not provided
      LeaguePurseService.calculateSkatPurseFromCount(widget.selectedPlayers!.length);

      // Only calculate Closest Pin Purse if NOT returning from Closest Pin screen
      if (!ScreenDataRetentionService().hasClosestPinData()) {
        // Calculate Closest Pin Purse: Closest Pin Amount × Number of Players
        double closestPinPurse = LeaguePurseService.closestPinAmount * widget.selectedPlayers!.length;
        LeaguePurseService.setClosestPinPurse(closestPinPurse, isExplicit: false);
      }

      // Calculate Mulligan Purse: Mulligan Amount × Number of Players
      double mulliganPurse = LeaguePurseService.mulliganAmount * widget.selectedPlayers!.length;
      LeaguePurseService.setMulliganPurse(mulliganPurse, isExplicit: false);
    }
    
    // Check if shuffle was previously done first, then populate if no saved order
    _initializePlayerGroups();
    
    // Set orientation preferences based on device type after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EnterScoresUIService.setOrientationForDevice(context);
    });
  }
  
  @override
  void dispose() {
    // Dispose of all focus nodes
    _disposeFocusNodes();
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

      // Create a copy of selected players
      List<Map<String, dynamic>> shuffledPlayers = List.from(widget.selectedPlayers!);

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

  /// Initializes focus nodes for all SKATS input fields
  void _initializeFocusNodes() {
    for (int groupIndex = 0; groupIndex < _skatsFocusNodes.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < _skatsFocusNodes[groupIndex].length; playerIndex++) {
        final focusNode = FocusNode();
        
        // Add focus listener to show/hide keypad
        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            _showKeypadForPlayer(groupIndex, playerIndex);
          } else {
            _hideKeypad();
          }
        });
        
        _skatsFocusNodes[groupIndex][playerIndex] = focusNode;
      }
    }
  }

  /// Disposes of all focus nodes to prevent memory leaks
  void _disposeFocusNodes() {
    for (int groupIndex = 0; groupIndex < _skatsFocusNodes.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < _skatsFocusNodes[groupIndex].length; playerIndex++) {
        _skatsFocusNodes[groupIndex][playerIndex]?.dispose();
        _skatsFocusNodes[groupIndex][playerIndex] = null;
      }
    }
  }

  /// Shows the keypad for a specific player's SKATS input
  void _showKeypadForPlayer(int groupIndex, int playerIndex) {
    // Prevent keypad from showing when Adjust Players overlay is visible
    if (_showAdjustPlayersOverlay) {
      return;
    }

    if (groupIndex < groups.length && playerIndex < groups[groupIndex].length) {
      _currentFocusedPlayer = groups[groupIndex][playerIndex];
      _keypadController.setInput(_currentFocusedPlayer?.skats ?? '');
      setState(() {
        _keypadController.show();
      });
    }
  }
  
  /// Hides the keypad
  void _hideKeypad({bool keepFocus = false}) {
    setState(() {
      _keypadController.hide();
      if (!keepFocus) {
        // Unfocus the current field properly
        if (_currentFocusedPlayer != null) {
          _unfocusCurrentField();
        }
        _currentFocusedPlayer = null;
      }
    });
  }

  /// Properly unfocuses the current SKATS field
  void _unfocusCurrentField() {
    if (_currentFocusedPlayer == null) return;
    
    // Find and unfocus the current field's focus node
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
        if (groups[groupIndex][playerIndex].name == _currentFocusedPlayer!.name) {
          final focusNode = _skatsFocusNodes[groupIndex][playerIndex];
          if (focusNode != null && focusNode.hasFocus) {
            focusNode.unfocus();
          }
          return;
        }
      }
    }
  }
  
  /// Programmatically updates a SKATS field value and recalculates DIFF
  void _updateSkatsField(PlayerData player, String newValue) {
    // Find the player in groups and update both SKATS and DIFF
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
        if (groups[groupIndex][playerIndex].name == player.name) {
          // Calculate DIFF only for 2-digit numbers
          String diffValue = '';
          if (newValue.length == 2 && player.skNumber.isNotEmpty) {
            try {
              int skatsNum = int.parse(newValue);
              int skNumber = int.parse(player.skNumber);
              int difference = skatsNum - skNumber;

              if (difference > 0) {
                diffValue = '+$difference';
              } else if (difference < 0) {
                diffValue = '$difference';
              } else {
                diffValue = '0';
              }
            } catch (e) {
              // If parsing fails, keep diffValue empty
              diffValue = '';
            }
          }
          // For 1-digit numbers, keep existing DIFF value or empty if new entry
          else if (newValue.length == 1) {
            // Keep DIFF empty for partial input
            diffValue = '';
          }
          
          // Check if money calculations are active (only recalculate for complete 2-digit input)
          bool shouldRecalculateMoney = _hasMoneyCalculations() && newValue.length == 2;
          
          // Update the player data
          groups[groupIndex][playerIndex] = PlayerData(
            name: player.name,
            skNumber: player.skNumber,
            skats: newValue,
            diff: diffValue,
            money: player.money,
          );
          
          // Recalculate money fields if needed
          if (shouldRecalculateMoney) {
            _recalculateMoneyFields();
          }
          return;
        }
      }
    }
  }

  /// Handles keypad input
  void _handleKeypadInput(String key) {
    if (_currentFocusedPlayer == null) return;

    if (key == 'backspace') {
      // Handle normal backspace functionality
      String? newInput = _keypadController.handleKeyPress(key);
      if (newInput != null) {
        setState(() {
          // Live update the display while typing
          _updateSkatsField(_currentFocusedPlayer!, _keypadController.currentInput);
        });
      }
    } else if (key == 'enter') {

      // Apply current input and move to next field
      String currentInput = _keypadController.currentInput;
      if (currentInput.isNotEmpty) {
        _updateSkatsField(_currentFocusedPlayer!, currentInput);
      }

      // Check if all SKATS are complete and calculate money if so
      if (_areAllSkatsFieldsComplete()) {
        _handleSkatMoney();
      }

      // Find current player position and move to next
      for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
          if (groups[groupIndex][playerIndex].name == _currentFocusedPlayer!.name) {
            _moveToNextSkatsField(groupIndex, playerIndex);
            return;
          }
        }
      }
    } else {
      // Handle digit or backspace input
      String? newInput = _keypadController.handleKeyPress(key);
      if (newInput != null) {
        setState(() {
          // Live update the display while typing
          _updateSkatsField(_currentFocusedPlayer!, _keypadController.currentInput);
        });

        // Auto-advance when 2 digits are entered
        if (_keypadController.currentInput.length == 2) {

          // Check if all SKATS are complete and calculate money if so
          if (_areAllSkatsFieldsComplete()) {
            _handleSkatMoney();
          }

          // Find current player position and move to next after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
              for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
                if (groups[groupIndex][playerIndex].name == _currentFocusedPlayer!.name) {
                  _moveToNextSkatsField(groupIndex, playerIndex);
                  return;
                }
              }
            }
          });
        }
      }
    }
  }

  /// Moves focus to the next available SKATS input field
  void _moveToNextSkatsField(int currentGroupIndex, int currentPlayerIndex) {
    // Failsafe: if all players already have skat numbers, just hide the keypad
    if (_areAllSkatsFieldsComplete()) {
      _hideKeypad();
      return;
    }

    // First, try to move to next player in the same group
    for (int playerIndex = currentPlayerIndex + 1; playerIndex < groups[currentGroupIndex].length; playerIndex++) {
      FocusNode? nextFocus = _skatsFocusNodes[currentGroupIndex][playerIndex];
      if (nextFocus != null) {
        nextFocus.requestFocus();
        return;
      }
    }
    
    // If no more players in current group, move to next group
    for (int groupIndex = currentGroupIndex + 1; groupIndex < groups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
        FocusNode? nextFocus = _skatsFocusNodes[groupIndex][playerIndex];
        if (nextFocus != null) {
          nextFocus.requestFocus();
          return;
        }
      }
    }
    
    // If we reach here, we're at the end - hide keypad
    _hideKeypad();
  }

  /// Calculates Skat money payouts for players with positive DIFF values
  Future<void> _handleSkatMoney() async {
    
    // Check if all SKATS data is entered before proceeding
    if (!_areAllSkatsFieldsComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter SKATS data for all players before calculating money'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Calculate payouts using the payout validation service
    final payoutService = PayoutValidationService();
    Map<String, double> payouts = payoutService.calculateSkatPayouts(groups);
    
    // Update the money field for each player
    setState(() {
      for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
          var player = groups[groupIndex][playerIndex];
          double payout = payouts[player.name] ?? 0.0;

          // Format the payout amount - rounded to whole dollars
          String moneyValue = payout > 0 ? '\$${payout.round().toString()}' : '';

          // Update the player data with the calculated money value
          groups[groupIndex][playerIndex] = PlayerData(
            name: player.name,
            skNumber: player.skNumber,
            skats: player.skats,
            diff: player.diff,
            money: moneyValue,
          );

          if (payout > 0) {
          }
        }
      }

      // Calculate total distributed money and update the Payout field
      double totalDistributed = _calculateTotalDistributedMoney();
      _payoutAmount = totalDistributed;

      // Keep Skat Purse unchanged - don't subtract payouts from it
      // Skat Purse remains at: Selected Players × Player's Ante

      // Adjust Mulligan Purse based on the difference between Skat Purse and Payout
      double currentSkatPurse = LeaguePurseService.skatPurse;
      double difference = totalDistributed - currentSkatPurse;
      double currentMulligan = LeaguePurseService.mulliganPurse;
      double adjustedMulligan = currentMulligan - difference;
      LeaguePurseService.setMulliganPurse(adjustedMulligan);
    });
    
  }


  /// Handles the swap players functionality
  void _handleSwapPlayers() {
    final updatedGroups = _swapService.handleSwapButtonPress(context, groups);
    if (updatedGroups != null) {
      setState(() {
        groups = updatedGroups;
      });
    }
  }

  /// Handles player tap for swap selection
  void _onPlayerTap(int groupIndex, int playerIndex, PlayerData player) {

    // Prevent any swap functionality if SKATS data exists
    if (_hasAnySkatsData()) {
      return;
    }

    setState(() {
      // Track triple-click for delete (only in adjust players overlay)
      if (_showAdjustPlayersOverlay) {
        if (_deleteTargetPlayerName == player.name) {
          if (_deleteTargetTapCount >= 3) {
            // 4th click - cancel delete mode
            _resetDeleteMode();
            _swapService.clearSelection();
            return;
          }
          _deleteTargetTapCount++;
          // On 2nd and 3rd click, don't pass through to swap service
          return;
        } else {
          // Different player tapped - reset delete tracking
          _resetDeleteMode();
          _deleteTargetPlayerName = player.name;
          _deleteTargetTapCount = 1;
        }
      }

      _swapService.handlePlayerSelection(player.name);
    });
  }

  /// Handles empty slot tap — triple-tap in Adjust Players overlay adds a player,
  /// otherwise handles swap selection.
  void _onEmptySlotTap(int groupIndex, int playerIndex) {
    if (_hasAnySkatsData()) return;

    if (_showAdjustPlayersOverlay) {
      // If a player is already selected for swap, select this slot for swap
      if (_swapService.selectionCount > 0 && _swapService.selectionCount < 2) {
        final swapKey = 'empty_${groupIndex + 1}_$playerIndex';
        setState(() {
          _resetAddMode();
          _swapService.handleEmptySlotSelection(swapKey);
        });
        return;
      }

      // Otherwise triple-tap opens the add-player picker
      final slotKey = '${groupIndex}_$playerIndex';
      bool showPicker = false;
      setState(() {
        if (_addTargetSlotKey == slotKey) {
          if (_addTargetTapCount >= 3) {
            _resetAddMode();
          } else {
            _addTargetTapCount++;
            if (_addTargetTapCount >= 3) showPicker = true;
          }
        } else {
          _resetAddMode();
          _addTargetSlotKey = slotKey;
          _addTargetTapCount = 1;
        }
      });
      if (showPicker) {
        _showAddPlayerDialog(groupIndex, playerIndex);
        setState(() => _resetAddMode());
      }
      return;
    }

    String slotKey = 'empty_${groupIndex + 1}_$playerIndex';
    setState(() {
      _swapService.handleEmptySlotSelection(slotKey);
    });
  }

  void _resetAddMode() {
    _addTargetSlotKey = null;
    _addTargetTapCount = 0;
  }

  Future<void> _showAddPlayerDialog(int groupIndex, int playerIndex) async {
    final Set<String> inGroups = {};
    for (var group in groups) {
      for (var player in group) {
        inGroups.add(player.name);
      }
    }

    final allPlayers = await DatabaseHelper().getPlayersByLeague(League.monday);
    final unassigned = allPlayers
        .where((p) => !inGroups.contains(p['last'] ?? ''))
        .toList()
      ..sort((a, b) => (a['last'] ?? '').compareTo(b['last'] ?? ''));

    if (!mounted) return;

    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unassigned players available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Player'),
        content: SizedBox(
          width: 240,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unassigned.length,
            itemBuilder: (_, i) {
              final player = unassigned[i];
              final skatNum = player['skat_number']?.toString() ?? '';
              return ListTile(
                title: Text(player['last'] ?? ''),
                trailing: skatNum.isNotEmpty
                    ? Text('SKAT $skatNum',
                        style: const TextStyle(fontSize: 12, color: Colors.grey))
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    groups[groupIndex].add(PlayerData(
                      name: player['last'] ?? '',
                      skNumber: player['skat_number']?.toString() ?? '',
                    ));
                    int newPlayerCount = 0;
                    for (var group in groups) {
                      newPlayerCount += group.length;
                    }
                    final ante = LeaguePurseService.playersAnte;
                    LeaguePurseService.setSkatPurse(ante * newPlayerCount);
                    LeaguePurseService.setClosestPinPurse(LeaguePurseService.closestPinAmount * newPlayerCount, isExplicit: false);
                    LeaguePurseService.setMulliganPurse(LeaguePurseService.mulliganAmount * newPlayerCount, isExplicit: false);
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Checks if a player is selected for swapping or delete
  bool _isPlayerSelected(PlayerData player) {
    // Prevent highlighting if SKATS data exists
    if (_hasAnySkatsData()) {
      return false;
    }
    // Keep player highlighted during delete progression
    if (_deleteTargetPlayerName == player.name && _deleteTargetTapCount >= 1) {
      return true;
    }
    return _swapService.isPlayerSelected(player.name);
  }

  /// Returns the background color for a player based on delete tap count
  Color? _getPlayerSelectedColor(PlayerData player) {
    if (_deleteTargetPlayerName == player.name) {
      if (_deleteTargetTapCount >= 3) return Colors.red;
      if (_deleteTargetTapCount == 2) return Colors.purple[200];
    }
    return null; // Use default color (blue[100] for swap selection)
  }

  /// Checks if an empty slot is selected for swapping or add-player progression
  bool _isEmptySlotSelected(int groupIndex, int playerIndex) {
    if (_hasAnySkatsData()) return false;
    if (_showAdjustPlayersOverlay &&
        _addTargetSlotKey == '${groupIndex}_$playerIndex') {
      return true;
    }
    String slotKey = 'empty_${groupIndex + 1}_$playerIndex';
    return _swapService.isEmptySlotSelected(slotKey);
  }

  /// Checks if a specific player is currently focused for SKATS input
  bool _isPlayerFocused(PlayerData player) {
    return _currentFocusedPlayer?.name == player.name;
  }

  /// Checks if any player has money calculated (indicates Skat $$$ button was used)
  bool _hasMoneyCalculations() {
    for (var group in groups) {
      for (var player in group) {
        if (player.money.isNotEmpty && player.money.contains('\$')) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if all players have complete SKATS data (2-digit numbers)
  bool _areAllSkatsFieldsComplete() {
    for (var group in groups) {
      for (var player in group) {
        // Check if player has a name (is not empty slot) and SKATS field is incomplete
        if (player.name.isNotEmpty) {
          if (player.skats.length != 2) {
            return false;
          }
          // Additional validation: check if it's a valid 2-digit number
          try {
            int.parse(player.skats);
          } catch (e) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Checks if any player has SKATS data entered
  bool _hasAnySkatsData() {
    for (var group in groups) {
      for (var player in group) {
        if (player.name.isNotEmpty && player.skats.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calculates the total amount of money distributed to all players
  double _calculateTotalDistributedMoney() {
    double total = 0.0;
    for (var group in groups) {
      for (var player in group) {
        if (player.money.isNotEmpty && player.money.contains('\$')) {
          // Remove $ symbol and parse as double
          String cleanMoney = player.money.replaceAll('\$', '');
          double amount = double.tryParse(cleanMoney) ?? 0.0;
          total += amount;
        }
      }
    }
    return total;
  }

  /// Recalculates all money fields using current DIFF values
  void _recalculateMoneyFields() {
    final payoutService = PayoutValidationService();
    Map<String, double> payouts = payoutService.calculateSkatPayouts(groups);
    
    // Update money fields for all players
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
        var player = groups[groupIndex][playerIndex];
        double payout = payouts[player.name] ?? 0.0;
        
        // Format the payout amount - rounded to whole dollars
        String moneyValue = payout > 0 ? '\$${payout.round().toString()}' : '';
        
        // Update the player data with the calculated money value
        groups[groupIndex][playerIndex] = PlayerData(
          name: player.name,
          skNumber: player.skNumber,
          skats: player.skats,
          diff: player.diff,
          money: moneyValue,
        );
      }
    }
    
    // Calculate total distributed money and update the Payout field
    double totalDistributed = _calculateTotalDistributedMoney();
    _payoutAmount = totalDistributed;

    // Keep Skat Purse unchanged - don't subtract payouts from it
    // Skat Purse remains at: Selected Players × Player's Ante

    // Adjust Mulligan Purse based on the difference between Skat Purse and Payout
    double currentSkatPurse = LeaguePurseService.skatPurse;
    double difference = totalDistributed - currentSkatPurse;
    double currentMulligan = LeaguePurseService.mulliganPurse;
    double adjustedMulligan = currentMulligan - difference;
    LeaguePurseService.setMulliganPurse(adjustedMulligan);
  }

  /// Handles SKATS input change and calculates DIFF automatically
  /// Also recalculates money fields if Skat $$$ button was previously used
  void _onSkatsChanged(PlayerData player, String skatValue) {
    
    // Only process if we have a 2-digit number
    if (skatValue.length == 2) {
      try {
        int skatsNum = int.parse(skatValue);

        // Calculate DIFF (SKATS - SK #)
        String diffValue = '';
        if (player.skNumber.isNotEmpty) {
          int skNumber = int.parse(player.skNumber);
          int difference = skatsNum - skNumber;

          // Format with appropriate sign
          if (difference > 0) {
            diffValue = '+$difference';
          } else if (difference < 0) {
            diffValue = '$difference'; // negative sign already included
          } else {
            diffValue = '0';
          }
        }

        // Check if money calculations are active before updating
        bool shouldRecalculateMoney = _hasMoneyCalculations();

        // Find and update the player in groups, then move focus
        setState(() {
          for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
            for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
              if (groups[groupIndex][playerIndex].name == player.name) {
                groups[groupIndex][playerIndex] = PlayerData(
                  name: player.name,
                  skNumber: player.skNumber,
                  skats: skatValue,
                  diff: diffValue,
                  money: player.money,
                );

                // If money calculations were previously done, recalculate all money fields
                if (shouldRecalculateMoney) {
                  _recalculateMoneyFields();
                }

                // Move focus to next SKATS field after a short delay
                Future.delayed(const Duration(milliseconds: 100), () {
                  _moveToNextSkatsField(groupIndex, playerIndex);
                });
                return; // Exit once found and updated
              }
            }
          }
        });
      } catch (e) {
        // If parsing fails, silently ignore
      }
    }
    // For 1-digit input, update SKATS field but don't calculate DIFF yet
    else if (skatValue.length == 1) {
      setState(() {
        for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
          for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
            if (groups[groupIndex][playerIndex].name == player.name) {
              groups[groupIndex][playerIndex] = PlayerData(
                name: player.name,
                skNumber: player.skNumber,
                skats: skatValue,
                diff: '', // Keep DIFF empty for 1-digit input
                money: player.money,
              );
              return; // Exit once found and updated
            }
          }
        }
      });
    }
  }

  /// Gets the color for the SWAP button based on selection state and SKATS data
  Color _getSwapButtonColor() {
    if (_hasAnySkatsData()) {
      return Colors.grey[400]!; // Green when disabled due to SKATS data
    } else if (_swapService.selectionCount == 2) {
      return Colors.green[400]!; // Medium green when 2nd player is selected
    } else {
      return Colors.green[100]!; // Green for default state and after swap is completed
    }
  }

  /// Initializes player groups - either from saved order or fresh population
  Future<void> _initializePlayerGroups() async {
    try {
      // First check if we're returning from Closest Pin screen with saved data
      if (ScreenDataRetentionService().hasEnterScoresData()) {
        // Restore player groups from retention service (includes SKAT values)
        List<List<PlayerData>>? savedGroups = ScreenDataRetentionService().playerGroups;
        if (savedGroups != null) {
          // Deep copy the saved groups to avoid reference issues
          for (int i = 0; i < groups.length && i < savedGroups.length; i++) {
            groups[i].clear();
            for (var player in savedGroups[i]) {
              groups[i].add(PlayerData(
                name: player.name,
                skNumber: player.skNumber,
                skats: player.skats,
                diff: player.diff,
                money: player.money,
              ));
            }
          }

          // Restore shuffle state
          _hasBeenShuffled = ScreenDataRetentionService().playersShuffled ?? false;

          // Money calculation is now handled before navigation to Closest Pin screen
          // No need to recalculate when returning

          setState(() {
            // Trigger UI update after loading
          });
          return;
        }
      }

      // Otherwise, check for saved shuffle state from database
      final shuffleState = await DatabaseHelper().getSetting('monday_players_shuffled', league: League.monday);
      final playerOrder = await DatabaseHelper().getSetting('monday_player_order', league: League.monday);

      _hasBeenShuffled = (shuffleState == 'true');

      // If shuffled and we have saved order, restore it
      if (_hasBeenShuffled && playerOrder != null && playerOrder.isNotEmpty) {
        _deserializePlayerOrder(playerOrder);

        // Validate and sync with current selected players
        _validateAndSyncWithSelectedPlayers();
      } else {
        // No saved order, populate normally
        _populateGroupsWithSelectedPlayers();
      }

      setState(() {
        // Trigger UI update after loading/populating
      });
    } catch (e) {
      // Fallback to normal population
      _hasBeenShuffled = false;
      _populateGroupsWithSelectedPlayers();
    }
  }

  /// Saves the shuffle state and player order when leaving the screen
  Future<void> _saveShuffleState() async {
    try {
      if (_shuffledInCurrentSession) {
        await DatabaseHelper().setSetting('monday_players_shuffled', 'true', league: League.monday);
        
        // Save the current player order
        String playerOrder = _serializePlayerOrder();
        await DatabaseHelper().setSetting('monday_player_order', playerOrder, league: League.monday);
      }
    } catch (e) {
      //print("Error saving shuffle state: $e");
    }
  }

  /// Serializes the current player order to a string for storage
  String _serializePlayerOrder() {
    List<Map<String, dynamic>> orderData = [];
    
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
        PlayerData player = groups[groupIndex][playerIndex];
        orderData.add({
          'groupIndex': groupIndex,
          'playerIndex': playerIndex,
          'name': player.name,
          'skNumber': player.skNumber,
          'skats': player.skats,
          'diff': player.diff,
          'money': player.money,
        });
      }
    }
    
    // Convert to JSON string
    return orderData.map((player) => 
      '${player['groupIndex']}|${player['playerIndex']}|${player['name']}|${player['skNumber']}|${player['skats']}|${player['diff']}|${player['money']}'
    ).join(';;');
  }

  /// Deserializes and restores player order from storage
  void _deserializePlayerOrder(String orderData) {
    try {
      // Clear existing groups
      for (int i = 0; i < groups.length; i++) {
        groups[i].clear();
      }
      
      if (orderData.isEmpty) return;
      
      List<String> playerEntries = orderData.split(';;');
      for (String entry in playerEntries) {
        List<String> parts = entry.split('|');
        if (parts.length >= 7) {
          int groupIndex = int.parse(parts[0]);
          String name = parts[2];
          String skNumber = parts[3];
          String skats = parts[4];
          String diff = parts[5];
          String money = parts[6];
          
          if (groupIndex >= 0 && groupIndex < groups.length) {
            groups[groupIndex].add(PlayerData(
              name: name,
              skNumber: skNumber,
              skats: skats,
              diff: diff,
              money: money,
            ));
          }
        }
      }
    } catch (e) {
      //print("Error deserializing player order: $e");
    }
  }

  /// Validates and synchronizes restored groups with current selected players
  void _validateAndSyncWithSelectedPlayers() {
    if (widget.selectedPlayers == null || widget.selectedPlayers!.isEmpty) return;
    
    // Get list of players currently in groups
    Set<String> playersInGroups = {};
    for (var group in groups) {
      for (var player in group) {
        playersInGroups.add(player.name);
      }
    }
    
    // Get list of currently selected players
    Set<String> selectedPlayerNames = {};
    for (var player in widget.selectedPlayers!) {
      String playerName = player['last'] ?? '';
      selectedPlayerNames.add(playerName);
    }
    
    // Find players that need to be added (in selection but not in groups)
    Set<String> playersToAdd = selectedPlayerNames.difference(playersInGroups);
    
    // Find players that need to be removed (in groups but not in selection)
    Set<String> playersToRemove = playersInGroups.difference(selectedPlayerNames);
    
    // Remove players that are no longer selected
    for (String playerName in playersToRemove) {
      _removePlayerFromGroups(playerName);
    }
    
    // Add newly selected players
    for (String playerName in playersToAdd) {
      var playerData = widget.selectedPlayers!.firstWhere(
        (p) => p['last'] == playerName,
        orElse: () => {},
      );
      if (playerData.isNotEmpty) {
        _addPlayerToGroups(playerName, playerData['skat_number']?.toString() ?? '');
      }
    }
  }

  /// Removes a player from all groups
  void _removePlayerFromGroups(String playerName) {
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      groups[groupIndex].removeWhere((player) => player.name == playerName);
    }
  }

  /// Adds a player to the group with the fewest players
  void _addPlayerToGroups(String playerName, String skNumber) {
    // Find group with fewest players
    int targetGroupIndex = 0;
    int minPlayerCount = groups[0].length;
    
    for (int i = 1; i < groups.length; i++) {
      if (groups[i].length < minPlayerCount) {
        minPlayerCount = groups[i].length;
        targetGroupIndex = i;
      }
    }
    
    // If all groups have 4+ players, find first group with less than 4
    if (minPlayerCount >= 4) {
      for (int i = 0; i < groups.length; i++) {
        if (groups[i].length < 4) {
          targetGroupIndex = i;
          break;
        }
      }
    }
    
    // Add player to the target group
    groups[targetGroupIndex].add(PlayerData(
      name: playerName,
      skNumber: skNumber,
      skats: '',
      diff: '',
      money: '',
    ));
  }


  /// Handles the Return button press with proper orientation management
  void _handleReturn() async {
    // Save shuffle state if shuffling occurred in this session
    await _saveShuffleState();

    // Check if widget is still mounted before using context
    if (!mounted) return;

    // Set landscape orientation before popping to prevent brief portrait flash
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Navigator.pop(context);
  }

  /// Handles the Shuffle button press to randomize player order
  void _handleShuffle() {
    
    // Collect all players from all groups
    List<PlayerData> allPlayers = [];
    List<int> groupSizes = [];
    
    // Store original group sizes and collect all players
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      int groupSize = groups[groupIndex].length;
      if (groupSize > 0) {
        groupSizes.add(groupSize);
        allPlayers.addAll(groups[groupIndex]);
      } else {
        groupSizes.add(0);
      }
    }
    
    if (allPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No players to shuffle'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Shuffle all players randomly
    final random = Random();
    allPlayers.shuffle(random);
    
    setState(() {
      // Clear all groups
      for (int i = 0; i < groups.length; i++) {
        groups[i].clear();
      }
      
      // Redistribute shuffled players back into groups with original sizes
      int playerIndex = 0;
      for (int groupIndex = 0; groupIndex < groupSizes.length; groupIndex++) {
        int groupSize = groupSizes[groupIndex];
        for (int i = 0; i < groupSize && playerIndex < allPlayers.length; i++) {
          groups[groupIndex].add(allPlayers[playerIndex]);
          playerIndex++;
        }
      }
      
      // Mark that shuffling occurred in this session
      _shuffledInCurrentSession = true;
    });
  }


  /// Returns true if a player is selected for deletion (triple-clicked)
  bool _isDeleteMode() {
    return _deleteTargetPlayerName != null && _deleteTargetTapCount >= 3;
  }

  /// Handles deleting the triple-clicked player
  void _handleDeletePlayer() {
    if (_deleteTargetPlayerName == null) return;

    setState(() {
      _removePlayerFromGroups(_deleteTargetPlayerName!);
      _deleteTargetPlayerName = null;
      _deleteTargetTapCount = 0;
      _swapService.clearSelection();

      // Recalculate purse amounts based on new player count
      int newPlayerCount = 0;
      for (var group in groups) {
        newPlayerCount += group.length;
      }
      double ante = LeaguePurseService.playersAnte;
      LeaguePurseService.setSkatPurse(ante * newPlayerCount);
      LeaguePurseService.setClosestPinPurse(LeaguePurseService.closestPinAmount * newPlayerCount, isExplicit: false);
      LeaguePurseService.setMulliganPurse(LeaguePurseService.mulliganAmount * newPlayerCount, isExplicit: false);
    });
  }

  /// Resets delete mode
  void _resetDeleteMode() {
    _deleteTargetPlayerName = null;
    _deleteTargetTapCount = 0;
  }

  /// Gets the text for the shuffle/delete button
  String _getShuffleButtonText() {
    if (_isDeleteMode()) return 'Delete';
    return 'Shuffle';
  }

  /// Gets the color for the shuffle button based on SKATS data only
  Color _getShuffleButtonColor() {
    if (_isDeleteMode()) return Colors.red;
    if (_hasAnySkatsData()) {
      return Colors.grey[400]!;
    }
    return Colors.purple[200]!;
  }

  /// Gets the handler for the shuffle button based on SKATS data only
  VoidCallback _getShuffleButtonHandler() {
    if (_isDeleteMode()) return _handleDeletePlayer;
    if (_hasAnySkatsData()) {
      return _handleShuffleDisabledDueToSkats;
    }
    return _handleShuffle;
  }


  /// Handles when shuffle button is pressed but disabled due to SKATS data
  void _handleShuffleDisabledDueToSkats() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot shuffle players after SKATS data has been entered'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gets the handler for the SWAP button based on SKATS data
  VoidCallback _getSwapButtonHandler() {
    if (_hasAnySkatsData()) {
      return _handleSwapDisabled;
    }
    return _handleSwapPlayers;
  }

  /// Handles when swap button is pressed but disabled due to SKATS data
  void _handleSwapDisabled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot swap players after SKATS data has been entered'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gets the color for the Player Selection button
  Color _getPlayerSelectionButtonColor() {
    if (_hasAnySkatsData()) {
      return Colors.grey[400]!;
    }
    return Colors.blue[300]!;
  }

  /// Gets the handler for the Player Selection button
  VoidCallback? _getPlayerSelectionButtonHandler() {
    if (_hasAnySkatsData()) {
      return _handlePlayerSelectionDisabled;
    }
    return _handleReturn;
  }

  /// Handles when Player Selection button is pressed but disabled due to SKATS data
  void _handlePlayerSelectionDisabled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot return to Player Selection after SKATS data has been entered'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Builds bottom buttons with dynamic SWAP button text
  Widget _buildBottomButtonsWithSwap() {
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[300]!,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: '◄- Player Selection',
          color: _getPlayerSelectionButtonColor(),
          onPressed: _getPlayerSelectionButtonHandler(),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Adjust Players',
          color: _getAdjustPlayersButtonColor(),
          onPressed: _getAdjustPlayersButtonHandler(),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: _getSkatButtonText(),
          color: _getSkatButtonColor(),
          onPressed: _getSkatButtonHandler(),
        ),
      ],
    );
  }


//************************************************************************************************
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              EnterScoresUIService.buildPurseHeader(context, League.monday, onReturn: _handleReturn, payoutAmount: _payoutAmount, collectAmount: () {
                int count = 0;
                for (var g in groups) { count += g.where((p) => p.name.isNotEmpty).length; }
                return (LeaguePurseService.getPlayersAnte(league: League.monday) + LeaguePurseService.getClosestPinAmount(league: League.monday) + LeaguePurseService.getMulliganAmount(league: League.monday)) * count;
              }()),
              EnterScoresUIService.buildGroupsGrid(
                context,
                groups,
                onPlayerTap: _onPlayerTap,
                onEmptySlotTap: _onEmptySlotTap,
                isPlayerSelected: _isPlayerSelected,
                isEmptySlotSelected: _isEmptySlotSelected,
                onSkatsChanged: _onSkatsChanged,
                skatsFocusNodes: _skatsFocusNodes,
                isPlayerFocused: _isPlayerFocused,
                getPlayerSelectedColor: _getPlayerSelectedColor,
              ),
              _buildBottomButtonsWithSwap(),
            ],
          ),
          // Custom keypad overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomKeypadService.buildCustomKeypad(
              context: context,
              onKeyPress: _handleKeypadInput,
              isVisible: _keypadController.isVisible,
            ),
          ),
          // Adjust Players overlay button bar
          if (_showAdjustPlayersOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildAdjustPlayersOverlay(),
            ),
        ],
      ),
    );
  }

  /// Gets the text for the Skat/Results button based on purse amounts
  String _getSkatButtonText() {
    if (LeaguePurseService.skatPurse > 0) {
      return 'Close Pin ---➤';
    } else if (_hasMoneyCalculations()) {
      return 'Close Pin ---➤';
    } else {
      return 'PAYOUT ---➤';
    }
  }

  /// Gets the color for the Skat/Results button based on purse amounts
  Color _getSkatButtonColor() {
    if (LeaguePurseService.skatPurse > 0) {
      // Only show green if all SKATS data is complete
      return _areAllSkatsFieldsComplete() ? Colors.green[200]! : Colors.grey[400]!;
    } else {
      return Colors.blue[200]!;
    }
  }

  /// Gets the handler for the Skat/Results button based on purse amounts
  VoidCallback _getSkatButtonHandler() {
    if (LeaguePurseService.skatPurse > 0) {
      return _handleClosePinWinners;
    } else if (_hasMoneyCalculations()) {
      return _handleClosePinWinners;
    } else {
      return _handleResults;
    }
  }

  /// Handles the Close Pin Winners button press to navigate to Closest Pin screen
  void _handleClosePinWinners() {

    // Check if all SKATS data is entered before proceeding
    if (!_areAllSkatsFieldsComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter SKATS data for all players before proceeding'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Money is already calculated automatically when last SKATS value was entered
    // No need to calculate again here

    // Capture data in the retention service before transitioning to Closest Pin screen
    ScreenDataRetentionService().captureEnterScoresData(
      playerGroups: groups,
      hasMoneyCalculations: _hasMoneyCalculations(),
      playersShuffled: _shuffledInCurrentSession || _hasBeenShuffled,
    );

    // Build player list from current groups so added/deleted players are reflected
    List<Map<String, dynamic>> allPlayersFromGroups = [];
    for (var group in groups) {
      for (var player in group) {
        allPlayersFromGroups.add({'last': player.name});
      }
    }

    // Navigate to Monday Closest Pin Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MondayClosestPinScreen(
          selectedPlayers: allPlayersFromGroups,
          playersAnte: widget.playersAnte,
        ),
      ),
    );
  }

  /// Handles the RESULTS button press to show game results
  void _handleResults() {
    
    // Capture data in the retention service before transitioning to results
    ScreenDataRetentionService().captureEnterScoresData(
      playerGroups: groups,
      hasMoneyCalculations: _hasMoneyCalculations(),
      playersShuffled: _shuffledInCurrentSession || _hasBeenShuffled,
    );
    
    // Save shuffle state before navigating to results
    _saveShuffleState();
    
    // Navigate to Results Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MondayResultsScreen(),
      ),
    );
  }

  // ============== ADJUST PLAYERS OVERLAY ==============

  /// Builds the Adjust Players overlay button bar
  Widget _buildAdjustPlayersOverlay() {
    List<Widget> buttons = [];

    // Done button
    buttons.add(ButtonBarUIService.buildActionButton(
      context,
      text: '◄- Enter Skats',
      color: Colors.lightBlue[100]!,
      onPressed: _handleCloseAdjustPlayersOverlay,
    ));

    // Shuffle/Delete button
    buttons.add(ButtonBarUIService.buildActionButton(
      context,
      text: _getShuffleButtonText(),
      color: _getShuffleButtonColor(),
      onPressed: _getShuffleButtonHandler(),
    ));

    // Swap button
    buttons.add(ButtonBarUIService.buildActionButton(
      context,
      text: _swapService.getSwapButtonText(),
      color: _getSwapButtonColor(),
      onPressed: _getSwapButtonHandler(),
    ));

    // Save Groups / Recall Groups button
    buttons.add(ButtonBarUIService.buildActionButton(
      context,
      text: _hasFirebaseGroupings ? 'Recall Groups' : 'Save Groups',
      color: Colors.purple[200]!,
      onPressed: _handleGroupingsButton,
    ));

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.orange[100]!,
      children: buttons,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      useMinHeight: true,
    );
  }

  /// Handler for Adjust Players button - shows overlay
  void _handleAdjustPlayers() {
    setState(() {
      _showAdjustPlayersOverlay = true;
    });
  }

  /// Handler for closing the Adjust Players overlay
  void _handleCloseAdjustPlayersOverlay() {
    setState(() {
      _showAdjustPlayersOverlay = false;
      _swapService.clearSelection();
      _resetDeleteMode();
    });
  }

  /// Checks Firebase for saved Monday groupings and updates the button label.
  Future<void> _checkFirebaseGroupings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('M_scheduled_groups')
          .doc('pending')
          .get();
      if (mounted) {
        setState(() {
          _hasFirebaseGroupings = doc.exists;
        });
      }
    } catch (e) {
      debugPrint('Could not check Firebase groupings: $e');
    }
  }

  /// Dispatches to save or recall based on whether groupings exist in Firebase.
  Future<void> _handleGroupingsButton() async {
    if (_hasFirebaseGroupings) {
      await _recallGroupingsFromFirebase();
    } else {
      await _saveGroupingsToFirebase();
    }
  }

  /// Saves current Monday groupings to Firebase so they can be restored on restart.
  Future<void> _saveGroupingsToFirebase() async {
    try {
      final groupsJson = jsonEncode(groups.map((group) =>
          group.map((p) => {
            'name': p.name,
            'skNumber': p.skNumber,
            'skats': p.skats,
            'diff': p.diff,
            'money': p.money,
          }).toList()
      ).toList());

      final playersJson = widget.selectedPlayers != null
          ? jsonEncode(widget.selectedPlayers!.map((p) => Map<String, dynamic>.from(p)).toList())
          : jsonEncode([]);

      await FirebaseFirestore.instance.collection('M_scheduled_groups').doc('pending').set({
        'groups': groupsJson,
        'players': playersJson,
        'saved_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _hasFirebaseGroupings = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Groupings saved to Firebase'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save Monday groupings to Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save groupings'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Recalls saved Monday groupings from Firebase and reloads them into the screen.
  Future<void> _recallGroupingsFromFirebase() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('M_scheduled_groups')
          .doc('pending')
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved groupings found'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final data = doc.data()!;
      final groupsJson = data['groups'] as String? ?? '[]';
      final decoded = jsonDecode(groupsJson) as List<dynamic>;

      final recalled = <List<PlayerData>>[];
      for (final group in decoded) {
        final playerList = <PlayerData>[];
        for (final p in (group as List<dynamic>)) {
          final m = p as Map<String, dynamic>;
          playerList.add(PlayerData(
            name: m['name'] as String? ?? '',
            skNumber: m['skNumber'] as String? ?? '',
            skats: m['skats'] as String? ?? '',
            diff: m['diff'] as String? ?? '',
            money: m['money'] as String? ?? '',
          ));
        }
        recalled.add(playerList);
      }

      setState(() {
        // Restore only the non-empty groups from the saved data
        for (int i = 0; i < groups.length; i++) {
          groups[i] = i < recalled.length ? recalled[i] : [];
        }
        _showAdjustPlayersOverlay = false;
        _swapService.clearSelection();
        _resetDeleteMode();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Groupings recalled from Firebase'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to recall Monday groupings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to recall groupings'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Gets the color for the Adjust Players button
  Color _getAdjustPlayersButtonColor() {
    if (_hasAnySkatsData()) {
      return Colors.grey[400]!;
    }
    return Colors.blue[200]!;
  }

  /// Gets the handler for the Adjust Players button
  VoidCallback? _getAdjustPlayersButtonHandler() {
    if (_hasAnySkatsData()) {
      return null;
    }
    return _handleAdjustPlayers;
  }

}
