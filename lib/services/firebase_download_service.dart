import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/league.dart';
import 'database_helper.dart';

/// Service for downloading data from Firebase into the local database
/// Handles initial data population for each league
class FirebaseDownloadService {
  static final FirebaseDownloadService _instance = FirebaseDownloadService._internal();
  factory FirebaseDownloadService() => _instance;
  FirebaseDownloadService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Download all Monday league data from Firebase
  /// This includes players (only if local DB is empty), scores, and golf courses
  Future<Map<String, dynamic>> downloadMondayLeagueData() async {
    debugPrint('=== DOWNLOADING MONDAY LEAGUE DATA FROM FIREBASE ===');

    int playersDownloaded = 0;
    int scoresDownloaded = 0;
    int coursesDownloaded = 0;
    List<String> errors = [];

    try {
      // Only download player profiles on a fresh install (no players in local DB).
      // On existing installs, local SK# values are authoritative — downloading would
      // overwrite them with potentially stale Firebase data.
      final db = await _dbHelper.database;
      final existingPlayers = await db.query('players',
          where: 'league = ? OR league = ?',
          whereArgs: ['monday', 'both'],
          limit: 1);
      if (existingPlayers.isEmpty) {
        final playersResult = await _downloadMondayPlayers();
        playersDownloaded = playersResult['count'] as int;
        if (playersResult['errors'] != null) {
          errors.addAll(playersResult['errors'] as List<String>);
        }
      } else {
        debugPrint('Monday players already in local DB — skipping player profile download');
      }

      // Download Monday scores from M_player_scores
      final scoresResult = await _downloadMondayScores();
      scoresDownloaded = scoresResult['count'] as int;
      if (scoresResult['errors'] != null) {
        errors.addAll(scoresResult['errors'] as List<String>);
      }

      // Download Monday golf courses from M_golf_course
      final coursesResult = await _downloadMondayGolfCourses();
      coursesDownloaded = coursesResult['count'] as int;
      if (coursesResult['errors'] != null) {
        errors.addAll(coursesResult['errors'] as List<String>);
      }

      debugPrint('✓ Monday league download complete: $playersDownloaded players, $scoresDownloaded scores, $coursesDownloaded courses');

      return {
        'success': true,
        'players': playersDownloaded,
        'scores': scoresDownloaded,
        'courses': coursesDownloaded,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('✗ Error downloading Monday league data: $e');
      errors.add('Critical error: $e');
      return {
        'success': false,
        'players': playersDownloaded,
        'scores': scoresDownloaded,
        'courses': coursesDownloaded,
        'errors': errors,
      };
    }
  }

  /// Download all Wednesday league data from Firebase
  /// This includes players (only if local DB is empty) and scores
  Future<Map<String, dynamic>> downloadWednesdayLeagueData() async {
    debugPrint('=== DOWNLOADING WEDNESDAY LEAGUE DATA FROM FIREBASE ===');

    int playersDownloaded = 0;
    int scoresDownloaded = 0;
    List<String> errors = [];

    try {
      // Only download player profiles on a fresh install (no players in local DB).
      // On existing installs, local HC values are authoritative — downloading would
      // overwrite them with potentially stale Firebase data.
      final db = await _dbHelper.database;
      final existingPlayers = await db.query('players',
          where: 'league = ? OR league = ?',
          whereArgs: ['wednesday', 'both'],
          limit: 1);
      if (existingPlayers.isEmpty) {
        final playersResult = await _downloadWednesdayPlayers();
        playersDownloaded = playersResult['count'] as int;
        if (playersResult['errors'] != null) {
          errors.addAll(playersResult['errors'] as List<String>);
        }
      } else {
        debugPrint('Wednesday players already in local DB — skipping player profile download');
      }

      // Download Wednesday scores from W_player_scores
      final scoresResult = await _downloadWednesdayScores();
      scoresDownloaded = scoresResult['count'] as int;
      if (scoresResult['errors'] != null) {
        errors.addAll(scoresResult['errors'] as List<String>);
      }

      debugPrint('✓ Wednesday league download complete: $playersDownloaded players, $scoresDownloaded scores');

      return {
        'success': true,
        'players': playersDownloaded,
        'scores': scoresDownloaded,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('✗ Error downloading Wednesday league data: $e');
      errors.add('Critical error: $e');
      return {
        'success': false,
        'players': playersDownloaded,
        'scores': scoresDownloaded,
        'errors': errors,
      };
    }
  }

  /// Download Monday players from M_player_profile collection
  Future<Map<String, dynamic>> _downloadMondayPlayers() async {
    int count = 0;
    List<String> errors = [];

    try {
      debugPrint('Downloading Monday players from M_player_profile...');
      QuerySnapshot snapshot = await _firestore.collection('M_player_profile').get();

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Map Firebase fields to local database fields
          Map<String, dynamic> playerData = {
            'player_number': data['player_number'],
            'first': data['first'] ?? '',
            'last': data['last'] ?? '',
            'skat_number': data['skat_number'],
            'cell': data['cell'],
            'email': data['email'],
            'league': 'monday',
          };

          // Remove null values
          playerData.removeWhere((key, value) => value == null);

          // Insert into local database
          await _dbHelper.insertPlayer(playerData);
          count++;
        } catch (e) {
          errors.add('Error importing player ${doc.id}: $e');
        }
      }

      debugPrint('Downloaded $count Monday players');
      return {'count': count, 'errors': errors};
    } catch (e) {
      errors.add('Error downloading Monday players: $e');
      return {'count': count, 'errors': errors};
    }
  }

