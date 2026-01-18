import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/firebase_upload_service.dart';
import '../../services/firebase_download_service.dart';

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
  final FirebaseDownloadService _firebaseDownloadService = FirebaseDownloadService();
  bool _isDownloading = false;
  bool _firebaseUploadsEnabled = true;
  bool _allowDuplicateDates = true;

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
    _loadFirebaseUploadsState();
    _loadAllowDuplicateDatesState();
  }

  /// Load the Firebase uploads enabled state from SharedPreferences
  Future<void> _loadFirebaseUploadsState() async {
    // Wait for the state to be loaded from SharedPreferences
    await FirebaseUploadService.loadUploadsEnabledState();
    if (mounted) {
      setState(() {
        _firebaseUploadsEnabled = FirebaseUploadService.uploadsEnabled;
      });
    }
  }

  /// Load the allow duplicate dates state from SharedPreferences
  Future<void> _loadAllowDuplicateDatesState() async {
    // Wait for the state to be loaded from SharedPreferences
    await DatabaseHelper.loadAllowDuplicateDatesState();
    if (mounted) {
      setState(() {
        _allowDuplicateDates = DatabaseHelper.allowDuplicateDates;
      });
    }
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

                // Firebase Upload Toggle Checkbox
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Card(
                      elevation: 4,
                      color: _firebaseUploadsEnabled ? Colors.green[50] : Colors.red[50],
                      child: CheckboxListTile(
                        title: Text(
                          'Turn off Firebase Uploads',
                          style: TextStyle(
                            fontSize: 20 * DeviceDetectionService.getFontScale(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _firebaseUploadsEnabled
                            ? 'Firebase uploads are currently ENABLED'
                            : 'Firebase uploads are currently DISABLED',
                          style: TextStyle(
                            fontSize: 16 * DeviceDetectionService.getFontScale(context),
                            color: _firebaseUploadsEnabled ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: !_firebaseUploadsEnabled,
                        onChanged: (bool? value) async {
                          final newState = !(value ?? false);
                          setState(() {
                            _firebaseUploadsEnabled = newState;
                          });

                          // Save the state to SharedPreferences
                          await FirebaseUploadService.saveUploadsEnabledState(newState);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _firebaseUploadsEnabled
                                    ? 'Firebase uploads ENABLED'
                                    : 'Firebase uploads DISABLED',
                                ),
                                backgroundColor: _firebaseUploadsEnabled ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Allow Duplicate Dates Checkbox
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Card(
                      elevation: 4,
                      color: _allowDuplicateDates ? Colors.blue[50] : Colors.orange[50],
                      child: CheckboxListTile(
                        title: Text(
                          'Allow Duplicate Dates',
                          style: TextStyle(
                            fontSize: 20 * DeviceDetectionService.getFontScale(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _allowDuplicateDates
                            ? 'Multiple scores can be stored for the same date'
                            : 'Only one score per date allowed',
                          style: TextStyle(
                            fontSize: 16 * DeviceDetectionService.getFontScale(context),
                            color: _allowDuplicateDates ? Colors.blue[800] : Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _allowDuplicateDates,
                        onChanged: (bool? value) async {
                          final newState = value ?? true;
                          setState(() {
                            _allowDuplicateDates = newState;
                          });

                          // Save the state to SharedPreferences
                          await DatabaseHelper.saveAllowDuplicateDatesState(newState);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _allowDuplicateDates
                                    ? 'Duplicate dates ALLOWED'
                                    : 'Duplicate dates BLOCKED',
                                ),
                                backgroundColor: _allowDuplicateDates ? Colors.blue : Colors.orange,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),

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
                      'Delete Wed Player Scores',
                      Icons.delete_forever,
                      Colors.red[400]!,
                      () => _clearAllScoreData(),
                    ),

                    _buildDownloadButton(
                      _isDownloading ? 'Uploading...' : 'Copy M to W Profiles',
                      _isDownloading ? Icons.hourglass_bottom : Icons.upload,
                      _isDownloading ? Colors.grey[400]! : Colors.green[300]!,
                      _isDownloading ? () {} : () => _copyMondayProfilesToWednesday(),
                    ),

                    _buildDownloadButton(
                      'Copy OHC to HC',
                      Icons.copy_all,
                      Colors.purple[300]!,
                      () => _copyOhcToHc(),
                    ),

                    _buildDownloadButton(
                      _isDownloading ? 'Downloading...' : 'Download Wed Player Profiles',
                      _isDownloading ? Icons.hourglass_bottom : Icons.people,
                      _isDownloading ? Colors.grey[400]! : Colors.blue[300]!,
                      _isDownloading ? () {} : () => _downloadWednesdayPlayerProfiles(),
                    ),

                    _buildDownloadButton(
                      'Delete All Wed Player Profiles',
                      Icons.person_remove,
                      Colors.red[400]!,
                      () => _deleteWednesdayPlayerProfiles(),
                    ),

                    _buildDownloadButton(
                      'Create W_starting_OHC',
                      Icons.content_copy,
                      Colors.teal[300]!,
                      () => _createStartingOHCCollection(),
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
      // Local players table has: player_number, first, last, skat_number, OHC, HC, cell, email, league
      Map<String, dynamic> cleanData = {
        'player_number': playerData['player_number'],
        'first': playerData['first'],
        'last': playerData['last'],
        'skat_number': playerData['skat_number'],
        'OHC': playerData['OHC'],
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


  Future<void> _clearAllScoreData() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wed Player Scores'),
        content: const Text('This will permanently delete ALL scores, games, and winnings data for Wednesday league players from both the local database and Firebase. This cannot be undone. Are you sure?'),
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
        // Delete from local database
        await _dbHelper.clearWednesdayScoreData();

        // Delete from Firebase
        await _deleteAllWednesdayScoresFromFirebase();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All Wednesday score data has been cleared from local database and Firebase'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Delete all Wednesday player scores from Firebase
  Future<void> _deleteAllWednesdayScoresFromFirebase() async {
    try {
      // Get all documents from W_player_scores collection
      QuerySnapshot snapshot = await _firestore.collection('W_player_scores').get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No Wednesday scores found in Firebase to delete');
        return;
      }

      // Create a batch to delete all documents
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
      }

      // Commit the batch deletion
      await batch.commit();
      debugPrint('Successfully deleted $count Wednesday scores from Firebase');
    } catch (e) {
      debugPrint('Error deleting Wednesday scores from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _deleteWednesdayPlayerProfiles() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Wed Player Profiles'),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $count Wednesday player profiles'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting players: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _copyMondayProfilesToWednesday() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copying Monday player profiles to W_player_profile collection...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Read all documents from M_player_profile collection
      QuerySnapshot mondaySnapshot = await _firestore.collection('M_player_profile').get();

      if (mondaySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No profiles found in M_player_profile collection'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Create a batch to write to W_player_profile
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in mondaySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Convert skat_number to HC and set value to 15
        if (data.containsKey('skat_number')) {
          data['HC'] = 15.0;
          data.remove('skat_number');
        } else if (data.containsKey('SKAT#')) {
          data['HC'] = 15.0;
          data.remove('SKAT#');
        } else {
          // If neither field exists, just add HC
          data['HC'] = 15.0;
        }

        // Use the same document ID (last name)
        String docId = doc.id;

        // Write to W_player_profile collection
        DocumentReference wedRef = _firestore.collection('W_player_profile').doc(docId);
        batch.set(wedRef, data);
        count++;
      }

      // Commit the batch
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully copied $count player profiles to W_player_profile!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copy Failed: ${e.toString()}'),
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

  Future<void> _copyOhcToHc() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy OHC to HC'),
        content: const Text(
          'This will copy the Starting Handicap (OHC) from Firebase to the HC (Handicap) field '
          'for all Wednesday players.\n\n'
          'This will overwrite existing HC values.\n\n'
          'Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('COPY OHC TO HC'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get all Wednesday players from local database
      final wednesdayPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);

      // Get all starting handicaps from Firebase W_starting_handicap collection
      final startingHandicaps = await _firebaseDownloadService.getAllStartingHandicaps();

      int updatedCount = 0;
      int skippedCount = 0;

      for (var player in wednesdayPlayers) {
        final playerNumber = player['player_number'];
        final lastName = player['last']?.toString() ?? '';

        // Get OHC from Firebase (using last name as key)
        final ohcValue = startingHandicaps[lastName];

        if (ohcValue != null && playerNumber != null) {
          // Update the player's HC field with OHC value from Firebase
          await _dbHelper.updatePlayer(playerNumber, {'HC': ohcValue});
          updatedCount++;
        } else {
          skippedCount++;
        }
      }

      // Upload updated player data to Firebase
      final firebaseSuccess = await _firebaseUploadService.uploadPlayerTableWithQueue(League.wednesday);

      if (mounted) {
        if (firebaseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Copy Complete!\n'
                'Updated: $updatedCount players (local & Firebase)\n'
                '${skippedCount > 0 ? 'Skipped: $skippedCount players (no OHC in Firebase)' : ''}'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Copy Complete!\n'
                'Updated: $updatedCount players locally\n'
                'Firebase will sync when WiFi is available\n'
                '${skippedCount > 0 ? 'Skipped: $skippedCount players (no OHC in Firebase)' : ''}'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying OHC to HC: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createStartingOHCCollection() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create W_starting_OHC Collection'),
        content: const Text(
          'This will create/update the W_starting_OHC collection in Firebase by copying:\n\n'
          '• player_number\n'
          '• Last Name\n'
          '• OHC (from HC field)\n\n'
          'for all players in W_player_profile.\n\n'
          'Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
            child: const Text('CREATE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating W_starting_OHC collection...'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 2),
        ),
      );

      final success = await _firebaseUploadService.createStartingOHCCollection();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('W_starting_OHC collection created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create W_starting_OHC collection. Check if Firebase uploads are enabled.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
