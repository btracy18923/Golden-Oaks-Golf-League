import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../models/league.dart';
import '../main_menu_screen.dart';
import '../../services/firebase_upload_service.dart';
import '../../services/handicap_calculation_service.dart';

class WednesdayResultsScreen extends StatefulWidget {
  final double groupPurseAmount;
  final double groupPayoutAmount;
  final double adjustedMulliganPurse;
  final List<List<Map<String, dynamic>?>> groups;
  final List<Map<String, dynamic>> individualWinners;
  final double playersAnte;
  final double closestPinAmount;
  final double mulliganAmount;

  const WednesdayResultsScreen({
    super.key,
    required this.groupPurseAmount,
    required this.groupPayoutAmount,
    required this.adjustedMulliganPurse,
    required this.groups,
    required this.individualWinners,
    required this.playersAnte,
    required this.closestPinAmount,
    required this.mulliganAmount,
  });

  @override
  State<WednesdayResultsScreen> createState() => _WednesdayResultsScreenState();
}

class _WednesdayResultsScreenState extends State<WednesdayResultsScreen> {
  final ScreenDataRetentionService _retentionService = ScreenDataRetentionService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setOrientation();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Wednesday League
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    // Keep landscape mode locked when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  bool _isSavingToDatabase = false;

  /// Saves the results data to the wednesday_scores table
  Future<void> _saveResultsToDatabase() async {
    debugPrint('=== SAVE RESULTS TO DATABASE CALLED ===');

    // Prevent double-saving
    if (_isSavingToDatabase) {
      debugPrint('=== ALREADY SAVING - ABORTING DUPLICATE CALL ===');
      return;
    }

    _isSavingToDatabase = true;

    try {
      final selectedGolfCourse = _retentionService.selectedGolfCourse ?? 'Not Selected';
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final playerClosestPinWinnings = _retentionService.playerClosestPinWinnings ?? {};

      // Get player database records for lookups
      final allDbPlayers = await _databaseHelper.getPlayersByLeague(League.wednesday);

      // Collect all selected players from groups
      List<Map<String, dynamic>> allSelectedPlayers = [];
      for (var group in widget.groups) {
        for (var player in group) {
          if (player != null && player['last'] != null && player['last'].toString().isNotEmpty) {
            allSelectedPlayers.add(player);
          }
        }
      }

      debugPrint('=== COLLECTED ${allSelectedPlayers.length} player entries from groups ===');

      // CRITICAL: Check for duplicate dates BEFORE saving anything
      // TEMPORARILY DISABLED FOR TESTING - RE-ENABLE AFTER TESTING
      /*
      bool duplicateFound = false;
      for (var player in allSelectedPlayers) {
        final playerName = player['last'].toString();
        final dbPlayer = allDbPlayers.firstWhere(
          (p) => p['last'] == playerName,
          orElse: () => <String, dynamic>{}
        );

        if (dbPlayer.isNotEmpty) {
          final playerId = dbPlayer['player_number'];
          final existingScoreForDate = await _databaseHelper.getPlayerScoreByDate(playerId, currentDate, League.wednesday);

          if (existingScoreForDate != null) {
            duplicateFound = true;
            break;
          }
        }
      }

      // If duplicate date found, show error and DO NOT SAVE
      if (duplicateFound) {
        debugPrint('=== DUPLICATE DATE FOUND - ABORTING SAVE ===');
        if (!mounted) return;
        final fontSize = ResponsiveTypography.getBodyText(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Duplicate Play Dates - data not saved',
              style: TextStyle(fontSize: fontSize + 4),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
      */

      debugPrint('=== DUPLICATE CHECK DISABLED - PROCEEDING WITH SAVE ===');

      // Build a consolidated map of all player data (one entry per unique player)
      Map<String, Map<String, dynamic>> consolidatedPlayerData = {};

      // First pass: collect all players and their basic data
      debugPrint('=== FIRST PASS: Processing ${allSelectedPlayers.length} player entries ===');
      for (var player in allSelectedPlayers) {
        final playerName = player['last'].toString().trim(); // Add trim() to remove whitespace
        final grossScore = player['gross_score'];

        debugPrint('  Processing: "$playerName" - Gross: $grossScore - Has in map: ${consolidatedPlayerData.containsKey(playerName)}');

        // Initialize player entry if it doesn't exist
        if (!consolidatedPlayerData.containsKey(playerName)) {
          consolidatedPlayerData[playerName] = {
            'name': playerName,
            'gross_score': null,
            'individual_winnings': 0.0,
            'group_winnings': 0.0,
            'close_pin_winnings': 0.0,
            'pos': null,
            'manual_group': null,
          };
          debugPrint('    -> Created new entry for $playerName');
        }

        // Merge data from this instance (non-null values override)
        if (player['gross_score'] != null) {
          consolidatedPlayerData[playerName]!['gross_score'] = player['gross_score'];
          debugPrint('    -> Updated gross score to ${player['gross_score']}');
        }
        if (player['manual_group'] != null) {
          consolidatedPlayerData[playerName]!['manual_group'] = player['manual_group'];
        }
        if (player['pos'] != null && player['pos'].toString().isNotEmpty) {
          consolidatedPlayerData[playerName]!['pos'] = player['pos'].toString();
        }
      }

      debugPrint('=== After first pass: ${consolidatedPlayerData.length} unique players ===');

      // Second pass: add data from individualWinners list (gross scores + winnings)
      debugPrint('=== SECOND PASS: Processing ${widget.individualWinners.length} individual winners ===');
      for (var winner in widget.individualWinners) {
        if (winner['last'] != null) {
          String playerName = winner['last'].toString().trim();

          // Create entry if doesn't exist (some players might only be in individualWinners, not in groups)
          if (!consolidatedPlayerData.containsKey(playerName)) {
            consolidatedPlayerData[playerName] = {
              'name': playerName,
              'gross_score': null,
              'individual_winnings': 0.0,
              'group_winnings': 0.0,
              'close_pin_winnings': 0.0,
              'pos': null,
              'manual_group': null,
            };
            debugPrint('  Created entry for $playerName (from individualWinners)');
          }

          // Add gross score from individualWinners
          if (winner['gross_score'] != null) {
            consolidatedPlayerData[playerName]!['gross_score'] = winner['gross_score'];
            debugPrint('  $playerName: Gross score = ${winner['gross_score']}');
          }

          // Add individual winnings
          if (winner['prize_money'] != null) {
            String prizeMoney = winner['prize_money'].toString();
            if (prizeMoney.contains('\$')) {
              try {
                double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
                consolidatedPlayerData[playerName]!['individual_winnings'] = amount;
                debugPrint('  $playerName: Individual winnings = \$$amount');
              } catch (e) {
                debugPrint('Error parsing individual winnings for $playerName: $e');
              }
            }
          }
        }
      }

      // Third pass: add group winnings from groups
      debugPrint('=== THIRD PASS: Adding group winnings ===');
      for (var group in widget.groups) {
        for (var player in group) {
          if (player != null &&
              player['last'] != null &&
              player['prize_money'] != null &&
              player['manual_group'] != null) {
            String playerName = player['last'].toString().trim();
            String prizeMoney = player['prize_money'].toString();

            if (consolidatedPlayerData.containsKey(playerName) && prizeMoney.contains('\$')) {
              try {
                double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
                if (amount > 0) {
                  consolidatedPlayerData[playerName]!['group_winnings'] = amount;
                  debugPrint('  $playerName: Group winnings = \$$amount');
                }
              } catch (e) {
                debugPrint('Error parsing group winnings for $playerName: $e');
              }
            } else if (!consolidatedPlayerData.containsKey(playerName)) {
              debugPrint('  WARNING: $playerName not found in consolidated data (group)');
            }
          }
        }
      }

      // Fourth pass: add closest pin winnings
      debugPrint('=== FOURTH PASS: Adding closest pin winnings ===');
      for (String playerName in playerClosestPinWinnings.keys) {
        String trimmedName = playerName.trim();
        double closePinWinnings = playerClosestPinWinnings[playerName] ?? 0.0;
        if (consolidatedPlayerData.containsKey(trimmedName)) {
          consolidatedPlayerData[trimmedName]!['close_pin_winnings'] = closePinWinnings;
          debugPrint('  $trimmedName: Close pin = \$$closePinWinnings');
        } else {
          debugPrint('  WARNING: $trimmedName not found in consolidated data (close pin)');
        }
      }

      // Now insert ONE row per player with ALL their data
      debugPrint('=== STARTING SCORE INSERTION FOR ${consolidatedPlayerData.length} UNIQUE PLAYERS ===');

      // Track all deleted scores for Firebase sync
      List<Map<String, dynamic>> allDeletedScores = [];

      for (var playerName in consolidatedPlayerData.keys) {
        final playerData = consolidatedPlayerData[playerName]!;

        final dbPlayer = allDbPlayers.firstWhere(
          (p) => p['last'] == playerName,
          orElse: () => <String, dynamic>{}
        );

        if (dbPlayer.isNotEmpty) {
          // Create complete score record with ALL data
          Map<String, dynamic> scoreData = {
            'player_id': dbPlayer['player_number'],
            'name': playerName,
            'date_played': currentDate,
            'golf_course': selectedGolfCourse,
            'gross_score': playerData['gross_score'],
            'handicap': dbPlayer['HC'] ?? 0.0,
            'pos': playerData['pos'],
            'single_winnings': playerData['individual_winnings'] ?? 0.0,
            'group_winnings': playerData['group_winnings'] ?? 0.0,
            'close_pin_winnings': playerData['close_pin_winnings'] ?? 0.0,
          };

          debugPrint('Inserting CONSOLIDATED score for: $playerName');
          debugPrint('  - Gross: ${playerData['gross_score']}');
          debugPrint('  - Individual: \$${playerData['individual_winnings']}');
          debugPrint('  - Group: \$${playerData['group_winnings']}');
          debugPrint('  - Close Pin: \$${playerData['close_pin_winnings']}');

          Map<String, dynamic> insertResult = await _databaseHelper.insertScoreLeague(scoreData, League.wednesday);
          int recordId = insertResult['insertId'] as int;
          List<Map<String, dynamic>> deletedScores = insertResult['deletedScores'] as List<Map<String, dynamic>>;

          debugPrint('  - Record ID: $recordId');

          // Collect deleted scores for Firebase sync
          if (deletedScores.isNotEmpty) {
            allDeletedScores.addAll(deletedScores);
            debugPrint('  - Deleted ${deletedScores.length} old score(s) for this player');
          }
        } else {
          debugPrint('WARNING: No database player found for $playerName');
        }
      }

      debugPrint('=== SCORE INSERTION COMPLETE - ${consolidatedPlayerData.length} RECORDS CREATED ===');

      // Calculate and update handicaps for selected players only
      debugPrint('=== STARTING HANDICAP CALCULATION ===');
      await _updateSelectedPlayerHandicaps(allSelectedPlayers, allDbPlayers);
      debugPrint('=== HANDICAP CALCULATION COMPLETE ===');

      // Upload NEW scores to Firebase FIRST
      await _uploadScoresToFirebase();

      // Then delete old scores from Firebase if any were removed locally
      if (allDeletedScores.isNotEmpty) {
        debugPrint('=== DELETING ${allDeletedScores.length} OLD SCORES FROM FIREBASE ===');
        await _deleteScoresFromFirebase(allDeletedScores);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Results saved successfully! ${consolidatedPlayerData.length} player records created.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR in _saveResultsToDatabase: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isSavingToDatabase = false;
    }
  }

  /// Calculates and updates handicaps for selected players only
  /// Uses the first 6 latest scores with positive gross data from wednesday_scores table
  /// Algorithm:
  /// - 1 score: Add 5 (OHC + 35) as the 2nd-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 2 scores: Add 4 (OHC + 35) as the 3rd-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 3 scores: Add 3 (OHC + 35) as the 4th-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 4 scores: Add 2 (OHC + 35) as the 5th-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 5 scores: Add 1 (OHC + 35) as the 6th score, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 6+ scores: Drop 2 highest, HC = (Avg of 4 remaining) - 35
  Future<void> _updateSelectedPlayerHandicaps(
    List<Map<String, dynamic>> selectedPlayers,
    List<Map<String, dynamic>> allDbPlayers,
  ) async {
    try {
      final handicapService = HandicapCalculationService();

      // Create a set of unique player names from selected players
      Set<String> selectedPlayerNames = {};
      for (var player in selectedPlayers) {
        if (player['last'] != null && player['last'].toString().isNotEmpty) {
          selectedPlayerNames.add(player['last'].toString().trim());
        }
      }

      debugPrint('Updating handicaps for ${selectedPlayerNames.length} selected Wednesday players');

      int updatedCount = 0;
      for (var playerName in selectedPlayerNames) {
        // Find the player in the database
        final dbPlayer = allDbPlayers.firstWhere(
          (p) => p['last'] == playerName,
          orElse: () => <String, dynamic>{}
        );

        if (dbPlayer.isNotEmpty) {
          final playerId = dbPlayer['player_number'];
          final originalHandicap = (dbPlayer['OHC'] as num?)?.toDouble() ?? 0.0;

          // Get the last 6 gross scores for this player (most recent first)
          final scores = await _databaseHelper.getPlayerRecentScores(
            playerId,
            League.wednesday,
            limit: 6,
          );

          // Extract gross scores only (filter out nulls)
          List<int> grossScores = scores
              .where((score) => score['gross_score'] != null)
              .map((score) => score['gross_score'] as int)
              .toList();

          if (grossScores.isNotEmpty) {
            // Calculate handicap using Wednesday league's OHC padding algorithm
            double newHandicap = handicapService.calculateWednesdayHandicap(
              grossScores: grossScores,
              originalHandicap: originalHandicap,
            );

            debugPrint('Player: $playerName (ID: $playerId) - OHC: ${originalHandicap.toStringAsFixed(1)} - Scores: $grossScores - New HC: ${newHandicap.toStringAsFixed(1)}');

            // Update the player's HC field in the players table
            await _databaseHelper.updatePlayerHandicap(
              playerId,
              newHandicap,
              League.wednesday,
            );
            updatedCount++;
          }
        } else {
          debugPrint('WARNING: No database player found for $playerName during handicap update');
        }
      }
      debugPrint('Successfully updated handicaps for $updatedCount selected players');
    } catch (e) {
      // Log error but don't stop the save process
      debugPrint('Error updating handicaps: $e');
    }
  }

  /// Upload player scores to Firebase after saving to database
  Future<void> _uploadScoresToFirebase() async {
    try {
      final success = await _firebaseUploadService.uploadPlayerScoresTableWithQueue(League.wednesday);
      if (!success) {
        // Log failure but don't show to user
      }
    } catch (e) {
      // Log error but don't show to user
    }
  }

  /// Delete old scores from Firebase when they are removed locally
  Future<void> _deleteScoresFromFirebase(List<Map<String, dynamic>> scoresToDelete) async {
    try {
      final success = await _firebaseUploadService.deletePlayerScoresFromFirebase(scoresToDelete, League.wednesday);
      if (success) {
        debugPrint('Successfully deleted ${scoresToDelete.length} old scores from Firebase');
      } else {
        debugPrint('Failed to delete old scores from Firebase');
      }
    } catch (e) {
      debugPrint('Error deleting scores from Firebase: $e');
      // Log error but don't show to user - deletion failure shouldn't block save operation
    }
  }

  /// Saves results to database and returns to the main menu
  Future<void> _saveResultsAndReturnToMainMenu() async {
    debugPrint('=== _saveResultsAndReturnToMainMenu CALLED - _isSaving=$_isSaving ===');

    if (_isSaving) {
      debugPrint('=== ALREADY SAVING - RETURNING EARLY ===');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    debugPrint('=== CALLING _saveResultsToDatabase ===');

    try {
      await _saveResultsToDatabase();
      _retentionService.clearAllData();

      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
            });
            return const UnifiedMainMenuScreen();
          }),
          (Route<dynamic> route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    final basePadding = isPhone ? 8.0 : 16.0;
    final contentPadding = isPhone ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Wednesday League Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.orange[300],
        foregroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: isPhone ? 48 : 64,
      ),
      body: Padding(
        padding: EdgeInsets.all(basePadding),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: basePadding),
                      _buildDataSection(),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: isPhone ? 4 : 6),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[100]!,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: _isSaving ? 'Saving...' : 'Save Results',
          color: Colors.orange[600]!,
          onPressed: _isSaving ? null : _saveResultsAndReturnToMainMenu,
          flex: 10,
        ),
        Expanded(
          flex: 20,
          child: SizedBox(),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    final isPhone = DeviceDetectionService.isPhone(context);
    final sectionPadding = isPhone ? 12.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sectionPadding),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // League Setup Data
          _buildLeagueSetupData(),

          const SizedBox(height: 16),

          // Closest Pin Data
          if (_retentionService.hasClosestPinData()) ...[
            _buildClosestPinData(),
            const SizedBox(height: 16),
          ],

          // Consolidated Payout Summary Section
          _buildConsolidatedPayoutSummary(),

          const SizedBox(height: 16),

          // Consolidated Payout Details Table
          _buildConsolidatedPayoutTable(),
        ],
      ),
    );
  }

  Widget _buildLeagueSetupData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: Players' Ante, Closest Pin, Mulligans
        _buildParentScreenDataRow(),
        // Second row: Total Players, Collect, Party Fund
        _buildPlayersAndCollectRow(),
        // Third row: Golf Course
        _buildGolfCourseRow(),
      ],
    );
  }

  /// Builds first row with Players' Ante, Closest Pin, and Mulligans
  Widget _buildParentScreenDataRow() {
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;
    final double fontSize = is6InchPhone ? 22 : 24;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.orange[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Text(
              'Players\' Ante: \$${widget.playersAnte.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize - 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Closest Pin: \$${widget.closestPinAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize - 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Mulligans: \$${widget.mulliganAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize - 10,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds second row with Total Players, Collect amount, and Party Fund
  Widget _buildPlayersAndCollectRow() {
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;
    final double fontSize = is6InchPhone ? 22 : 24;

    // Count total players from groups
    int totalPlayers = 0;
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null && player['last'] != null && player['last'].toString().isNotEmpty) {
          totalPlayers++;
        }
      }
    }

    // Calculate collect amount: (Players Ante + Closest Pin + Mulligan) * Total Players
    final collectAmount = (widget.playersAnte + widget.closestPinAmount + widget.mulliganAmount) * totalPlayers;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total Players = $totalPlayers',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize - 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Collect \$${collectAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize - 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Party Fund = \$${widget.adjustedMulliganPurse.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize - 10,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds third row with Golf Course
  Widget _buildGolfCourseRow() {
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;
    final double fontSize = is6InchPhone ? 22 : 24;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Golf Course: ${_retentionService.selectedGolfCourse ?? 'The Hideout'}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: fontSize - 10,
        ),
      ),
    );
  }

  Widget _buildConsolidatedPayoutSummary() {
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;
    final double fontSize = is6InchPhone ? 14 : 24;

    // Get individual payout data from the saved individual winners (only count those with positive prize money)
    int individualWinnersCount = 0;
    double totalIndividualPayout = 0.0;

    for (var player in widget.individualWinners) {
      if (player['prize_money'] != null) {
        String prizeMoney = player['prize_money'].toString();
        if (prizeMoney.contains('\$')) {
          try {
            double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
            if (amount > 0) {
              individualWinnersCount++;
              totalIndividualPayout += amount;
            }
          } catch (e) {
            // Skip if parsing fails
          }
        }
      }
    }

    // Count group winners (players with manual_group and positive prize_money)
    int groupWinnersCount = 0;
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null &&
            player['prize_money'] != null &&
            player['manual_group'] != null) {
          // Check if prize money is positive
          String prizeMoney = player['prize_money'].toString();
          if (prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              if (amount > 0) {
                groupWinnersCount++;
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }
        }
      }
    }

    // Only show if there are winners
    if (individualWinnersCount == 0 && groupWinnersCount == 0) {
      return const SizedBox.shrink();
    }

    return Center(
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (individualWinnersCount > 0)
                Text(
                  'Individual Payout Summary:  Winners: $individualWinnersCount  Total Payout: \$${totalIndividualPayout.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              if (individualWinnersCount > 0 && groupWinnersCount > 0)
                const SizedBox(height: 8),
              if (groupWinnersCount > 0)
                Text(
                  'Group Payout Summary:  Winners: $groupWinnersCount  Total Payout: \$${widget.groupPayoutAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClosestPinData() {
    if (!_retentionService.hasClosestPinData()) {
      return const SizedBox.shrink();
    }

    final playerCounts = _retentionService.playerClosestPinCounts ?? {};

    final winnersCount = playerCounts.values.where((count) => count > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (winnersCount > 0)
          _buildClosestPinWinnersTable(),
      ],
    );
  }

  Widget _buildClosestPinWinnersTable() {
    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;
    final double fontSize = is6InchPhone ? 14 : 24;

    final winners = playerCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
          'name': entry.key,
          'pins': entry.value,
          'winnings': playerWinnings[entry.key] ?? 0.0,
        })
        .toList();

    if (winners.isEmpty) return const SizedBox.shrink();

    winners.sort((a, b) => (b['pins'] as double).compareTo(a['pins'] as double));

    // Create the table widget
    final tableWidget = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.blue[300],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: is6InchPhone ? 2 : 2,
                  child: Text(
                    'Closest Pin Winners',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Won',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '  \$\$\$',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ...winners.map((winner) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: is6InchPhone ? 3 : 2,
                  child: Text(
                    winner['name'] as String,
                    style: TextStyle(fontSize: fontSize),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    (winner['pins'] as double) % 1 == 0
                        ? '${(winner['pins'] as double).toInt()}'
                        : (winner['pins'] as double).toStringAsFixed(2),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.blue[100],
                    child: Text(
                      '\$${(winner['winnings'] as double).round()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );

    // Wrap in IntrinsicWidth and Align to constrain table width (same as Monday)
    return Align(
      alignment: Alignment.center,
      child: IntrinsicWidth(
        child: tableWidget,
      ),
    );
  }

  Widget _buildConsolidatedPayoutTable() {
    // Collect all players with winnings from both individual and group
    Map<String, Map<String, dynamic>> allWinners = {};

    // Add individual winners
    for (var player in widget.individualWinners) {
      if (player['prize_money'] != null && player['last'] != null) {
        String prizeMoney = player['prize_money'].toString();
        if (prizeMoney.contains('\$')) {
          try {
            double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
            if (amount > 0) {
              String playerName = player['last'].toString();
              allWinners[playerName] = {
                'name': playerName,
                'individual_winnings': amount,
                'group_number': null,
                'group_winnings': 0.0,
              };
            }
          } catch (e) {
            // Skip if parsing fails
          }
        }
      }
    }

    // Add group winners
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null &&
            player['prize_money'] != null &&
            player['manual_group'] != null &&
            player['last'] != null) {
          String prizeMoney = player['prize_money'].toString();
          if (prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              if (amount > 0) {
                String playerName = player['last'].toString();
                if (allWinners.containsKey(playerName)) {
                  // Player already has individual winnings, add group info
                  allWinners[playerName]!['group_number'] = player['manual_group'];
                  allWinners[playerName]!['group_winnings'] = amount;
                } else {
                  // New player with only group winnings
                  allWinners[playerName] = {
                    'name': playerName,
                    'individual_winnings': 0.0,
                    'group_number': player['manual_group'],
                    'group_winnings': amount,
                  };
                }
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }
        }
      }
    }

    if (allWinners.isEmpty) return const SizedBox.shrink();

    // Sort by Individual winnings (highest first), then Group winnings (highest first)
    List<Map<String, dynamic>> sortedWinners = allWinners.values.toList();
    sortedWinners.sort((a, b) {
      double aIndividual = a['individual_winnings'] as double;
      double bIndividual = b['individual_winnings'] as double;
      double aGroup = a['group_winnings'] as double;
      double bGroup = b['group_winnings'] as double;

      // Sort by individual winnings descending (highest first)
      int individualComparison = bIndividual.compareTo(aIndividual);
      if (individualComparison != 0) return individualComparison;

      // If both have no individual winnings, sort by group winnings descending
      if (aIndividual == 0 && bIndividual == 0) {
        int groupComparison = bGroup.compareTo(aGroup);
        if (groupComparison != 0) return groupComparison;
      }

      // If everything is the same, sort alphabetically by name
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return Table(
      border: TableBorder.all(color: Colors.grey[400]!, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blue[300]),
          children: [
            _buildTableCell('Player', isHeader: true),
            _buildTableCell('Ind \$\$\$', isHeader: true),
            _buildTableCell('Group \$\$\$', isHeader: true),
            _buildTableCell('Total \$\$\$', isHeader: true),
          ],
        ),
        ...sortedWinners.map((player) {
          double individualWinnings = player['individual_winnings'] as double;
          double groupWinnings = player['group_winnings'] as double;
          double totalWinnings = individualWinnings + groupWinnings;

          return TableRow(
            children: [
              _buildTableCell(player['name'] as String),
              _buildTableCell(
                individualWinnings > 0
                  ? '\$${individualWinnings.toStringAsFixed(2)}'
                  : '',
              ),
              _buildTableCell(
                groupWinnings > 0
                  ? '\$${groupWinnings.toStringAsFixed(2)}'
                  : '',
              ),
              _buildTableCell(
                '\$${totalWinnings.toStringAsFixed(2)}',
                isMoneyColumn: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isMoneyColumn = false}) {
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;
    final double fontSize = is6InchPhone ? 14 : 22;
    final double cellPadding = is6InchPhone ? 2 : 8;

    return Container(
      color: isMoneyColumn ? Colors.blue[100] : null,
      padding: EdgeInsets.all(cellPadding),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isMoneyColumn && text.contains('\$') ? Colors.black :
                 isHeader ? Colors.black87 : Colors.black,
        ),
        textAlign: isHeader || isMoneyColumn ? TextAlign.center : TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: isHeader ? 2 : 1,
      ),
    );
  }
}