  /// Download Wednesday players from W_player_profile collection
  Future<Map<String, dynamic>> _downloadWednesdayPlayers() async {
    int count = 0;
    List<String> errors = [];

    try {
      debugPrint('Downloading Wednesday players from W_player_profile...');
      QuerySnapshot snapshot = await _firestore.collection('W_player_profile').get();

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Map Firebase fields to local database fields
          Map<String, dynamic> playerData = {
            'player_number': data['player_number'],
            'first': data['first'] ?? '',
            'last': data['last'] ?? '',
            'HC': data['HC'],
            'OHC': data['OHC'],
            'cell': data['cell'],
            'email': data['email'],
            'league': 'wednesday',
          };

          // Remove null values
          playerData.removeWhere((key, value) => value == null);

          // Insert into local database
          await _dbHelper.insertPlayer(playerData);
          count++;
        } catch (e) {
          errors.add('Error importing player ${doc.id}: $e');
        }
      }

      debugPrint('Downloaded $count Wednesday players');
      return {'count': count, 'errors': errors};
    } catch (e) {
      errors.add('Error downloading Wednesday players: $e');
      return {'count': count, 'errors': errors};
    }
  }

  /// Download Monday scores from M_player_scores collection
  Future<Map<String, dynamic>> _downloadMondayScores() async {
    int count = 0;
    List<String> errors = [];

    try {
      debugPrint('Downloading Monday scores from M_player_scores...');
      QuerySnapshot snapshot = await _firestore.collection('M_player_scores').get();

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Parse currency values (remove $ and convert to double)
          double parseCurrency(dynamic value) {
            if (value == null) return 0.0;
            String str = value.toString().replaceAll('\$', '').trim();
            return double.tryParse(str) ?? 0.0;
          }

          // Map Firebase fields to local database fields
          Map<String, dynamic> scoreData = {
            'player_id': data['player_id'],
            'name': data['name'],
            'date_played': data['date_played'],
            'golf_course': data['golf_course'],
            'S_SK': data['S_SK'],
            'SKATS': data['SKATS'],
            'DIFF': data['DIFF'],
            'New_SK': data['New_SK'],
            'close_pin_winnings': parseCurrency(data['Close Pin Winnings']),
            'skat_winnings': parseCurrency(data['SKAT Winnings']),
          };

          // Remove null values
          scoreData.removeWhere((key, value) => value == null);

          // Insert only if no existing record for this player+date
          final db = await _dbHelper.database;
          final existing = await db.query('monday_scores',
              where: 'player_id = ? AND date_played = ?',
              whereArgs: [scoreData['player_id'], scoreData['date_played']]);
          if (existing.isEmpty) {
            await db.insert('monday_scores', scoreData);
            count++;
          }
        } catch (e) {
          errors.add('Error importing score ${doc.id}: $e');
        }
      }

      debugPrint('Downloaded $count Monday scores');
      return {'count': count, 'errors': errors};
    } catch (e) {
      errors.add('Error downloading Monday scores: $e');
      return {'count': count, 'errors': errors};
    }
  }

  /// Download Wednesday scores from W_player_scores collection
  Future<Map<String, dynamic>> _downloadWednesdayScores() async {
    int count = 0;
    List<String> errors = [];

    try {
      debugPrint('Downloading Wednesday scores from W_player_scores...');
      QuerySnapshot snapshot = await _firestore.collection('W_player_scores').get();

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Map Firebase fields to local database fields
          Map<String, dynamic> scoreData = {
            'player_id': data['player_id'],
            'name': data['name'],
            'date_played': data['date_played'],
            'golf_course': data['golf_course'] ?? 'The Hideout',
            'handicap': data['handicap'],
            'gross_score': data['gross_score'],
            'close_pin_winnings': data['close_pin_winnings'] ?? 0.0,
            'single_winnings': data['single_winnings'] ?? 0.0,
            'group_winnings': data['group_winnings'] ?? 0.0,
            'ind_pos': data['ind_pos'],
            'grp_pos': data['grp_pos'],
            'prize_money': data['prize_money'],
          };

          // Remove null values
          scoreData.removeWhere((key, value) => value == null);

          // Insert only if no existing record for this player+date
          final db = await _dbHelper.database;
          final existing = await db.query('wednesday_scores',
              where: 'player_id = ? AND date_played = ?',
              whereArgs: [scoreData['player_id'], scoreData['date_played']]);
          if (existing.isEmpty) {
            await db.insert('wednesday_scores', scoreData);
            count++;
          }
        } catch (e) {
          errors.add('Error importing score ${doc.id}: $e');
        }
      }

      debugPrint('Downloaded $count Wednesday scores');
      return {'count': count, 'errors': errors};
    } catch (e) {
      errors.add('Error downloading Wednesday scores: $e');
      return {'count': count, 'errors': errors};
    }
  }

  /// Download Monday golf courses from M_golf_course collection
  Future<Map<String, dynamic>> _downloadMondayGolfCourses() async {
    int count = 0;
    List<String> errors = [];

    try {
      debugPrint('Downloading Monday golf courses from M_golf_course...');
      QuerySnapshot snapshot = await _firestore.collection('M_golf_course').get();

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Map Firebase fields to local database fields
          Map<String, dynamic> courseData = {
            'name': data['name'],
            'phone': data['phone'],
            'Par3s': data['Par3s'],
            'tees': data['tees'],
            'travel_time': data['travel_time'],
          };

          // Remove null values
          courseData.removeWhere((key, value) => value == null);

          // Insert into golf_courses table
          await _dbHelper.insertGolfCourse(courseData);
          count++;
        } catch (e) {
          errors.add('Error importing golf course ${doc.id}: $e');
        }
      }

      debugPrint('Downloaded $count Monday golf courses');
      return {'count': count, 'errors': errors};
    } catch (e) {
      errors.add('Error downloading Monday golf courses: $e');
      return {'count': count, 'errors': errors};
    }
  }

  /// Check if Monday league has any local data
  Future<bool> hasMondayData() async {
    try {
      final players = await _dbHelper.getPlayersByLeague(League.monday);
      return players.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if Wednesday league has any local data
  Future<bool> hasWednesdayData() async {
    try {
      final players = await _dbHelper.getPlayersByLeague(League.wednesday);
      return players.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get a player's starting handicap (OHC) from W_starting_OHC collection
  /// Returns null if not found or on error
  Future<double?> getStartingHandicap(String lastName) async {
    try {
      // Use cleaned last name as document ID
      final docId = lastName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      final doc = await _firestore.collection('W_starting_OHC').doc(docId).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['OHC'] != null) {
          return (data['OHC'] as num).toDouble();
        }
      }

      debugPrint('No OHC found for $lastName in W_starting_OHC');
      return null;
    } catch (e) {
      debugPrint('Error getting OHC for $lastName: $e');
      return null;
    }
  }

  /// Get a player's starting handicap (OHC) by player number from W_starting_OHC
  /// Returns null if not found or on error
  Future<double?> getStartingHandicapByPlayerNumber(int playerNumber) async {
    try {
      final snapshot = await _firestore
          .collection('W_starting_OHC')
          .where('player_number', isEqualTo: playerNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data['OHC'] != null) {
          return (data['OHC'] as num).toDouble();
        }
      }

      debugPrint('No OHC found for player number $playerNumber in W_starting_OHC');
      return null;
    } catch (e) {
      debugPrint('Error getting OHC for player number $playerNumber: $e');
      return null;
    }
  }

  /// Get all starting handicaps from W_starting_OHC collection
  /// Returns a map of lastName -> OHC value
  Future<Map<String, double>> getAllStartingHandicaps() async {
    final Map<String, double> handicaps = {};

    try {
      final snapshot = await _firestore.collection('W_starting_OHC').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastName = data['Last Name']?.toString() ?? '';
        final handicap = data['OHC'];

        if (lastName.isNotEmpty && handicap != null) {
          handicaps[lastName] = (handicap as num).toDouble();
        }
      }

      debugPrint('Retrieved ${handicaps.length} starting handicaps from W_starting_OHC');
      return handicaps;
    } catch (e) {
      debugPrint('Error getting all starting handicaps: $e');
      return handicaps;
    }
  }
}
