import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/league.dart';
import 'database_helper.dart';

/// Service for importing player data from Firebase into the local database
/// Specifically handles importing Monday league players into Wednesday league
class FirebasePlayerImportService {
  static final FirebasePlayerImportService _instance = FirebasePlayerImportService._internal();
  factory FirebasePlayerImportService() => _instance;
  FirebasePlayerImportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Download Monday players from Firebase M_player_profile collection
  /// and add them to the Wednesday league in the local database
  ///
  /// Returns a map with:
  /// - 'success': bool indicating if operation completed successfully
  /// - 'total_downloaded': int number of players downloaded from Firebase
  /// - 'total_imported': int number of players successfully added to database
  /// - 'errors': List<String> any errors encountered
  /// - 'skipped': List<String> players that were skipped (already exist)
  Future<Map<String, dynamic>> importMondayPlayersToWednesday({
    bool skipExisting = true,
    bool updateExisting = false,
  }) async {
    int totalDownloaded = 0;
    int totalImported = 0;
    List<String> errors = [];
    List<String> skipped = [];

    try {
      print('Starting import of Monday players from Firebase M_player_profile collection...');

      // Download all players from M_player_profile collection
      QuerySnapshot snapshot = await _firestore.collection('M_player_profile').get();

      totalDownloaded = snapshot.docs.length;
      print('Downloaded $totalDownloaded players from Firebase M_player_profile collection');

      if (snapshot.docs.isEmpty) {
        print('No players found in M_player_profile collection');
        return {
          'success': true,
          'total_downloaded': 0,
          'total_imported': 0,
          'errors': ['No players found in M_player_profile collection'],
          'skipped': [],
        };
      }

      // Process each player document
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> firebaseData = doc.data() as Map<String, dynamic>;

          // Extract player data from Firebase document
          // Firebase may use different field names, so we'll try to map them
          String firstName = firebaseData['first'] ?? firebaseData['first_name'] ?? '';
          String lastName = firebaseData['last'] ?? firebaseData['last_name'] ?? '';
          int? skatNumber = firebaseData['skat_number'] as int?;
          int? playerNumber = firebaseData['player_number'] as int?;
          String? cell = firebaseData['cell'] ?? firebaseData['phone'];
          String? email = firebaseData['email'];

          // Validate required fields
          if (firstName.isEmpty || lastName.isEmpty) {
            errors.add('Skipping player with missing name: ${doc.id}');
            continue;
          }

          // Check if player already exists in Wednesday league
          if (skipExisting || updateExisting) {
            List<Map<String, dynamic>> existingPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);

            bool playerExists = existingPlayers.any((p) =>
              p['first'] == firstName &&
              p['last'] == lastName
            );

            if (playerExists) {
              if (skipExisting && !updateExisting) {
                skipped.add('$firstName $lastName (already exists)');
                print('Skipping existing player: $firstName $lastName');
                continue;
              } else if (updateExisting) {
                // Find the existing player and update
                var existingPlayer = existingPlayers.firstWhere((p) =>
                  p['first'] == firstName && p['last'] == lastName
                );

                Map<String, dynamic> updateData = {
                  'first': firstName,
                  'last': lastName,
                  'skat_number': skatNumber,
                  'cell': cell,
                  'email': email,
                  'league': 'wednesday',
                };

                await _dbHelper.updatePlayer(existingPlayer['player_number'], updateData);
                print('Updated existing player: $firstName $lastName');
                totalImported++;
                continue;
              }
            }
          }

          // Generate a new player_number if not provided
          // For Wednesday league, use 200+ range to avoid conflicts with Monday league
          if (playerNumber == null) {
            List<Map<String, dynamic>> wednesdayPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);

            // Find the highest player_number in Wednesday league
            int maxPlayerNumber = 200; // Start at 200 for Wednesday league
            for (var player in wednesdayPlayers) {
              int pNum = player['player_number'] ?? 0;
              if (pNum > maxPlayerNumber) {
                maxPlayerNumber = pNum;
              }
            }

            playerNumber = maxPlayerNumber + 1;
          }

          // Create player data for Wednesday league
          Map<String, dynamic> playerData = {
            'player_number': playerNumber,
            'first': firstName,
            'last': lastName,
            'skat_number': skatNumber,
            'cell': cell,
            'email': email,
            'league': 'wednesday', // Force league to Wednesday
          };

          // Insert player into database
          await _dbHelper.insertPlayer(playerData);
          totalImported++;
          print('Imported player #$totalImported: $firstName $lastName (player_number: $playerNumber)');

        } catch (e) {
          String errorMsg = 'Error importing player ${doc.id}: $e';
          errors.add(errorMsg);
          print(errorMsg);
        }
      }

      print('Import completed: $totalImported/$totalDownloaded players imported successfully');

      return {
        'success': true,
        'total_downloaded': totalDownloaded,
        'total_imported': totalImported,
        'errors': errors,
        'skipped': skipped,
      };

    } catch (e) {
      String errorMsg = 'CRITICAL ERROR during import: $e';
      print(errorMsg);
      errors.add(errorMsg);

      return {
        'success': false,
        'total_downloaded': totalDownloaded,
        'total_imported': totalImported,
        'errors': errors,
        'skipped': skipped,
      };
    }
  }

  /// Get count of players in M_player_profile collection
  Future<int> getMondayPlayerCount() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('M_player_profile').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting Monday player count: $e');
      return 0;
    }
  }

  /// Preview Monday players from Firebase without importing
  Future<List<Map<String, dynamic>>> previewMondayPlayers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('M_player_profile').get();

      List<Map<String, dynamic>> players = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        players.add({
          'firebase_id': doc.id,
          'first': data['first'] ?? data['first_name'] ?? '',
          'last': data['last'] ?? data['last_name'] ?? '',
          'skat_number': data['skat_number'],
          'player_number': data['player_number'],
          'cell': data['cell'] ?? data['phone'],
          'email': data['email'],
        });
      }

      return players;
    } catch (e) {
      print('Error previewing Monday players: $e');
      return [];
    }
  }

  /// Test Firebase connection to M_player_profile collection
  Future<bool> testMondayPlayerCollectionAccess() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('M_player_profile').limit(1).get();
      print('Successfully accessed M_player_profile collection');
      return true;
    } catch (e) {
      print('Failed to access M_player_profile collection: $e');
      return false;
    }
  }
}
