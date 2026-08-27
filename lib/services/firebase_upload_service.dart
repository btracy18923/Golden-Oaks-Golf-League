import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/league.dart';
import 'database_helper.dart';
import 'upload_queue_service.dart';

class FirebaseUploadService {
  static final FirebaseUploadService _instance = FirebaseUploadService._internal();
  static FirebaseFirestore? _firestore;

  factory FirebaseUploadService() => _instance;
  FirebaseUploadService._internal();

  final UploadQueueService _uploadQueueService = UploadQueueService();

  Future<FirebaseFirestore> get firestore async {
    if (_firestore == null) {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
    }
    return _firestore!;
  }

  /// Builds the Firebase document ID and field payload for a single player,
  /// per the league-specific field set. Shared by the full-roster and
  /// scoped upload paths so they stay in exact sync.
  (String docId, Map<String, dynamic> data) _playerFirebaseDoc(League league, Map<String, dynamic> player) {
    final lastName = (player['last'] ?? '').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final docId = lastName;

    Map<String, dynamic> firebaseData;
    if (league == League.monday) {
      // For Monday (M_player_profile): match local database field order
      firebaseData = <String, dynamic>{
        'player_number': player['player_number'],  // ID#
        'first': player['first'],                  // First
        'last': player['last'],                    // Last
        'skat_number': player['skat_number'],      // SKAT#
        'cell': player['cell'],                    // Phone
        'email': player['email'],                  // Email
        'upload_timestamp': FieldValue.serverTimestamp(),
      };
    } else {
      // For Wednesday (W_player_profile): exclude skat_number field
      firebaseData = <String, dynamic>{
        'player_number': player['player_number'],  // Player #
        'first': player['first'],                  // First
        'last': player['last'],                    // Last
        'HC': player['HC'],                        // HC
        'cell': player['cell'],                    // Phone
        'email': player['email'],                  // Email
        'league': player['league'],                // League
        'upload_timestamp': FieldValue.serverTimestamp(),
      };
    }

    // Remove any null values
    firebaseData.removeWhere((key, value) => value == null);
    return (docId, firebaseData);
  }

  /// Uploads player table data to Firebase
  ///
  /// Pushes the FULL local roster for [league], overwriting every player's
  /// Firebase doc with whatever this device currently has locally. Only
  /// safe to call when this device's local roster is known to be fresh for
  /// EVERY player, not just the one(s) actually being edited — otherwise a
  /// stale local value for an untouched player (e.g. a handicap this device
  /// hasn't re-synced since another device updated it) silently overwrites
  /// that player's correct Firebase value. For any edit that only concerns
  /// one or a few specific players, use [uploadPlayers] instead so unrelated
  /// players' data can't be clobbered by this device's stale cache.
  Future<bool> uploadPlayerTable(League league) async {
    try {
      final databaseHelper = DatabaseHelper();
      final players = await databaseHelper.getPlayersByLeague(league);
      return await uploadPlayers(league, players);
    } catch (e) {
      return false;
    }
  }

