import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  /// Uploads player table data to Firebase
  Future<bool> uploadPlayerTable(League league) async {
    try {
      final db = await firestore;
      final databaseHelper = DatabaseHelper();
      
      // Get all players for the specified league
      final players = await databaseHelper.getPlayersByLeague(league);
      
      if (players.isEmpty) {
        print('No players found for ${league.name} league');
        return true; // Not an error if no players exist
      }
      
      // Create a batch operation for efficient upload
      final batch = db.batch();
      
      // Upload to league-specific player profile collection
      final collectionName = league == League.monday ? 'M_player_profile' : 'wednesday_player_profile';
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
          // For Wednesday: keep the league_lastname format
          docId = 'wednesday_$lastName';
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
          // For Wednesday: include all fields as before
          firebaseData = Map<String, dynamic>.from(player);
          firebaseData['upload_timestamp'] = FieldValue.serverTimestamp();
        }
        
        // Remove any null values
        firebaseData.removeWhere((key, value) => value == null);
        
        batch.set(docRef, firebaseData, SetOptions(merge: true));
      }
      
      // Execute the batch operation
      await batch.commit();
      
      print('Successfully uploaded ${players.length} players for ${league.name} league to Firebase');
      return true;
      
    } catch (e) {
      print('Error uploading player table for ${league.name} league: $e');
      return false;
    }
  }

  /// Uploads golf course table data to Firebase
  Future<bool> uploadGolfCourseTable(League league) async {
    try {
      final db = await firestore;
      final databaseHelper = DatabaseHelper();
      
      // Get all golf courses for the specified league
      final golfCourses = await databaseHelper.getGolfCoursesByLeague(league);
      
      if (golfCourses.isEmpty) {
        print('No golf courses found for ${league.name} league');
        return true; // Not an error if no courses exist
      }
      
      // Create a batch operation for efficient upload
      final batch = db.batch();
      
      // Get collection reference based on league (only Monday has golf courses)
      if (league != League.monday) {
        print('No golf courses collection for ${league.name} league - only Monday league has golf courses');
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
          'Par3s': course['holes'], // Rename "holes" to "Par3s"
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
      
      print('Successfully uploaded ${golfCourses.length} golf courses for ${league.name} league to Firebase');
      return true;
      
    } catch (e) {
      print('Error uploading golf course table for ${league.name} league: $e');
      return false;
    }
  }

  /// Uploads player scores table data to Firebase
  Future<bool> uploadPlayerScoresTable(League league) async {
    try {
      final db = await firestore;
      final databaseHelper = DatabaseHelper();
      
      // Get all player scores for the specified league
      final scores = await databaseHelper.getScoresByLeague(league);
      
      if (scores.isEmpty) {
        print('No scores found for ${league.name} league');
        return true; // Not an error if no scores exist
      }
      
      // Create a batch operation for efficient upload
      final batch = db.batch();
      
      // Get collection reference based on league
      final collectionName = league == League.monday ? 'M_player_scores' : 'wednesday_player_scores';
      final collection = db.collection(collectionName);
      
      // Add each score record to the batch
      for (final score in scores) {
        // Create document ID in format: MM-DD-YY_PlayerName_ID
        String docId;
        String? wednesdayFormattedDate; // For Wednesday league date formatting
        if (league == League.monday) {
          // For Monday (M_player_scores): use MM-DD-YY_PlayerName_ID format
          final dateStr = score['date_played'] ?? '';
          final playerName = (score['name'] ?? '').toString().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
          final recordId = score['id']?.toString() ?? 'unknown';
          
          // Convert date from YYYY-MM-DD to MM-DD-YY format
          String formattedDate = '';
          if (dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              final month = date.month.toString().padLeft(2, '0');
              final day = date.day.toString().padLeft(2, '0');
              final year = (date.year % 100).toString().padLeft(2, '0');
              formattedDate = '$month-$day-$year';
            } catch (e) {
              formattedDate = 'unknown-date';
            }
          } else {
            formattedDate = 'unknown-date';
          }
          
          // Use player_id + date for consistent document IDs across devices (prevents duplicates)
          docId = '${formattedDate}_${score['player_id']}';
        } else {
          // For Wednesday: use player_id + date for consistency (prevents duplicates)
          if (score['date_played'] != null) {
            try {
              final date = DateTime.parse(score['date_played']);
              wednesdayFormattedDate = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year.toString().substring(2)}';
            } catch (e) {
              wednesdayFormattedDate = 'unknown-date';
            }
          } else {
            wednesdayFormattedDate = 'unknown-date';
          }
          docId = '${wednesdayFormattedDate}_${score['player_id']}';
        }
        
        final docRef = collection.doc(docId);
        
        // Prepare data for Firebase with different field sets for each league
        Map<String, dynamic> firebaseData;
        
        if (league == League.monday) {
          // For Monday (M_player_scores): exclude specific fields and rename others
          
          // Debug logging to check actual values from database
          print('DEBUG: Raw score data from database:');
          print('  close_pin_winnings: ${score['close_pin_winnings']} (${score['close_pin_winnings'].runtimeType})');
          print('  skat_winnings: ${score['skat_winnings']} (${score['skat_winnings'].runtimeType})');
          
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
            'SKAT #': score['skat_number'], // Add SKAT # field
            'Close Pin Winnings': formatCurrency(score['close_pin_winnings']), // Format as currency
            'SKAT Winnings': formatCurrency(score['skat_winnings']), // Format as currency
            'league': score['league'],
            'upload_timestamp': FieldValue.serverTimestamp(),
          };
          
          print('DEBUG: Firebase data being uploaded:');
          print('  Close Pin Winnings: ${firebaseData['Close Pin Winnings']}');
          print('  SKAT Winnings: ${firebaseData['SKAT Winnings']}');
          
          // Check if document already exists to prevent duplicates for Monday league
          // Only check when WiFi is available to avoid blocking offline uploads
          if (await _isWiFiConnected()) {
            try {
              final existingDoc = await docRef.get();
              if (existingDoc.exists) {
                String playerName = score['name']?.toString() ?? 'Unknown';
                String dateFromDocId = docId.split('_')[0]; // Extract date from document ID
                print('Skipping duplicate score upload for $playerName on $dateFromDocId');
                continue; // Skip this score, it already exists in Firebase
              }
            } catch (e) {
              print('Warning: Could not check for existing document: $e');
              // Continue with upload if check fails
            }
          }
        } else {
          // For Wednesday: include all fields as before
          firebaseData = Map<String, dynamic>.from(score);
          firebaseData['upload_timestamp'] = FieldValue.serverTimestamp();
          
          // Check if document already exists to prevent duplicates for Wednesday league
          // Only check when WiFi is available to avoid blocking offline uploads
          if (await _isWiFiConnected()) {
            try {
              final existingDoc = await docRef.get();
              if (existingDoc.exists) {
                String playerName = score['name']?.toString() ?? 'Unknown';
                String formattedDate = wednesdayFormattedDate ?? 'unknown-date';
                print('Skipping duplicate score upload for ${playerName} on ${formattedDate}');
                continue; // Skip this score, it already exists in Firebase
              }
            } catch (e) {
              print('Warning: Could not check for existing Wednesday document: $e');
              // Continue with upload if check fails
            }
          }
        }
        
        // Remove any null values
        firebaseData.removeWhere((key, value) => value == null);
        
        batch.set(docRef, firebaseData, SetOptions(merge: true));
      }
      
      // Execute the batch operation
      await batch.commit();
      
      print('Successfully uploaded ${scores.length} score records for ${league.name} league to Firebase');
      return true;
      
    } catch (e) {
      print('Error uploading player scores table for ${league.name} league: $e');
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
        print('No data to upload for collection: $collectionName');
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
      
      print('Successfully uploaded ${data.length} records to Firebase collection: $collectionName');
      return true;
      
    } catch (e) {
      print('Error uploading data to collection $collectionName: $e');
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
      print('Error checking WiFi connectivity: $e');
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
      print('Upload queued for later: ${uploadType.name} - ${league.name}');
      return true;
    } catch (e) {
      print('Error queuing upload: $e');
      return false;
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadPlayerTableWithQueue(League league) async {
    if (await _isWiFiConnected()) {
      return await uploadPlayerTable(league);
    } else {
      print('No WiFi connection - queuing player table upload for ${league.name}');
      return await _queueUpload(UploadType.players, league);
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadGolfCourseTableWithQueue(League league) async {
    if (await _isWiFiConnected()) {
      return await uploadGolfCourseTable(league);
    } else {
      print('No WiFi connection - queuing golf course table upload for ${league.name}');
      return await _queueUpload(UploadType.golfCourses, league);
    }
  }

  /// Upload with connectivity checking and queuing
  Future<bool> uploadPlayerScoresTableWithQueue(League league) async {
    if (await _isWiFiConnected()) {
      return await uploadPlayerScoresTable(league);
    } else {
      print('No WiFi connection - queuing scores table upload for ${league.name}');
      return await _queueUpload(UploadType.scores, league);
    }
  }

  /// Check Firebase connection status
  Future<bool> isFirebaseConnected() async {
    try {
      final db = await firestore;
      await db.collection('_test').doc('connection').get();
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }
}