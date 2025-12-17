import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../popup_utils.dart';
import '../main_menu_screen.dart';
import 'wednesday_auto_process_groups_screen.dart';
import '../../services/database_helper.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/csv_payout_service.dart';
import '../../services/group_csv_payout_service.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/wednesday_winnings_service.dart';
import '../../models/league.dart';
import '../../models/wednesday_player_data.dart';

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
      double anteAmount = LeaguePurseService.playersAnte;
      double closestPinAmount = LeaguePurseService.closestPinAmount;
      double mulliganAmount = LeaguePurseService.mulliganAmount;

      int playerCount = 0;
      for (var group in groups) {
        for (var player in group) {
          if (player != null) playerCount++;
        }
      }

      totalPurse = anteAmount * playerCount;
      double closestPinPurse = closestPinAmount * playerCount;
      double mulliganPurse = mulliganAmount * playerCount;

      setState(() {
        _playersPurseDisplayText = groupsProcessed
            ? '\$${groupPurse.toStringAsFixed(2)}'
            : '\$${totalPurse.toStringAsFixed(2)}';
        _closestPinPurseDisplayText = '\$${closestPinPurse.toStringAsFixed(2)}';
        _mulliganPurseDisplayText = '\$${mulliganPurse.toStringAsFixed(2)}';
        _adjustedMulliganPurse = mulliganPurse;
      });
    } catch (e) {
      // Handle error
    }
  }

  // ============== SHUFFLE FUNCTIONALITY ==============

  /// Handles the Shuffle button press to randomize player order
  void _handleShuffle() {
    // Collect all players from all groups
    List<Map<String, dynamic>> allPlayers = [];
    List<int> groupSizes = [];

    // Store original group sizes and collect all players
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      int groupSize = 0;
      for (var player in groups[groupIndex]) {
        if (player != null) {
          groupSize++;
          allPlayers.add(Map<String, dynamic>.from(player));
        }
      }
      groupSizes.add(groupSize);
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
        // Keep 4 slots per group
        groups[i] = [null, null, null, null];
      }

      // Redistribute shuffled players back into groups with original sizes
      int playerIndex = 0;
      for (int groupIndex = 0; groupIndex < groupSizes.length; groupIndex++) {
        int groupSize = groupSizes[groupIndex];
        for (int i = 0; i < groupSize && playerIndex < allPlayers.length; i++) {
          groups[groupIndex][i] = allPlayers[playerIndex];
          playerIndex++;
        }
      }

      // Mark that shuffling occurred in this session
      _shuffledInCurrentSession = true;
      _hasBeenShuffled = true;
    });

    _createControllersForPlayers();
  }

  /// Gets the color for the shuffle button based on score data only
  Color _getShuffleButtonColor() {
    if (_hasAnyScoreData()) {
      return Colors.grey[400]!;
    }
    return Colors.purple[200]!;
  }

  /// Gets the handler for the shuffle button based on score data only
  VoidCallback? _getShuffleButtonHandler() {
    if (_hasAnyScoreData()) {
      return _handleShuffleDisabledDueToScores;
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

  // ============== SWAP FUNCTIONALITY ==============

  void _onPlayerTap(int groupIndex, int playerIndex, Map<String, dynamic> player) {
    if (_hasAnyScoreData()) return;

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
    if (_hasAnyScoreData()) return;

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
    if (_hasAnyScoreData()) return false;
    return selectedForSwap.contains(playerName);
  }

  bool _isEmptySlotSelected(int groupIndex, int playerIndex) {
    if (_hasAnyScoreData()) return false;
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
    if (_hasAnyScoreData()) return Colors.grey[400]!;
    if (selectedForSwap.length == 2) return Colors.orange[300]!;
    return Colors.grey[400]!;
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

  Future<void> _navigateToAutoProcessGroups() async {
    if (!individualsProcessingComplete) {
      await PopupUtils.showWarning(context, "Process Error", "Please process individuals first!");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WednesdayAutoProcessGroupsScreen(
          initialGroups: groups,
          initialLeague: 'wednesday',
        ),
      ),
    );
  }

  // ============== NAVIGATION ==============

  void _returnToMainMenu() {
    EnterScoresUIService.resetOrientation();
    Navigator.pop(context);
  }

  // ============== BUILD ==============

  @override
  Widget build(BuildContext context) {
    // Parse purse values from display strings
    double playersPurse = double.tryParse(_playersPurseDisplayText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    double closestPinPurse = double.tryParse(_closestPinPurseDisplayText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
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
                closestPinPurse: closestPinPurse,
                mulliganPurse: mulliganPurse,
                groupsProcessed: groupsProcessed,
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
                onMainMenu: _returnToMainMenu,
                onShuffle: _getShuffleButtonHandler(),
                shuffleButtonColor: _getShuffleButtonColor(),
                onIndividuals: _handleIndividuals,
                onProcessGroups: _handleAutoProcessGroups,
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
    _navigateToAutoProcessGroups();
  }
}
