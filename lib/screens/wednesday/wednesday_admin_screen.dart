import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/firebase_download_service.dart';
import '../../services/firebase_upload_service.dart';
import '../../services/handicap_calculation_service.dart';
import '../../services/error_log_service.dart';

class WednesdayAdminScreen extends StatefulWidget {
  final League? currentLeague;

  const WednesdayAdminScreen({super.key, this.currentLeague});

  @override
  State<WednesdayAdminScreen> createState() => _WednesdayAdminScreenState();
}

class _WednesdayAdminScreenState extends State<WednesdayAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  bool _isDownloading = false;
  bool _isRecalculatingHandicaps = false;

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
  }

  void _initializeFirestore() {
    try {
      // Configure Firestore settings to potentially avoid some Google Play Services issues
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Firestore settings configuration failed - continue with defaults
      debugPrint('Firestore settings configuration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wednesday Administration'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 7.5,
                  children: [
                    _buildDownloadButton(
                      'Download Wed Player Scores',
                      Icons.download,
                      Colors.orange[300]!,
                      () => _downloadWednesdayPlayerScores(),
                    ),

                    _buildDownloadButton(
                      _isDownloading ? 'Downloading...' : 'Download Wed Player Profiles',
                      _isDownloading ? Icons.hourglass_bottom : Icons.people,
                      _isDownloading ? Colors.grey[400]! : Colors.blue[300]!,
                      _isDownloading ? () {} : () => _downloadWednesdayPlayerProfiles(),
                    ),

                    _buildDownloadButton(
                      _isRecalculatingHandicaps ? 'Recalculating...' : 'Recalculate All Handicaps',
                      _isRecalculatingHandicaps ? Icons.hourglass_bottom : Icons.calculate,
                      _isRecalculatingHandicaps ? Colors.grey[400]! : Colors.purple[200]!,
                      _isRecalculatingHandicaps ? () {} : () => _recalculateAllHandicaps(),
                    ),

                    _buildDownloadButton(
                      'View Error Log',
                      Icons.bug_report,
                      Colors.red[200]!,
                      () => _showErrorLog(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadWednesdayPlayerProfiles() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading Wednesday Player Profiles from Firebase...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Download from Wednesday player profile collection only
      // No need to test connection separately - the actual query will fail if there's a connection issue
      QuerySnapshot wednesdaySnapshot = await _firestore.collection('W_player_profile').get();

      int wednesdayCount = 0;
      int errorCount = 0;

      // Process Wednesday players
      for (var doc in wednesdaySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');

          // Set league based on collection
          data['league'] = 'wednesday';

          await _insertOrUpdatePlayer(data);
          wednesdayCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download Complete!\n'
              'Wednesday: $wednesdayCount players\n'
              '${errorCount > 0 ? 'Errors: $errorCount\n' : ''}'
              'Total: $wednesdayCount players downloaded'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  /// Helper method to insert or update a player
  Future<void> _insertOrUpdatePlayer(Map<String, dynamic> playerData) async {
    try {
      // Clean the data to only include fields that exist in the local database schema
      // Local players table has: player_number, first, last, skat_number, HC, cell, email, league
      Map<String, dynamic> cleanData = {
        'player_number': playerData['player_number'],
        'first': playerData['first'],
        'last': playerData['last'],
        'skat_number': playerData['skat_number'],
        'HC': playerData['HC'],
        'cell': playerData['cell'],
        'email': playerData['email'],
        'league': playerData['league'],
      };

      // Remove null values
      cleanData.removeWhere((key, value) => value == null);

      int? playerNumber = cleanData['player_number'];
      String? incomingLeague = cleanData['league'];

      if (playerNumber != null && incomingLeague != null) {
        // Check if player exists by player_number
        final db = await _dbHelper.database;
        List<Map<String, dynamic>> existingPlayers = await db.query(
          'players',
          where: 'player_number = ?',
          whereArgs: [playerNumber],
          limit: 1,
        );

        if (existingPlayers.isNotEmpty) {
          String existingLeague = existingPlayers.first['league'] as String;

          // If player is in a different league, mark them as being in BOTH leagues
          if (existingLeague != incomingLeague) {
            cleanData['league'] = 'both';
          }

          // Update existing player (preserving multi-league status)
          await _dbHelper.updatePlayer(playerNumber, cleanData);
        } else {
          // Insert new player
          await _dbHelper.insertPlayer(cleanData);
        }
      } else {
        // No player_number or league, try to insert anyway
        await _dbHelper.insertPlayer(cleanData);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Recalculates every Wednesday player's handicap from their score history
  /// using the current algorithm, overwriting their stored HC locally and in
  /// Firebase. Also refreshes the new_hc/pad_count on each player's most
  /// recent score record so the website's history stays in sync.
  Future<void> _recalculateAllHandicaps() async {
    if (_isRecalculatingHandicaps) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recalculate All Handicaps?'),
        content: const Text(
          'This recalculates every Wednesday player\'s handicap from their score '
          'history and overwrites their current HC, both locally and in Firebase. '
          'This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recalculate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRecalculatingHandicaps = true;
    });

    try {
      // Refresh local scores/profiles from Firebase first. This recalculates
      // every player's handicap from THIS device's local score history and
      // then pushes the full roster back to Firebase (a genuinely bulk
      // action, unlike a single-player edit) — if this device's local score
      // history were stale (missing a round entered on another device), it
      // would compute a wrong handicap and overwrite the correct one already
      // in Firebase. Pulling fresh first makes the calculation trustworthy.
      try {
        await FirebaseDownloadService().downloadWednesdayLeagueData();
      } catch (e) {
        debugPrint('Pre-recalculate Firebase refresh failed, continuing with local data: $e');
      }

      final players = await _dbHelper.getPlayersByLeague(League.wednesday);
      final handicapService = HandicapCalculationService();
      int updatedCount = 0;
      int skippedCount = 0;
      int failedCount = 0;

      // Each player is isolated in its own try/catch so one bad/malformed
      // record can't silently abort the recalculation for every other
      // player (previously a single exception anywhere in this loop
      // aborted the whole batch with no indication of which player caused it).
      for (final player in players) {
        final playerId = player['player_number'];
        final playerName = player['last']?.toString() ?? 'Unknown';
        if (playerId == null) {
          skippedCount++;
          continue;
        }

        try {
          final scores = await _dbHelper.getPlayerRecentScores(
            playerId,
            League.wednesday,
            limit: 6,
          );

          final grossScores = scores
              .where((score) => score['gross_score'] != null)
              .map((score) => (score['gross_score'] as num).toInt())
              .toList();

          if (grossScores.isEmpty) {
            skippedCount++;
            continue;
          }

          final padCount = 6 - grossScores.length.clamp(0, 6);
          final newHandicap = handicapService.calculateWednesdayHandicap(
            grossScores: grossScores,
          );

          await _dbHelper.updatePlayerHandicap(playerId, newHandicap, League.wednesday);

          // Keep the most recent score record's new_hc/pad_count in sync too
          final mostRecentScoreId = scores.first['id'] as int?;
          if (mostRecentScoreId != null) {
            await _dbHelper.updateScoreField(mostRecentScoreId, 'new_hc', newHandicap, League.wednesday);
            await _dbHelper.updateScoreField(mostRecentScoreId, 'pad_count', padCount, League.wednesday);
          }

          updatedCount++;
        } catch (e) {
          failedCount++;
          debugPrint('Error recalculating handicap for $playerName: $e');
          await ErrorLogService().logError('Wednesday Recalculate Handicap ($playerName)', e);
        }
      }

      // Push the updated players and scores to Firebase
      final playersUploadOk = await _firebaseUploadService.uploadPlayerTableWithQueue(League.wednesday);
      final scoresUploadOk = await _firebaseUploadService.uploadPlayerScoresTableWithQueue(League.wednesday);

      if (mounted) {
        final uploadNote = (!playersUploadOk || !scoresUploadOk)
            ? ' Firebase upload queued for retry (no WiFi).'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recalculated $updatedCount handicap${updatedCount == 1 ? '' : 's'}'
              '${skippedCount > 0 ? ' ($skippedCount skipped - no scores)' : ''}'
              '${failedCount > 0 ? ' ($failedCount failed - see Error Log)' : ''}.'
              '$uploadNote',
            ),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recalculate failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecalculatingHandicaps = false;
        });
      }
    }
  }

  /// Shows the persistent local error log (populated by the Results save
  /// flow whenever a save, upload, or email step fails silently) so failures
  /// can be reviewed later without a tethered debug session.
  Future<void> _showErrorLog() async {
    final entries = await ErrorLogService().getErrors();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Error Log'),
          content: SizedBox(
            width: double.maxFinite,
            child: entries.isEmpty
                ? const Text('No errors recorded.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry['timestamp'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${entry['context'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${entry['error'] ?? ''}'),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            if (entries.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await ErrorLogService().clearErrors();
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: const Text('Clear Log'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadWednesdayPlayerScores() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading Wednesday Player Scores from Firebase...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Download from W_player_scores collection only
      // No need to test connection separately - the actual query will fail if there's a connection issue
      QuerySnapshot wednesdaySnapshot = await _firestore.collection('W_player_scores').get();

      // Use only Wednesday docs
      List<QueryDocumentSnapshot> allDocs = wednesdaySnapshot.docs;

      int wednesdayCount = 0;
      int errorCount = 0;


      for (var doc in allDocs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');

          // All documents from W_player_scores go to Wednesday database
          await _insertOrUpdatePlayerScore(data, 'wednesday');
          wednesdayCount++;

        } catch (e) {
          errorCount++;
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download Complete!\n'
              'Wednesday Scores: $wednesdayCount downloaded\n'
              '${errorCount > 0 ? 'Errors: $errorCount\n' : ''}'
              'Total: $wednesdayCount scores downloaded from W_player_scores'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  /// Helper method to insert or update a player score
  Future<void> _insertOrUpdatePlayerScore(Map<String, dynamic> scoreData, String league) async {
    try {

      // Convert Firebase field names back to local database field names
      // Note: Don't include 'league' field as it's not in the local database schema
      Map<String, dynamic> localScoreData = <String, dynamic>{
        'player_id': scoreData['player_id'],
        'name': scoreData['name'],
        'date_played': scoreData['date_played'],
        'golf_course': scoreData['golf_course'],
      };


      // Handle Monday league specific fields
      if (league.toLowerCase() == 'monday') {
        // Convert Firebase currency strings back to numbers
        localScoreData['skat_number'] = scoreData['SKAT #'];
        localScoreData['close_pin_winnings'] = _parseCurrency(scoreData['Close Pin Winnings']);
        localScoreData['skat_winnings'] = _parseCurrency(scoreData['SKAT Winnings']);

      } else {
        // Wednesday league - handle differently if needed
        localScoreData['close_pin_winnings'] = _parseCurrency(scoreData['Close Pin Winnings']);
        if (scoreData.containsKey('single_winnings')) {
          localScoreData['single_winnings'] = scoreData['single_winnings'];
        }
        if (scoreData.containsKey('group_winnings')) {
          localScoreData['group_winnings'] = scoreData['group_winnings'];
        }
        if (scoreData.containsKey('handicap')) {
          localScoreData['handicap'] = scoreData['handicap'];
        }
        if (scoreData.containsKey('gross_score')) {
          localScoreData['gross_score'] = scoreData['gross_score'];
        }
      }


      // Use the passed league parameter
      League leagueEnum = league == 'monday' ? League.monday : League.wednesday;

      Map<String, dynamic> insertResult = await _dbHelper.insertScoreLeague(localScoreData, leagueEnum);
      List<Map<String, dynamic>> deletedScores = insertResult['deletedScores'] as List<Map<String, dynamic>>;

      // Delete old scores from Firebase if any were removed locally
      if (deletedScores.isNotEmpty) {
        final FirebaseUploadService firebaseService = FirebaseUploadService();
        await firebaseService.deletePlayerScoresFromFirebase(deletedScores, leagueEnum);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to parse currency strings back to double values
  double _parseCurrency(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove $ and parse as double
      String cleanValue = value.replaceAll('\$', '').replaceAll(',', '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }


  Widget _buildDownloadButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    final fontScale = DeviceDetectionService.getFontScale(context);
    const baseFontSize = 20.0;
    final responsiveFontSize = baseFontSize * fontScale;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: responsiveFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
