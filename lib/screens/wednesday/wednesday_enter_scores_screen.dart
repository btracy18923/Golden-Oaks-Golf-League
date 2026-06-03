import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';
import '../popup_utils.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/csv_payout_service.dart';
import '../../services/group_csv_payout_service.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/UI/custom_keypad_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/wednesday_winnings_service.dart';
import '../../services/process_groups_service.dart';
import '../../services/backend_email_service.dart';
import '../../services/database_helper.dart';
import '../../config/email_config.dart';
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
    super.key,
    this.initialPlayers,
    this.initialGroups,
    this.initialLeague,
  });

  @override
  _WednesdayEnterScoresScreenState createState() => _WednesdayEnterScoresScreenState();
}

/// Wrapper widget for navigation with data
class EnterScoresScreenWithData extends StatelessWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  final List<List<Map<String, dynamic>?>> groups;
  final String leagueType;

  const EnterScoresScreenWithData({
    super.key,
    required this.selectedPlayers,
    required this.groups,
    required this.leagueType,
  });

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

  // Services
  final WednesdayWinningsService _winningsService = WednesdayWinningsService();
  final ProcessGroupsService _processGroupsService = ProcessGroupsService();

  // Custom keypad controller
  CustomKeypadController? _keypadController;

  // Swap selection tracking (inline, since SwapService uses PlayerData)
  List<String> selectedForSwap = [];

  // Adjust Players overlay state
  bool _showAdjustPlayersOverlay = false;

  // Triple-click delete functionality
  String? _deleteTargetPlayerName;
  int _deleteTargetTapCount = 0;

  // Triple-click add functionality for empty slots
  String? _addTargetSlotKey; // "groupIndex_playerIndex"
  int _addTargetTapCount = 0;

  // State
  List<List<Map<String, dynamic>?>> groups = [];
  List<Map<String, dynamic>> selectedPlayers = [];

  // Controllers and Focus Nodes
  Map<String, TextEditingController> grossControllers = {};
  Map<String, FocusNode> grossFocusNodes = {};

  // Focus management
  final _focusNodeMatrix = List.generate(10, (_) => List<FocusNode?>.filled(4, null));
  WednesdayPlayerData? _currentFocusedPlayer;

  // Purse display values
  String _playersPurseDisplayText = "\$0.00";
  String _mulliganPurseDisplayText = "\$0.00";
  double _adjustedMulliganPurse = 0.0;
  double _totalPayoutSum = 0.0;
  double _groupPurseAmount = 0.0;
  double _groupPayoutAmount = 0.0;

  // Processing state
  double totalPurse = 0.0;
  double individualPurse = 0.0;
  double groupPurse = 0.0;
  bool winnersCalculated = false;
  bool groupsProcessed = false;
  bool individualsProcessingComplete = false;

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
    for (var c in grossControllers.values) {
      c.dispose();
    }
    for (var n in grossFocusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// Sets players data from navigation
  void setPlayers(List<Map<String, dynamic>> players, List<List<Map<String, dynamic>?>> groupsData, String league) {
    setState(() {
      selectedPlayers = List.from(players);
      groups = groupsData.map((g) => g.map((p) {
        if (p != null) {
          Map<String, dynamic> playerCopy = Map<String, dynamic>.from(p);
          // Map HC field to handicap if it exists, ensuring we use the database HC value
          // HC is the handicap field for Wednesday league players
          if (playerCopy.containsKey('HC')) {
            playerCopy['handicap'] = playerCopy['HC'];
          } else if (!playerCopy.containsKey('handicap')) {
            // If no HC or handicap field exists, default to 0.0
            playerCopy['handicap'] = 0.0;
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
    // Prevent keypad from showing when Adjust Players overlay is visible
    if (_showAdjustPlayersOverlay) {
      return;
    }

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
          Future.delayed(const Duration(milliseconds: 300), () {
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
      LeaguePurseService.getClosestPinAmount(league: League.wednesday);
      double mulliganAmount = LeaguePurseService.getMulliganAmount(league: League.wednesday);

      int playerCount = 0;
      for (var group in groups) {
        for (var player in group) {
          if (player != null) playerCount++;
        }
      }

      totalPurse = anteAmount * playerCount;
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

  /// Handles the Shuffle button press using handicap-seeded distribution.
  /// Each group of 4 gets 2 high-HC and 2 low-HC players.
  /// Each group of 3 gets 1 high-HC and 2 low-HC players.
  /// The last group may not match if pools run dry.
  void _handleShuffle() {
    List<Map<String, dynamic>> allPlayers = [];
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

    if (totalPlayers < 4) {
      setState(() {
        for (int i = 0; i < groups.length; i++) {
          groups[i].clear();
          groups[i] = [null, null, null, null];
        }
        for (int i = 0; i < allPlayers.length; i++) {
          groups[0][i] = allPlayers[i];
        }
      });
      _createControllersForPlayers();
      return;
    }

    // Sort by HC descending so top half = high handicap players
    allPlayers.sort((a, b) {
      double hcA = ((a['HC'] ?? a['handicap']) as num? ?? 0).toDouble();
      double hcB = ((b['HC'] ?? b['handicap']) as num? ?? 0).toDouble();
      return hcB.compareTo(hcA);
    });

    // Split into high HC (top half) and low HC (bottom half)
    int splitPoint = (totalPlayers / 2).ceil();
    List<Map<String, dynamic>> highHC = List.from(allPlayers.sublist(0, splitPoint));
    List<Map<String, dynamic>> lowHC = List.from(allPlayers.sublist(splitPoint));

    // Shuffle each pool independently so seeding is random within each tier
    final random = Random();
    highHC.shuffle(random);
    lowHC.shuffle(random);

    // Calculate number of groups
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

    int playersPerGroup = totalPlayers ~/ numGroups;
    int remainingPlayers = totalPlayers % numGroups;

    int highIdx = 0;
    int lowIdx = 0;

    setState(() {
      for (int i = 0; i < groups.length; i++) {
        groups[i].clear();
        groups[i] = [null, null, null, null];
      }

      for (int groupIndex = 0; groupIndex < numGroups; groupIndex++) {
        int groupSize = playersPerGroup + (groupIndex < remainingPlayers ? 1 : 0);
        int slot = 0;

        if (groupSize >= 4) {
          // 2 high HC + 2 low HC; fill any leftover slots from whichever pool remains
          for (int i = 0; i < 2 && highIdx < highHC.length && slot < 4; i++) {
            groups[groupIndex][slot++] = highHC[highIdx++];
          }
          for (int i = 0; i < 2 && lowIdx < lowHC.length && slot < 4; i++) {
            groups[groupIndex][slot++] = lowHC[lowIdx++];
          }
          while (slot < groupSize && slot < 4) {
            if (highIdx < highHC.length) {
              groups[groupIndex][slot++] = highHC[highIdx++];
            } else if (lowIdx < lowHC.length) {
              groups[groupIndex][slot++] = lowHC[lowIdx++];
            } else break;
          }
        } else if (groupSize == 3) {
          // 1 high HC + 2 low HC; fall back to opposite pool if one runs dry
          if (highIdx < highHC.length) {
            groups[groupIndex][slot++] = highHC[highIdx++];
          } else if (lowIdx < lowHC.length) {
            groups[groupIndex][slot++] = lowHC[lowIdx++];
          }
          for (int i = 0; i < 2 && slot < 4; i++) {
            if (lowIdx < lowHC.length) {
              groups[groupIndex][slot++] = lowHC[lowIdx++];
            } else if (highIdx < highHC.length) {
              groups[groupIndex][slot++] = highHC[highIdx++];
            }
          }
        } else {
          // Group of 2 or fewer — fill from whichever pool has players
          while (slot < groupSize && slot < 4) {
            if (highIdx < highHC.length) {
              groups[groupIndex][slot++] = highHC[highIdx++];
            } else if (lowIdx < lowHC.length) {
              groups[groupIndex][slot++] = lowHC[lowIdx++];
            } else break;
          }
        }
      }
    });

    _createControllersForPlayers();
  }

  /// Returns true if a player is selected for deletion (triple-clicked)
  bool _isDeleteMode() {
    return _deleteTargetPlayerName != null && _deleteTargetTapCount >= 3;
  }

  /// Handles deleting the triple-clicked player
  void _handleDeletePlayer() {
    if (_deleteTargetPlayerName == null) return;

    setState(() {
      // Remove the player from all groups by setting their slot to null
      for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        for (int i = 0; i < groups[groupIndex].length; i++) {
          if (groups[groupIndex][i] != null && groups[groupIndex][i]!['last'] == _deleteTargetPlayerName) {
            groups[groupIndex][i] = null;
          }
        }
      }
      _deleteTargetPlayerName = null;
      _deleteTargetTapCount = 0;
      selectedForSwap.clear();
    });
    _createControllersForPlayers();
    // Recalculate purse amounts based on new player count
    updateTitleInformation();
  }

  /// Resets delete mode
  void _resetDeleteMode() {
    _deleteTargetPlayerName = null;
    _deleteTargetTapCount = 0;
  }

  /// Resets add mode
  void _resetAddMode() {
    _addTargetSlotKey = null;
    _addTargetTapCount = 0;
  }

  /// Shows a dialog listing all Wednesday league players not currently in any group slot.
  /// Covers both players not selected today and players deleted during this session.
  Future<void> _showAddPlayerDialog(int groupIndex, int playerIndex) async {
    // Build set of last names already placed in groups
    final Set<String> inGroups = {};
    for (var group in groups) {
      for (var player in group) {
        if (player != null) inGroups.add(player['last'] ?? '');
      }
    }

    // Load the full Wednesday roster from the database
    final allPlayers = await DatabaseHelper().getPlayersByLeague(League.wednesday);
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
              final hc = ((player['HC'] ?? player['handicap']) as num? ?? 0).toDouble();
              return ListTile(
                title: Text(player['last'] ?? ''),
                trailing: Text('HC ${hc.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    groups[groupIndex][playerIndex] = player;
                  });
                  _createControllersForPlayers();
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

  /// Gets the text for the shuffle/delete button
  String _getShuffleButtonText() {
    if (_isDeleteMode()) return 'Delete';
    return 'Shuffle';
  }

  /// Gets the color for the shuffle button based on score data or group processing
  Color _getShuffleButtonColor() {
    if (_isDeleteMode()) return Colors.red;
    if (_hasAnyScoreData() || groupsProcessed) {
      return Colors.grey[400]!;
    }
    return Colors.purple[200]!;
  }

  /// Gets the handler for the shuffle button based on score data or group processing
  VoidCallback? _getShuffleButtonHandler() {
    if (_isDeleteMode()) return _handleDeletePlayer;
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
      // Track triple-click for delete (only in adjust players overlay)
      if (_showAdjustPlayersOverlay) {
        if (_deleteTargetPlayerName == playerLast) {
          if (_deleteTargetTapCount >= 3) {
            // 4th click - cancel delete mode
            _resetDeleteMode();
            selectedForSwap.clear();
            return;
          }
          _deleteTargetTapCount++;
          // On 2nd and 3rd click, don't pass through to swap service
          return;
        } else {
          // Different player tapped - reset delete tracking
          _resetDeleteMode();
          _deleteTargetPlayerName = playerLast;
          _deleteTargetTapCount = 1;
        }
      }

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

    // In adjust players overlay: triple-tap opens the add-player picker
    if (_showAdjustPlayersOverlay) {
      final slotKey = '${groupIndex}_$playerIndex';
      bool showPicker = false;
      setState(() {
        if (_addTargetSlotKey == slotKey) {
          if (_addTargetTapCount >= 3) {
            _resetAddMode(); // 4th tap cancels
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

    // Outside adjust overlay: existing swap-selection behavior
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
    // Keep player highlighted during delete progression
    if (_deleteTargetPlayerName == playerName && _deleteTargetTapCount >= 1) {
      return true;
    }
    return selectedForSwap.contains(playerName);
  }

  /// Returns the background color for a player based on delete tap count
  Color? _getPlayerSelectedColor(String playerName) {
    if (_deleteTargetPlayerName == playerName) {
      if (_deleteTargetTapCount >= 3) return Colors.red;
      if (_deleteTargetTapCount == 2) return Colors.purple[200];
    }
    return null; // Use default color for swap selection
  }

  bool _isEmptySlotSelected(int groupIndex, int playerIndex) {
    if (_hasAnyScoreData() || groupsProcessed) return false;
    String swapKey = 'empty_${groupIndex + 1}_$playerIndex';
    if (selectedForSwap.contains(swapKey)) return true;
    // Highlight during add tap progression
    if (_showAdjustPlayersOverlay && _addTargetSlotKey == '${groupIndex}_$playerIndex') return true;
    return false;
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

  /// Gets the color for the back button based on score data or group processing state
  Color _getBackButtonColor() {
    if (_hasAnyScoreData() || groupsProcessed) {
      return Colors.grey[400]!;
    }
    return Colors.lightBlue[100]!;
  }

  /// Gets the handler for the back button based on score data or group processing state
  VoidCallback? _getBackButtonHandler() {
    if (_hasAnyScoreData()) {
      return _handleBackDisabledDueToScores;
    }
    if (groupsProcessed) {
      return null;
    }
    return _returnToMainMenu;
  }

  /// Handles when back button is pressed but disabled due to score data
  void _handleBackDisabledDueToScores() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot return to Player Selection after Gross scores have been entered'),
        duration: Duration(seconds: 2),
      ),
    );
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
          player['net_score'] = (grossScore - handicap).toDouble();

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

      // NOTE: Do NOT save to database here - the comprehensive save happens in wednesday_results_screen
      // when "Save Results" button is pressed (which includes both individual AND group winnings)
      // await _saveResultsToDatabase(playerScores);
      await updateTitleInformation();
    } catch (e) {
      // Handle error silently for auto-processing
    }
  }

  // ============== AUTO FILL ==============

  void _handleAutoFill() {
    // Prevent Auto Fill when Adjust Players overlay is visible
    if (_showAdjustPlayersOverlay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot use Auto Fill while adjusting players'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final random = Random();

    // Create a new groups list to force rebuild
    List<List<Map<String, dynamic>?>> newGroups = [];

    for (var group in groups) {
      List<Map<String, dynamic>?> newGroup = [];
      for (var player in group) {
        if (player != null) {
          // Create a new player map with updated scores
          Map<String, dynamic> newPlayer = Map<String, dynamic>.from(player);

          // Get HC (Handicap) value for score calculation
          double hc = (newPlayer['HC'] ?? 0.0).toDouble();
          int hcValue = hc.round();

          // Calculate gross score: HC + 35 ± random(-2 to +3)
          int baseScore = hcValue + 35;
          int randomAdjustment = random.nextInt(6) - 2; // -2 to +3
          int grossScore = baseScore + randomAdjustment;

          // For net score calculation, use the regular handicap (HC)
          double handicap = (newPlayer['handicap'] ?? 0.0).toDouble();

          newPlayer['gross_score'] = grossScore;
          newPlayer['net_score'] = (grossScore - handicap).toDouble();
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

  // ============== COLLECT PLAYER SCORES ==============

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

  Future<void> _calculateWednesdayWinnings(List<Map<String, dynamic>> playerScores) async {
    // Sort by net score
    playerScores.sort((a, b) {
      double netA = (a['net_score'] ?? 999).toDouble();
      double netB = (b['net_score'] ?? 999).toDouble();
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
          player['ind_pos'] = result.isTied ? 'T${result.place}' : '${result.place}';
          player['prize_money'] = '\$${result.winnings.round()}';
        } else {
          player['ind_pos'] = '';
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
            player['ind_pos'] = updatedPlayer['ind_pos'];
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

  /// Saves individual processing results before group processing
  /// Preserves the data to pass to results screen
  final List<Map<String, dynamic>> _individualWinners = [];

  Future<void> _saveIndividualResultsToDatabase() async {
    // Collect players with individual winnings (before groups processing)
    _individualWinners.clear();
    for (var group in groups) {
      for (var player in group) {
        if (player != null &&
            player['prize_money'] != null &&
            player['manual_group'] == null &&
            player['last'] != null) {
          _individualWinners.add(Map<String, dynamic>.from(player));
        }
      }
    }
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

    // Get base amounts from LeaguePurseService
    double playersAnte = LeaguePurseService.getPlayersAnte(league: League.wednesday);
    double closestPinAmount = LeaguePurseService.getClosestPinAmount(league: League.wednesday);
    double mulliganAmount = LeaguePurseService.getMulliganAmount(league: League.wednesday);

    // Navigate to wednesday_closest_pin_screen with group data, purse amounts, and individual winners
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WednesdayClosestPinScreen(
          selectedPlayers: allPlayers,
          groups: groups,
          groupPurseAmount: _groupPurseAmount,
          groupPayoutAmount: _groupPayoutAmount,
          adjustedMulliganPurse: _adjustedMulliganPurse,
          individualWinners: _individualWinners,
          playersAnte: playersAnte,
          closestPinAmount: closestPinAmount,
          mulliganAmount: mulliganAmount,
        ),
      ),
    );
  }

  // ============== BUILD ==============

  /// Builds bottom buttons with Adjust Players button
  Widget _buildBottomButtons(bool individualsComplete, bool groupsProcessed) {
    // Determine button text and callback based on groups processing state
    String processButtonText = groupsProcessed ? 'Close Pin Winner ---➤' : 'Process Groups ---➤';
    VoidCallback? processButtonCallback = groupsProcessed
        ? _navigateToClosestPin
        : (individualsComplete ? _handleAutoProcessGroups : null);
    Color processButtonColor = groupsProcessed
        ? Colors.orange[300]!
        : (individualsComplete ? Colors.orange[300]! : Colors.grey[400]!);

    // Build button list based on processing state
    List<Widget> buttons = [];

    if (!groupsProcessed) {
      // Show all buttons when not processed
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: '◄- Player Selection',
        color: _getBackButtonColor(),
        onPressed: _getBackButtonHandler(),
      ));
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: 'Adjust Players',
        color: _getAdjustPlayersButtonColor(),
        onPressed: _getAdjustPlayersButtonHandler(),
      ));
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: processButtonText,
        color: processButtonColor,
        onPressed: processButtonCallback,
      ));
    } else {
      // Only show Close Pin Winner button when processed
      final screenWidth = MediaQuery.of(context).size.width;
      final buttonWidth = (screenWidth / 5) * 1.5;
      final buttonFontSize = ResponsiveTypography.getButton(context);
      final buttonRadius = ButtonBarUIService.getButtonRadius(context);
      final buttonInternalPadding = ButtonBarUIService.getButtonInternalPadding(context);

      return ButtonBarUIService.buildButtonBar(
        context,
        backgroundColor: Colors.grey[300]!,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: SizedBox(
              width: buttonWidth,
              child: ElevatedButton(
                onPressed: processButtonCallback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: processButtonColor,
                  foregroundColor: Colors.black,
                  padding: buttonInternalPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonRadius),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Text(
                  processButtonText,
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[300]!,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

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
                getPlayerSelectedColor: _getPlayerSelectedColor,
              ),
              _buildBottomButtons(individualsProcessingComplete, groupsProcessed),
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

  // ============== ADJUST PLAYERS OVERLAY ==============

  /// Builds the Adjust Players overlay button bar
  Widget _buildAdjustPlayersOverlay() {
    List<Widget> buttons = [];

    // Back button
    buttons.add(ButtonBarUIService.buildActionButton(
      context,
      text: '◄- Enter Gross',
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
      text: _getSwapButtonText(),
      color: _getSwapButtonColor(),
      onPressed: selectedForSwap.length == 2 ? _handleSwap : null,
    ));

    // Email button
    buttons.add(ButtonBarUIService.buildActionButton(
      context,
      text: 'Email',
      color: Colors.orange[200]!,
      onPressed: _handleEmailAndTexts,
    ));

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.orange[100]!,
      children: buttons,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      useMinHeight: true,
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

  /// Wrapper for Auto Process Groups button
  void _handleAutoProcessGroups() {
    _autoProcessGroups();
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
      selectedForSwap.clear(); // Clear any swap selections when closing
      _resetDeleteMode(); // Clear any delete selection when closing
    });
  }

  /// Handler for Email button - shows dialog with options
  void _handleEmailAndTexts() {
    // Dismiss any open keyboard before showing dialog
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email'),
          content: const Text('Choose an action:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleEmailProShop();
              },
              child: const Text('Email ProShop and Groups'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Saves current groupings to Firebase so they can be restored on game day
  Future<void> _saveGroupingsToFirebase() async {
    try {
      final groupsJson = jsonEncode(groups.map((group) =>
          group.map((p) => p != null ? Map<String, dynamic>.from(p) : null).toList()
      ).toList());
      final playersJson = jsonEncode(selectedPlayers.map((p) => Map<String, dynamic>.from(p)).toList());

      await FirebaseFirestore.instance.collection('W_scheduled_groups').doc('pending').set({
        'groups': groupsJson,
        'players': playersJson,
        'saved_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save groupings to Firebase: $e');
    }
  }

  /// Handler for Email ProShop - sends via backend service
  Future<void> _handleEmailProShop() async {
    final backendEmailService = BackendEmailService();

    // Build email subject
    final currentDate = DateTime.now().toString().split(' ')[0];
    final subject = 'Golden Oaks Wed. Players - $currentDate';

    // Build email body with groups
    final body = _buildProShopEmailBody();

    // Send email via backend service
    final success = await backendEmailService.sendProShopEmail(
      subject: subject,
      body: body,
    );

    if (success) {
      await _saveGroupingsToFirebase();
      await _handleEmailGroups();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Player list emailed to ProShop and groupings saved.'
                : 'Email failed — groupings NOT saved. Check your connection and try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Handler for Text Players - sends SMS with player groups to all players
  Future<void> _handleTextPlayers() async {
    // TEST MODE: Set to true to send only to test number, false for real player numbers
    const bool testMode = true;
    // Alex Grohol mobile number
    const String testPhoneNumber = '9083775851';
    // Bill Tracy mobile number
    // const String testPhoneNumber = '9082087608';

    // Collect phone numbers from all players in all groups
    final phoneNumbers = <String>[];

    if (testMode) {
      phoneNumbers.add(testPhoneNumber);
    } else {
      // Production mode: collect all player cell numbers
      for (var group in groups) {
        for (var player in group) {
          if (player != null) {
            final cell = player['cell']?.toString() ?? '';
            // Clean phone number - remove non-digits
            final cleanNumber = cell.replaceAll(RegExp(r'[^\d]'), '');
            if (cleanNumber.length >= 10) {
              phoneNumbers.add(cleanNumber);
            }
          }
        }
      }
    }

    if (phoneNumbers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone numbers found for players'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Build message body with all groups (like pro shop email)
    final message = _buildTextPlayersMessage();

    // Encode the message for URL
    final encodedMessage = Uri.encodeComponent(message);

    // Join phone numbers with commas for group text
    final recipients = phoneNumbers.join(',');

    // Try Android-friendly SMS URI format
    final smsUri = Uri.parse('sms:$recipients?body=$encodedMessage');

    try {
      final launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open SMS app'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening SMS: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Gets the next upcoming Wednesday date formatted as M/DD/YY
  String _getNextWednesday() {
    final now = DateTime.now();
    // DateTime.weekday: 1=Monday, 2=Tuesday, 3=Wednesday, etc.
    int daysUntilWednesday = (DateTime.wednesday - now.weekday) % 7;
    // If today is Wednesday, use today (daysUntilWednesday would be 0)
    if (daysUntilWednesday == 0 && now.hour >= 12) {
      // If it's Wednesday afternoon, show next Wednesday
      daysUntilWednesday = 7;
    }
    final nextWed = now.add(Duration(days: daysUntilWednesday));

    final month = nextWed.month;
    final day = nextWed.day;
    final year = (nextWed.year % 100).toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  /// Builds the SMS message body showing all groups (like pro shop email)
  String _buildTextPlayersMessage() {
    final buffer = StringBuffer();
    final nextWednesday = _getNextWednesday();

    buffer.writeln('Wed Golf $nextWednesday');

    // Filter out empty groups and empty players
    final validGroups = <List<Map<String, dynamic>>>[];
    for (var group in groups) {
      final validPlayers = group.where((player) {
        if (player == null) return false;
        final name = player['last']?.toString() ?? '';
        return name.isNotEmpty;
      }).cast<Map<String, dynamic>>().toList();

      if (validPlayers.isNotEmpty) {
        validGroups.add(validPlayers);
      }
    }

    int totalPlayers = 0;
    for (int groupIndex = 0; groupIndex < validGroups.length; groupIndex++) {
      final group = validGroups[groupIndex];
      buffer.writeln('Group ${groupIndex + 1}:');

      for (var player in group) {
        final firstName = player['first']?.toString() ?? '';
        final lastName = player['last']?.toString() ?? '';
        buffer.writeln('  $firstName $lastName');
        totalPlayers++;
      }
    }

    buffer.writeln('Total: $totalPlayers players');

    return buffer.toString();
  }

  /// Emails the group assignments to all selected players
  Future<void> _handleEmailGroups() async {
    final backendEmailService = BackendEmailService();
    final currentDate = DateTime.now().toString().split(' ')[0];
    final subject = 'Golden Oaks Wed. Groups - $currentDate';
    final body = _buildGroupsEmailBody();

    // Collect emails from all players in the groups
    final emails = <String>{};
    for (var group in groups) {
      for (var player in group) {
        if (player != null) {
          final email = player['email']?.toString() ?? '';
          if (email.contains('@')) emails.add(email);
        }
      }
    }

    if (emails.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No player emails found.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final success = await backendEmailService.sendCustomEmail(
      to: [EmailConfig.fallbackEmail],
      bcc: emails.toList(),
      subject: subject,
      body: body,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Groups emailed to ${emails.length} players.'
              : 'Failed to send group email. Check connection.'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Builds a simple group listing email body (no member numbers)
  String _buildGroupsEmailBody() {
    final buffer = StringBuffer();
    buffer.writeln('Golden Oaks Wednesday League - Group Assignments');
    buffer.writeln('Date: ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln();

    final validGroups = <List<Map<String, dynamic>>>[];
    for (var group in groups) {
      final validPlayers = group
          .where((p) => p != null && (p['last']?.toString() ?? '').isNotEmpty)
          .cast<Map<String, dynamic>>()
          .toList();
      if (validPlayers.isNotEmpty) validGroups.add(validPlayers);
    }

    for (int i = 0; i < validGroups.length; i++) {
      final playerNames = validGroups[i].map((p) {
        final first = p['first']?.toString() ?? '';
        final last = p['last']?.toString() ?? '';
        return '$first $last'.trim();
      }).join(', ');
      buffer.writeln('Group ${i + 1}: $playerNames');
    }

    return buffer.toString();
  }

  /// Builds the email body for ProShop player list
  String _buildProShopEmailBody() {
    final buffer = StringBuffer();

    // Filter out empty groups and empty players
    final validGroups = <List<Map<String, dynamic>>>[];
    for (var group in groups) {
      final validPlayers = group.where((player) {
        if (player == null) return false;
        final name = player['last']?.toString() ?? '';
        return name.isNotEmpty;
      }).cast<Map<String, dynamic>>().toList();

      if (validPlayers.isNotEmpty) {
        validGroups.add(validPlayers);
      }
    }

    int totalPlayers = 0;
    for (int groupIndex = 0; groupIndex < validGroups.length; groupIndex++) {
      final group = validGroups[groupIndex];
      buffer.writeln('Group ${groupIndex + 1}:');

      for (int playerIndex = 0; playerIndex < group.length; playerIndex++) {
        final player = group[playerIndex];
        final playerNumberRaw = player['player_number']?.toString() ?? '';
        final playerNumber = playerNumberRaw.isEmpty ? 'N/A' : playerNumberRaw.padLeft(4, '0');
        final firstName = player['first']?.toString() ?? '';
        final lastName = player['last']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();

        buffer.writeln('  $playerNumber - $fullName');
        totalPlayers++;
      }

      buffer.writeln(); // Empty line between groups
    }

    buffer.writeln('Total Players: $totalPlayers');
    buffer.writeln();
    buffer.writeln('Generated on: ${DateTime.now()}');

    return buffer.toString();
  }

  /// Gets the color for the Adjust Players button
  Color _getAdjustPlayersButtonColor() {
    if (_hasAnyScoreData() || groupsProcessed) {
      return Colors.grey[400]!;
    }
    return Colors.blue[200]!;
  }

  /// Gets the handler for the Adjust Players button
  VoidCallback? _getAdjustPlayersButtonHandler() {
    if (_hasAnyScoreData() || groupsProcessed) {
      return null;
    }
    return _handleAdjustPlayers;
  }
}
