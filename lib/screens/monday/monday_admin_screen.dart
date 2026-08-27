import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/firebase_upload_service.dart';
import '../../services/error_log_service.dart';

class MondayAdminScreen extends StatefulWidget {
  final League? currentLeague;

  const MondayAdminScreen({super.key, this.currentLeague});

  @override
  State<MondayAdminScreen> createState() => _MondayAdminScreenState();
}

class _MondayAdminScreenState extends State<MondayAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isDownloading = false;

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
      // Ignore errors during Firestore initialization - settings may already be configured
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monday Administration'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                _buildDownloadButton(
                  _isDownloading ? 'Downloading...' : 'Download Monday Player Profiles',
                  _isDownloading ? Icons.hourglass_bottom : Icons.people,
                  _isDownloading ? Colors.grey[400]! : Colors.green[300]!,
                  _isDownloading ? () {} : () => _downloadMondayPlayerProfiles(),
                ),

                const SizedBox(height: 16),

                _buildDownloadButton(
                  'Download Golf Courses',
                  Icons.golf_course,
                  Colors.green[300]!,
                  () => _downloadGolfCourses(),
                ),

                const SizedBox(height: 16),

                _buildDownloadButton(
                  'Download Monday Player Scores',
                  Icons.download,
                  Colors.green[300]!,
                  () => _downloadMondayPlayerScores(),
                ),

                const SizedBox(height: 16),

                _buildDownloadButton(
                  'View Error Log',
                  Icons.bug_report,
                  Colors.red[200]!,
                  () => _showErrorLog(),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _downloadMondayPlayerProfiles() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Downloading Monday Player Profiles from Firebase...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Download from Monday player profile collection only
      // No need to test connection separately - the actual query will fail if there's a connection issue
      QuerySnapshot mondaySnapshot = await _firestore.collection('M_player_profile').get();

      int mondayCount = 0;
      int errorCount = 0;

      // Process Monday players
      for (var doc in mondaySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');

          // Set league based on collection
          data['league'] = 'monday';

          await _insertOrUpdatePlayer(data);
          mondayCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Download Complete!\n'
            'Monday: $mondayCount players\n'
            '${errorCount > 0 ? 'Errors: $errorCount\n' : ''}'
            'Total: $mondayCount players downloaded'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Download Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Helper method to insert or update a player
  Future<void> _insertOrUpdatePlayer(Map<String, dynamic> playerData) async {
    try {
      // Clean the data to only include fields that exist in the local database schema
      // Local players table has: player_number, first, last, skat_number, cell, email, league
      Map<String, dynamic> cleanData = {
        'player_number': playerData['player_number'],
        'first': playerData['first'],
        'last': playerData['last'],
        'skat_number': playerData['skat_number'],
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

  Future<void> _downloadGolfCourses() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Downloading Golf Courses from Firebase...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );


      // Sign in anonymously if not already authenticated
      if (_auth.currentUser == null) {

        await _auth.signInAnonymously();
      } else {
      }

      // Download from Monday golf courses collection
      QuerySnapshot snapshot = await _firestore.collection('M_golf_course').get();

      int courseCount = 0;
      int errorCount = 0;

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');

          // Insert or update golf course in local database
          await _insertOrUpdateGolfCourse(data);
          courseCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Download Complete!\n'
            'Golf Courses: $courseCount downloaded\n'
            '${errorCount > 0 ? 'Errors: $errorCount\n' : ''}'
            'Total: $courseCount golf courses downloaded'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Download Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Helper method to insert or update a golf course
  Future<void> _insertOrUpdateGolfCourse(Map<String, dynamic> courseData) async {
    try {
      String? courseName = courseData['name'];
      if (courseName == null || courseName.isEmpty) {
        return;
      }

      // Remove the id field from Firebase data - let local DB auto-generate it
      courseData.remove('id');

      // Check if golf course exists by name (since name is unique)
      final db = await _dbHelper.database;
      List<Map<String, dynamic>> existingCourses = await db.query(
        'golf_courses',
        where: 'name = ?',
        whereArgs: [courseName],
        limit: 1,
      );

      if (existingCourses.isNotEmpty) {
        // Update existing golf course by ID
        int existingId = existingCourses.first['id'] as int;
        await _dbHelper.updateGolfCourse(existingId, courseData);
      } else {
        // Insert new golf course (ID will be auto-generated)
        await _dbHelper.insertGolfCourse(courseData);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _downloadMondayPlayerScores() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Downloading Monday Player Scores from Firebase...'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );

      // Download from M_player_scores collection only
      // No need to test connection separately - the actual query will fail if there's a connection issue
      QuerySnapshot mondaySnapshot = await _firestore.collection('M_player_scores').get();

      // Use only Monday docs
      List<QueryDocumentSnapshot> allDocs = mondaySnapshot.docs;

      int mondayCount = 0;
      int errorCount = 0;


      for (var doc in allDocs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');

          // All documents from M_player_scores go to Monday database
          await _insertOrUpdatePlayerScore(data, 'monday');
          mondayCount++;

        } catch (e) {
          errorCount++;
        }
      }

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Download Complete!\n'
            'Monday Scores: $mondayCount downloaded\n'
            '${errorCount > 0 ? 'Errors: $errorCount\n' : ''}'
            'Total: $mondayCount scores downloaded from M_player_scores'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Download Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
        // monday_scores has no 'skat_number' column, and Firebase never
        // uploads a field called 'SKAT #' — the actual uploaded fields are
        // S_SK, SKATS, DIFF, and New_SK (see firebase_upload_service.dart).
        // The old field names here caused every downloaded row to fail with
        // "no such column: skat_number", which is what produced the
        // "Errors: 113" result on this button.
        localScoreData['S_SK'] = scoreData['S_SK'];
        localScoreData['SKATS'] = scoreData['SKATS'];
        localScoreData['DIFF'] = scoreData['DIFF'];
        localScoreData['New_SK'] = scoreData['New_SK'];
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

      // insertScoreLeague only dedupes by player+date for Wednesday; for
      // Monday it always inserts, so re-running this download would create
      // duplicate rows for every score already present locally. Update the
      // existing row in place instead — this also lets a corrected Firebase
      // record (e.g. after manually fixing a mistaken SK#) actually land
      // locally, rather than being silently skipped because "a record
      // already exists" for that player+date.
      if (leagueEnum == League.monday) {
        final existing = await _dbHelper.getPlayerScoreByDate(
          localScoreData['player_id'] as int,
          localScoreData['date_played'] as String,
          League.monday,
        );
        if (existing != null) {
          await _dbHelper.updateScoreRecord(existing['id'] as int, localScoreData, League.monday);
          return;
        }
      }

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
    const baseFontSize = 14.0;
    final responsiveFontSize = baseFontSize * fontScale;

    return SizedBox(
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: responsiveFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