  /// Uploads only the given players' profile docs to Firebase — leaves
  /// every other player's Firebase doc untouched. Use this whenever an
  /// action on this device only actually changed specific player(s), so a
  /// stale local cache for unrelated players can never overwrite their
  /// correct Firebase values (see [uploadPlayerTable] for the full-roster
  /// alternative and why it's riskier).
  Future<bool> uploadPlayers(League league, List<Map<String, dynamic>> players) async {
    try {
      if (players.isEmpty) {
        return true; // Not an error if there's nothing to push
      }

      final db = await firestore;
      final batch = db.batch();
      final collectionName = league == League.monday ? 'M_player_profile' : 'W_player_profile';
      final collection = db.collection(collectionName);

      for (final player in players) {
        final (docId, firebaseData) = _playerFirebaseDoc(league, player);
        batch.set(collection.doc(docId), firebaseData, SetOptions(merge: true));
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Re-fetches each given player's profile doc directly from the Firestore
  /// server (bypassing local persistence cache) and compares the key field
  /// — skat_number for Monday, HC for Wednesday — against the value that
  /// was expected to have just been uploaded.
  ///
  /// This exists because uploadPlayerTable/uploadPlayerTableWithQueue can
  /// report "success" even when the write didn't really land: WithQueue
  /// reports success just for successfully queuing when offline, and a
  /// connectivity blip while "online" (WiFi/mobile-associated but no real
  /// internet) can make the write silently fail inside its own catch block.
  /// Forcing a server read (not cache) here means a failure to even
  /// complete this check is itself meaningful — it means there's currently
  /// no real connectivity to verify anything, not just that data mismatched.
  ///
  /// [expected] is a list of {'name': lastName, 'expected': value} maps.
  /// Throws if Firestore can't be reached at all — callers should treat
  /// that as "couldn't verify yet", distinct from a confirmed mismatch.
  Future<Map<String, dynamic>> verifyPlayerProfileSync(
    League league,
    List<Map<String, dynamic>> expected,
  ) async {
    final db = await firestore;
    final collectionName = league == League.monday ? 'M_player_profile' : 'W_player_profile';
    final fieldName = league == League.monday ? 'skat_number' : 'HC';

    final mismatches = <String>[];
    for (final entry in expected) {
      final name = entry['name'].toString();
      final expectedValue = entry['expected'];
      final docId = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      final doc = await db
          .collection(collectionName)
          .doc(docId)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) {
        mismatches.add('$name (missing in Firebase)');
        continue;
      }

      final actual = doc.data()?[fieldName];
      final actualNum = (actual as num?)?.toDouble();
      final expectedNum = (expectedValue as num?)?.toDouble();
      if (actualNum == null || expectedNum == null || (actualNum - expectedNum).abs() > 0.01) {
        mismatches.add('$name (Firebase has ${actual ?? 'nothing'}, expected $expectedValue)');
      }
    }

    return {'ok': mismatches.isEmpty, 'mismatches': mismatches};
  }

  /// Uploads golf course table data to Firebase
  Future<bool> uploadGolfCourseTable(League league) async {
    try {
      final db = await firestore;
      final databaseHelper = DatabaseHelper();
      
      // Get all golf courses for the specified league
      final golfCourses = await databaseHelper.getGolfCoursesByLeague(league);
      
      if (golfCourses.isEmpty) {
        return true; // Not an error if no courses exist
      }
      
      // Create a batch operation for efficient upload
      final batch = db.batch();
      
      // Get collection reference based on league (only Monday has golf courses)
      if (league != League.monday) {
        return true; // Not an error - Wednesday doesn't have golf courses
      }
      
      final collection = db.collection('M_golf_course');
      
      // Add each golf course to the batch
      for (final course in golfCourses) {
        // Use golf course name as document ID, cleaned for Firebase compatibility
        final courseName = (course['name'] ?? 'Unknown_Course').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        final docRef = collection.doc(courseName);
        
        // Prepare data for Firebase with only specific fields
        final firebaseData = <String, dynamic>{
          'id': course['id'],
          'name': course['name'],
          'phone': course['phone'],
          'Par3s': course['Par3s'],
          'tees': course['tees'],
          'travel_time': course['travel_time'],
          'upload_timestamp': FieldValue.serverTimestamp(),
        };
        
        // Remove any null values
        firebaseData.removeWhere((key, value) => value == null);
        
        batch.set(docRef, firebaseData, SetOptions(merge: true));
      }
      
      // Execute the batch operation
      await batch.commit();
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Uploads player scores table data to Firebase
  Future<bool> uploadPlayerScoresTable(League league) async {
    try {
      final db = await firestore;
      final databaseHelper = DatabaseHelper();

      // Get all player scores for the specified league
      final scoresFromDb = await databaseHelper.getScoresByLeague(league);

      if (scoresFromDb.isEmpty) {
        return true; // Not an error if no scores exist
      }

      // Create a mutable copy of the scores list for sorting
      final scores = List<Map<String, dynamic>>.from(scoresFromDb);

      // Sort scores by date (oldest first, newest last)
      // This ensures oldest dates are uploaded last and appear last in Firebase
      scores.sort((a, b) {
        final dateA = a['date_played']?.toString() ?? '';
        final dateB = b['date_played']?.toString() ?? '';

        // Parse dates for comparison
        try {
          // Dates are in MM/DD/YY format - convert to comparable format
          final partsA = dateA.split('/');
          final partsB = dateB.split('/');

          if (partsA.length == 3 && partsB.length == 3) {
            // Convert to YYYYMMDD format for comparison
            final fullDateA = '20${partsA[2]}${partsA[0].padLeft(2, '0')}${partsA[1].padLeft(2, '0')}';
            final fullDateB = '20${partsB[2]}${partsB[0].padLeft(2, '0')}${partsB[1].padLeft(2, '0')}';
            return fullDateA.compareTo(fullDateB); // Ascending order (oldest first)
          }
        } catch (e) {
          // If parsing fails, keep original order
        }

        return 0;
      });

      // Create a batch operation for efficient upload
      final batch = db.batch();

      // Get collection reference based on league
      final collectionName = league == League.monday ? 'M_player_scores' : 'W_player_scores';
      final collection = db.collection(collectionName);

      // Add each score record to the batch
      for (final score in scores) {
        // Create document ID in format: MM-DD-YY_PlayerName_ID
        String docId;
        String? wednesdayFormattedDate; // For Wednesday league date formatting
        // Build docId as LastName_MM-DD-YY — readable and unique per player per date
        final dateStr = score['date_played']?.toString() ?? '';
        String formattedDate = 'unknown-date';
        try {
          if (dateStr.contains('-')) {
            final date = DateTime.parse(dateStr);
            final month = date.month.toString().padLeft(2, '0');
            final day = date.day.toString().padLeft(2, '0');
            final year = (date.year % 100).toString().padLeft(2, '0');
            formattedDate = '$month-$day-$year';
          } else if (dateStr.contains('/')) {
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              formattedDate = '${parts[0].padLeft(2,'0')}-${parts[1].padLeft(2,'0')}-${parts[2].padLeft(2,'0')}';
            }
          }
        } catch (e) {
          debugPrint('Error parsing date for docId: $dateStr - $e');
        }
        final lastName = (score['name'] ?? 'unknown').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        docId = '${lastName}_$formattedDate';

        final docRef = collection.doc(docId);
        
        // Prepare data for Firebase with different field sets for each league
        Map<String, dynamic> firebaseData;
        
        if (league == League.monday) {
          // For Monday (M_player_scores): exclude specific fields and rename others
          
          // Debug logging to check actual values from database

          // Format currency values
          String formatCurrency(dynamic value) {
            if (value == null || value == 0 || value == 0.0) return '\$0.00';
            double amount = (value is num) ? value.toDouble() : 0.0;
            return '\$${amount.toStringAsFixed(2)}';
          }

          firebaseData = <String, dynamic>{
            'player_id': score['player_id'],
            'name': score['name'],
            'date_played': score['date_played'],
            'golf_course': score['golf_course'],
            'S_SK': score['S_SK'],
            'SKATS': score['SKATS'],
            'DIFF': score['DIFF'],
            'New_SK': score['New_SK'],
            'Close Pin Winnings': formatCurrency(score['close_pin_winnings']),
            'SKAT Winnings': formatCurrency(score['skat_winnings']),
            'upload_timestamp': FieldValue.serverTimestamp(),
          };

        } else {
          // For Wednesday: include all fields as before
          firebaseData = Map<String, dynamic>.from(score);
          firebaseData['upload_timestamp'] = FieldValue.serverTimestamp();

          // Wednesday league always plays at "The Hideout"
          firebaseData['golf_course'] = 'The Hideout';

        }

        // Remove any null values
        firebaseData.removeWhere((key, value) => value == null);

        batch.set(docRef, firebaseData, SetOptions(merge: true));
      }

      // Execute the batch operation
      await batch.commit();
      return true;

    } catch (e) {
      debugPrint('Error uploading scores to Firebase: $e');
      return false;
    }
  }

  /// Deletes player scores from Firebase based on provided score data
  /// Used when old scores are deleted locally to maintain sync
  Future<bool> deletePlayerScoresFromFirebase(
    List<Map<String, dynamic>> scoresToDelete,
    League league
  ) async {
    try {
      final db = await firestore;

      if (scoresToDelete.isEmpty) {
        return true; // Nothing to delete
      }

      // Create a batch operation for efficient deletion
      final batch = db.batch();

      // Get collection reference based on league
      final collectionName = league == League.monday ? 'M_player_scores' : 'W_player_scores';
      final collection = db.collection(collectionName);

      // Add each score deletion to the batch
      for (final score in scoresToDelete) {
        // Create document ID using the same format as upload
        String docId;

        // Build docId using same format as upload: LastName_MM-DD-YY
        final dateStr = score['date_played']?.toString() ?? '';
        String formattedDate = 'unknown-date';
        try {
          if (dateStr.contains('-')) {
            final date = DateTime.parse(dateStr);
            final month = date.month.toString().padLeft(2, '0');
            final day = date.day.toString().padLeft(2, '0');
            final year = (date.year % 100).toString().padLeft(2, '0');
            formattedDate = '$month-$day-$year';
          } else if (dateStr.contains('/')) {
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              formattedDate = '${parts[0].padLeft(2,'0')}-${parts[1].padLeft(2,'0')}-${parts[2].padLeft(2,'0')}';
            }
          }
        } catch (e) {
          debugPrint('Error parsing date for delete docId: $dateStr - $e');
        }
        final lastName = (score['name'] ?? 'unknown').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        docId = '${lastName}_$formattedDate';

        final docRef = collection.doc(docId);
        batch.delete(docRef);
      }

      // Execute the batch deletion
      await batch.commit();
      return true;

    } catch (e) {
      debugPrint('Error deleting scores from Firebase: $e');
      return false;
    }
  }

  /// Generic method to upload any table data to Firebase
  Future<bool> uploadTableData({
    required String collectionName,
    required List<Map<String, dynamic>> data,
    String? documentIdField,
  }) async {
    try {
      final db = await firestore;

      if (data.isEmpty) {
        return true;
      }

      // Create a batch operation for efficient upload
      final batch = db.batch();
      final collection = db.collection(collectionName);

      // Add each record to the batch
      for (int i = 0; i < data.length; i++) {
        final record = data[i];
        
        // Determine document ID
        String docId;
        if (documentIdField != null && record.containsKey(documentIdField)) {
          docId = record[documentIdField].toString();
        } else if (record.containsKey('id')) {
          docId = record['id'].toString();
        } else {
          docId = 'record_$i'; // fallback
        }
        
        final docRef = collection.doc(docId);
        
        // Prepare data for Firebase
        final firebaseData = Map<String, dynamic>.from(record);
        firebaseData['upload_timestamp'] = FieldValue.serverTimestamp();
        
        batch.set(docRef, firebaseData, SetOptions(merge: true));
      }
      
      // Execute the batch operation
      await batch.commit();
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Check if connected to WiFi or mobile data
  Future<bool> _isOnline() async {
    try {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile);
    } catch (e) {
      return false;
    }
  }

  /// Queue upload for later when there's no connection
  Future<bool> _queueUpload(UploadType uploadType, League league, {List<int>? playerNumbers}) async {
    try {
      await _uploadQueueService.queueUpload(
        uploadType: uploadType,
        league: league,
        playerNumbers: playerNumbers,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadPlayerTableWithQueue(League league) async {
    if (await _isOnline()) {
      return await uploadPlayerTable(league);
    } else {
      return await _queueUpload(UploadType.players, league);
    }
  }

  /// Scoped version of [uploadPlayerTableWithQueue] — only pushes the given
  /// players, online or queued for retry, so this device's cache for
  /// everyone else can never overwrite their correct Firebase values. This
  /// is the one to use for any edit that only concerns specific player(s)
  /// (score entry, a profile edit, a single-player handicap recalc) —
  /// reserve the full-roster version for genuinely bulk operations.
  Future<bool> uploadPlayersWithQueue(League league, List<Map<String, dynamic>> players) async {
    if (players.isEmpty) return true;
    if (await _isOnline()) {
      return await uploadPlayers(league, players);
    } else {
      final playerNumbers = players
          .map((p) => p['player_number'])
          .whereType<int>()
          .toList();
      return await _queueUpload(UploadType.players, league, playerNumbers: playerNumbers);
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadGolfCourseTableWithQueue(League league) async {
    if (await _isOnline()) {
      return await uploadGolfCourseTable(league);
    } else {
      return await _queueUpload(UploadType.golfCourses, league);
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadPlayerScoresTableWithQueue(League league) async {
    final isConnected = await _isOnline();

    if (isConnected) {
      return await uploadPlayerScoresTable(league);
    } else {
      return await _queueUpload(UploadType.scores, league);
    }
  }

  /// Delete a player from Firebase
  Future<bool> deletePlayerFromFirebase(League league, String lastName) async {
    try {
      final db = await firestore;

      // Get collection reference based on league
      final collectionName = league == League.monday ? 'M_player_profile' : 'W_player_profile';
      final collection = db.collection(collectionName);

      // Clean the last name for document ID (same logic as upload)
      final cleanedLastName = lastName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      // Delete the document
      await collection.doc(cleanedLastName).delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a player from Firebase with connectivity checking
  Future<bool> deletePlayerFromFirebaseWithQueue(League league, String lastName) async {
    if (await _isOnline()) {
      return await deletePlayerFromFirebase(league, lastName);
    } else {
      // If no WiFi, we can't delete from Firebase now
      // Return false to indicate offline mode
      return false;
    }
  }

  /// Delete a golf course from Firebase
  Future<bool> deleteGolfCourseFromFirebase(String courseName) async {
    try {
      final db = await firestore;

      // Only Monday has golf courses in Firebase
      final collection = db.collection('M_golf_course');

      // Clean the course name for document ID (same logic as upload)
      final cleanedCourseName = courseName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      // Delete the document
      await collection.doc(cleanedCourseName).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting golf course from Firebase: $e');
      return false;
    }
  }

  /// Delete a golf course from Firebase with connectivity checking
  Future<bool> deleteGolfCourseFromFirebaseWithQueue(String courseName) async {
    if (await _isOnline()) {
      return await deleteGolfCourseFromFirebase(courseName);
    } else {
      // If no WiFi, we can't delete from Firebase now
      return false;
    }
  }

  /// Check Firebase connection status
  Future<bool> isFirebaseConnected() async {
    try {
      final db = await firestore;
      await db.collection('_test').doc('connection').get();
      return true;
    } catch (e) {
      return false;
    }
  }

}