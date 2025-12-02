import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/league.dart';
import '../services/database_helper.dart';

class AdminScreen extends StatefulWidget {
  final League? currentLeague;
  
  const AdminScreen({super.key, this.currentLeague});
  
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      print('Firestore settings configured');
    } catch (e) {
      print('Error configuring Firestore settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration Screen'),
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
                const Text(
                  'Firebase Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Row for Download Score buttons at the top
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDownloadButton(
                        'Monday Scores',
                        Colors.green[300]!,
                        () => _downloadMondayPlayerScores(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDownloadButton(
                        'Wednesday Scores',
                        Colors.orange[300]!,
                        () => _downloadWednesdayPlayerScores(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildDownloadButton(
                  _isDownloading ? 'Downloading...' : 'Download Player Profiles',
                  _isDownloading ? Icons.hourglass_bottom : Icons.people,
                  _isDownloading ? Colors.grey[400]! : Colors.blue[300]!,
                  _isDownloading ? () {} : () => _downloadPlayerProfiles(),
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
                  'Set All Golf Courses Par3s to 4',
                  Icons.update,
                  Colors.amber[300]!,
                  () => _updateAllGolfCoursesPar3sTo4(),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _downloadPlayerProfiles() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading Player Profiles from Firebase...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      print('Attempting to connect to Firebase...');
      
      // Test connection first
      try {
        await _firestore.collection('test').limit(1).get();
        print('Firebase connection successful');
      } catch (e) {
        print('Firebase connection test failed: $e');
        throw Exception('Cannot connect to Firebase. Check internet connection and Firebase configuration.');
      }

      // Download from both Monday and Wednesday player profile collections
      print('Downloading from Monday and Wednesday player profile collections...');
      
      // Download Monday players
      print('Downloading Monday players...');
      QuerySnapshot mondaySnapshot = await _firestore.collection('M_player_profile').get();
      
      // Download Wednesday players  
      print('Downloading Wednesday players...');
      QuerySnapshot wednesdaySnapshot = await _firestore.collection('wednesday_player_profile').get();
      
      // Combine both snapshots
      List<QueryDocumentSnapshot> allDocs = [];
      allDocs.addAll(mondaySnapshot.docs);
      allDocs.addAll(wednesdaySnapshot.docs);
      
      int mondayCount = 0;
      int wednesdayCount = 0;
      int errorCount = 0;

      for (var doc in allDocs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          // Determine league and store in appropriate local database
          String? league = data['league'];
          if (league != null) {
            if (league.toLowerCase() == 'monday') {
              // Store/Update in Monday league local database
              await _insertOrUpdatePlayer(data);
              mondayCount++;
            } else if (league.toLowerCase() == 'wednesday') {
              // Store/Update in Wednesday league local database
              await _insertOrUpdatePlayer(data);
              wednesdayCount++;
            } else {
              // Unknown league, still insert/update but count as error
              await _insertOrUpdatePlayer(data);
              errorCount++;
            }
          } else {
            // No league specified, count as error but still insert/update
            await _insertOrUpdatePlayer(data);
            errorCount++;
          }
        } catch (e) {
          print('Error processing player profile ${doc.id}: $e');
          errorCount++;
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Download Complete!\n'
            'Monday: $mondayCount players\n'
            'Wednesday: $wednesdayCount players\n'
            '${errorCount > 0 ? 'Errors: $errorCount\n' : ''}'
            'Total: ${mondayCount + wednesdayCount} players downloaded'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('Error downloading player profiles: $e');
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
      int? playerId = playerData['id'];
      if (playerId != null) {
        // Check if player exists
        Map<String, dynamic>? existingPlayer = await _dbHelper.getPlayer(playerId);
        
        if (existingPlayer != null) {
          // Update existing player
          await _dbHelper.updatePlayer(playerId, playerData);
          print('Updated player: ${playerData['first']} ${playerData['last']} (${playerData['league']})');
        } else {
          // Insert new player
          await _dbHelper.insertPlayer(playerData);
          print('Inserted new player: ${playerData['first']} ${playerData['last']} (${playerData['league']})');
        }
      } else {
        // No ID, try to insert anyway
        await _dbHelper.insertPlayer(playerData);
        print('Inserted player without ID: ${playerData['first']} ${playerData['last']} (${playerData['league']})');
      }
    } catch (e) {
      print('Error inserting/updating player ${playerData['first']} ${playerData['last']}: $e');
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

      print('Attempting to connect to Firebase...');
      
      // Test connection first
      try {
        await _firestore.collection('test').limit(1).get();
        print('Firebase connection successful');
      } catch (e) {
        print('Firebase connection test failed: $e');
        throw Exception('Cannot connect to Firebase. Check internet connection and Firebase configuration.');
      }

      // Download from Monday golf courses collection only
      print('Downloading from M_golf_course collection...');
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
          print('Error processing golf course ${doc.id}: $e');
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
      print('Error downloading golf courses: $e');
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
      int? courseId = courseData['id'];
      if (courseId != null) {
        // Check if golf course exists
        Map<String, dynamic>? existingCourse = await _dbHelper.getGolfCourse(courseId);
        
        if (existingCourse != null) {
          // Update existing golf course
          await _dbHelper.updateGolfCourse(courseId, courseData);
          print('Updated golf course: ${courseData['name']}');
        } else {
          // Insert new golf course
          await _dbHelper.insertGolfCourse(courseData);
          print('Inserted new golf course: ${courseData['name']}');
        }
      } else {
        // No ID, try to insert anyway
        await _dbHelper.insertGolfCourse(courseData);
        print('Inserted golf course without ID: ${courseData['name']}');
      }
    } catch (e) {
      print('Error inserting/updating golf course ${courseData['name']}: $e');
      throw e;
    }
  }

  Future<void> _downloadMondayPlayerScores() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading Monday Player Scores from Firebase...'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );

      print('Attempting to connect to Firebase...');
      
      // Test connection first
      try {
        await _firestore.collection('test').limit(1).get();
        print('Firebase connection successful');
      } catch (e) {
        print('Firebase connection test failed: $e');
        throw Exception('Cannot connect to Firebase. Check internet connection and Firebase configuration.');
      }

      // Download from M_player_scores collection only
      print('Downloading from M_player_scores collection...');
      
      // Download Monday scores
      print('Downloading Monday scores...');
      QuerySnapshot mondaySnapshot = await _firestore.collection('M_player_scores').get();
      print('M_player_scores collection documents found: ${mondaySnapshot.docs.length}');
      
      // Use only Monday docs
      List<QueryDocumentSnapshot> allDocs = mondaySnapshot.docs;
      
      int mondayCount = 0;
      int errorCount = 0;

      print('Total M_player_scores documents to process: ${allDocs.length}');
      
      for (var doc in allDocs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          print('Processing M_player_scores document: ${doc.id}');
          print('Document data keys: ${data.keys.toList()}');
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          // All documents from M_player_scores go to Monday database
          await _insertOrUpdatePlayerScore(data, 'monday');
          mondayCount++;
          print('Successfully inserted Monday score. Count: $mondayCount');
          
        } catch (e) {
          print('Error processing player score ${doc.id}: $e');
          print('Error stack trace: ${e.toString()}');
          errorCount++;
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
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
      print('Error downloading player scores: $e');
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

      print('Attempting to connect to Firebase...');
      
      // Test connection first
      try {
        await _firestore.collection('test').limit(1).get();
        print('Firebase connection successful');
      } catch (e) {
        print('Firebase connection test failed: $e');
        throw Exception('Cannot connect to Firebase. Check internet connection and Firebase configuration.');
      }

      // Download from wednesday_player_scores collection only
      print('Downloading from wednesday_player_scores collection...');
      
      // Download Wednesday scores
      print('Downloading Wednesday scores...');
      QuerySnapshot wednesdaySnapshot = await _firestore.collection('wednesday_player_scores').get();
      print('wednesday_player_scores collection documents found: ${wednesdaySnapshot.docs.length}');
      
      // Use only Wednesday docs
      List<QueryDocumentSnapshot> allDocs = wednesdaySnapshot.docs;
      
      int wednesdayCount = 0;
      int errorCount = 0;

      print('Total wednesday_player_scores documents to process: ${allDocs.length}');
      
      for (var doc in allDocs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          print('Processing wednesday_player_scores document: ${doc.id}');
          print('Document data keys: ${data.keys.toList()}');
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          // All documents from wednesday_player_scores go to Wednesday database
          await _insertOrUpdatePlayerScore(data, 'wednesday');
          wednesdayCount++;
          print('Successfully inserted Wednesday score. Count: $wednesdayCount');
          
        } catch (e) {
          print('Error processing player score ${doc.id}: $e');
          print('Error stack trace: ${e.toString()}');
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
            'Total: $wednesdayCount scores downloaded from wednesday_player_scores'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('Error downloading Wednesday player scores: $e');
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
      print('=== PROCESSING SCORE DATA ===');
      print('Input scoreData: $scoreData');
      print('League: $league');
      
      // Convert Firebase field names back to local database field names
      // Note: Don't include 'league' field as it's not in the local database schema
      Map<String, dynamic> localScoreData = <String, dynamic>{
        'player_id': scoreData['player_id'],
        'name': scoreData['name'],
        'date_played': scoreData['date_played'],
        'golf_course': scoreData['golf_course'],
      };

      print('Base localScoreData: $localScoreData');

      // Handle Monday league specific fields
      if (league.toLowerCase() == 'monday') {
        print('Processing Monday league fields...');
        // Convert Firebase currency strings back to numbers
        localScoreData['skat_number'] = scoreData['SKAT #'];
        localScoreData['close_pin_winnings'] = _parseCurrency(scoreData['Close Pin Winnings']);
        localScoreData['skat_winnings'] = _parseCurrency(scoreData['SKAT Winnings']);
        
        print('SKAT #: ${scoreData['SKAT #']} -> ${localScoreData['skat_number']}');
        print('Close Pin Winnings: ${scoreData['Close Pin Winnings']} -> ${localScoreData['close_pin_winnings']}');
        print('SKAT Winnings: ${scoreData['SKAT Winnings']} -> ${localScoreData['skat_winnings']}');
      } else {
        print('Processing Wednesday league fields...');
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

      print('Final localScoreData to insert: $localScoreData');
      
      // Use the passed league parameter
      League leagueEnum = league == 'monday' ? League.monday : League.wednesday;
      
      print('Inserting into ${league} league database...');
      await _dbHelper.insertScoreLeague(localScoreData, leagueEnum);
      print('✅ Successfully inserted player score for: ${scoreData['name']} on ${scoreData['date_played']}');
    } catch (e) {
      print('❌ Error inserting player score: $e');
      print('Error details: ${e.toString()}');
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
      print('Error updating golf courses Par3s: $e');
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
  
  Widget _buildDownloadButton(String title, IconData icon, Color bgColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDownloadButton(String title, Color bgColor, VoidCallback onPressed) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Download',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}