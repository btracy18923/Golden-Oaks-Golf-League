import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/league.dart';
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

      // Check if user is already authenticated
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        return currentUser;
      }
      

      // Configure Firebase Auth to avoid Dynamic Links issues
      await _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );
      
      UserCredential result = await _auth.signInAnonymously();

      return result.user;
    } catch (e) {

      // Detailed error handling
      if (e.toString().contains('auth/operation-not-allowed')) {
      } else if (e.toString().contains('auth/network-request-failed')) {
      } else if (e.toString().contains('auth/invalid-api-key')) {
      } else if (e.toString().contains('auth/app-not-authorized')) {
      } else if (e.toString().contains('dynamic-links') || e.toString().contains('Dynamic Links')) {
        return await _tryAlternativeAuth();
      } else if (e.toString().contains('PigeonUserDetails') || e.toString().contains('type cast')) {
        // Return current user if it exists (workaround for type casting issue)
        User? fallbackUser = _auth.currentUser;
        if (fallbackUser != null) {
          return fallbackUser;
        }
        return null;
      } else {
      }
      
      return null;
    }
  }
  
  /// Alternative authentication method without Dynamic Links
  Future<User?> _tryAlternativeAuth() async {
    try {

      // Sign out any existing user first
      await _auth.signOut();
      
      // Try again with a fresh auth instance
      UserCredential result = await _auth.signInAnonymously();

      return result.user;
    } catch (e) {
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
        return false;
      }

      // Use the bypass method that we know works
      return await uploadWithoutAuth();
    } catch (e) {
      if (e.toString().contains('permission')) {
      }
      if (e.toString().contains('auth')) {
      }
      return false;
    }
  }

  /// Test Firebase connection
  Future<bool> testFirebaseConnection() async {
    try {
      // Try to read from a test collection
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED')) {
      }
      if (e.toString().contains('network')) {
      }
      return false;
    }
  }

  /// Upload data without authentication (bypasses auth requirement)
  Future<bool> uploadWithoutAuth() async {
    try {

      // Force enable sync
      await setSyncEnabled(true);
      
      // Try to get local data counts (but don't fail if this fails)
      try {
        await _dbHelper.getDataCounts();
      } catch (e) {
      }
      
      // Try direct database access to upload
      await _uploadDirectFromDatabase();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload directly from database without using helper methods
  Future<void> _uploadDirectFromDatabase() async {
    try {

      // Get direct database access
      final db = await _dbHelper.database;
      
      // Upload players directly from database
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
        } catch (e) {
        }
      }
      
      // Upload scores directly from database
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
          }
        } catch (e) {
        }
      }
      
      // Upload golf course info directly from database
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
        } catch (e) {
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
        } catch (e) {
        }
      }

      // Upload settings and other tables
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
        } catch (e) {
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
        } catch (e) {
        }
      }
      
    } catch (e) {
      throw e;
    }
  }


  /// Sync all Firebase data to local database
  Future<bool> syncFromFirebase() async {
    try {
      if (!await isSyncEnabled()) {
        return false;
      }

      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
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

      return true;
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
          // Ignore deletedScores return value - we're importing FROM Firebase
          await _dbHelper.insertScoreLeague(data, league);
        } else {
          // Fallback to generic insert if league not specified
          await _dbHelper.insertScore(data);
        }
      }
    } catch (e) {
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
    } catch (e) {
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
      return;
    }
    
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
  }
  
  /// Perform bidirectional sync
  Future<void> _performAutoSync() async {
    try {
      if (!await isSyncEnabled()) return;
      

      // Sync local data to Firebase
      bool uploadSuccess = await syncToFirebase();
      
      // Download updates from Firebase
      bool downloadSuccess = await syncFromFirebase();
      
      if (uploadSuccess && downloadSuccess) {
        await setLastSyncTime();
      } else {
      }
    } catch (e) {
    }
  }

  /// Manual conflict resolution - in case of data conflicts
  Future<void> resolveConflicts() async {
    // Implementation for handling sync conflicts
    // This would compare timestamps and let user choose which data to keep
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
        return false;
      }

      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          return false;
        }
      }

      // Sync Monday players bidirectionally
      await _syncSpecificLeagueToFirebase(League.monday);
      await _syncSpecificLeagueFromFirebase(League.monday);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sync only Wednesday League data
  Future<bool> syncWednesdayLeague() async {
    try {
      if (!await isSyncEnabled()) {
        return false;
      }

      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          return false;
        }
      }

      // Sync Wednesday players bidirectionally
      await _syncSpecificLeagueToFirebase(League.wednesday);
      await _syncSpecificLeagueFromFirebase(League.wednesday);
      
      return true;
    } catch (e) {
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

      // Authenticate first
      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          return false;
        }
      }
      
      // Test connection
      bool canConnect = await testFirebaseConnection();
      if (!canConnect) {
        return false;
      }
      
      // Get backup/restore stats
      await _dbHelper.getDataCounts();

      // Download all data from Firebase
      await _syncPlayersFromFirebase();
      
      await _syncGamesFromFirebase();
      
      await _syncScoresFromFirebase();
      
      await _syncSettingsFromFirebase();
      
      // Get final stats
      await _dbHelper.getDataCounts();

      await setLastSyncTime();

      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Create backup of current database to Firebase
  Future<bool> createFirebaseBackup({String? backupName}) async {
    try {
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      String backupId = backupName ?? 'backup_$timestamp';
      

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
      
      return true;
    } catch (e) {
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
      return [];
    }
  }
  
  /// Restore from specific backup
  Future<bool> restoreFromBackup(String backupId) async {
    try {

      // Verify backup exists
      DocumentSnapshot backupDoc = await _firestore.collection('backups').doc(backupId).get();
      if (!backupDoc.exists) {
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
        // Games will be restored through game recreation logic
      }
      
      await setLastSyncTime();
      return true;
    } catch (e) {
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
  }
  
  /// Handle real-time game results
  void _handleRealTimeGameResults(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        // Process new game results here
      }
    }
  }

  /// Simple method to upload damaged tablet database to Firebase
  /// Call this method to force upload all local data to Firebase
  Future<bool> uploadDamagedDatabaseToFirebase() async {
    try {

      // Force enable sync
      await setSyncEnabled(true);
      
      // Test connection
      bool canConnect = await testFirebaseConnection();
      if (!canConnect) {
        return false;
      }
      
      // Try to authenticate, but continue if it fails (for existing Firebase setups)
      User? user = getCurrentUser();
      if (user == null) {
        try {
          user = await signInAnonymously();
          if (user != null) {
          }
        } catch (e) {
        }
      }
      
      // Upload all data (this may work even without auth if Firebase rules allow it)
      await _syncPlayersToFirebase();
      
      await _syncGamesToFirebase();
      
      await _syncScoresToFirebase();
      
      await _syncSettingsToFirebase();
      
      return true;
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED')) {
      }
      return false;
    }
  }

  /// Restore data from damaged tablet collections
  Future<bool> restoreDamagedTabletData() async {
    try {

      // Test connection first
      bool canConnect = await testFirebaseConnection();
      if (!canConnect) {
        return false;
      }

      // Get current data counts before restore
      await _dbHelper.getDataCounts();

      // Restore players from damaged tablet collection
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
          }
        } catch (e) {
        }
      }

      // Restore scores from damaged tablet collection
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
          }
        } catch (e) {
        }
      }

      // Restore golf courses
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
        }
      }

      // Restore course info
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
        }
      }

      // Restore settings
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
        }
      }

      // Get final data counts
      Map<String, int> afterCounts = await _dbHelper.getDataCounts();

      await setLastSyncTime();
      

      return true;
      
    } catch (e) {
      return false;
    }
  }
}