import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../main_menu_screen.dart';
import '../../services/firebase_upload_service.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../services/skat_adjustment_service.dart';
import '../../services/backend_email_service.dart';
import '../../services/pending_email_service.dart';
import '../../services/connectivity_service.dart';

class MondayResultsScreen extends StatefulWidget {
  const MondayResultsScreen({super.key});

  @override
  State<MondayResultsScreen> createState() => _MondayResultsScreenState();
}

class _MondayResultsScreenState extends State<MondayResultsScreen> {
  final ScreenDataRetentionService _retentionService = ScreenDataRetentionService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  final SkatAdjustmentService _skatAdjustmentService = SkatAdjustmentService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setOrientation();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Monday League
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

  /// Saves the results data to the monday_scores table using 4-step process
  Future<void> _saveResultsToDatabase() async {
    try {
      final playerGroups = _retentionService.playerGroups ?? [];
      final selectedGolfCourse = _retentionService.selectedGolfCourse ?? 'Not Selected';
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final playerClosestPinWinnings = _retentionService.playerClosestPinWinnings ?? {};
      
      // Get player database records for lookups
      final allDbPlayers = await _databaseHelper.getPlayersByLeague(League.monday);
      
      // STEP A0: Collect all selected players
      List<PlayerData> allSelectedPlayers = [];
      for (int groupIndex = 0; groupIndex < playerGroups.length; groupIndex++) {
        for (var player in playerGroups[groupIndex]) {
          if (player.name.isNotEmpty) { // Only include players with names (not empty slots)
            allSelectedPlayers.add(player);
          }
        }
      }

      // CRITICAL: Check for duplicate dates BEFORE saving anything
      // If ANY player already has a score for today, abort the entire save operation
      // Only check if duplicate dates are NOT allowed
      if (!DatabaseHelper.allowDuplicateDates) {
        bool duplicateFound = false;
        for (var player in allSelectedPlayers) {
          final dbPlayer = allDbPlayers.firstWhere(
            (p) => p['last'] == player.name,
            orElse: () => <String, dynamic>{}
          );

          if (dbPlayer.isNotEmpty) {
            final playerId = dbPlayer['player_number'];
            final existingScoreForDate = await _databaseHelper.getPlayerScoreByDate(playerId, currentDate, League.monday);

            if (existingScoreForDate != null) {
              duplicateFound = true;
              break; // Stop checking as soon as we find one duplicate
            }
          }
        }

        // If duplicate date found, show error and DO NOT SAVE
        if (duplicateFound) {
          if (!mounted) return;
          final screenSize = MediaQuery.of(context).size;
          final is6InchPhone = screenSize.width <= 900;
          final is8InchTablet = screenSize.width > 900 && screenSize.width <= 1200;
          final double fontSize = is6InchPhone ? 14 : (is8InchTablet ? 16 : 34);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Duplicate Play Dates - SKAT data not saved',
                style: TextStyle(fontSize: fontSize + 10),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return; // STOP HERE - Do not save to database or Firebase
        }
      }

      // STEP A1: Create initial rows for all selected players
      Map<String, int> playerToRecordId = {}; // Track record IDs for updates
      List<Map<String, dynamic>> allDeletedScores = []; // Track deleted scores for Firebase sync

      for (var player in allSelectedPlayers) {
        // Find matching player in database
        final dbPlayer = allDbPlayers.firstWhere(
          (p) => p['last'] == player.name,
          orElse: () => <String, dynamic>{}
        );

        if (dbPlayer.isNotEmpty) {
          // Create initial score record with basic data
          Map<String, dynamic> scoreData = {
            'player_id': dbPlayer['player_number'],
            'name': player.name,
            'date_played': currentDate,
            'golf_course': selectedGolfCourse,
            'S_SK': int.tryParse(player.skNumber) ?? dbPlayer['skat_number'],
            'close_pin_winnings': 0.0, // Will be updated in Step A2
            'skat_winnings': 0.0, // Will be updated in Step A3
          };

          // Insert record and get the record ID and any deleted scores
          Map<String, dynamic> insertResult = await _databaseHelper.insertScoreLeague(scoreData, League.monday);
          int recordId = insertResult['insertId'] as int;
          List<Map<String, dynamic>> deletedScores = insertResult['deletedScores'] as List<Map<String, dynamic>>;

          playerToRecordId[player.name] = recordId;

          // Collect deleted scores for Firebase sync
          if (deletedScores.isNotEmpty) {
            allDeletedScores.addAll(deletedScores);
          }
        }
      }
      
      // STEP A2: Update Closest Pin Winnings for winners
      for (String playerName in playerClosestPinWinnings.keys) {
        double closePinWinnings = playerClosestPinWinnings[playerName] ?? 0.0;
        
        if (closePinWinnings > 0.0 && playerToRecordId.containsKey(playerName)) {
          int recordId = playerToRecordId[playerName]!;
          await _databaseHelper.updateScoreField(
            recordId, 
            'close_pin_winnings', 
            closePinWinnings,
            League.monday
          );
        }
      }
      
      // STEP A3: Update SKAT Winnings for players with money earnings
      for (var player in allSelectedPlayers) {
        if (player.money.isNotEmpty && player.money.contains('\$') && playerToRecordId.containsKey(player.name)) {
          try {
            double skatWinnings = double.parse(player.money.replaceAll('\$', '').replaceAll(',', ''));
            if (skatWinnings > 0.0) {
              int recordId = playerToRecordId[player.name]!;
              await _databaseHelper.updateScoreField(
                recordId, 
                'skat_winnings', 
                skatWinnings,
                League.monday);
            }
          } catch (e) {
            // Error parsing SKAT winnings - skip this player
          }
        }
      }
      
      // STEP A4: Save SKATS entered and DIFF for each player
      for (var player in allSelectedPlayers) {
        if (playerToRecordId.containsKey(player.name) && player.skats.isNotEmpty) {
          int recordId = playerToRecordId[player.name]!;
          try {
            await _databaseHelper.updateScoreField(
                recordId, 'SKATS', int.parse(player.skats), League.monday);
          } catch (e) {}
          if (player.diff.isNotEmpty) {
            await _databaseHelper.updateScoreField(
                recordId, 'DIFF', player.diff, League.monday);
          }
        }
      }

      // STEP A5: Apply SKAT # adjustments â€” updates player profile with new SK#
      await _skatAdjustmentService.applySkatAdjustments(playerGroups);

      // STEP A6: Save New_SK for each player (S_SK + adjustment from DIFF)
      for (var player in allSelectedPlayers) {
        if (playerToRecordId.containsKey(player.name) && player.diff.isNotEmpty) {
          try {
            int sSk = int.parse(player.skNumber);
            int diffVal = int.parse(player.diff.replaceAll('+', ''));
            int adjustment = _skatAdjustmentService.calculateSkatAdjustment(diffVal);
            int newSk = sSk + adjustment;
            int recordId = playerToRecordId[player.name]!;
            await _databaseHelper.updateScoreField(
                recordId, 'New_SK', newSk, League.monday);
          } catch (e) {}
        }
      }

      // Upload player profile data to Firebase (includes updated SKAT #)
      await _firebaseUploadService.uploadPlayerTableWithQueue(League.monday);

      // Upload NEW scores to Firebase FIRST
      await _uploadScoresToFirebase();

      // Then delete old scores from Firebase if any were removed locally
      if (allDeletedScores.isNotEmpty) {
        debugPrint('=== DELETING ${allDeletedScores.length} OLD SCORES FROM FIREBASE ===');
        await _deleteScoresFromFirebase(allDeletedScores);
      }

      // Save results summary to Firebase for website display
      _saveResultsSummaryToFirebase(allSelectedPlayers, currentDate);

      // Build full email body (including roster) here while still in the awaited save,
      // then fire the send unawaited so it doesn't block navigation.
      final emailSubject = 'Golden Oaks Monday League Results - $currentDate';
      final emailBody = _buildResultsEmailBody(allSelectedPlayers, currentDate)
          + await _buildSkatRoster();
      _sendResultsEmail(emailSubject, emailBody);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Results saved successfully! ${allSelectedPlayers.length} player records created and updated.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving results: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Upload player scores to Firebase after saving to database
  Future<void> _uploadScoresToFirebase() async {
    try {
      await _firebaseUploadService.uploadPlayerScoresTableWithQueue(League.monday);
    } catch (e) {
      // Error uploading/queuing player scores - will retry on next sync
    }
  }

  /// Saves the results summary to Firebase for website display
  Future<void> _saveResultsSummaryToFirebase(List<PlayerData> allSelectedPlayers, String date) async {
    try {
      final playersAnte = _retentionService.playersAnte ?? 0.0;
      final closestPin = _retentionService.closestPinAmount ?? 0.0;
      final mulligan = _retentionService.mulliganAmount ?? 0.0;
      final totalPlayers = allSelectedPlayers.length;
      final collectAmount = (playersAnte + closestPin + mulligan) * totalPlayers;
      final partyFund = LeaguePurseService.mulliganPurse;

      final playerCounts = _retentionService.playerClosestPinCounts ?? {};
      final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};
      final closestPinWinners = playerCounts.entries
          .where((e) => e.value > 0)
          .map((e) => {
                'name': e.key,
                'pins': e.value,
                'amount': (playerWinnings[e.key] ?? 0.0).round(),
              })
          .toList();

      final playerGroups = _retentionService.playerGroups ?? [];
      double totalDiff = 0.0;
      final List<PlayerData> skatWinners = [];
      for (var group in playerGroups) {
        for (var player in group) {
          try {
            final diffValue = double.parse(player.diff.replaceAll('+', ''));
            if (diffValue > 0) {
              skatWinners.add(player);
              totalDiff += diffValue;
            }
          } catch (_) {}
        }
      }
      final skatPurse = totalPlayers * playersAnte;
      final skatValue = totalDiff > 0 ? skatPurse / totalDiff : 0.0;

      final skatWinnersData = skatWinners.map((p) => {
            'name': p.name,
            'skat_number': p.skNumber,
            'skats': p.skats,
            'diff': p.diff,
            'amount': p.money,
          }).toList();

      await FirebaseFirestore.instance.collection('M_results').doc(date).set({
        'date': date,
        'golf_course': _retentionService.selectedGolfCourse ?? '',
        'players_ante': playersAnte,
        'closest_pin': closestPin,
        'mulligan': mulligan,
        'total_players': totalPlayers,
        'collect': collectAmount,
        'party_fund': partyFund,
        'skat_value': skatValue,
        'closest_pin_winners': closestPinWinners,
        'skat_winners': skatWinnersData,
        'saved_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save Monday results summary: $e');
    }
  }

  /// Sends the Monday results email to admins.
  /// Subject and body (including roster) are pre-built by the caller.
  /// If offline, saves the email to SharedPreferences for retry when WiFi reconnects.
  Future<void> _sendResultsEmail(String subject, String body) async {
    try {
      final isOnline = await ConnectivityService().isWiFiConnected();
      if (isOnline) {
        await BackendEmailService().sendMondayResultsEmail(subject: subject, body: body);
        debugPrint('Monday results email sent successfully');
      } else {
        await PendingEmailService().savePendingMondayEmail(subject: subject, body: body);
        debugPrint('Device offline — Monday results email queued for retry on WiFi reconnect');
      }
    } catch (e) {
      debugPrint('Error sending Monday results email: $e');
    }
  }

  /// Returns a plain-text SKAT roster for all Monday players, sorted by last name.
  Future<String> _buildSkatRoster() async {
    try {
      final rawPlayers = await DatabaseHelper().getPlayersByLeague(League.monday);
      final allPlayers = List<Map<String, dynamic>>.from(rawPlayers);
      allPlayers.sort((a, b) =>
          (a['last'] ?? '').toString().compareTo((b['last'] ?? '').toString()));
      final buffer = StringBuffer();
      buffer.writeln('');
      buffer.writeln('SKAT ROSTER');
      buffer.writeln('-' * 30);
      for (final player in allPlayers) {
        final last = player['last']?.toString() ?? '';
        final skatRaw = player['skat_number'];
        final skatStr = skatRaw?.toString() ?? '';
        if (last.isNotEmpty) {
          buffer.writeln('$last - $skatStr');
        }
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('Failed to build skat roster: $e');
      return '\n\nSKAT ROSTER\n[Error loading roster: $e]\n';
    }
  }

  /// Builds the plain-text email body matching the results screen layout
  String _buildResultsEmailBody(List<PlayerData> allSelectedPlayers, String date) {
    final buffer = StringBuffer();

    buffer.writeln('GOLDEN OAKS MONDAY LEAGUE RESULTS');
    buffer.writeln('Date: $date');
    buffer.writeln('Golf Course: ${_retentionService.selectedGolfCourse ?? 'Not Selected'}');
    buffer.writeln('');

    // Financial summary
    final playersAnte = _retentionService.playersAnte ?? 0.0;
    final closestPin = _retentionService.closestPinAmount ?? 0.0;
    final mulligan = _retentionService.mulliganAmount ?? 0.0;
    final totalPlayers = allSelectedPlayers.length;
    final collectAmount = (playersAnte + closestPin + mulligan) * totalPlayers;
    final partyFund = LeaguePurseService.mulliganPurse;

    buffer.writeln('Players Ante: \$${playersAnte.toStringAsFixed(2)}');
    buffer.writeln('Closest Pin: \$${closestPin.toStringAsFixed(2)}');
    buffer.writeln('Mulligan: \$${mulligan.toStringAsFixed(2)}');
    buffer.writeln('Total Players: $totalPlayers');
    buffer.writeln('Collect: \$${collectAmount.toStringAsFixed(2)}');
    buffer.writeln('Party Fund: \$${partyFund.toStringAsFixed(2)}');
    buffer.writeln('');

    // Closest pin winners
    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};
    final winners = playerCounts.entries.where((e) => e.value > 0).toList();
    if (winners.isNotEmpty) {
      buffer.writeln('CLOSEST PIN WINNERS');
      buffer.writeln('-' * 40);
      for (final entry in winners) {
        final winnings = playerWinnings[entry.key] ?? 0.0;
        buffer.writeln('${entry.key}  Pins: ${entry.value}  \$${winnings.round()}');
      }
      buffer.writeln('');
    }

    // SKAT winners (players with positive DIFF)
    final playerGroups = _retentionService.playerGroups ?? [];
    List<PlayerData> skatWinners = [];
    double totalDiff = 0.0;
    int actualPlayerCount = 0;
    for (var group in playerGroups) {
      actualPlayerCount += group.length;
    }
    for (var group in playerGroups) {
      for (var player in group) {
        if (player.diff.isNotEmpty && player.diff != '-') {
          try {
            final diffValue = double.parse(player.diff.replaceAll('+', ''));
            if (diffValue > 0) {
              skatWinners.add(player);
              totalDiff += diffValue;
            }
          } catch (_) {}
        }
      }
    }

    if (skatWinners.isNotEmpty) {
      final skatPurse = actualPlayerCount * playersAnte;
      final skatValue = totalDiff > 0 ? skatPurse / totalDiff : 0.0;

      buffer.writeln('SKAT WINNERS');
      buffer.writeln('Skat Value: \$${skatValue.toStringAsFixed(2)}');
      buffer.writeln('-' * 50);
      buffer.writeln('Player            SK#    Skats   Diff   \$\$\$');
      buffer.writeln('-' * 50);

      skatWinners.sort((a, b) {
        double mA = 0, mB = 0;
        try { mA = double.parse(a.money.replaceAll('\$', '').replaceAll(',', '')); } catch (_) {}
        try { mB = double.parse(b.money.replaceAll('\$', '').replaceAll(',', '')); } catch (_) {}
        return mB.compareTo(mA);
      });

      for (final player in skatWinners) {
        final name = player.name.padRight(18);
        final skNum = player.skNumber.padRight(7);
        final skats = (player.skats.isEmpty ? '-' : player.skats).padRight(8);
        final diff = (player.diff.isEmpty ? '-' : player.diff).padRight(7);
        final money = player.money.isEmpty ? '-' : player.money;
        buffer.writeln('$name$skNum$skats$diff$money');
      }
    }

    return buffer.toString();
  }

  /// Delete old scores from Firebase when they are removed locally
  Future<void> _deleteScoresFromFirebase(List<Map<String, dynamic>> scoresToDelete) async {
    try {
      final success = await _firebaseUploadService.deletePlayerScoresFromFirebase(scoresToDelete, League.monday);
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
    // Prevent multiple simultaneous saves
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // First save the results
      await _saveResultsToDatabase();

      // Clear all retained data for a fresh session
      _retentionService.clearAllData();

      // Immediately lock to landscape mode
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Navigate back to main menu, removing all previous screens from stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) {
            // Ensure orientation is locked again after navigation
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
      // Reset saving state (though we're navigating away, this is good practice)
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet10: _buildTablet10Layout(),
    );
  }

  Widget _buildPhoneLayout() {
    const double basePadding = 8.0;
    const double contentPadding = 12.0;
    const double iconSize = 18;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: FirebaseUploadService.anyAdminOverrideActive ? Colors.red[700] : Colors.blue[300],
        foregroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
      ),
      body: Padding(
        padding: const EdgeInsets.all(basePadding),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: basePadding),
                      _buildDataSection(
                        '',
                        _buildUnifiedData(),
                        Icons.summarize,
                        iconSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet10Layout() {
    const double basePadding = 16.0;
    const double contentPadding = 20.0;
    const double iconSize = 22;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: FirebaseUploadService.anyAdminOverrideActive ? Colors.red[700] : Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
      ),
      body: Padding(
        padding: const EdgeInsets.all(basePadding),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: basePadding),
                      _buildDataSection(
                        '',
                        _buildUnifiedData(),
                        Icons.summarize,
                        iconSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final screenWidth = MediaQuery.of(context).size.width;

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[100]!,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: screenWidth / 3,
          child: ButtonBarUIService.buildActionButton(
            context,
            text: _isSaving ? 'Saving...' : 'Save Results',
            color: Colors.blue[300]!,
            onPressed: _isSaving ? null : _saveResultsAndReturnToMainMenu,
          ),
        ),
        ButtonBarUIService.buildSpacer(),
        ButtonBarUIService.buildSpacer(),
      ],
    );
  }

