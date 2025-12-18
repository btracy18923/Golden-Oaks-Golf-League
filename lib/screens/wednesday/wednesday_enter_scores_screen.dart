import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../popup_utils.dart';
import '../main_menu_screen.dart';
import '../../services/database_helper.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/csv_payout_service.dart';
import '../../services/group_csv_payout_service.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/wednesday_winnings_service.dart';
import '../../services/process_groups_service.dart';
import '../../models/league.dart';
import '../../models/wednesday_player_data.dart';
import 'wednesday_closest_pin_screen.dart';

/// Helper class to track positions in the groups grid
class Position {
  final int groupIndex;
  final int playerIndex;
  Position(this.groupIndex, this.playerIndex);
}

/// Wednesday Enter Scores Screen - Modernized version using services
class WednesdayEnterScoresScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialPlayers;
  final List<List<Map<String, dynamic>?>>? initialGroups;
  final String? initialLeague;

  const WednesdayEnterScoresScreen({
    Key? key,
    this.initialPlayers,
    this.initialGroups,
    this.initialLeague,
  }) : super(key: key);

  @override
  _WednesdayEnterScoresScreenState createState() => _WednesdayEnterScoresScreenState();
}

/// Wrapper widget for navigation with data
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
    return WednesdayEnterScoresScreen(
      initialPlayers: selectedPlayers,
      initialGroups: groups,
      initialLeague: leagueType,
    );
  }
}

class _WednesdayEnterScoresScreenState extends State<WednesdayEnterScoresScreen> {
  // Constants
  static const String selectedLeague = 'wednesday';

  // Services
  final WednesdayWinningsService _winningsService = WednesdayWinningsService();
  final ProcessGroupsService _processGroupsService = ProcessGroupsService();

  // Custom keypad controller
  CustomKeypadController? _keypadController;

  // Swap selection tracking (inline, since SwapService uses PlayerData)
  List<String> selectedForSwap = [];

  // Shuffle tracking
  bool _shuffledInCurrentSession = false;
  bool _hasBeenShuffled = false;

  // State
  List<List<Map<String, dynamic>?>> groups = [];
  List<Map<String, dynamic>> selectedPlayers = [];

  // Controllers and Focus Nodes
  Map<String, TextEditingController> grossControllers = {};
  Map<String, FocusNode> grossFocusNodes = {};

  // Focus management
  List<List<FocusNode?>> _focusNodeMatrix = List.generate(10, (_) => List.filled(4, null));
  WednesdayPlayerData? _currentFocusedPlayer;

  // Purse display values
  String _playersPurseDisplayText = "\$0.00";
  String _closestPinPurseDisplayText = "\$0.00";
  String _mulliganPurseDisplayText = "\$0.00";
  double _adjustedMulliganPurse = 0.0;
  double _totalPrizeMoney = 0.0;
  double _totalPayoutSum = 0.0;
  double _groupPurseAmount = 0.0;
  double _groupPayoutAmount = 0.0;

  // Processing state
  double totalPurse = 0.0;
  int individualPercent = 40;
  int groupPercent = 60;
  double individualPurse = 0.0;
  double groupPurse = 0.0;
  bool winnersCalculated = false;
  bool groupsProcessed = false;
  bool individualsProcessingComplete = false;

  // Closest Pin
  String? closestPinWinnerName;
  double closestPinWinnings = 0.0;

