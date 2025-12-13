import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';

class WednesdayAdminScreen extends StatefulWidget {
  final League? currentLeague;

  const WednesdayAdminScreen({super.key, this.currentLeague});

  @override
  State<WednesdayAdminScreen> createState() => _WednesdayAdminScreenState();
}

class _WednesdayAdminScreenState extends State<WednesdayAdminScreen> {
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
                const SizedBox(height: 30),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 7.5,
                  children: [
                    _buildDownloadButton(
                      'Download Wednesday Player Scores',
                      Icons.download,
                      Colors.orange[300]!,
                      () => _downloadWednesdayPlayerScores(),
                    ),

                    _buildDownloadButton(
                      'Clear Wednesday Player Scores',
                      Icons.delete_forever,
                      Colors.red[400]!,
                      () => _clearAllScoreData(),
                    ),

                    _buildDownloadButton(
                      _isDownloading ? 'Downloading...' : 'Download Wednesday Player Profiles',
                      _isDownloading ? Icons.hourglass_bottom : Icons.people,
                      _isDownloading ? Colors.grey[400]! : Colors.blue[300]!,
                      _isDownloading ? () {} : () => _downloadWednesdayPlayerProfiles(),
                    ),

                    _buildDownloadButton(
                      'Delete All Wednesday Player Profiles',
                      Icons.person_remove,
                      Colors.red[400]!,
                      () => _deleteWednesdayPlayerProfiles(),
                    ),

                    _buildDownloadButton(
                      'Change all HC values to 15',
                      Icons.settings,
                      Colors.purple[300]!,
                      () => _changeAllWednesdayHandicapsTo15(),
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

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
      if (playerNumber != null) {
        // Check if player exists by player_number
        Map<String, dynamic>? existingPlayer = await _dbHelper.getPlayer(playerNumber);

        if (existingPlayer != null) {
          // Update existing player
          await _dbHelper.updatePlayer(playerNumber, cleanData);
        } else {
          // Insert new player
          await _dbHelper.insertPlayer(cleanData);
        }
      } else {
        // No player_number, try to insert anyway
        await _dbHelper.insertPlayer(cleanData);
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _downloadGolfCourses() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
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

      // Download from Monday golf courses collection (shared between leagues)
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
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
      throw e;
    }
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

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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

      await _dbHelper.insertScoreLeague(localScoreData, leagueEnum);
    } catch (e) {
      throw e;
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

  Future<void> _updateAllGolfCoursesPar3sTo4() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updating all golf courses Par3s to 4...'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 2),
        ),
      );

      // Call the database helper method to update all Par3s fields
      await _dbHelper.updateAllGolfCoursesPar3sTo4();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully updated all golf courses Par3s to 4!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _clearAllScoreData() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wednesday Score Data'),
        content: const Text('This will permanently delete ALL scores, games, and winnings data for Wednesday league players only. This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.clearWednesdayScoreData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All Wednesday score data has been cleared from the database'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _changeAllWednesdayHandicapsTo15() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Change Handicaps to 15'),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 16),
            children: [
              TextSpan(text: 'Are you sure you want to change all handicap values to 15?\n'),
              TextSpan(text: 'This usually is done only for testing purposes.\n'),
              TextSpan(text: 'Click '),
              TextSpan(text: 'Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: ' if you are not sure.\n'),
              TextSpan(text: 'This cannot be undone.\n\n'),
              TextSpan(
                text: 'This will affect all players in the Wednesday league ONLY.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update HC column in players table for all Wednesday players
      final db = await _dbHelper.database;
      int rowsAffected = await db.rawUpdate('''
        UPDATE players
        SET HC = 15.0
        WHERE league = 'wednesday'
      ''');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated $rowsAffected Wednesday players with HC = 15'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating handicaps: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _replaceAllSkatNumbersTo35() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Replace to 35'),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 16),
            children: [
              TextSpan(text: 'Are you sure you want to replace all Skat # values to 35?\n'),
              TextSpan(text: 'This usually is done only for testing purposes.\n'),
              TextSpan(text: 'Click '),
              TextSpan(text: 'Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: ' if you are not sure.\n'),
              TextSpan(text: 'This cannot be undone.\n\n'),
              TextSpan(
                text: 'This will affect all players in the Monday league ONLY.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update all Monday players' Skat # to 35
      final mondayPlayers = await _dbHelper.getPlayersByLeague(League.monday);

      int count = 0;
      for (var player in mondayPlayers) {
        await _dbHelper.updatePlayer(player['player_number'], {
          'player_number': player['player_number'],
          'first': player['first'],
          'last': player['last'],
          'skat_number': 35,
          'league': player['league'],
          'cell': player['cell'],
          'email': player['email'],
        });
        count++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All Monday Skat # values replaced to 35 for $count players'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating players: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteWednesdayPlayerProfiles() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Wednesday Player Profiles'),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 16),
            children: [
              TextSpan(text: 'This will permanently delete ALL player profiles from the '),
              TextSpan(text: 'Wednesday', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: ' league.\n\n'),
              TextSpan(text: 'All player data including names, contact information, and skat numbers will be removed.\n\n'),
              TextSpan(
                text: 'This CANNOT be undone.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              TextSpan(text: '\n\nAre you sure?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get all Wednesday players
      final wednesdayPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);

      int count = 0;
      for (var player in wednesdayPlayers) {
        await _dbHelper.deletePlayer(player['player_number']);
        count++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted $count Wednesday player profiles'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting players: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildDownloadButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    final fontScale = DeviceDetectionService.getFontScale(context);
    final baseFontSize = 20.0;
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
