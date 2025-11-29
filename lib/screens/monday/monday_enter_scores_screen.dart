import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/factories/auto_fill_factory.dart';
import '../../services/shared/swap_service.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/payout_validation_service.dart';
import '../../services/database_helper.dart';
import '../../services/screen_data_retention_service.dart';
import '../../models/league.dart';
import 'monday_closest_pin_screen.dart';
import 'monday_results_screen.dart';

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
  
  // Focus nodes for SKATS input fields - organized by group and player index
  List<List<FocusNode?>> _skatsFocusNodes = [
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
      
      print("Fresh Skat Purse calculation:");
      print("  Players: ${widget.selectedPlayers!.length}");
      print("  Player Ante: \$${widget.playersAnte!.toStringAsFixed(2)}");
      print("  Skat Purse: \$${freshSkatPurse.toStringAsFixed(2)}");
      
      // Calculate other purses based on selected players count
      LeaguePurseService.calculateClosestPinPurseFromCount(widget.selectedPlayers!.length);
      LeaguePurseService.calculateMulliganPurseFromCount(widget.selectedPlayers!.length);
    } else if (widget.selectedPlayers != null) {
      // Fallback to existing method if playersAnte is not provided
      LeaguePurseService.calculateSkatPurseFromCount(widget.selectedPlayers!.length);
      LeaguePurseService.calculateClosestPinPurseFromCount(widget.selectedPlayers!.length);
      LeaguePurseService.calculateMulliganPurseFromCount(widget.selectedPlayers!.length);
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
    if (groupIndex < groups.length && playerIndex < groups[groupIndex].length) {
      _currentFocusedPlayer = groups[groupIndex][playerIndex];
      _keypadController.setInput(_currentFocusedPlayer?.skats ?? '');
      setState(() {
        _keypadController.show();
      });
      print("Showing keypad for ${_currentFocusedPlayer?.name}");
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
    print("Hiding keypad${keepFocus ? ' (keeping focus)' : ''}");
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
            print("Unfocused field for ${_currentFocusedPlayer!.name}");
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
              print("Error parsing values: $e");
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
          
          print("Updated ${player.name}: SKATS=$newValue, DIFF=$diffValue");
          return;
        }
      }
    }
  }

  /// Handles keypad input
  void _handleKeypadInput(String key) {
    if (_currentFocusedPlayer == null) return;
    
    print("Keypad key pressed: $key");
    
    if (key == 'backspace') {
      // Handle normal backspace functionality
      String? newInput = _keypadController.handleKeyPress(key);
      if (newInput != null) {
        setState(() {
          // Live update the display while typing
          _updateSkatsField(_currentFocusedPlayer!, _keypadController.currentInput);
        });
        print("Current keypad input: ${_keypadController.currentInput}");
      }
    } else if (key == 'enter') {
      
      // Apply current input and move to next field
      String currentInput = _keypadController.currentInput;
      if (currentInput.isNotEmpty) {
        _updateSkatsField(_currentFocusedPlayer!, currentInput);
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
        print("Current keypad input: ${_keypadController.currentInput}");
        
        // Auto-advance when 2 digits are entered
        if (_keypadController.currentInput.length == 2) {
          print("Auto-advancing to next field after 2 digits");
          
          // Find current player position and move to next after a short delay
          Future.delayed(Duration(milliseconds: 300), () {
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
    print("Reached end of SKATS input fields");
  }

  /// Auto fills SKATS data with random values between 30-40 for all players
  void _handleAutoFill() {
    print("Auto Fill button pressed!");
    print("Groups before auto fill: ${groups.map((g) => g.map((p) => "${p.name}: ${p.skats}").toList()).toList()}");
    
    setState(() {
      final autoFillService = AutoFillFactory.create(League.monday);
      groups = autoFillService.autoFillData(groups);
    });
    
    // Hide keypad after auto-fill is complete
    _hideKeypad();
    
    print("Groups after auto fill: ${groups.map((g) => g.map((p) => "${p.name}: ${p.skats}").toList()).toList()}");
  }

  /// Calculates Skat money payouts for players with positive DIFF values
  void _handleSkatMoney() {
    print("Skat \$\$\$ button pressed!");
    
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
    
    print("Calculated Skat payouts: $payouts");
    
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
            print("Updated ${player.name}: money = $moneyValue (diff: ${player.diff})");
          }
        }
      }
    });
    
    // Calculate total distributed money and update the Skat Purse
    double totalDistributed = _calculateTotalDistributedMoney();
    double remainingSkatPurse = LeaguePurseService.skatPurse - totalDistributed;
    double currentMulligan = LeaguePurseService.mulliganPurse;
    
    if (remainingSkatPurse > 0) {
      // Positive remaining: transfer to Mulligan Purse
      double newMulliganPurse = currentMulligan + remainingSkatPurse;
      LeaguePurseService.setMulliganPurse(newMulliganPurse);
      LeaguePurseService.setRemainingPurse(0.0);
      
      print("Transferred remaining Skat Purse (\$${remainingSkatPurse.toStringAsFixed(2)}) to Mulligan Purse");
      print("New Mulligan Purse: \$${newMulliganPurse.toStringAsFixed(2)}");
      print("Skat Purse now: \$0");
    } else if (remainingSkatPurse < 0) {
      // Negative remaining: take deficit from Mulligan Purse
      double deficit = -remainingSkatPurse; // Make positive
      double newMulliganPurse = currentMulligan - deficit;
      LeaguePurseService.setMulliganPurse(newMulliganPurse);
      LeaguePurseService.setRemainingPurse(0.0);
      
      print("Skat Purse was short by \$${deficit.toStringAsFixed(2)}, taken from Mulligan Purse");
      print("New Mulligan Purse: \$${newMulliganPurse.toStringAsFixed(2)}");
      print("Skat Purse now: \$0");
    } else {
      // Exactly 0 remaining
      LeaguePurseService.setRemainingPurse(0.0);
      print("Skat Purse exactly balanced at \$0");
    }
    
    // Set Skat Purse to 0.0 after winnings are distributed
    LeaguePurseService.setSkatPurse(0.0);
    
    print("Skat money calculation completed");
    print("Total distributed: \$${totalDistributed.toStringAsFixed(2)}");
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
    
    // Prevent any swap functionality if SKATS data exists
    if (_hasAnySkatsData()) {
      print("Swap disabled due to SKATS data - ignoring player tap");
      return;
    }
    
    setState(() {
      _swapService.handlePlayerSelection(player.name);
    });
  }

  /// Handles empty slot tap for swap selection
  void _onEmptySlotTap(int groupIndex, int playerIndex) {
    String slotKey = 'empty_${groupIndex + 1}_$playerIndex';
    print("Empty slot tapped: $slotKey");
    
    // Prevent any swap functionality if SKATS data exists
    if (_hasAnySkatsData()) {
      print("Swap disabled due to SKATS data - ignoring empty slot tap");
      return;
    }
    
    setState(() {
      _swapService.handleEmptySlotSelection(slotKey);
    });
  }

  /// Checks if a player is selected for swapping
  bool _isPlayerSelected(PlayerData player) {
    // Prevent highlighting if SKATS data exists
    if (_hasAnySkatsData()) {
      return false;
    }
    return _swapService.isPlayerSelected(player.name);
  }

  /// Checks if an empty slot is selected for swapping
  bool _isEmptySlotSelected(int groupIndex, int playerIndex) {
    // Prevent highlighting if SKATS data exists
    if (_hasAnySkatsData()) {
      return false;
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
            print("Player ${player.name} has incomplete SKATS: '${player.skats}'");
            return false;
          }
          // Additional validation: check if it's a valid 2-digit number
          try {
            int.parse(player.skats);
          } catch (e) {
            print("Player ${player.name} has invalid SKATS: '${player.skats}'");
            return false;
          }
        }
      }
    }
    print("All SKATS fields are complete");
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
    
    print("Recalculating money fields with new DIFF values");
    
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
    
    // Calculate total distributed money and update the Skat Purse
    double totalDistributed = _calculateTotalDistributedMoney();
    double remainingSkatPurse = LeaguePurseService.skatPurse - totalDistributed;
    double currentMulligan = LeaguePurseService.mulliganPurse;
    
    if (remainingSkatPurse > 0) {
      // Positive remaining: transfer to Mulligan Purse
      double newMulliganPurse = currentMulligan + remainingSkatPurse;
      LeaguePurseService.setMulliganPurse(newMulliganPurse);
      LeaguePurseService.setRemainingPurse(0.0);
    } else if (remainingSkatPurse < 0) {
      // Negative remaining: take deficit from Mulligan Purse
      double deficit = -remainingSkatPurse; // Make positive
      double newMulliganPurse = currentMulligan - deficit;
      LeaguePurseService.setMulliganPurse(newMulliganPurse);
      LeaguePurseService.setRemainingPurse(0.0);
    } else {
      // Exactly 0 remaining
      LeaguePurseService.setRemainingPurse(0.0);
    }
    
    // Set Skat Purse to 0.0 after winnings are recalculated
    LeaguePurseService.setSkatPurse(0.0);
  }

  /// Handles SKATS input change and calculates DIFF automatically
  /// Also recalculates money fields if Skat $$$ button was previously used
  void _onSkatsChanged(PlayerData player, String skatValue) {
    print("SKATS changed for ${player.name}: $skatValue");
    
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
                print("Updated ${player.name}: SKATS=$skatValue, DIFF=$diffValue");
                
                // If money calculations were previously done, recalculate all money fields
                if (shouldRecalculateMoney) {
                  print("Recalculating money fields due to SKATS change");
                  _recalculateMoneyFields();
                }
                
                // Move focus to next SKATS field after a short delay
                Future.delayed(Duration(milliseconds: 100), () {
                  _moveToNextSkatsField(groupIndex, playerIndex);
                });
                return; // Exit once found and updated
              }
            }
          }
        });
        
      } catch (e) {
        print("Error parsing SKATS value: $skatValue");
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
              print("Updated ${player.name}: SKATS=$skatValue, DIFF='' (waiting for 2nd digit)");
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
      return Colors.grey[400]!; // Grey when disabled due to SKATS data
    } else if (_swapService.selectionCount == 2) {
      return Colors.green[400]!; // Medium green when 2nd player is selected
    } else {
      return Colors.grey[400]!; // Grey for default state and after swap is completed
    }
  }

  /// Initializes player groups - either from saved order or fresh population
  Future<void> _initializePlayerGroups() async {
    try {
      final shuffleState = await DatabaseHelper().getSetting('monday_players_shuffled', league: League.monday);
      final playerOrder = await DatabaseHelper().getSetting('monday_player_order', league: League.monday);
      
      _hasBeenShuffled = (shuffleState == 'true');
      
      // If shuffled and we have saved order, restore it
      if (_hasBeenShuffled && playerOrder != null && playerOrder.isNotEmpty) {
        _deserializePlayerOrder(playerOrder);
        
        // Validate and sync with current selected players
        _validateAndSyncWithSelectedPlayers();
        
        print("Restored and synchronized shuffled player order from previous session");
      } else {
        // No saved order, populate normally
        _populateGroupsWithSelectedPlayers();
        print("Populated groups with fresh player selection");
      }
      
      setState(() {
        // Trigger UI update after loading/populating
      });
    } catch (e) {
      print("Error initializing player groups: $e");
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
        
        print("Shuffle state and player order saved");
      }
    } catch (e) {
      print("Error saving shuffle state: $e");
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
      
      print("Player order restored from saved data");
    } catch (e) {
      print("Error deserializing player order: $e");
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
    
    print("Players in restored groups: $playersInGroups");
    print("Currently selected players: $selectedPlayerNames");
    
    // Find players that need to be added (in selection but not in groups)
    Set<String> playersToAdd = selectedPlayerNames.difference(playersInGroups);
    
    // Find players that need to be removed (in groups but not in selection)
    Set<String> playersToRemove = playersInGroups.difference(selectedPlayerNames);
    
    // Remove players that are no longer selected
    for (String playerName in playersToRemove) {
      _removePlayerFromGroups(playerName);
      print("Removed deselected player: $playerName");
    }
    
    // Add newly selected players
    for (String playerName in playersToAdd) {
      var playerData = widget.selectedPlayers!.firstWhere(
        (p) => p['last'] == playerName,
        orElse: () => {},
      );
      if (playerData.isNotEmpty) {
        _addPlayerToGroups(playerName, playerData['skat_number']?.toString() ?? '');
        print("Added newly selected player: $playerName");
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

  /// Clears the shuffle state (call this when starting a new game session)
  static Future<void> clearShuffleState() async {
    try {
      await DatabaseHelper().setSetting('monday_players_shuffled', 'false', league: League.monday);
      await DatabaseHelper().setSetting('monday_player_order', '', league: League.monday);
      print("Shuffle state cleared for new game session");
    } catch (e) {
      print("Error clearing shuffle state: $e");
    }
  }

  /// Handles the Return button press with proper orientation management
  void _handleReturn() async {
    // Save shuffle state if shuffling occurred in this session
    await _saveShuffleState();
    
    // Set landscape orientation before popping to prevent brief portrait flash
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Navigator.pop(context);
  }

  /// Handles the Shuffle button press to randomize player order
  void _handleShuffle() {
    print("Shuffle button pressed!");
    
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
    
    print("Players shuffled successfully! Total players redistributed: ${allPlayers.length}");
  }

  /// Handles the Closest Pin button press and navigates to the closest pin screen
  void _handleClosestPin() async {
    if (widget.selectedPlayers != null && widget.selectedPlayers!.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MondayClosestPinScreen(
            selectedPlayers: widget.selectedPlayers!,
          ),
        ),
      );
      // Refresh the UI to reflect any changes to the Closest Pin Purse
      setState(() {
        // Trigger UI rebuild to show updated purse amounts
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No players selected for closest pin contest'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Gets the color for the shuffle button based on navigation state and SKATS data
  Color _getShuffleButtonColor() {
    if (_hasBeenShuffled || _hasAnySkatsData()) {
      return Colors.grey[400]!;
    }
    return Colors.purple[200]!;
  }

  /// Gets the handler for the shuffle button based on navigation state and SKATS data
  VoidCallback _getShuffleButtonHandler() {
    if (_hasBeenShuffled) {
      return _handleShuffleDisabled;
    } else if (_hasAnySkatsData()) {
      return _handleShuffleDisabledDueToSkats;
    }
    return _handleShuffle;
  }

  /// Handles when shuffle button is pressed but disabled
  void _handleShuffleDisabled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Players were already shuffled in a previous session'),
        duration: Duration(seconds: 2),
      ),
    );
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
          _buildCustomButton(context, 'Shuffle', _getShuffleButtonColor(), _getShuffleButtonHandler()),
          _buildCustomButton(context, 'ClosePin \$\$\$', _getClosestPinButtonColor(), _getClosestPinButtonHandler()),
          _buildCustomButton(context, _getSkatButtonText(), _getSkatButtonColor(), _getSkatButtonHandler()),
          _buildCustomButton(context, _swapService.getSwapButtonText(), _getSwapButtonColor(), _getSwapButtonHandler()),
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
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              EnterScoresUIService.buildPurseHeader(context, League.monday, onReturn: _handleReturn, onAutoFill: _handleAutoFill),
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
        ],
      ),
    );
  }

  /// Gets the color for the Closest Pin button based on purse amount
  Color _getClosestPinButtonColor() {
    return LeaguePurseService.closestPinPurse > 0 ? Colors.green[200]! : Colors.grey[400]!;
  }

  /// Gets the handler for the Closest Pin button based on purse amount
  VoidCallback _getClosestPinButtonHandler() {
    return LeaguePurseService.closestPinPurse > 0 ? _handleClosestPin : () {};
  }

  /// Gets the text for the Skat/Results button based on purse amounts
  String _getSkatButtonText() {
    if (LeaguePurseService.skatPurse > 0) {
      return 'Skat \$\$\$';
    } else if (LeaguePurseService.skatPurse <= 0 && LeaguePurseService.closestPinPurse <= 0) {
      return 'RESULTS';
    } else {
      return 'Skat \$\$\$';
    }
  }

  /// Gets the color for the Skat/Results button based on purse amounts
  Color _getSkatButtonColor() {
    if (LeaguePurseService.skatPurse > 0) {
      // Only show green if all SKATS data is complete
      return _areAllSkatsFieldsComplete() ? Colors.green[200]! : Colors.grey[400]!;
    } else if (LeaguePurseService.skatPurse <= 0 && LeaguePurseService.closestPinPurse <= 0) {
      return Colors.orange[200]!;
    } else {
      return Colors.grey[400]!;
    }
  }

  /// Gets the handler for the Skat/Results button based on purse amounts
  VoidCallback _getSkatButtonHandler() {
    if (LeaguePurseService.skatPurse > 0) {
      return _handleSkatMoney;
    } else if (LeaguePurseService.skatPurse <= 0 && LeaguePurseService.closestPinPurse <= 0) {
      return _handleResults;
    } else {
      return () {}; // Empty function when Skat is done but ClosePin is still active
    }
  }

  /// Handles the RESULTS button press to show game results
  void _handleResults() {
    print("RESULTS button pressed!");
    
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

}