  @override
  void initState() {
    super.initState();
    _keypadController = CustomKeypadService.createController();
    _initializeServices();
    _initializeFocusNodes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      EnterScoresUIService.setOrientationForDevice(context);
      if (widget.initialPlayers != null && widget.initialGroups != null) {
        setPlayers(widget.initialPlayers!, widget.initialGroups!, widget.initialLeague ?? 'wednesday');
      }
    });
  }

  void _initializeServices() {
    CsvPayoutService().loadPayoutData().catchError((e) {});
    GroupCsvPayoutService().loadPayoutData().catchError((e) {});
  }

  void _initializeFocusNodes() {
    for (int g = 0; g < 10; g++) {
      for (int p = 0; p < 4; p++) {
        final focusNode = FocusNode();
        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            _onPlayerFocused(g, p);
            _showKeypadForPlayer(g, p);
          } else {
            _hideKeypad();
          }
        });
        _focusNodeMatrix[g][p] = focusNode;
      }
    }
  }

  @override
  void dispose() {
    // Dispose focus nodes
    for (var group in _focusNodeMatrix) {
      for (var node in group) {
        node?.dispose();
      }
    }
    // Dispose controllers
    grossControllers.values.forEach((c) => c.dispose());
    grossFocusNodes.values.forEach((n) => n.dispose());
    super.dispose();
  }

  /// Sets players data from navigation
  void setPlayers(List<Map<String, dynamic>> players, List<List<Map<String, dynamic>?>> groupsData, String league) {
    setState(() {
      selectedPlayers = List.from(players);
      groups = groupsData.map((g) => g.map((p) {
        if (p != null) {
          Map<String, dynamic> playerCopy = Map<String, dynamic>.from(p);
          // Map HC field to handicap if it exists
          if (playerCopy.containsKey('HC') && !playerCopy.containsKey('handicap')) {
            playerCopy['handicap'] = playerCopy['HC'];
          }
          return playerCopy;
        }
        return null;
      }).toList()).toList();

      // Ensure we have 10 groups with 4 slots each
      while (groups.length < 10) {
        groups.add([null, null, null, null]);
      }
      for (int i = 0; i < groups.length; i++) {
        while (groups[i].length < 4) {
          groups[i].add(null);
        }
      }
    });

    _createControllersForPlayers();
    updateTitleInformation();
  }

  void _createControllersForPlayers() {
    grossControllers.clear();
    grossFocusNodes.clear();

    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          String key = '${player['last']}_gross';
          grossControllers[key] = TextEditingController(
            text: player['gross_score']?.toString() ?? '',
          );
          grossFocusNodes[key] = FocusNode();
        }
      }
    }
  }

  void _onPlayerFocused(int groupIndex, int playerIndex) {
    if (groupIndex < groups.length && playerIndex < groups[groupIndex].length) {
      var player = groups[groupIndex][playerIndex];
      if (player != null) {
        setState(() {
          _currentFocusedPlayer = WednesdayPlayerData.fromMap(player);
        });
      }
    }
  }

  /// Shows the keypad for a specific player's Gross score input
  void _showKeypadForPlayer(int groupIndex, int playerIndex) {
    if (_keypadController == null) return;
    if (groupIndex < groups.length && playerIndex < groups[groupIndex].length) {
      var player = groups[groupIndex][playerIndex];
      if (player != null) {
        _currentFocusedPlayer = WednesdayPlayerData.fromMap(player);
        _keypadController!.setInput(player['gross_score']?.toString() ?? '');
        setState(() {
          _keypadController!.show();
        });
      }
    }
  }

  /// Hides the keypad
  void _hideKeypad({bool keepFocus = false}) {
    if (_keypadController == null) return;
    setState(() {
      _keypadController!.hide();
      if (!keepFocus) {
        _currentFocusedPlayer = null;
      }
    });
  }

  /// Handles keypad input
  void _handleKeypadInput(String key) {
    if (_keypadController == null || _currentFocusedPlayer == null) return;

    if (key == 'backspace') {
      String? newInput = _keypadController!.handleKeyPress(key);
      if (newInput != null) {
        setState(() {
          _updateGrossScoreFromKeypad(_keypadController!.currentInput);
        });
      }
    } else if (key == 'enter') {
      String currentInput = _keypadController!.currentInput;
      if (currentInput.isNotEmpty) {
        _updateGrossScoreFromKeypad(currentInput);
      }

      // Find current player position and move to next
      for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
          var player = groups[groupIndex][playerIndex];
          if (player != null && player['last'] == _currentFocusedPlayer!.name) {
            _moveToNextGrossInput(groupIndex, playerIndex);
            return;
          }
        }
      }
    } else {
      // Handle digit input
      String? newInput = _keypadController!.handleKeyPress(key);
      if (newInput != null) {
        setState(() {
          _updateGrossScoreFromKeypad(_keypadController!.currentInput);
        });

        // Auto-advance when 2 digits are entered
        if (_keypadController!.currentInput.length == 2) {
          Future.delayed(Duration(milliseconds: 300), () {
            for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
              for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
                var player = groups[groupIndex][playerIndex];
                if (player != null && player['last'] == _currentFocusedPlayer!.name) {
                  _moveToNextGrossInput(groupIndex, playerIndex);
                  return;
                }
              }
            }
          });
        }
      }
    }
  }

  /// Updates gross score from keypad input
  void _updateGrossScoreFromKeypad(String value) {
    if (_currentFocusedPlayer == null) return;

    // Find the player in groups and update
    for (int g = 0; g < groups.length; g++) {
      for (int p = 0; p < groups[g].length; p++) {
        var player = groups[g][p];
        if (player != null && player['last'] == _currentFocusedPlayer!.name) {
          _onGrossScoreChanged(g, p, value);
          return;
        }
      }
    }
  }

  /// Updates title purse information
  Future<void> updateTitleInformation() async {
    try {
      double anteAmount = LeaguePurseService.getPlayersAnte(league: League.wednesday);
      double closestPinAmount = LeaguePurseService.getClosestPinAmount(league: League.wednesday);
      double mulliganAmount = LeaguePurseService.getMulliganAmount(league: League.wednesday);

      int playerCount = 0;
      for (var group in groups) {
        for (var player in group) {
          if (player != null) playerCount++;
        }
      }

      totalPurse = anteAmount * playerCount;
      double closestPinPurse = closestPinAmount * playerCount;
      double mulliganPurse = mulliganAmount * playerCount;

      // Get individual purse from CSV for initial display
      double displayPurse = totalPurse;
      double displayMulliganPurse = mulliganPurse;

      if (!groupsProcessed && playerCount > 0) {
        try {
          final csvService = CsvPayoutService();
          final payouts = await csvService.getPayoutAmounts(playerCount);
          displayPurse = payouts['total_individual'] ?? totalPurse;
          individualPurse = displayPurse; // Store for later use

          // If individuals have been processed, use adjusted Mulligan
          if (individualsProcessingComplete) {
            // Keep displayPurse unchanged - Ind Purse never changes
            displayMulliganPurse = _adjustedMulliganPurse; // Use adjusted Mulligan purse
          }
        } catch (e) {
          // Fallback to total purse if CSV lookup fails
          displayPurse = totalPurse;
        }
      } else if (groupsProcessed) {
        displayPurse = groupPurse;
        displayMulliganPurse = _adjustedMulliganPurse; // Use adjusted Mulligan after groups processing
      }

      setState(() {
        _playersPurseDisplayText = '\$${displayPurse.toStringAsFixed(2)}';
        _closestPinPurseDisplayText = '\$${closestPinPurse.toStringAsFixed(2)}';
        _mulliganPurseDisplayText = '\$${displayMulliganPurse.toStringAsFixed(2)}';
        if (!individualsProcessingComplete) {
          _adjustedMulliganPurse = mulliganPurse;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  // ============== SHUFFLE FUNCTIONALITY ==============

  /// Handles the Shuffle button press to randomize player order
  /// Ensures each group has at least 3 players
  void _handleShuffle() {
    // Collect all players from all groups
    List<Map<String, dynamic>> allPlayers = [];

    // Collect all players
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (var player in groups[groupIndex]) {
        if (player != null) {
          allPlayers.add(Map<String, dynamic>.from(player));
        }
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

    final totalPlayers = allPlayers.length;

    // Handle edge cases
    if (totalPlayers < 4) {
      // If less than 4 players, put all in Group 1
      setState(() {
        for (int i = 0; i < groups.length; i++) {
          groups[i].clear();
          groups[i] = [null, null, null, null];
        }
        for (int i = 0; i < allPlayers.length; i++) {
          groups[0][i] = allPlayers[i];
        }
        _shuffledInCurrentSession = true;
        _hasBeenShuffled = true;
      });
      _createControllersForPlayers();
      return;
    }

    if (totalPlayers == 5) {
      // Special case: 5 players - put 3 in first group, 2 in second group
      final random = Random();
      allPlayers.shuffle(random);

      setState(() {
        for (int i = 0; i < groups.length; i++) {
          groups[i].clear();
          groups[i] = [null, null, null, null];
        }

        // Add first 3 players to Group 1
        for (int i = 0; i < 3; i++) {
          groups[0][i] = allPlayers[i];
        }

        // Add remaining 2 players to Group 2
        for (int i = 3; i < 5; i++) {
          groups[1][i - 3] = allPlayers[i];
        }

        _shuffledInCurrentSession = true;
        _hasBeenShuffled = true;
      });
      _createControllersForPlayers();
      return;
    }

    // Shuffle all players randomly
    final random = Random();
    allPlayers.shuffle(random);

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

    setState(() {
      // Clear all groups
      for (int i = 0; i < groups.length; i++) {
        groups[i].clear();
        // Keep 4 slots per group
        groups[i] = [null, null, null, null];
      }

      // Redistribute shuffled players
      int playerIndex = 0;
      for (int groupIndex = 0; groupIndex < numGroups; groupIndex++) {
        int playersInThisGroup = playersPerGroup;

        // Distribute remaining players to first groups
        if (groupIndex < remainingPlayers) {
          playersInThisGroup++;
        }

        // Add players to this group
        for (int i = 0; i < playersInThisGroup; i++) {
          if (playerIndex < allPlayers.length) {
            groups[groupIndex][i] = allPlayers[playerIndex];
            playerIndex++;
          }
        }
      }

      // Mark that shuffling occurred in this session
      _shuffledInCurrentSession = true;
      _hasBeenShuffled = true;
    });

    _createControllersForPlayers();
  }

  /// Gets the color for the shuffle button based on score data or group processing
  Color _getShuffleButtonColor() {
    if (_hasAnyScoreData() || groupsProcessed) {
      return Colors.grey[400]!;
    }
    return Colors.purple[200]!;
  }

  /// Gets the handler for the shuffle button based on score data or group processing
  VoidCallback? _getShuffleButtonHandler() {
    if (_hasAnyScoreData()) {
      return _handleShuffleDisabledDueToScores;
    }
    if (groupsProcessed) {
      return _handleShuffleDisabledDueToGroupProcessing;
    }
    return _handleShuffle;
  }

  /// Handles when shuffle button is pressed but disabled due to score data
  void _handleShuffleDisabledDueToScores() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot shuffle players after score data has been entered'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Handles when shuffle button is pressed but disabled due to group processing
  void _handleShuffleDisabledDueToGroupProcessing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot shuffle players after groups have been processed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============== SWAP FUNCTIONALITY ==============

  void _onPlayerTap(int groupIndex, int playerIndex, Map<String, dynamic> player) {
    if (_hasAnyScoreData() || groupsProcessed) return;

    String playerLast = player['last'] ?? '';
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

  void _onEmptySlotTap(int groupIndex, int playerIndex) {
    if (_hasAnyScoreData() || groupsProcessed) return;

    String slotKey = 'empty_${groupIndex + 1}_$playerIndex';
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

  bool _isPlayerSelected(String playerName) {
    if (_hasAnyScoreData() || groupsProcessed) return false;
    return selectedForSwap.contains(playerName);
  }

  bool _isEmptySlotSelected(int groupIndex, int playerIndex) {
    if (_hasAnyScoreData() || groupsProcessed) return false;
    String slotKey = 'empty_${groupIndex + 1}_$playerIndex';
    return selectedForSwap.contains(slotKey);
  }

  void _handleSwap() {
    if (selectedForSwap.length != 2) return;

    try {
      String item1 = selectedForSwap[0];
      String item2 = selectedForSwap[1];

      // Find positions
      int g1 = -1, p1 = -1, g2 = -1, p2 = -1;

      // Find item1 position
      if (item1.startsWith('empty_')) {
        List<String> parts = item1.split('_');
        g1 = int.parse(parts[1]) - 1;
        p1 = int.parse(parts[2]);
      } else {
        for (int g = 0; g < groups.length; g++) {
          for (int p = 0; p < groups[g].length; p++) {
            if (groups[g][p] != null && groups[g][p]!['last'] == item1) {
              g1 = g; p1 = p;
              break;
            }
          }
          if (g1 >= 0) break;
        }
      }

      // Find item2 position
      if (item2.startsWith('empty_')) {
        List<String> parts = item2.split('_');
        g2 = int.parse(parts[1]) - 1;
        p2 = int.parse(parts[2]);
      } else {
        for (int g = 0; g < groups.length; g++) {
          for (int p = 0; p < groups[g].length; p++) {
            if (groups[g][p] != null && groups[g][p]!['last'] == item2) {
              g2 = g; p2 = p;
              break;
            }
          }
          if (g2 >= 0) break;
        }
      }

      if (g1 >= 0 && p1 >= 0 && g2 >= 0 && p2 >= 0) {
        setState(() {
          // Swap the players
          var temp = groups[g1][p1];
          groups[g1][p1] = groups[g2][p2];
          groups[g2][p2] = temp;
          selectedForSwap.clear();
        });
        _createControllersForPlayers();
      }
    } catch (e) {
      selectedForSwap.clear();
    }
  }

  String _getSwapButtonText() {
    if (selectedForSwap.length == 1) {
      String displayName = selectedForSwap[0].startsWith('empty_')
          ? 'Empty ${selectedForSwap[0].split('_')[1]}'
          : selectedForSwap[0];
      return 'Selected: $displayName';
    } else if (selectedForSwap.length == 2) {
      return 'SWAP Players';
    }
    return 'Swap Players';
  }

  bool _hasAnyScoreData() {
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['gross_score'] != null) {
          // Check if it's a complete score (2 digits)
          String scoreStr = player['gross_score'].toString();
          if (scoreStr.length >= 2) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Color _getSwapButtonColor() {
    if (_hasAnyScoreData() || groupsProcessed) return Colors.grey[400]!;
    if (selectedForSwap.length == 2) return Colors.orange[300]!;
    return Colors.grey[400]!;
  }

  /// Gets the color for the back button based on group processing state
  Color _getBackButtonColor() {
    if (groupsProcessed) return Colors.grey[400]!;
    return Colors.lightBlue[100]!;
  }

  // ============== SCORE INPUT ==============

  void _onGrossScoreChanged(int groupIndex, int playerIndex, String value) {
    if (groupIndex >= groups.length || playerIndex >= groups[groupIndex].length) return;

    var player = groups[groupIndex][playerIndex];
    if (player == null) return;

    setState(() {
      if (value.isNotEmpty && value.length >= 2) {
        try {
          int grossScore = int.parse(value);
          player['gross_score'] = grossScore;
          double handicap = (player['handicap'] ?? 0.0).toDouble();
          player['net_score'] = grossScore - handicap.round();

          // Clear calculated values when score changes
          winnersCalculated = false;
          individualsProcessingComplete = false;
        } catch (e) {
          player['net_score'] = null;
        }
      } else if (value.isNotEmpty && value.length == 1) {
        try {
          player['gross_score'] = int.parse(value);
          player['net_score'] = null;
        } catch (e) {
          player['gross_score'] = null;
          player['net_score'] = null;
        }
      } else {
        player['gross_score'] = null;
        player['net_score'] = null;
      }
    });

    // Note: Auto-advance is handled by the keypad input handler
    // Do NOT move focus here to avoid double advancement

    // Auto-calculate if all scores entered (schedule after setState completes)
    Future.microtask(() => _checkAndAutoCalculate());
  }

  void _moveToNextGrossInput(int currentGroup, int currentPlayer) {
    // Try next player in same group
    for (int p = currentPlayer + 1; p < groups[currentGroup].length; p++) {
      if (groups[currentGroup][p] != null) {
        FocusNode? nextFocus = _focusNodeMatrix[currentGroup][p];
        if (nextFocus != null) {
          nextFocus.requestFocus();
          return;
        }
      }
    }

    // Try next groups
    for (int g = currentGroup + 1; g < groups.length; g++) {
      for (int p = 0; p < groups[g].length; p++) {
        if (groups[g][p] != null) {
          FocusNode? nextFocus = _focusNodeMatrix[g][p];
          if (nextFocus != null) {
            nextFocus.requestFocus();
            return;
          }
        }
      }
    }

    // End of inputs - hide keypad
    _hideKeypad();
  }

  Future<void> _checkAndAutoCalculate() async {
    // Check if all players have gross scores
    bool allComplete = true;
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          if (player['gross_score'] == null || player['gross_score'].toString().length < 2) {
            allComplete = false;
            break;
          }
        }
      }
      if (!allComplete) break;
    }

    if (allComplete && !winnersCalculated) {
      // Hide keypad first
      _hideKeypad();

      // Auto-process individuals to calculate prize money (without closest pin dialog)
      // Note: Payout amounts come directly from CSV, not percentage-based calculation
      await _autoProcessIndividuals();
    }
  }

  Future<void> _autoProcessIndividuals() async {
    try {
      List<Map<String, dynamic>> playerScores = _collectPlayerScores();
      if (playerScores.isEmpty) return;

      // Skip closest pin processing - just calculate winnings
      await _calculateWednesdayWinnings(playerScores);

      // Update groups with calculated values
      _updateGroupsWithWinnings(playerScores);

      setState(() {
        individualsProcessingComplete = true;
      });

      await _saveResultsToDatabase(playerScores);
      await updateTitleInformation();
    } catch (e) {
      // Handle error silently for auto-processing
    }
  }

  // ============== AUTO FILL ==============

  void _handleAutoFill() {
    final random = Random();

    // Create a new groups list to force rebuild
    List<List<Map<String, dynamic>?>> newGroups = [];

    for (var group in groups) {
      List<Map<String, dynamic>?> newGroup = [];
      for (var player in group) {
        if (player != null) {
          // Create a new player map with updated scores
          Map<String, dynamic> newPlayer = Map<String, dynamic>.from(player);
          int grossScore = 30 + random.nextInt(16); // 30-45
          newPlayer['gross_score'] = grossScore;
          double handicap = (newPlayer['handicap'] ?? 0.0).toDouble();
          newPlayer['net_score'] = grossScore - handicap.round();
          newGroup.add(newPlayer);

          String key = '${player['last']}_gross';
          grossControllers[key]?.text = grossScore.toString();
        } else {
          newGroup.add(null);
        }
      }
      newGroups.add(newGroup);
    }

    setState(() {
      groups = newGroups;
      winnersCalculated = false; // Reset winners flag so auto-calculate will run
      individualsProcessingComplete = false;
    });

    // Hide keypad after auto-fill is complete
    _hideKeypad();

    // Trigger auto-calculate to process individual payouts
    Future.microtask(() => _checkAndAutoCalculate());
  }

  // ============== PROCESS INDIVIDUALS ==============

  Future<void> _processIndividuals() async {
    try {
      FocusScope.of(context).unfocus();

      List<Map<String, dynamic>> playerScores = _collectPlayerScores();
      if (playerScores.isEmpty) {
        await PopupUtils.showWarning(context, "Process Error", "No player scores available to process!");
        return;
      }

      // Process closest pin first
      bool closestPinCompleted = await _processClosestPin(playerScores);
      if (!closestPinCompleted) return;

      // Calculate winnings
      await _calculateWednesdayWinnings(playerScores);

      // Update groups with calculated values
      _updateGroupsWithWinnings(playerScores);

      setState(() {
        individualsProcessingComplete = true;
      });

      await _saveResultsToDatabase(playerScores);
      await updateTitleInformation();
    } catch (e) {
      // Handle error
    }
  }

  List<Map<String, dynamic>> _collectPlayerScores() {
    List<Map<String, dynamic>> scores = [];
    Set<String> added = {};

    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          String id = '${player['first']}_${player['last']}';
          if (!added.contains(id)) {
            scores.add(Map<String, dynamic>.from(player));
            added.add(id);
          }
        }
      }
    }
    return scores;
  }

  Future<bool> _processClosestPin(List<Map<String, dynamic>> players) async {
    // Show closest pin selection dialog
    Map<String, int> playerValues = {};
    for (var player in players) {
      playerValues[player['last'] ?? 'Unknown'] = 0;
    }

    double closestPinAmount = LeaguePurseService.closestPinAmount;
    int targetTotal = closestPinAmount.round() * players.length;

    bool? result = await _showClosestPinDialog(players, playerValues, targetTotal);

    if (result == true) {
      // Calculate winnings from closest pin
      double prizePerPoint = players.length.toDouble();
      playerValues.forEach((name, value) {
        if (value > 0) {
          double winnings = value * prizePerPoint;
          // Find player and update
          for (var player in players) {
            if (player['last'] == name) {
              player['close_pin_winnings'] = winnings;
              break;
            }
          }
        }
      });
      return true;
    }
    return false;
  }

  Future<bool?> _showClosestPinDialog(
    List<Map<String, dynamic>> players,
    Map<String, int> playerValues,
    int targetTotal,
  ) async {
    final isPhone = DeviceDetectionService.isPhone(context);
    int runningTotal = 0;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            runningTotal = playerValues.values.fold(0, (sum, v) => sum + v);

            return AlertDialog(
              title: Column(
                children: [
                  Text(
                    'Closest Pin - Wednesday League',
                    style: TextStyle(fontSize: isPhone ? 14 : 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Target: \$$targetTotal | Current: $runningTotal',
                    style: TextStyle(
                      fontSize: isPhone ? 11 : 14,
                      color: runningTotal == targetTotal ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: players.map((player) {
                      String name = player['last'] ?? 'Unknown';
                      int value = playerValues[name] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          if (value < 5 && runningTotal < targetTotal) {
                            setState(() {
                              playerValues[name] = value + 1;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: value > 0 ? Colors.green[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name, style: TextStyle(fontSize: isPhone ? 12 : 14)),
                              if (value > 0) ...[
                                SizedBox(width: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    value.toString(),
                                    style: TextStyle(color: Colors.white, fontSize: isPhone ? 10 : 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      playerValues.updateAll((key, value) => 0);
                    });
                  },
                  child: Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _calculateWednesdayWinnings(List<Map<String, dynamic>> playerScores) async {
    // Sort by net score
    playerScores.sort((a, b) {
      int netA = a['net_score'] ?? 999;
      int netB = b['net_score'] ?? 999;
      return netA.compareTo(netB);
    });

    // Use winnings service
    var results = await _winningsService.calculateIndividualWinnings(playerScores, individualPurse);

    // Apply results
    for (var player in playerScores) {
      String name = player['last'] ?? '';
      var result = results[name];
      if (result != null) {
        player['place'] = result.place;
        player['is_tied'] = result.isTied;
        player['winnings'] = result.winnings;

        if (result.winnings > 0) {
          player['pos'] = result.isTied ? 'T${result.place}' : '${result.place}';
          player['prize_money'] = '\$${result.winnings.round()}';
        } else {
          player['pos'] = '';
          player['prize_money'] = '';
        }
      }
    }

    setState(() {
      winnersCalculated = true;
    });
  }

  void _updateGroupsWithWinnings(List<Map<String, dynamic>> playerScores) {
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

    // Calculate total prize money paid out
    _calculateTotalPrizeMoney();
  }

  /// Calculates the sum of all prize money amounts and adjusts Mulligan Purse
  /// Sums the whole dollar amounts in the $$$ column and compares to Ind Purse
  /// Any difference is transferred to/from Mulligan Purse to bring Ind Purse to $0.00
  void _calculateTotalPrizeMoney() {
    double totalDollarsPaidOut = 0.0;

    // Sum up all the whole dollar amounts in the $$$ column
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['prize_money'] != null) {
          String prizeMoneyStr = player['prize_money'].toString();
          // Remove $ and parse
          prizeMoneyStr = prizeMoneyStr.replaceAll('\$', '').trim();
          if (prizeMoneyStr.isNotEmpty) {
            try {
              totalDollarsPaidOut += double.parse(prizeMoneyStr);
            } catch (e) {
              // Skip invalid values
            }
          }
        }
      }
    }

    _totalPrizeMoney = totalDollarsPaidOut;
    _totalPayoutSum = totalDollarsPaidOut; // Store the total sum for display

    // Calculate the difference: Ind Purse - Total Dollars Paid Out
    // This is the amount needed to bring Ind Purse to $0.00
    double difference = individualPurse - totalDollarsPaidOut;

    // Calculate base Mulligan Purse (mulliganAmount × playerCount)
    int playerCount = 0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null) playerCount++;
      }
    }
    double baseMulliganPurse = LeaguePurseService.getMulliganAmount(league: League.wednesday) * playerCount;

    // Adjust Mulligan Purse by the difference
    // If difference > 0: we paid out less than Ind Purse, add surplus to Mulligan
    // If difference < 0: we paid out more than Ind Purse, subtract deficit from Mulligan
    double newMulliganPurse = baseMulliganPurse + difference;
    LeaguePurseService.setMulliganPurse(newMulliganPurse);
    _adjustedMulliganPurse = newMulliganPurse;
  }

  Future<void> _saveResultsToDatabase(List<Map<String, dynamic>> playerScores) async {
    try {
      final dbHelper = DatabaseHelper();
      String today = DateTime.now().toIso8601String().substring(0, 10);

      for (var player in playerScores) {
        Map<String, dynamic> scoreData = {
          'player_number': player['player_number'],
          'name': player['last'],
          'date_played': today,
          'golf_course': 'TBD',
          'handicap': player['handicap'],
          'gross_score': player['gross_score'],
          'net_score': player['net_score'],
          'position': player['pos'] ?? '',
          'individual_winnings': player['winnings'] ?? 0.0,
          'close_pin_winnings': player['close_pin_winnings'] ?? 0.0,
        };
        await dbHelper.insertScoreLeague(scoreData, League.wednesday);
      }
    } catch (e) {
      // Handle error
    }
  }

  // ============== PROCESS GROUPS ==============

  Future<void> _autoProcessGroups() async {
    if (!individualsProcessingComplete) {
      await PopupUtils.showWarning(context, "Process Error", "Please process individuals first!");
      return;
    }

    // Save current individual processing data to database
    await _saveIndividualResultsToDatabase();

    // Process groups in the current screen
    await _processGroupsInPlace();
  }

  /// Saves individual processing results to database before group processing
  Future<void> _saveIndividualResultsToDatabase() async {
    // TODO: Implementation will save individual results for PAYOUT/Results screen
    // This preserves the data before group processing transforms the UI
  }

  /// Processes groups in the current screen without navigation
  /// Uses ProcessGroupsService to handle the logic
  Future<void> _processGroupsInPlace() async {
    // Use the service to process groups, passing the adjusted Mulligan Purse as carryover
    ProcessGroupsResult result = await _processGroupsService.processGroups(groups, _adjustedMulliganPurse);

    // Update state with the results
    setState(() {
      groups = result.newGroups;
      _groupPurseAmount = result.groupPurseAmount;
      _groupPayoutAmount = result.groupPayoutAmount;
      _adjustedMulliganPurse = result.mulliganPurseAmount; // Use the carryover value
      groupsProcessed = true;
      selectedForSwap.clear(); // Clear swap selection when groups are processed
    });

    await updateTitleInformation();
  }

  // ============== NAVIGATION ==============

  void _returnToMainMenu() {
    EnterScoresUIService.resetOrientation();
    Navigator.pop(context);
  }

  void _navigateToClosestPin() {
    // Collect all players from all groups to pass to closest pin screen
    List<Map<String, dynamic>> allPlayers = [];
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['is_wild_card'] != true) {
          allPlayers.add(player);
        }
      }
    }

    // Navigate to wednesday_closest_pin_screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WednesdayClosestPinScreen(
          selectedPlayers: allPlayers,
        ),
      ),
    );
  }

  // ============== BUILD ==============

  @override
  Widget build(BuildContext context) {
    // First purse position:
    // - Before groups processing: shows "Ind Purse" with individual purse amount
    // - After groups processing: shows "Group Purse" with team_total from CSV
    double playersPurse;
    if (groupsProcessed) {
      playersPurse = _groupPurseAmount;
    } else {
      playersPurse = double.tryParse(_playersPurseDisplayText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }

    // For the second purse position (now "Payout"):
    // - Initially and during score entry: show $0.00
    // - After individuals processing: show total payout sum
    // - After groups processing: show group payout (sum of $$$ column)
    double payoutAmount = 0.0;
    if (individualsProcessingComplete && !groupsProcessed) {
      payoutAmount = _totalPayoutSum;
    } else if (groupsProcessed) {
      payoutAmount = _groupPayoutAmount;
    }

    double mulliganPurse = double.tryParse(_mulliganPurseDisplayText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              EnterScoresUIService.buildWednesdayPurseHeader(
                context,
                playersPurse: playersPurse,
                closestPinPurse: payoutAmount,
                mulliganPurse: mulliganPurse,
                groupsProcessed: groupsProcessed,
                individualsProcessingComplete: individualsProcessingComplete,
                onReturn: _returnToMainMenu,
                onAutoFill: _handleAutoFill,
              ),
              EnterScoresUIService.buildWednesdayGroupsGrid(
                context,
                groups,
                groupsProcessed: groupsProcessed,
                onPlayerTap: _onPlayerTap,
                onEmptySlotTap: _onEmptySlotTap,
                isPlayerSelected: _isPlayerSelected,
                isEmptySlotSelected: _isEmptySlotSelected,
                onGrossScoreChanged: _onGrossScoreChangedWrapper,
                grossFocusNodes: _focusNodeMatrix,
                isPlayerFocused: _isPlayerFocusedWrapper,
              ),
              EnterScoresUIService.buildWednesdayBottomButtons(
                context,
                swapButtonText: _getSwapButtonText(),
                swapButtonColor: _getSwapButtonColor(),
                individualsComplete: individualsProcessingComplete,
                groupsProcessed: groupsProcessed,
                onMainMenu: _returnToMainMenu,
                onShuffle: _getShuffleButtonHandler(),
                shuffleButtonColor: _getShuffleButtonColor(),
                backButtonColor: _getBackButtonColor(),
                onIndividuals: _handleIndividuals,
                onProcessGroups: _handleAutoProcessGroups,
                onClosestPin: _navigateToClosestPin,
                onSwap: selectedForSwap.length == 2 ? _handleSwap : null,
              ),
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
              isVisible: _keypadController?.isVisible ?? false,
            ),
          ),
        ],
      ),
    );
  }

  // ============== UI SERVICE WRAPPERS ==============

  /// Wrapper to convert UI service callback signature to screen's method signature
  void _onGrossScoreChangedWrapper(Map<String, dynamic> player, String value) {
    // Find the player's position in groups
    for (int g = 0; g < groups.length; g++) {
      for (int p = 0; p < groups[g].length; p++) {
        if (groups[g][p] != null && groups[g][p] == player) {
          _onGrossScoreChanged(g, p, value);
          return;
        }
      }
    }
  }

  /// Wrapper to check if a player is currently focused
  bool _isPlayerFocusedWrapper(Map<String, dynamic> player) {
    if (_currentFocusedPlayer == null) return false;
    String playerName = player['last'] ?? '';
    return _currentFocusedPlayer!.name == playerName;
  }

  /// Wrapper for Individuals button
  void _handleIndividuals() {
    _processIndividuals();
  }

  /// Wrapper for Auto Process Groups button
  void _handleAutoProcessGroups() {
    _autoProcessGroups();
  }
}