  /// Builds a data section with title, icon, and content
  Widget _buildDataSection(String title, Widget content, IconData icon, double iconSize) {
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;

    final double sectionPadding = is6InchPhone ? 12 : 20;
    final double titleSize = is6InchPhone ? 16 : 20;
    final double spacingHeight = is6InchPhone ? 8 : 16;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sectionPadding),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Row(
              children: [
                Icon(icon, color: Colors.green[700], size: iconSize),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingHeight),
          ],
          content,
        ],
      ),
    );
  }

  /// Builds unified data display combining all sections
  Widget _buildUnifiedData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // League Setup Data
        if (_retentionService.hasParentScreenData())
          _buildParentScreenData(),

        // Closest Pin Data
        if (_retentionService.hasClosestPinData()) ...[
          _buildClosestPinData(),
          const SizedBox(height: 16),
        ],
        
        // Player Details Table
        if (_retentionService.hasEnterScoresData()) ...[
          _buildPlayerDetailsTableContent(),
        ],
        
        // Show message if no data available
        if (!_retentionService.hasParentScreenData() &&
            !_retentionService.hasPlayerSelectionData() &&
            !_retentionService.hasEnterScoresData() &&
            !_retentionService.hasClosestPinData())
          const Text(
            'No session data available',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  /// Builds the parent screen data display
  Widget _buildParentScreenData() {
    if (!_retentionService.hasParentScreenData()) {
      return const Text(
        'No league setup data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single row layout for money amounts
        LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.of(context).size;
            final is6InchPhone = screenSize.width <= 900;
            
            final double fontSize = is6InchPhone ? 22 : 24;
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Players Ante: \$${_retentionService.playersAnte?.toStringAsFixed(2) ?? 'N/A'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: fontSize -10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Closest Pin: \$${_retentionService.closestPinAmount?.toStringAsFixed(2) ?? 'N/A'}',
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
                      'Mulligan: \$${_retentionService.mulliganAmount?.toStringAsFixed(2) ?? 'N/A'}',
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
          },
        ),
        // Total Players and Collect row
        _buildPlayersAndCollectRow(),
        // Golf Course row (separate line)
        _buildGolfCourseRow(),
      ],
    );
  }

  /// Builds Total Players, Collect amount, and Mulligan/Party funds on one row
  Widget _buildPlayersAndCollectRow() {
    // Count actual players from groups (accounts for any deleted players)
    final playerGroups = _retentionService.playerGroups ?? [];
    int selectedCount = 0;
    for (var group in playerGroups) {
      selectedCount += group.length;
    }

    // Calculate collect amount: (Players Ante + Closest Pin + Mulligan) * Total Players
    final playersAnte = _retentionService.playersAnte ?? 0.0;
    final closestPin = _retentionService.closestPinAmount ?? 0.0;
    final originalMulligan = _retentionService.mulliganAmount ?? 0.0;
    final collectAmount = (playersAnte + closestPin + originalMulligan) * selectedCount;
    
    // Get the adjusted Mulligan Purse amount after SKAT calculations
    final adjustedMulliganPurse = LeaguePurseService.mulliganPurse;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.of(context).size;
          final is6InchPhone = screenSize.width <= 900;
          final double fontSize = is6InchPhone ? 22 : 24;
          
          return Row(
            children: [
              Expanded(
                child: Text(
                  'Total Players = $selectedCount',
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
                  "Party Fund = \$${adjustedMulliganPurse.toStringAsFixed(2)}",
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
          );
        },
      ),
    );
  }

  /// Builds Golf Course on its own row
  Widget _buildGolfCourseRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.of(context).size;
          final is6InchPhone = screenSize.width <= 900;
          final double fontSize = is6InchPhone ? 22 : 24;

          return Text(
            'Golf Course: ${_retentionService.selectedGolfCourse ?? 'Not Selected'}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: fontSize - 10,
            ),
          );
        },
      ),
    );
  }

  /// Builds the closest pin data display
  Widget _buildClosestPinData() {
    if (!_retentionService.hasClosestPinData()) {
      return const Text(
        'No closest pin data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
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

  /// Builds player details table content without the outer container
  Widget _buildPlayerDetailsTableContent() {
    final playerGroups = _retentionService.playerGroups ?? [];
    if (playerGroups.isEmpty) return const SizedBox.shrink();

    // Flatten all players from all groups and filter for positive DIFF
    List<PlayerData> allPlayers = [];
    for (int groupIndex = 0; groupIndex < playerGroups.length; groupIndex++) {
      for (var player in playerGroups[groupIndex]) {
        // Only include players with positive DIFF
        if (player.diff.isNotEmpty && player.diff != '-') {
          try {
            final diffValue = double.parse(player.diff.replaceAll('+', ''));
            if (diffValue > 0) {
              allPlayers.add(player);
            }
          } catch (e) {
            // If parsing fails, skip this player
          }
        }
      }
    }

    if (allPlayers.isEmpty) return const SizedBox.shrink();

    // Sort players by money amount (highest first)
    allPlayers.sort((a, b) {
      // Parse money values, defaulting to 0 if parsing fails
      double moneyA = 0.0;
      double moneyB = 0.0;

      if (a.money.isNotEmpty && a.money.contains('\$')) {
        try {
          moneyA = double.parse(a.money.replaceAll('\$', '').replaceAll(',', ''));
        } catch (e) {
          moneyA = 0.0;
        }
      }

      if (b.money.isNotEmpty && b.money.contains('\$')) {
        try {
          moneyB = double.parse(b.money.replaceAll('\$', '').replaceAll(',', ''));
        } catch (e) {
          moneyB = 0.0;
        }
      }

      // Sort descending (highest first)
      return moneyB.compareTo(moneyA);
    });

    final playersWithMoney = allPlayers.length;

    // Calculate Skat Value: Skat Purse / sum of all positive DIFF values
    double skatValue = 0.0;
    double totalDiff = 0.0;

    // Sum all positive DIFF values
    for (var player in allPlayers) {
      if (player.diff.isNotEmpty && player.diff != '-') {
        try {
          final diffValue = double.parse(player.diff.replaceAll('+', ''));
          if (diffValue > 0) {
            totalDiff += diffValue;
          }
        } catch (e) {
          // Skip if parsing fails
        }
      }
    }

    // Calculate Skat Purse: total players Ã— players ante
    final playerGroupsForSkat = _retentionService.playerGroups ?? [];
    int actualPlayerCount = 0;
    for (var group in playerGroupsForSkat) {
      actualPlayerCount += group.length;
    }
    final playersAnte = _retentionService.playersAnte ?? 0.0;
    final skatPurse = actualPlayerCount * playersAnte;

    // Calculate Skat Value
    if (totalDiff > 0) {
      skatValue = skatPurse / totalDiff;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.of(context).size;
            final is6InchPhone = screenSize.width <= 900;
            final double fontSize = is6InchPhone ? 14 : 24;

            // Always use single row layout with Skat Value on the left
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Skat Value: \$${skatValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '         SKAT Winners: $playersWithMoney',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),

                  ),
                ),
                Expanded(
                  child: Text(
                    'Rounded....',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),

        // Table with responsive column widths
        LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.of(context).size;
            final is6InchPhone = screenSize.width <= 900;

            // Adjust column widths for smaller screens
            final Map<int, TableColumnWidth> columnWidths = is6InchPhone
              ? {
                  0: const FlexColumnWidth(3), // Name - wider on small screens
                  1: const FlexColumnWidth(1), // SK#
                  2: const FlexColumnWidth(1), // Skats
                  3: const FlexColumnWidth(1), // Diff
                  4: const FlexColumnWidth(1.5), // Money - slightly wider
                }
              : {
                  0: const FlexColumnWidth(2), // Name
                  1: const FlexColumnWidth(1), // SK#
                  2: const FlexColumnWidth(1), // Skats
                  3: const FlexColumnWidth(1), // Diff
                  4: const FlexColumnWidth(1), // Money
                };

            return Table(
              border: TableBorder.all(color: Colors.grey[400]!, width: 1),
              columnWidths: columnWidths,
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(color: Colors.green[300]),
                  children: [
                    _buildTableCell('Player', isHeader: true, isCompact: false),
                    _buildTableCell('SK#', isHeader: true, isCompact: false),
                    _buildTableCell('Skats', isHeader: true, isCompact: false),
                    _buildTableCell('Diff', isHeader: true, isCompact: false),
                    _buildTableCell('\$\$\$', isHeader: true, isCompact: false),
                  ],
                ),

                // Player data rows
                ...allPlayers.map((player) => TableRow(
                  children: [
                    _buildTableCell(player.name, isCompact: false),
                    _buildTableCell(player.skNumber, isCompact: false),
                    _buildTableCell(player.skats.isEmpty ? '-' : player.skats, isCompact: false),
                    _buildTableCell(player.diff.isEmpty ? '-' : player.diff, isCompact: false),
                    _buildTableCell(
                      player.money.isEmpty ? '-' : player.money,
                      isCompact: false,
                      isMoneyColumn: true,
                    ),
                  ],
                )),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Builds a table cell with proper styling
  Widget _buildTableCell(String text, {bool isHeader = false, bool isCompact = false, bool isMoneyColumn = false}) {
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;

    // Responsive font sizes for table cells
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

  /// Builds a table showing closest pin winners and their winnings
  Widget _buildClosestPinWinnersTable() {
    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};

    // Get only players who won closest pins
    final winners = playerCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
          'name': entry.key,
          'pins': entry.value,
          'winnings': playerWinnings[entry.key] ?? 0.0,
        })
        .toList();

    if (winners.isEmpty) return const SizedBox.shrink();

    // Sort by number of pins won (descending)
    winners.sort((a, b) => (b['pins'] as double).compareTo(a['pins'] as double));

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        final is6InchPhone = screenSize.width <= 900;

        // For 6.5" phones, constrain the table to minimum width
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
                  color: Colors.green[300],
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
                          fontSize: is6InchPhone ? 14 : 24,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Won',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: is6InchPhone ? 14 : 24,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '\$\$\$',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: is6InchPhone ? 14 : 24,
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
                        style: TextStyle(fontSize: is6InchPhone ? 14 : 24),
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
                        style: TextStyle(fontSize: is6InchPhone ? 14 : 24),
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
                            fontSize: is6InchPhone ? 14 : 24,
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

        // Wrap in intrinsic width to minimize table width for all device sizes
        return Align(
          alignment: Alignment.center,
          child: IntrinsicWidth(
            child: tableWidget,
          ),
        );
      },
    );
  }

}