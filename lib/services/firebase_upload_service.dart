import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/email_config.dart';
import '../models/league.dart';
import 'database_helper.dart';
import 'upload_queue_service.dart';

class FirebaseUploadService {
  static final FirebaseUploadService _instance = FirebaseUploadService._internal();
  static FirebaseFirestore? _firestore;

  /// Global flag to disable all Firebase uploads
  static bool uploadsEnabled = true;

  /// Returns true if any admin checkbox is in a non-normal state (any screen should show red app bar)
  static bool get anyAdminOverrideActive =>
      !uploadsEnabled || DatabaseHelper.allowDuplicateDates || EmailConfig.testEmailMode;

  /// SharedPreferences key for storing the uploads enabled state
  static const String _uploadsEnabledKey = 'firebase_uploads_enabled';

  factory FirebaseUploadService() => _instance;
  FirebaseUploadService._internal() {
    loadUploadsEnabledState();
  }

  /// Load the uploads enabled state from SharedPreferences
  static Future<void> loadUploadsEnabledState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      uploadsEnabled = prefs.getBool(_uploadsEnabledKey) ?? true;
    } catch (e) {
      debugPrint('Error loading uploads enabled state: $e');
      uploadsEnabled = true; // Default to enabled on error
    }
  }

  /// Save the uploads enabled state to SharedPreferences
  static Future<void> saveUploadsEnabledState(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_uploadsEnabledKey, enabled);
      uploadsEnabled = enabled;
    } catch (e) {
      debugPrint('Error saving uploads enabled state: $e');
    }
  }

  final UploadQueueService _uploadQueueService = UploadQueueService();
  
  Future<FirebaseFirestore> get firestore async {
    if (_firestore == null) {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
    }
    return _firestore!;
  }

  /// Uploads player table data to Firebase
  Future<bool> uploadPlayerTable(League league) async {
    if (!uploadsEnabled) {
      return false;
    }

    try {
      final db = await firestore;
      final databaseHelper = DatabaseHelper();
      
      // Get all players for the specified league
      final players = await databaseHelper.getPlayersByLeague(league);
      
      if (players.isEmpty) {
        return true; // Not an error if no players exist
      }
      
      // Create a batch operation for efficient upload
      final batch = db.batch();
      
      // Upload to league-specific player profile collection
      final collectionName = league == League.monday ? 'M_player_profile' : 'W_player_profile';
      final collection = db.collection(collectionName);
      
      // Add each player to the batch
      for (final player in players) {
        // Use different document ID formats for each league
        final lastName = (player['last'] ?? '').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        
        String docId;
        if (league == League.monday) {
          // For Monday (M_player_profile): use just the last name
          docId = lastName;
        } else {
          // For Wednesday (W_player_profile): use just the last name
          docId = lastName;
        }
        
        final docRef = collection.doc(docId);
        
        // Prepare data for Firebase with different field sets for each league
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
        
        batch.set(docRef, firebaseData, SetOptions(merge: true));
      }
      
      // Execute the batch operation
      await batch.commit();
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Uploads golf course table data to Firebase
  Future<bool> uploadGolfCourseTable(League league) async {
    if (!uploadsEnabled) {
      return false;
    }

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
    if (!uploadsEnabled) {
      return false;
    }

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
    if (!uploadsEnabled) {
      return false;
    }

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
    if (!uploadsEnabled) {
      return false;
    }

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

  /// Check if WiFi is connected
  Future<bool> _isWiFiConnected() async {
    try {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  /// Queue upload for later when no WiFi connection
  Future<bool> _queueUpload(UploadType uploadType, League league) async {
    try {
      await _uploadQueueService.queueUpload(
        uploadType: uploadType,
        league: league,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadPlayerTableWithQueue(League league) async {
    if (!uploadsEnabled) {
      return false;
    }

    if (await _isWiFiConnected()) {
      return await uploadPlayerTable(league);
    } else {
      return await _queueUpload(UploadType.players, league);
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadGolfCourseTableWithQueue(League league) async {
    if (!uploadsEnabled) {
      return false;
    }

    if (await _isWiFiConnected()) {
      return await uploadGolfCourseTable(league);
    } else {
      return await _queueUpload(UploadType.golfCourses, league);
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadPlayerScoresTableWithQueue(League league) async {
    if (!uploadsEnabled) {
      return false;
    }

    final isConnected = await _isWiFiConnected();

    if (isConnected) {
      return await uploadPlayerScoresTable(league);
    } else {
      return await _queueUpload(UploadType.scores, league);
    }
  }

  /// Delete a player from Firebase
  Future<bool> deletePlayerFromFirebase(League league, String lastName) async {
    if (!uploadsEnabled) {
      return false;
    }

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
    if (!uploadsEnabled) {
      return false;
    }

    if (await _isWiFiConnected()) {
      return await deletePlayerFromFirebase(league, lastName);
    } else {
      // If no WiFi, we can't delete from Firebase now
      // Return false to indicate offline mode
      return false;
    }
  }

  /// Delete a golf course from Firebase
  Future<bool> deleteGolfCourseFromFirebase(String courseName) async {
    if (!uploadsEnabled) {
      return false;
    }

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
    if (!uploadsEnabled) {
      return false;
    }

    if (await _isWiFiConnected()) {
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