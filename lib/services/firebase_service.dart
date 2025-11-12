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
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
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

      User? user = getCurrentUser();
      if (user == null) {
        user = await signInAnonymously();
        if (user == null) {
          print('Failed to authenticate with Firebase');
          return false;
        }
      }

      // Sync players
      await _syncPlayersToFirebase();
      
      // Sync games
      await _syncGamesToFirebase();
      
      // Sync scores
      await _syncScoresToFirebase();
      
      // Sync settings
      await _syncSettingsToFirebase();

      print('Successfully synced all data to Firebase');
      return true;
    } catch (e) {
      print('Error syncing to Firebase: $e');
      return false;
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
  Future<void> startAutoSync({Duration interval = const Duration(minutes: 5)}) async {
    // This would typically use a background service or timer
    // For demo purposes, we'll just sync once
    await syncToFirebase();
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
}