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
import '../../services/backend_email_service.dart';
import '../../services/pending_email_service.dart';
import '../../services/connectivity_service.dart';

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
    // Prevent double-saving
    if (_isSavingToDatabase) {
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

      // Build a consolidated map of all player data (one entry per unique player)
      Map<String, Map<String, dynamic>> consolidatedPlayerData = {};

      // First pass: collect all players and their basic data
      for (var player in allSelectedPlayers) {
        final playerName = player['last'].toString().trim();

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
        }

        // Merge data from this instance (non-null values override)
        if (player['gross_score'] != null) {
          consolidatedPlayerData[playerName]!['gross_score'] = player['gross_score'];
        }
        if (player['manual_group'] != null) {
          consolidatedPlayerData[playerName]!['manual_group'] = player['manual_group'];
        }
        if (player['pos'] != null && player['pos'].toString().isNotEmpty) {
          consolidatedPlayerData[playerName]!['pos'] = player['pos'].toString();
        }
      }

      // Second pass: add data from individualWinners list (gross scores + winnings)
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
          }

          // Add gross score from individualWinners
          if (winner['gross_score'] != null) {
            consolidatedPlayerData[playerName]!['gross_score'] = winner['gross_score'];
          }

          // Add individual winnings
          if (winner['prize_money'] != null) {
            String prizeMoney = winner['prize_money'].toString();
            if (prizeMoney.contains('\$')) {
              try {
                double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
                consolidatedPlayerData[playerName]!['individual_winnings'] = amount;
              } catch (e) {
                debugPrint('Error parsing individual winnings for $playerName: $e');
              }
            }
          }
        }
      }

      // Third pass: add group winnings from groups (include wildcards - they can win in multiple groups)
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
                  // Accumulate group winnings (player can win in primary group AND as wildcard)
                  double currentWinnings = (consolidatedPlayerData[playerName]!['group_winnings'] as double?) ?? 0.0;
                  consolidatedPlayerData[playerName]!['group_winnings'] = currentWinnings + amount;
                }
              } catch (e) {
                debugPrint('Error parsing group winnings for $playerName: $e');
              }
            } else if (!consolidatedPlayerData.containsKey(playerName)) {
              debugPrint('WARNING: $playerName not found in consolidated data (group)');
            }
          }
        }
      }

      // Fourth pass: add closest pin winnings
      for (String playerName in playerClosestPinWinnings.keys) {
        String trimmedName = playerName.trim();
        double closePinWinnings = playerClosestPinWinnings[playerName] ?? 0.0;
        if (consolidatedPlayerData.containsKey(trimmedName)) {
          consolidatedPlayerData[trimmedName]!['close_pin_winnings'] = closePinWinnings;
        } else {
          debugPrint('WARNING: $trimmedName not found in consolidated data (close pin)');
        }
      }

      // Now insert ONE row per player with ALL their data

      // Track all deleted scores for Firebase sync
      List<Map<String, dynamic>> allDeletedScores = [];

      // Track inserted record IDs for HC update (keyed by player name)
      Map<String, int> insertedRecordIds = {};

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

          Map<String, dynamic> insertResult = await _databaseHelper.insertScoreLeague(scoreData, League.wednesday);
          int recordId = insertResult['insertId'] as int;
          List<Map<String, dynamic>> deletedScores = insertResult['deletedScores'] as List<Map<String, dynamic>>;

          // Store the record ID for later HC update
          insertedRecordIds[playerName] = recordId;

          // Collect deleted scores for Firebase sync
          if (deletedScores.isNotEmpty) {
            allDeletedScores.addAll(deletedScores);
          }
        } else {
          debugPrint('WARNING: No database player found for $playerName');
        }
      }

      // Calculate and update handicaps for selected players only
      Map<String, double> newHandicaps = await _updateSelectedPlayerHandicaps(allSelectedPlayers, allDbPlayers);

      // Update the score records with the new HC values (using record ID for precision)
      for (var playerName in newHandicaps.keys) {
        final newHC = newHandicaps[playerName]!;
        final recordId = insertedRecordIds[playerName];
        if (recordId != null) {
          // Update the handicap field using the specific record ID (not date)
          await _databaseHelper.updateWednesdayScoreHandicapById(recordId, newHC);
        } else {
          debugPrint('WARNING: No record ID found for $playerName - skipping HC update');
        }
      }

      // Upload NEW scores to Firebase FIRST
      await _uploadScoresToFirebase();

      // Then delete old scores from Firebase if any were removed locally
      if (allDeletedScores.isNotEmpty) {
        await _deleteScoresFromFirebase(allDeletedScores);
      }

      // Send results email in background — don't block save on network call
      _sendResultsEmail(consolidatedPlayerData, currentDate);

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
  /// Returns a map of player names to their new handicap values
  Future<Map<String, double>> _updateSelectedPlayerHandicaps(
    List<Map<String, dynamic>> selectedPlayers,
    List<Map<String, dynamic>> allDbPlayers,
  ) async {
    Map<String, double> newHandicaps = {};

    try {
      final handicapService = HandicapCalculationService();

      // Create a set of unique player names from selected players
      Set<String> selectedPlayerNames = {};
      for (var player in selectedPlayers) {
        if (player['last'] != null && player['last'].toString().isNotEmpty) {
          selectedPlayerNames.add(player['last'].toString().trim());
        }
      }

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

            // Update the player's HC field in the players table
            await _databaseHelper.updatePlayerHandicap(
              playerId,
              newHandicap,
              League.wednesday,
            );

            // Store the new handicap for updating score records
            newHandicaps[playerName] = newHandicap;
            updatedCount++;
          }
        } else {
          debugPrint('WARNING: No database player found for $playerName during handicap update');
        }
      }
    } catch (e) {
      // Log error but don't stop the save process
      debugPrint('Error updating handicaps: $e');
    }

    return newHandicaps;
  }

  /// Sends the Wednesday results email to admins.
  /// If offline, saves to SharedPreferences for retry when WiFi reconnects.
  Future<void> _sendResultsEmail(
    Map<String, Map<String, dynamic>> consolidatedPlayerData,
    String date,
  ) async {
    try {
      final subject = 'Golden Oaks Wednesday League Results - $date';
      final body = _buildResultsEmailBody(consolidatedPlayerData, date);

      final isOnline = await ConnectivityService().isWiFiConnected();
      if (isOnline) {
        await BackendEmailService().sendWednesdayResultsEmail(subject: subject, body: body);
        debugPrint('Wednesday results email sent successfully');
      } else {
        await PendingEmailService().savePendingWednesdayEmail(subject: subject, body: body);
        debugPrint('Device offline — Wednesday results email queued for retry on WiFi reconnect');
      }
    } catch (e) {
      debugPrint('Error sending Wednesday results email: $e');
    }
  }

  /// Builds the plain-text email body from consolidated player data.
  String _buildResultsEmailBody(
    Map<String, Map<String, dynamic>> consolidatedPlayerData,
    String date,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('GOLDEN OAKS WEDNESDAY LEAGUE RESULTS');
    buffer.writeln('Date: $date');
    buffer.writeln('Golf Course: ${_retentionService.selectedGolfCourse ?? 'The Hideout'}');
    buffer.writeln('');

    // Count non-wildcard players
    int totalPlayers = 0;
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null &&
            player['last'] != null &&
            player['last'].toString().isNotEmpty &&
            player['is_wild_card'] != true) {
          totalPlayers++;
        }
      }
    }

    final collectAmount =
        (widget.playersAnte + widget.closestPinAmount + widget.mulliganAmount) * totalPlayers;

    buffer.writeln('Players Ante: \$${widget.playersAnte.toStringAsFixed(2)}');
    buffer.writeln('Closest Pin: \$${widget.closestPinAmount.toStringAsFixed(2)}');
    buffer.writeln('Mulligan: \$${widget.mulliganAmount.toStringAsFixed(2)}');
    buffer.writeln('Total Players: $totalPlayers');
    buffer.writeln('Collect: \$${collectAmount.toStringAsFixed(2)}');
    buffer.writeln('Party Fund: \$${widget.adjustedMulliganPurse.toStringAsFixed(2)}');
    buffer.writeln('');

    // Closest pin winners
    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};
    final pinWinners = playerCounts.entries.where((e) => e.value > 0).toList();
    if (pinWinners.isNotEmpty) {
      buffer.writeln('CLOSEST PIN WINNERS');
      buffer.writeln('-' * 40);
      for (final entry in pinWinners) {
        final winnings = playerWinnings[entry.key] ?? 0.0;
        buffer.writeln('${entry.key}  Pins: ${entry.value}  \$${winnings.round()}');
      }
      buffer.writeln('');
    }

    // Build consolidated winners (individual + group)
    Map<String, Map<String, dynamic>> allWinners = {};

    for (var player in widget.individualWinners) {
      if (player['prize_money'] != null && player['last'] != null) {
        final raw = player['prize_money'].toString().replaceAll('\$', '').replaceAll(',', '');
        try {
          final amount = double.parse(raw);
          if (amount > 0) {
            final name = player['last'].toString();
            allWinners[name] = {
              'net_score': player['net_score'],
              'individual': amount,
              'group': 0.0,
            };
          }
        } catch (_) {}
      }
    }

    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null && player['prize_money'] != null && player['manual_group'] != null && player['last'] != null) {
          final raw = player['prize_money'].toString().replaceAll('\$', '').replaceAll(',', '');
          try {
            final amount = double.parse(raw);
            if (amount > 0) {
              final name = player['last'].toString();
              if (allWinners.containsKey(name)) {
                allWinners[name]!['group'] = (allWinners[name]!['group'] as double) + amount;
              } else {
                allWinners[name] = {
                  'net_score': player['net_score'],
                  'individual': 0.0,
                  'group': amount,
                };
              }
            }
          } catch (_) {}
        }
      }
    }

    if (allWinners.isNotEmpty) {
      final sorted = allWinners.entries.toList()
        ..sort((a, b) {
          final aNet = (a.value['net_score'] as num?)?.toDouble() ?? 999.0;
          final bNet = (b.value['net_score'] as num?)?.toDouble() ?? 999.0;
          return aNet.compareTo(bNet);
        });

      buffer.writeln('WINNERS');
      buffer.writeln('-' * 52);
      buffer.writeln('${'Player'.padRight(18)}${'Net'.padRight(6)}${'Ind \$\$\$'.padRight(10)}${'Group \$\$\$'.padRight(10)}Total \$\$\$');
      buffer.writeln('-' * 52);

      for (final entry in sorted) {
        final name = entry.key.padRight(18);
        final net = (entry.value['net_score'] != null)
            ? (entry.value['net_score'] as num).toStringAsFixed(1).padRight(6)
            : ''.padRight(6);
        final ind = entry.value['individual'] as double;
        final grp = entry.value['group'] as double;
        final total = ind + grp;
        final indStr = (ind > 0 ? '\$${ind.toStringAsFixed(2)}' : '').padRight(10);
        final grpStr = (grp > 0 ? '\$${grp.toStringAsFixed(2)}' : '').padRight(10);
        buffer.writeln('$name$net$indStr$grpStr\$${total.toStringAsFixed(2)}');
      }
    }

    return buffer.toString();
  }

  /// Upload player scores and player profiles to Firebase after saving to database
  /// This ensures updated HC values are synced to Firebase
  Future<void> _uploadScoresToFirebase() async {
    try {
      // Upload scores
      final scoresSuccess = await _firebaseUploadService.uploadPlayerScoresTableWithQueue(League.wednesday);
      if (!scoresSuccess) {
        debugPrint('Failed to upload scores to Firebase');
      }

      // Upload player profiles to sync updated HC values
      final profilesSuccess = await _firebaseUploadService.uploadPlayerTableWithQueue(League.wednesday);
      if (!profilesSuccess) {
        debugPrint('Failed to upload player profiles to Firebase');
      }
    } catch (e) {
      // Log error but don't show to user
      debugPrint('Error uploading to Firebase: $e');
    }
  }

  /// Delete old scores from Firebase when they are removed locally
  Future<void> _deleteScoresFromFirebase(List<Map<String, dynamic>> scoresToDelete) async {
    try {
      final success = await _firebaseUploadService.deletePlayerScoresFromFirebase(scoresToDelete, League.wednesday);
      if (!success) {
        debugPrint('Failed to delete old scores from Firebase');
      }
    } catch (e) {
      debugPrint('Error deleting scores from Firebase: $e');
      // Log error but don't show to user - deletion failure shouldn't block save operation
    }
  }

  /// Saves results to database and returns to the main menu
  Future<void> _saveResultsAndReturnToMainMenu() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

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
        const Expanded(
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

    // Count total players from groups (excluding wildcards)
    int totalPlayers = 0;
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null && player['last'] != null && player['last'].toString().isNotEmpty && player['is_wild_card'] != true) {
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

    // Count unique group winners (players can appear in multiple groups as wildcards, count each player once)
    Set<String> groupWinnerNames = {};
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null &&
            player['prize_money'] != null &&
            player['manual_group'] != null &&
            player['last'] != null) {
          // Check if prize money is positive
          String prizeMoney = player['prize_money'].toString();
          if (prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              if (amount > 0) {
                groupWinnerNames.add(player['last'].toString());
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }
        }
      }
    }
    int groupWinnersCount = groupWinnerNames.length;

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
              double? netScore = player['net_score'] != null ? (player['net_score'] as num).toDouble() : null;
              allWinners[playerName] = {
                'name': playerName,
                'net_score': netScore,
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

    // Add group winners (include wildcards - they can win in multiple groups)
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
                double? netScore = player['net_score'] != null ? (player['net_score'] as num).toDouble() : null;
                if (allWinners.containsKey(playerName)) {
                  // Player already exists, accumulate group winnings (can win in primary + wildcard group)
                  double currentGroupWinnings = (allWinners[playerName]!['group_winnings'] as double?) ?? 0.0;
                  allWinners[playerName]!['group_winnings'] = currentGroupWinnings + amount;
                  // Update group number only if not already set (primary group takes precedence)
                  if (allWinners[playerName]!['group_number'] == null) {
                    allWinners[playerName]!['group_number'] = player['manual_group'];
                  }
                  // Update net_score if not already set
                  if (allWinners[playerName]!['net_score'] == null && netScore != null) {
                    allWinners[playerName]!['net_score'] = netScore;
                  }
                } else {
                  // New player with only group winnings
                  allWinners[playerName] = {
                    'name': playerName,
                    'net_score': netScore,
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

    // Sort by Net score (lowest first)
    List<Map<String, dynamic>> sortedWinners = allWinners.values.toList();
    sortedWinners.sort((a, b) {
      // Get net scores, use high value for null to push them to the end
      double aNet = (a['net_score'] as double?) ?? 999.0;
      double bNet = (b['net_score'] as double?) ?? 999.0;

      // Sort by net score ascending (lowest first)
      int netComparison = aNet.compareTo(bNet);
      if (netComparison != 0) return netComparison;

      // If net scores are the same, sort alphabetically by name
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return Table(
      border: TableBorder.all(color: Colors.grey[400]!, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blue[300]),
          children: [
            _buildTableCell('Player', isHeader: true),
            _buildTableCell('Net', isHeader: true),
            _buildTableCell('Ind \$\$\$', isHeader: true),
            _buildTableCell('Group \$\$\$', isHeader: true),
            _buildTableCell('Total \$\$\$', isHeader: true),
          ],
        ),
        ...sortedWinners.map((player) {
          double individualWinnings = player['individual_winnings'] as double;
          double groupWinnings = player['group_winnings'] as double;
          double totalWinnings = individualWinnings + groupWinnings;
          double? netScore = player['net_score'] as double?;

          return TableRow(
            children: [
              _buildTableCell(player['name'] as String),
              _buildTableCell(
                netScore != null ? netScore.toStringAsFixed(1) : '',
              ),
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
