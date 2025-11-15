import 'dart:convert';
import 'dart:io';
import '../services/database_helper.dart';
import '../models/league.dart';

class DataMigration {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Main migration function
  static Future<bool> migrateFromExportedData(String exportFilePath) async {
    try {
      
      // Read exported data
      Map<String, dynamic> exportData = await _readExportFile(exportFilePath);
      if (exportData.isEmpty) {
        return false;
      }
      
      
      // Clear existing data (optional - comment out to keep sample data)
      // await _dbHelper.clearAllData();
      
      // Migrate each table
      bool success = true;
      
      if (exportData['tables']['players'] != null) {
        success &= await _migratePlayers(exportData['tables']['players']);
      }
      
      if (exportData['tables']['scores'] != null) {
        success &= await _migrateScores(exportData['tables']['scores']);
      }
      
      if (exportData['tables']['games'] != null) {
        success &= await _migrateGames(exportData['tables']['games']);
      }
      
      // Add other tables as needed
      
      return success;
      
    } catch (e) {
      return false;
    }
  }

  /// Read the exported JSON file
  static Future<Map<String, dynamic>> _readExportFile(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        return {};
      }
      
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);
      
      
      return data;
    } catch (e) {
      return {};
    }
  }

  /// Migrate players data
  static Future<bool> _migratePlayers(Map<String, dynamic> playersTable) async {
    try {
      List<dynamic> playerData = playersTable['data'] ?? [];
      
      for (var playerRow in playerData) {
        Map<String, dynamic> player = Map<String, dynamic>.from(playerRow);
        
        // Map old structure to new structure
        Map<String, dynamic> migratedPlayer = await _mapPlayerData(player);
        
        if (migratedPlayer.isNotEmpty) {
          try {
            await _dbHelper.insertPlayer(migratedPlayer);
          } catch (e) {
            // Handle insertion error silently
          }
        }
      }
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Map old player data structure to new structure
  static Future<Map<String, dynamic>> _mapPlayerData(Map<String, dynamic> oldPlayer) async {
    try {
      // Determine league based on data patterns or add logic here
      String league = _determineLegueFromPlayer(oldPlayer);
      
      Map<String, dynamic> newPlayer = {
        'first': oldPlayer['first'] ?? '',
        'last': oldPlayer['last'] ?? '',
        'handicap': _parseDouble(oldPlayer['handicap']),
        'skat_number': _parseInt(oldPlayer['skat_number']),
        'league': league,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Remove any null/empty required fields
      if (newPlayer['first'].toString().isEmpty || newPlayer['last'].toString().isEmpty) {
        return {};
      }
      
      return newPlayer;
      
    } catch (e) {
      return {};
    }
  }

  /// Determine league from player data
  static String _determineLegueFromPlayer(Map<String, dynamic> player) {
    // Logic to determine league - you may need to adjust this based on your data
    
    // Option 1: Check if there's a league field
    if (player['league'] != null) {
      String league = player['league'].toString().toLowerCase();
      if (league.contains('monday')) return 'monday';
      if (league.contains('wednesday')) return 'wednesday';
    }
    
    // Option 2: Check skat_number (Monday players might have skat numbers)
    if (player['skat_number'] != null && player['skat_number'] != '') {
      return 'monday';
    }
    
    // Option 3: Default to Wednesday if no skat number
    return 'wednesday';
  }

  /// Migrate scores data
  static Future<bool> _migrateScores(Map<String, dynamic> scoresTable) async {
    try {
      List<dynamic> scoresData = scoresTable['data'] ?? [];
      
      for (var scoreRow in scoresData) {
        Map<String, dynamic> score = Map<String, dynamic>.from(scoreRow);
        
        // Map old structure to new structure
        Map<String, dynamic> migratedScore = _mapScoreData(score);
        
        if (migratedScore.isNotEmpty) {
          try {
            await _dbHelper.insertScore(migratedScore);
          } catch (e) {
            // Handle insertion error silently
          }
        }
      }
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Map old score data structure to new structure
  static Map<String, dynamic> _mapScoreData(Map<String, dynamic> oldScore) {
    try {
      return {
        'player_id': _parseInt(oldScore['player_id']),
        'gross_score': _parseInt(oldScore['gross_score']),
        'net_score': _parseDouble(oldScore['net_score']),
        'skats_score': _parseInt(oldScore['skats_score']),
        'date_played': oldScore['date_played'] ?? DateTime.now().toIso8601String().split('T')[0],
        'league': oldScore['league'] ?? 'monday',
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  /// Migrate games data
  static Future<bool> _migrateGames(Map<String, dynamic> gamesTable) async {
    try {
      List<dynamic> gamesData = gamesTable['data'] ?? [];
      // For now, just process the games data
      // You can implement actual game migration based on your needs
      for (var _ in gamesData) {
        // Process game data here - placeholder implementation
      }
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Helper function to parse integer values
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Helper function to parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Get migration status
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      Map<String, int> counts = await _dbHelper.getDataCounts();
      
      List<Map<String, dynamic>> mondayPlayers = await _dbHelper.getPlayersByLeague(League.monday);
      List<Map<String, dynamic>> wednesdayPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);
      
      return {
        'total_players': counts['players'],
        'monday_players': mondayPlayers.length,
        'wednesday_players': wednesdayPlayers.length,
        'total_scores': counts['scores'],
        'total_games': counts['games'],
        'migration_completed': counts['players']! > 6, // More than sample data
      };
    } catch (e) {
      return {};
    }
  }

  /// Create sample export file for testing
  static Future<void> createSampleExportFile(String outputPath) async {
    Map<String, dynamic> sampleData = {
      'exported_at': DateTime.now().toIso8601String(),
      'source_db': 'sample_data',
      'tables': {
        'players': {
          'columns': ['id', 'first', 'last', 'handicap', 'skat_number', 'league'],
          'data': [
            {'id': 1, 'first': 'John', 'last': 'Doe', 'handicap': 12.5, 'skat_number': 1, 'league': 'monday'},
            {'id': 2, 'first': 'Jane', 'last': 'Smith', 'handicap': 18.0, 'skat_number': null, 'league': 'wednesday'},
            {'id': 3, 'first': 'Bob', 'last': 'Wilson', 'handicap': 8.5, 'skat_number': 2, 'league': 'monday'},
          ],
          'row_count': 3
        }
      }
    };
    
    File file = File(outputPath);
    await file.writeAsString(jsonEncode(sampleData));
  }
}