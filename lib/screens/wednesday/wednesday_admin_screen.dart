import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/firebase_upload_service.dart';

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
        backgroundColor: FirebaseUploadService.uploadsEnabled ? Colors.orange[800] : Colors.red[700],
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
                            FirebaseUploadService.uploadsEnabled = newState;
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
                      _isDownloading ? 'Downloading...' : 'Download Wed Player Profiles',
                      _isDownloading ? Icons.hourglass_bottom : Icons.people,
                      _isDownloading ? Colors.grey[400]! : Colors.blue[300]!,
                      _isDownloading ? () {} : () => _downloadWednesdayPlayerProfiles(),
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
      // Local players table has: player_number, first, last, skat_number, HC, OHC, cell, email, league
      Map<String, dynamic> cleanData = {
        'player_number': playerData['player_number'],
        'first': playerData['first'],
        'last': playerData['last'],
        'skat_number': playerData['skat_number'],
        'HC': playerData['HC'],
        'OHC': playerData['OHC'],
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
