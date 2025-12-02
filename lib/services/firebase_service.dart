import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/league.dart';
import '../firebase_options.dart';
import 'database_helper.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Collections
  static const String playersCollection = 'players';
  static const String gamesCollection = 'games';
  static const String scoresCollection = 'scores';
  static const String settingsCollection = 'settings';

  /// Check if Firebase sync is enabled
  Future<bool> isSyncEnabled() async {
    String? syncEnabled = await _dbHelper.getSetting('firebase_sync_enabled');
    return syncEnabled == 'true';
  }

  /// Enable or disable Firebase sync
  Future<void> setSyncEnabled(bool enabled) async {
    await _dbHelper.setSetting('firebase_sync_enabled', enabled.toString());
  }

  /// Sign in anonymously for tablet access
  Future<User?> signInAnonymously() async {
    try {
      print('Checking authentication status...');
      print('Firebase Auth instance: ${_auth.toString()}');
      
      // Check if user is already authenticated
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('User already authenticated: ${currentUser.uid}');
        print('User anonymous: ${currentUser.isAnonymous}');
        print('User created: ${currentUser.metadata.creationTime}');
        print('Authentication status: ALREADY SIGNED IN');
        return currentUser;
      }
      
      print('No current user, attempting anonymous authentication...');
      
      // Configure Firebase Auth to avoid Dynamic Links issues
      await _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );
      
      UserCredential result = await _auth.signInAnonymously();
      print('Anonymous authentication successful: ${result.user?.uid}');
      print('User created: ${result.user?.metadata.creationTime}');
      print('User anonymous: ${result.user?.isAnonymous}');
      
      return result.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      
      // Detailed error handling
      if (e.toString().contains('auth/operation-not-allowed')) {
        print('SOLUTION: Enable Anonymous Authentication in Firebase Console');
        print('Go to: Authentication → Sign-in method → Anonymous → Enable');
      } else if (e.toString().contains('auth/network-request-failed')) {
        print('SOLUTION: Check internet connection');
      } else if (e.toString().contains('auth/invalid-api-key')) {
        print('SOLUTION: Check Firebase API key configuration');
        print('Current API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey.substring(0, 10)}...');
      } else if (e.toString().contains('auth/app-not-authorized')) {
        print('SOLUTION: Check Firebase project configuration and app registration');
        print('Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      } else if (e.toString().contains('dynamic-links') || e.toString().contains('Dynamic Links')) {
        print('SOLUTION: Dynamic Links deprecation - using alternative auth flow');
        return await _tryAlternativeAuth();
      } else if (e.toString().contains('PigeonUserDetails') || e.toString().contains('type cast')) {
        print('SOLUTION: Type casting issue - checking current user instead');
        // Return current user if it exists (workaround for type casting issue)
        User? fallbackUser = _auth.currentUser;
        if (fallbackUser != null) {
          print('Fallback successful: Using existing authenticated user ${fallbackUser.uid}');
          return fallbackUser;
        }
        return null;
      } else {
        print('UNKNOWN ERROR: Please check Firebase Console and project configuration');
      }
      
      return null;
    }
  }
  
  /// Alternative authentication method without Dynamic Links
  Future<User?> _tryAlternativeAuth() async {
    try {
      print('Trying alternative anonymous authentication...');
      
      // Sign out any existing user first
      await _auth.signOut();
      
      // Try again with a fresh auth instance
      UserCredential result = await _auth.signInAnonymously();
      print('Alternative auth successful: ${result.user?.uid}');
      
      return result.user;
    } catch (e) {
      print('Alternative auth also failed: $e');
      return null;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sync all local data to Firebase
  Future<bool> syncToFirebase() async {
    try {
      if (!await isSyncEnabled()) {
        print('Firebase sync is disabled');
        return false;
      }

      // Use the bypass method that we know works
      return await uploadWithoutAuth();
    } catch (e) {
      print('DETAILED ERROR syncing to Firebase: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('permission')) {
        print('PERMISSION ERROR: Check Firebase security rules');
      }
      if (e.toString().contains('auth')) {
        print('AUTH ERROR: Check Firebase authentication settings');
      }
      return false;
    }
  }

  /// Test Firebase connection
  Future<bool> testFirebaseConnection() async {
    try {
      // Try to read from a test collection
      await _firestore.collection('test').limit(1).get();
      print('Firebase connection test successful');
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      if (e.toString().contains('PERMISSION_DENIED')) {
        print('Permission denied - check Firebase security rules');
      }
      if (e.toString().contains('network')) {
        print('Network issue - check internet connection');
      }
      return false;
    }
  }

  /// Upload data without authentication (bypasses auth requirement)
  Future<bool> uploadWithoutAuth() async {
    try {
      print('Starting upload without authentication...');
      
      // Force enable sync
      await setSyncEnabled(true);
      
      // Try to get local data counts (but don't fail if this fails)
      try {
        Map<String, int> dataCounts = await _dbHelper.getDataCounts();
        print('Local data: ${dataCounts['players']} players, ${dataCounts['games']} games, ${dataCounts['scores']} scores');
      } catch (e) {
        print('Could not get data counts (database may be read-only): $e');
      }
      
      // Try direct database access to upload
      await _uploadDirectFromDatabase();
      
      print('SUCCESS: Upload completed without authentication');
      return true;
    } catch (e) {
      print('Upload without auth failed: $e');
      return false;
    }
  }

  /// Upload directly from database without using helper methods
  Future<void> _uploadDirectFromDatabase() async {
    try {
      print('Attempting direct database access...');
      
      // Get direct database access
      final db = await _dbHelper.database;
      
      // Upload players directly from database
      print('Reading players directly from database...');
      List<Map<String, dynamic>> allPlayers = await db.query('players', where: 'active = 1');
      
      int playerCount = 0;
      for (var player in allPlayers) {
        try {
          Map<String, dynamic> cleanPlayer = Map<String, dynamic>.from(player);
          cleanPlayer.removeWhere((key, value) => value == null);
          
          String playerName = '${player['last'] ?? ''}'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
          String docId = '${player['league'] ?? 'unknown'}_${playerName}';
          await _firestore.collection('Player Profile').doc(docId).set({
            ...cleanPlayer,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'sync_upload',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          playerCount++;
          print('Uploaded player $playerCount: ${player['first']} ${player['last']}');
        } catch (e) {
          print('Error uploading player ${player['id']}: $e');
        }
      }
      
      // Upload scores directly from database
      print('Reading scores directly from database...');
      List<Map<String, dynamic>> mondayScores = await db.query('monday_scores', orderBy: 'id DESC', limit: 100);
      List<Map<String, dynamic>> wednesdayScores = await db.query('wednesday_scores', orderBy: 'id DESC', limit: 100);
      List<Map<String, dynamic>> legacyScores = await db.query('scores', orderBy: 'id DESC', limit: 50);
      
      List<Map<String, dynamic>> allScores = [...mondayScores, ...wednesdayScores, ...legacyScores];
      
      int scoreCount = 0;
      for (var score in allScores) {
        try {
          Map<String, dynamic> cleanScore = Map<String, dynamic>.from(score);
          cleanScore.removeWhere((key, value) => value == null);
          
          // Get player name for score document
          String playerName = 'Unknown_Player';
          if (cleanScore['name'] != null) {
            // Extract last name from full name (assuming format "First Last")
            List<String> nameParts = cleanScore['name'].toString().split(' ');
            playerName = nameParts.isNotEmpty ? nameParts.last : 'Unknown_Player';
          }
          
          // Format date as MM-DD-YY
          String dateStr = 'no_date';
          if (cleanScore['date_played'] != null) {
            try {
              DateTime date = DateTime.parse(cleanScore['date_played'].toString());
              dateStr = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year.toString().substring(2)}';
            } catch (e) {
              dateStr = cleanScore['date_played'].toString().replaceAll('/', '-');
            }
          }
          
          String docId = '${playerName}_${dateStr}';
          await _firestore.collection('Player Scores').doc(docId).set({
            ...cleanScore,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'sync_upload',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          scoreCount++;
          if (scoreCount % 10 == 0) {
            print('Uploaded $scoreCount scores...');
          }
        } catch (e) {
          print('Error uploading score: $e');
        }
      }
      
      // Upload golf course info directly from database
      print('Reading golf course info directly from database...');
      List<Map<String, dynamic>> courseInfo = await db.query('course_info');
      List<Map<String, dynamic>> golfCourses = await db.query('golf_courses');
      
      int courseCount = 0;
      for (var course in courseInfo) {
        try {
          Map<String, dynamic> cleanCourse = Map<String, dynamic>.from(course);
          cleanCourse.removeWhere((key, value) => value == null);
          
          String courseName = (course['name'] ?? 'Unknown_Course').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
          String docId = '${course['league'] ?? 'unknown'}_${courseName}';
          await _firestore.collection('Golf Courses').doc(docId).set({
            ...cleanCourse,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'sync_upload',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          courseCount++;
          print('Uploaded course info $courseCount: ${course['name']}');
        } catch (e) {
          print('Error uploading course info ${course['id']}: $e');
        }
      }
      
      int golfCourseCount = 0;
      for (var course in golfCourses) {
        try {
          Map<String, dynamic> cleanCourse = Map<String, dynamic>.from(course);
          cleanCourse.removeWhere((key, value) => value == null);
          
          String courseName = (course['name'] ?? 'Unknown_Course').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
          String docId = '${courseName}';
          await _firestore.collection('Golf Courses').doc(docId).set({
            ...cleanCourse,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'sync_upload',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          golfCourseCount++;
          print('Uploaded golf course $golfCourseCount: ${course['name']}');
        } catch (e) {
          print('Error uploading golf course ${course['id']}: $e');
        }
      }

      // Upload settings and other tables
      print('Reading settings directly from database...');
      List<Map<String, dynamic>> settings = await db.query('settings');
      List<Map<String, dynamic>> mulligans = await db.query('mulligans');
      
      int settingsCount = 0;
      for (var setting in settings) {
        try {
          Map<String, dynamic> cleanSetting = Map<String, dynamic>.from(setting);
          cleanSetting.removeWhere((key, value) => value == null);
          
          String docId = 'setting_${setting['key_name']}_${setting['league'] ?? 'global'}_${DateTime.now().millisecondsSinceEpoch}';
          await _firestore.collection('damaged_tablet_settings').doc(docId).set({
            ...cleanSetting,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'damaged_tablet_direct',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          settingsCount++;
          print('Uploaded setting $settingsCount: ${setting['key_name']}');
        } catch (e) {
          print('Error uploading setting ${setting['id']}: $e');
        }
      }
      
      int mulliganCount = 0;
      for (var mulligan in mulligans) {
        try {
          Map<String, dynamic> cleanMulligan = Map<String, dynamic>.from(mulligan);
          cleanMulligan.removeWhere((key, value) => value == null);
          
          String docId = 'mulligan_${mulligan['league']}_${mulligan['date_recorded']}_${DateTime.now().millisecondsSinceEpoch}';
          await _firestore.collection('damaged_tablet_mulligans').doc(docId).set({
            ...cleanMulligan,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'damaged_tablet_direct',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          mulliganCount++;
          print('Uploaded mulligan $mulliganCount for ${mulligan['league']} league');
        } catch (e) {
          print('Error uploading mulligan ${mulligan['id']}: $e');
        }
      }
      
      print('SUCCESS: Complete database upload - $playerCount players, $scoreCount scores, $courseCount course info, $golfCourseCount golf courses, $settingsCount settings, $mulliganCount mulligans');
    } catch (e) {
      print('CRITICAL ERROR in direct database upload: $e');
      throw e;
    }
  }

  /// Direct upload to Firestore (no auth required if rules allow)
  Future<void> _uploadDirectToFirestore() async {
    try {
      // Upload players
      print('Uploading players directly...');
      List<Map<String, dynamic>> mondayPlayers = await _dbHelper.getPlayersByLeague(League.monday);
      List<Map<String, dynamic>> wednesdayPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);
      
      int playerCount = 0;
      for (var player in [...mondayPlayers, ...wednesdayPlayers]) {
        try {
          // Create a clean copy of the player data without problematic fields
          Map<String, dynamic> cleanPlayer = Map<String, dynamic>.from(player);
          
          // Remove any null values that might cause issues
          cleanPlayer.removeWhere((key, value) => value == null);
          
          String docId = 'player_${player['league']}_${player['id']}_${DateTime.now().millisecondsSinceEpoch}';
          await _firestore.collection('damaged_tablet_players').doc(docId).set({
            ...cleanPlayer,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'damaged_tablet',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          playerCount++;
          print('Uploaded player $playerCount: ${player['first']} ${player['last']}');
        } catch (e) {
          print('Error uploading player ${player['id']}: $e');
          // Continue with next player
        }
      }
      
      // Upload scores  
      print('Uploading scores directly...');
      List<Map<String, dynamic>> allScores = await _getLeagueScores(League.monday);
      allScores.addAll(await _getLeagueScores(League.wednesday));
      
      int scoreCount = 0;
      for (var score in allScores) {
        try {
          // Create a clean copy of the score data
          Map<String, dynamic> cleanScore = Map<String, dynamic>.from(score);
          
          // Remove any null values that might cause issues
          cleanScore.removeWhere((key, value) => value == null);
          
          String docId = 'score_${cleanScore['league'] ?? 'unknown'}_${cleanScore['player_id']}_${DateTime.now().millisecondsSinceEpoch}_$scoreCount';
          await _firestore.collection('damaged_tablet_scores').doc(docId).set({
            ...cleanScore,
            'uploaded_at': DateTime.now().toIso8601String(),
            'source': 'damaged_tablet',
            'upload_timestamp': FieldValue.serverTimestamp()
          });
          scoreCount++;
          if (scoreCount % 10 == 0) {
            print('Uploaded $scoreCount scores...');
          }
        } catch (e) {
          print('Error uploading score: $e');
          // Continue with next score
        }
      }
      
      print('SUCCESS: Direct upload completed - $playerCount players, $scoreCount scores');
    } catch (e) {
      print('CRITICAL ERROR in direct upload: $e');
      throw e;
    }
  }

  /// Sync all Firebase data to local database
  Future<bool> syncFromFirebase() async {
    try {
      if (!await isSyncEnabled()) {
        print('Firebase sync is disabled');
        return false;
      }

      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          print('Failed to authenticate with Firebase');
          return false;
        }
      }

      // Sync players from Firebase
      await _syncPlayersFromFirebase();
      
      // Sync games from Firebase
      await _syncGamesFromFirebase();
      
      // Sync scores from Firebase
      await _syncScoresFromFirebase();
      
      // Sync settings from Firebase
      await _syncSettingsFromFirebase();

      print('Successfully synced all data from Firebase');
      return true;
    } catch (e) {
      print('Error syncing from Firebase: $e');
      return false;
    }
  }

  /// Sync players to Firebase
  Future<void> _syncPlayersToFirebase() async {
    List<Map<String, dynamic>> mondayPlayers = await _dbHelper.getPlayersByLeague(League.monday);
    List<Map<String, dynamic>> wednesdayPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);
    
    List<Map<String, dynamic>> allPlayers = [...mondayPlayers, ...wednesdayPlayers];
    
    WriteBatch batch = _firestore.batch();
    
    for (var player in allPlayers) {
      String docId = 'player_${player['id']}';
      DocumentReference docRef = _firestore.collection(playersCollection).doc(docId);
      
      // Add metadata
      player['last_synced'] = FieldValue.serverTimestamp();
      player['synced_from'] = 'local';
      
      batch.set(docRef, player, SetOptions(merge: true));
    }
    
    await batch.commit();
  }

  /// Sync players from Firebase
  Future<void> _syncPlayersFromFirebase() async {
    QuerySnapshot snapshot = await _firestore.collection(playersCollection).get();
    
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Remove Firebase-specific fields
      data.remove('last_synced');
      data.remove('synced_from');
      
      // Check if player exists locally
      if (data['id'] != null) {
        Map<String, dynamic>? existingPlayer = await _dbHelper.getPlayer(data['id']);
        
        if (existingPlayer != null) {
          // Update existing player
          await _dbHelper.updatePlayer(data['id'], data);
        } else {
          // Insert new player
          await _dbHelper.insertPlayer(data);
        }
      }
    }
  }

  /// Sync games to Firebase
  Future<void> _syncGamesToFirebase() async {
    List<Map<String, dynamic>> mondayGames = await _dbHelper.getGamesByLeague(League.monday);
    List<Map<String, dynamic>> wednesdayGames = await _dbHelper.getGamesByLeague(League.wednesday);
    
    List<Map<String, dynamic>> allGames = [...mondayGames, ...wednesdayGames];
    
    WriteBatch batch = _firestore.batch();
    
    for (var game in allGames) {
      String docId = 'game_${game['id']}';
      DocumentReference docRef = _firestore.collection(gamesCollection).doc(docId);
      
      // Add metadata
      game['last_synced'] = FieldValue.serverTimestamp();
      game['synced_from'] = 'local';
      
      batch.set(docRef, game, SetOptions(merge: true));
    }
    
    await batch.commit();
  }

  /// Sync games from Firebase
  Future<void> _syncGamesFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(gamesCollection).get();
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Remove Firebase-specific fields
        data.remove('last_synced');
        data.remove('synced_from');
        
        // Determine league from data
        String? leagueStr = data['league'];
        double anteAmount = (data['ante_amount'] ?? 0.0).toDouble();
        
        if (leagueStr != null) {
          League league = leagueStr == 'monday' ? League.monday : League.wednesday;
          
          // Check if game already exists by comparing date and league
          List<Map<String, dynamic>> existingGames = await _dbHelper.getGamesByLeague(league);
          
          bool gameExists = existingGames.any((game) => 
            game['date'] == data['date'] && 
            game['league'] == leagueStr
          );
          
          if (!gameExists) {
            // Create new game
            await _dbHelper.createGame(league, anteAmount);
          }
        }
      }
      print('Successfully synced ${snapshot.docs.length} games from Firebase');
    } catch (e) {
      print('Error syncing games from Firebase: $e');
    }
  }

  /// Sync scores to Firebase
  Future<void> _syncScoresToFirebase() async {
    try {
      // Get scores for Monday league
      List<Map<String, dynamic>> mondayScores = await _getLeagueScores(League.monday);
      
      // Get scores for Wednesday league
      List<Map<String, dynamic>> wednesdayScores = await _getLeagueScores(League.wednesday);
      
      List<Map<String, dynamic>> allScores = [...mondayScores, ...wednesdayScores];
      
      WriteBatch batch = _firestore.batch();
      
      for (var score in allScores) {
        String docId = 'score_${score['league']}_${score['player_id']}_${score['date']}';
        DocumentReference docRef = _firestore.collection(scoresCollection).doc(docId);
        
        // Add metadata
        score['last_synced'] = FieldValue.serverTimestamp();
        score['synced_from'] = 'local';
        
        batch.set(docRef, score, SetOptions(merge: true));
      }
      
      await batch.commit();
      print('Successfully synced ${allScores.length} scores to Firebase');
    } catch (e) {
      print('Error syncing scores to Firebase: $e');
    }
  }
  
  /// Helper method to get all scores for a specific league
  Future<List<Map<String, dynamic>>> _getLeagueScores(League league) async {
    List<Map<String, dynamic>> scores = [];
    
    try {
      // Get all players for the league
      List<Map<String, dynamic>> players = await _dbHelper.getPlayersByLeague(league);
      
      // For each player, get their scores
      for (var player in players) {
        List<Map<String, dynamic>> playerScores = await _dbHelper.getPlayerScoresWithWinnings(player['id'], league);
        scores.addAll(playerScores);
      }
    } catch (e) {
      print('Error getting league scores for ${league.toString()}: $e');
    }
    
    return scores;
  }

  /// Sync scores from Firebase
  Future<void> _syncScoresFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(scoresCollection).get();
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Remove Firebase-specific fields
        data.remove('last_synced');
        data.remove('synced_from');
        
        // Determine league from data
        String? leagueStr = data['league'];
        if (leagueStr != null) {
          League league = leagueStr == 'monday' ? League.monday : League.wednesday;
          
          // Insert score into appropriate league table
          await _dbHelper.insertScoreLeague(data, league);
        } else {
          // Fallback to generic insert if league not specified
          await _dbHelper.insertScore(data);
        }
      }
      print('Successfully synced ${snapshot.docs.length} scores from Firebase');
    } catch (e) {
      print('Error syncing scores from Firebase: $e');
    }
  }

  /// Sync settings to Firebase
  Future<void> _syncSettingsToFirebase() async {
    try {
      // Get all settings and sync them
      List<String> settingKeys = [
        'monday_ante',
        'wednesday_ante', 
        'individual_percent',
        'group_percent',
        'firebase_sync_enabled',
        'last_sync_time',
        'adjusted_mulligan_purse_monday',
        'adjusted_mulligan_purse_wednesday'
      ];
      
      WriteBatch batch = _firestore.batch();
      
      for (String key in settingKeys) {
        String? value = await _dbHelper.getSetting(key);
        if (value != null) {
          DocumentReference docRef = _firestore.collection(settingsCollection).doc(key);
          
          Map<String, dynamic> settingData = {
            'key_name': key,
            'value': value,
            'last_synced': FieldValue.serverTimestamp(),
            'synced_from': 'local',
          };
          
          batch.set(docRef, settingData, SetOptions(merge: true));
        }
      }
      
      await batch.commit();
      print('Successfully synced ${settingKeys.length} settings to Firebase');
    } catch (e) {
      print('Error syncing settings to Firebase: $e');
    }
  }

  /// Sync settings from Firebase
  Future<void> _syncSettingsFromFirebase() async {
    QuerySnapshot snapshot = await _firestore.collection(settingsCollection).get();
    
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      String keyName = data['key_name'] ?? doc.id;
      String value = data['value'] ?? '';
      
      await _dbHelper.setSetting(keyName, value);
    }
  }

  /// Upload player scores for a specific game
  Future<bool> uploadGameResults(int gameId, List<Map<String, dynamic>> playerResults) async {
    try {
      if (!await isSyncEnabled()) return false;

      String docId = 'game_results_$gameId';
      
      Map<String, dynamic> gameData = {
        'game_id': gameId,
        'player_results': playerResults,
        'uploaded_at': FieldValue.serverTimestamp(),
        'uploaded_from': 'tablet',
      };
      
      await _firestore.collection('game_results').doc(docId).set(gameData);
      
      return true;
    } catch (e) {
      print('Error uploading game results: $e');
      return false;
    }
  }

  /// Listen to real-time updates from Firebase
  Stream<QuerySnapshot> listenToPlayers(League league) {
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    return _firestore
        .collection(playersCollection)
        .where('league', isEqualTo: leagueStr)
        .where('active', isEqualTo: 1)
        .snapshots();
  }

  /// Listen to game results
  Stream<QuerySnapshot> listenToGameResults() {
    return _firestore
        .collection('game_results')
        .orderBy('uploaded_at', descending: true)
        .snapshots();
  }

  /// Auto-sync service that runs periodically
  Timer? _autoSyncTimer;
  bool _isAutoSyncRunning = false;
  
  Future<void> startAutoSync({Duration interval = const Duration(minutes: 5)}) async {
    if (_isAutoSyncRunning) {
      print('Auto-sync already running');
      return;
    }
    
    print('Starting auto-sync with ${interval.inMinutes} minute intervals');
    _isAutoSyncRunning = true;
    
    // Initial sync
    await _performAutoSync();
    
    // Start periodic sync
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      await _performAutoSync();
    });
  }
  
  /// Stop auto-sync service
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _isAutoSyncRunning = false;
    print('Auto-sync stopped');
  }
  
  /// Perform bidirectional sync
  Future<void> _performAutoSync() async {
    try {
      if (!await isSyncEnabled()) return;
      
      print('Auto-sync: Starting bidirectional sync...');
      
      // Sync local data to Firebase
      bool uploadSuccess = await syncToFirebase();
      
      // Download updates from Firebase
      bool downloadSuccess = await syncFromFirebase();
      
      if (uploadSuccess && downloadSuccess) {
        await setLastSyncTime();
        print('Auto-sync: Completed successfully');
      } else {
        print('Auto-sync: Partial failure (upload: $uploadSuccess, download: $downloadSuccess)');
      }
    } catch (e) {
      print('Auto-sync error: $e');
    }
  }

  /// Manual conflict resolution - in case of data conflicts
  Future<void> resolveConflicts() async {
    // Implementation for handling sync conflicts
    // This would compare timestamps and let user choose which data to keep
    print('Conflict resolution not implemented yet');
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    User? user = getCurrentUser();
    bool syncEnabled = await isSyncEnabled();
    
    return {
      'sync_enabled': syncEnabled,
      'authenticated': user != null,
      'user_id': user?.uid,
      'last_sync': await _dbHelper.getSetting('last_sync_time'),
    };
  }

  /// Set last sync time
  Future<void> setLastSyncTime() async {
    await _dbHelper.setSetting('last_sync_time', DateTime.now().toIso8601String());
  }

  /// Sync only Monday League data
  Future<bool> syncMondayLeague() async {
    try {
      if (!await isSyncEnabled()) {
        print('Firebase sync is disabled');
        return false;
      }

      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          print('Failed to authenticate with Firebase');
          return false;
        }
      }

      // Sync Monday players bidirectionally
      await _syncSpecificLeagueToFirebase(League.monday);
      await _syncSpecificLeagueFromFirebase(League.monday);
      
      print('Successfully synced Monday League data');
      return true;
    } catch (e) {
      print('Error syncing Monday League: $e');
      return false;
    }
  }

  /// Sync only Wednesday League data
  Future<bool> syncWednesdayLeague() async {
    try {
      if (!await isSyncEnabled()) {
        print('Firebase sync is disabled');
        return false;
      }

      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          print('Failed to authenticate with Firebase');
          return false;
        }
      }

      // Sync Wednesday players bidirectionally
      await _syncSpecificLeagueToFirebase(League.wednesday);
      await _syncSpecificLeagueFromFirebase(League.wednesday);
      
      print('Successfully synced Wednesday League data');
      return true;
    } catch (e) {
      print('Error syncing Wednesday League: $e');
      return false;
    }
  }

  /// Sync specific league data to Firebase
  Future<void> _syncSpecificLeagueToFirebase(League league) async {
    String leagueStr = league.toString().split('.').last;
    
    // Sync players for this league
    List<Map<String, dynamic>> players = await _dbHelper.getPlayersByLeague(league);
    
    WriteBatch batch = _firestore.batch();
    
    for (var player in players) {
      String docId = 'player_${leagueStr}_${player['id']}';
      DocumentReference docRef = _firestore.collection(playersCollection).doc(docId);
      
      player['last_synced'] = FieldValue.serverTimestamp();
      player['synced_from'] = 'local';
      
      batch.set(docRef, player, SetOptions(merge: true));
    }
    
    // Sync games for this league
    List<Map<String, dynamic>> games = await _dbHelper.getGamesByLeague(league);
    
    for (var game in games) {
      String docId = 'game_${leagueStr}_${game['id']}';
      DocumentReference docRef = _firestore.collection(gamesCollection).doc(docId);
      
      game['last_synced'] = FieldValue.serverTimestamp();
      game['synced_from'] = 'local';
      
      batch.set(docRef, game, SetOptions(merge: true));
    }
    
    // Sync scores for this league
    List<Map<String, dynamic>> scores = await _getLeagueScores(league);
    
    for (var score in scores) {
      String docId = 'score_${leagueStr}_${score['player_id']}_${score['date']}';
      DocumentReference docRef = _firestore.collection(scoresCollection).doc(docId);
      
      score['last_synced'] = FieldValue.serverTimestamp();
      score['synced_from'] = 'local';
      
      batch.set(docRef, score, SetOptions(merge: true));
    }
    
    await batch.commit();
    print('Synced ${players.length} players, ${games.length} games, and ${scores.length} scores for ${leagueStr} league to Firebase');
  }

  /// Sync specific league data from Firebase
  Future<void> _syncSpecificLeagueFromFirebase(League league) async {
    String leagueStr = league.toString().split('.').last;
    
    // Sync players for this league
    QuerySnapshot playersSnapshot = await _firestore
        .collection(playersCollection)
        .where('league', isEqualTo: leagueStr)
        .get();
    
    for (var doc in playersSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data.remove('last_synced');
      data.remove('synced_from');
      
      if (data['id'] != null) {
        Map<String, dynamic>? existingPlayer = await _dbHelper.getPlayer(data['id']);
        
        if (existingPlayer != null) {
          await _dbHelper.updatePlayer(data['id'], data);
        } else {
          await _dbHelper.insertPlayer(data);
        }
      }
    }
    
    // Sync scores for this league
    QuerySnapshot scoresSnapshot = await _firestore
        .collection(scoresCollection)
        .where('league', isEqualTo: leagueStr)
        .get();
    
    for (var doc in scoresSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data.remove('last_synced');
      data.remove('synced_from');
      
      await _dbHelper.insertScoreLeague(data, league);
    }
    
    print('Synced ${playersSnapshot.docs.length} players and ${scoresSnapshot.docs.length} scores for ${leagueStr} league from Firebase');
  }

  /// Get comprehensive sync statistics
  Future<Map<String, dynamic>> getComprehensiveSyncStats() async {
    Map<String, int> dataCounts = await _dbHelper.getDataCounts();
    
    // Get league-specific counts
    List<Map<String, dynamic>> mondayPlayers = await _dbHelper.getPlayersByLeague(League.monday);
    List<Map<String, dynamic>> wednesdayPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);
    List<Map<String, dynamic>> mondayGames = await _dbHelper.getGamesByLeague(League.monday);
    List<Map<String, dynamic>> wednesdayGames = await _dbHelper.getGamesByLeague(League.wednesday);
    
    return {
      'total_data': dataCounts,
      'monday_league': {
        'players': mondayPlayers.length,
        'games': mondayGames.length,
      },
      'wednesday_league': {
        'players': wednesdayPlayers.length,
        'games': wednesdayGames.length,
      },
      'firebase_status': await getSyncStatus(),
      'last_sync': await _dbHelper.getSetting('last_sync_time'),
    };
  }

  /// Download and restore complete database from Firebase
  Future<bool> downloadAndRestoreDatabase() async {
    try {
      print('Starting complete database restore from Firebase...');
      
      // Authenticate first
      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          print('FAILED: Cannot authenticate with Firebase');
          return false;
        }
      }
      
      // Test connection
      bool canConnect = await testFirebaseConnection();
      if (!canConnect) {
        print('FAILED: Cannot connect to Firebase');
        return false;
      }
      
      // Get backup/restore stats
      Map<String, int> beforeCounts = await _dbHelper.getDataCounts();
      print('Local data before restore: $beforeCounts');
      
      // Download all data from Firebase
      print('Downloading players from Firebase...');
      await _syncPlayersFromFirebase();
      
      print('Downloading games from Firebase...');
      await _syncGamesFromFirebase();
      
      print('Downloading scores from Firebase...');
      await _syncScoresFromFirebase();
      
      print('Downloading settings from Firebase...');
      await _syncSettingsFromFirebase();
      
      // Get final stats
      Map<String, int> afterCounts = await _dbHelper.getDataCounts();
      print('Local data after restore: $afterCounts');
      
      await setLastSyncTime();
      print('SUCCESS: Database restored from Firebase');
      
      return true;
    } catch (e) {
      print('RESTORE FAILED: $e');
      return false;
    }
  }
  
  /// Create backup of current database to Firebase
  Future<bool> createFirebaseBackup({String? backupName}) async {
    try {
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      String backupId = backupName ?? 'backup_$timestamp';
      
      print('Creating Firebase backup: $backupId');
      
      // Get current data counts
      Map<String, int> dataCounts = await _dbHelper.getDataCounts();
      
      // Create backup metadata
      await _firestore.collection('backups').doc(backupId).set({
        'created_at': FieldValue.serverTimestamp(),
        'created_by': getCurrentUser()?.uid ?? 'unknown',
        'data_counts': dataCounts,
        'backup_type': 'full_database',
        'tablet_type': 'android_tablet',
      });
      
      // Upload all data with backup prefix
      await _createBackupData(backupId);
      
      print('SUCCESS: Backup $backupId created with ${dataCounts['players']} players, ${dataCounts['games']} games, ${dataCounts['scores']} scores');
      return true;
    } catch (e) {
      print('BACKUP FAILED: $e');
      return false;
    }
  }
  
  /// Create backup data collections
  Future<void> _createBackupData(String backupId) async {
    WriteBatch batch = _firestore.batch();
    
    // Backup players
    List<Map<String, dynamic>> allPlayers = await _dbHelper.getPlayersByLeague(League.monday);
    allPlayers.addAll(await _dbHelper.getPlayersByLeague(League.wednesday));
    
    for (var player in allPlayers) {
      String docId = 'player_${player['league']}_${player['id']}';
      DocumentReference docRef = _firestore.collection('backup_$backupId\_players').doc(docId);
      batch.set(docRef, player);
    }
    
    // Backup scores
    List<Map<String, dynamic>> allScores = await _getLeagueScores(League.monday);
    allScores.addAll(await _getLeagueScores(League.wednesday));
    
    for (var score in allScores) {
      String docId = 'score_${score['league']}_${score['player_id']}_${score['date']}';
      DocumentReference docRef = _firestore.collection('backup_$backupId\_scores').doc(docId);
      batch.set(docRef, score);
    }
    
    // Backup games
    List<Map<String, dynamic>> allGames = await _dbHelper.getGamesByLeague(League.monday);
    allGames.addAll(await _dbHelper.getGamesByLeague(League.wednesday));
    
    for (var game in allGames) {
      String docId = 'game_${game['league']}_${game['id']}';
      DocumentReference docRef = _firestore.collection('backup_$backupId\_games').doc(docId);
      batch.set(docRef, game);
    }
    
    await batch.commit();
  }
  
  /// List available backups
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('backups')
          .orderBy('created_at', descending: true)
          .get();
      
      List<Map<String, dynamic>> backups = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['backup_id'] = doc.id;
        backups.add(data);
      }
      
      return backups;
    } catch (e) {
      print('Error listing backups: $e');
      return [];
    }
  }
  
  /// Restore from specific backup
  Future<bool> restoreFromBackup(String backupId) async {
    try {
      print('Restoring from backup: $backupId');
      
      // Verify backup exists
      DocumentSnapshot backupDoc = await _firestore.collection('backups').doc(backupId).get();
      if (!backupDoc.exists) {
        print('FAILED: Backup $backupId does not exist');
        return false;
      }
      
      // Clear local database first (optional - user choice)
      // await _dbHelper.clearAllData();
      
      // Restore players
      QuerySnapshot playersSnapshot = await _firestore.collection('backup_$backupId\_players').get();
      for (var doc in playersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        await _dbHelper.insertPlayer(data);
      }
      
      // Restore scores
      QuerySnapshot scoresSnapshot = await _firestore.collection('backup_$backupId\_scores').get();
      for (var doc in scoresSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? leagueStr = data['league'];
        if (leagueStr != null) {
          League league = leagueStr == 'monday' ? League.monday : League.wednesday;
          await _dbHelper.insertScoreLeague(data, league);
        }
      }
      
      // Restore games
      QuerySnapshot gamesSnapshot = await _firestore.collection('backup_$backupId\_games').get();
      for (var doc in gamesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Games will be restored through game recreation logic
        print('Game restored: ${data['date']} for ${data['league']} league');
      }
      
      print('SUCCESS: Restored from backup $backupId - ${playersSnapshot.docs.length} players, ${scoresSnapshot.docs.length} scores, ${gamesSnapshot.docs.length} games');
      await setLastSyncTime();
      return true;
    } catch (e) {
      print('RESTORE FROM BACKUP FAILED: $e');
      return false;
    }
  }
  
  /// Enable real-time sync listeners
  void enableRealTimeSync() {
    // Listen to Monday league changes
    listenToPlayers(League.monday).listen((snapshot) {
      _handleRealTimePlayerUpdates(snapshot, League.monday);
    });
    
    // Listen to Wednesday league changes
    listenToPlayers(League.wednesday).listen((snapshot) {
      _handleRealTimePlayerUpdates(snapshot, League.wednesday);
    });
    
    // Listen to game results
    listenToGameResults().listen((snapshot) {
      _handleRealTimeGameResults(snapshot);
    });
    
    print('Real-time sync enabled for both leagues');
  }
  
  /// Handle real-time player updates
  void _handleRealTimePlayerUpdates(QuerySnapshot snapshot, League league) {
    for (var change in snapshot.docChanges) {
      Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
      
      switch (change.type) {
        case DocumentChangeType.added:
          _dbHelper.insertPlayer(data);
          break;
        case DocumentChangeType.modified:
          if (data['id'] != null) {
            _dbHelper.updatePlayer(data['id'], data);
          }
          break;
        case DocumentChangeType.removed:
          if (data['id'] != null) {
            _dbHelper.deletePlayer(data['id']);
          }
          break;
      }
    }
    print('Real-time update: ${snapshot.docChanges.length} ${league.toString()} player changes processed');
  }
  
  /// Handle real-time game results
  void _handleRealTimeGameResults(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
        print('New game result received: Game ${data['game_id']}');
        // Process new game results here
      }
    }
  }

  /// Simple method to upload damaged tablet database to Firebase
  /// Call this method to force upload all local data to Firebase
  Future<bool> uploadDamagedDatabaseToFirebase() async {
    try {
      print('Starting upload of damaged tablet database to Firebase...');
      
      // Force enable sync
      await setSyncEnabled(true);
      
      // Test connection
      print('Testing Firebase connection...');
      bool canConnect = await testFirebaseConnection();
      if (!canConnect) {
        print('FAILED: Cannot connect to Firebase - check internet and Firebase config');
        return false;
      }
      
      // Try to authenticate, but continue if it fails (for existing Firebase setups)
      print('Attempting Firebase authentication...');
      User? user = getCurrentUser();
      if (user == null) {
        try {
          user = await signInAnonymously();
          if (user != null) {
            print('Authentication successful: ${user.uid}');
          }
        } catch (e) {
          print('Authentication failed, but continuing without auth: $e');
          print('This may work if your Firebase has open security rules');
        }
      }
      
      // Upload all data (this may work even without auth if Firebase rules allow it)
      print('Uploading players...');
      await _syncPlayersToFirebase();
      
      print('Uploading games...');
      await _syncGamesToFirebase();
      
      print('Uploading scores...');
      await _syncScoresToFirebase();
      
      print('Uploading settings...');
      await _syncSettingsToFirebase();
      
      print('SUCCESS: All damaged database data uploaded to Firebase');
      return true;
    } catch (e) {
      print('UPLOAD FAILED: $e');
      if (e.toString().contains('PERMISSION_DENIED')) {
        print('SOLUTION: Enable Anonymous Authentication in Firebase Console');
        print('Or update Firebase Security Rules to allow public access');
      }
      return false;
    }
  }

  /// Restore data from damaged tablet collections
  Future<bool> restoreDamagedTabletData() async {
    try {
      print('Starting restore from damaged tablet collections...');
      
      // Test connection first
      bool canConnect = await testFirebaseConnection();
      if (!canConnect) {
        print('FAILED: Cannot connect to Firebase');
        return false;
      }

      // Get current data counts before restore
      Map<String, int> beforeCounts = await _dbHelper.getDataCounts();
      print('Local data before restore: $beforeCounts');
      
      // Restore players from damaged tablet collection
      print('Downloading players from damaged_tablet_players...');
      QuerySnapshot playersSnapshot = await _firestore.collection('damaged_tablet_players').get();
      int playerCount = 0;
      
      for (var doc in playersSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          // Insert player
          await _dbHelper.insertPlayer(data);
          playerCount++;
          
          if (playerCount % 10 == 0) {
            print('Restored $playerCount players...');
          }
        } catch (e) {
          print('Error restoring player: $e');
        }
      }
      print('Restored $playerCount players from damaged tablet backup');
      
      // Restore scores from damaged tablet collection
      print('Downloading scores from damaged_tablet_scores...');
      QuerySnapshot scoresSnapshot = await _firestore.collection('damaged_tablet_scores').get();
      int scoreCount = 0;
      
      for (var doc in scoresSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          // Determine league and insert into appropriate table
          String? leagueStr = data['league'];
          if (leagueStr != null) {
            League league = leagueStr == 'monday' ? League.monday : League.wednesday;
            await _dbHelper.insertScoreLeague(data, league);
          } else {
            // Fallback to legacy scores table
            await _dbHelper.insertScore(data);
          }
          scoreCount++;
          
          if (scoreCount % 20 == 0) {
            print('Restored $scoreCount scores...');
          }
        } catch (e) {
          print('Error restoring score: $e');
        }
      }
      print('Restored $scoreCount scores from damaged tablet backup');
      
      // Restore golf courses
      print('Downloading golf courses from damaged_tablet_golf_courses...');
      QuerySnapshot coursesSnapshot = await _firestore.collection('damaged_tablet_golf_courses').get();
      int courseCount = 0;
      
      for (var doc in coursesSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          await _dbHelper.insertGolfCourse(data);
          courseCount++;
        } catch (e) {
          print('Error restoring golf course: $e');
        }
      }
      print('Restored $courseCount golf courses from damaged tablet backup');
      
      // Restore course info
      print('Downloading course info from damaged_tablet_course_info...');
      QuerySnapshot courseInfoSnapshot = await _firestore.collection('damaged_tablet_course_info').get();
      int courseInfoCount = 0;
      
      for (var doc in courseInfoSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          // Insert into course_info table
          final db = await _dbHelper.database;
          await db.insert('course_info', data);
          courseInfoCount++;
        } catch (e) {
          print('Error restoring course info: $e');
        }
      }
      print('Restored $courseInfoCount course info records from damaged tablet backup');
      
      // Restore settings
      print('Downloading settings from damaged_tablet_settings...');
      QuerySnapshot settingsSnapshot = await _firestore.collection('damaged_tablet_settings').get();
      int settingsCount = 0;
      
      for (var doc in settingsSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Clean up Firebase metadata
          data.remove('uploaded_at');
          data.remove('source');
          data.remove('upload_timestamp');
          
          String keyName = data['key_name'] ?? '';
          String value = data['value'] ?? '';
          String? league = data['league'];
          
          if (keyName.isNotEmpty && value.isNotEmpty) {
            if (league != null) {
              League leagueEnum = league == 'monday' ? League.monday : League.wednesday;
              await _dbHelper.setSetting(keyName, value, league: leagueEnum);
            } else {
              await _dbHelper.setSetting(keyName, value);
            }
            settingsCount++;
          }
        } catch (e) {
          print('Error restoring setting: $e');
        }
      }
      print('Restored $settingsCount settings from damaged tablet backup');
      
      // Get final data counts
      Map<String, int> afterCounts = await _dbHelper.getDataCounts();
      print('Local data after restore: $afterCounts');
      
      await setLastSyncTime();
      
      print('SUCCESS: Damaged tablet data restored - $playerCount players, $scoreCount scores, $courseCount golf courses, $courseInfoCount course info, $settingsCount settings');
      
      return true;
      
    } catch (e) {
      print('RESTORE FROM DAMAGED TABLET FAILED: $e');
      return false;
    }
  }
}