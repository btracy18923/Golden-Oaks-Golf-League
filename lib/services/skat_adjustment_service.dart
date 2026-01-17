import 'database_helper.dart';

/// Service to handle Skat # adjustments based on DIFF values
/// Implements the following calculation rules:
/// - DIFF -1, 0, +1: No change to Skat #
/// - DIFF -2, -3: Skat # reduced by 1  
/// - DIFF +2, +3: Skat # increased by 1
/// - DIFF <= -4: Skat # reduced by 2
/// - DIFF >= +4: Skat # increased by 2
class SkatAdjustmentService {
  static final SkatAdjustmentService _instance = SkatAdjustmentService._internal();
  factory SkatAdjustmentService() => _instance;
  SkatAdjustmentService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Calculates the adjustment to apply to a Skat # based on DIFF value
  /// Returns the adjustment amount (positive = increase, negative = decrease)
  int calculateSkatAdjustment(int diffValue) {
    if (diffValue >= -1 && diffValue <= 1) {
      // DIFF -1, 0, +1: No change
      return 0;
    } else if (diffValue >= -3 && diffValue <= -2) {
      // DIFF -2, -3: Reduce by 1
      return -1;
    } else if (diffValue >= 2 && diffValue <= 3) {
      // DIFF +2, +3: Increase by 1
      return 1;
    } else if (diffValue <= -4) {
      // DIFF <= -4: Reduce by 2
      return -2;
    } else if (diffValue >= 4) {
      // DIFF >= +4: Increase by 2
      return 2;
    }
    
    return 0; // Fallback (shouldn't reach here)
  }

  /// Applies Skat # adjustments for all players with complete DIFF values
  /// Returns a map of player names to their adjustment amounts for logging
  Future<Map<String, int>> applySkatAdjustments(List<List<dynamic>> playerGroups) async {
    Map<String, int> adjustments = {};
    
    try {

      for (int groupIndex = 0; groupIndex < playerGroups.length; groupIndex++) {
        for (int playerIndex = 0; playerIndex < playerGroups[groupIndex].length; playerIndex++) {
          var player = playerGroups[groupIndex][playerIndex];
          
          // Skip empty slots
          if (player.name.isEmpty) continue;
          
          // Only process players with valid DIFF values
          if (player.diff.isNotEmpty && player.diff != '0') {
            try {
              // Parse DIFF value (remove + sign if present)
              String diffStr = player.diff.replaceAll('+', '');
              int diffValue = int.parse(diffStr);
              
              // Calculate adjustment
              int adjustment = calculateSkatAdjustment(diffValue);
              
              if (adjustment != 0) {
                // Get current Skat # and calculate new value
                int currentSkatNumber = int.parse(player.skNumber);
                int newSkatNumber = currentSkatNumber + adjustment;
                
                // Update player in database
                await _updatePlayerSkatNumber(player.name, newSkatNumber);
                
                adjustments[player.name] = adjustment;
                
              }
            } catch (e) {
            }
          }
        }
      }
      

    } catch (e) {
    }
    
    return adjustments;
  }

  /// Updates a player's Skat # in the database
  Future<void> _updatePlayerSkatNumber(String playerName, int newSkatNumber) async {
    try {
      final db = await _databaseHelper.database;

      // Find player by name in Monday league (also check 'both' for players in both leagues)
      final players = await db.query(
        'players',
        where: 'last = ? AND (league = ? OR league = ?)',
        whereArgs: [playerName, 'monday', 'both'],
      );

      if (players.isNotEmpty) {
        int playerNumber = players.first['player_number'] as int;

        // Update the Skat # in the players table
        await db.update(
          'players',
          {'skat_number': newSkatNumber},
          where: 'player_number = ?',
          whereArgs: [playerNumber],
        );

      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Gets a summary description of the adjustment rules for display
  static String getAdjustmentRulesDescription() {
    return '''Skat # Adjustment Rules:
• DIFF -1, 0, +1: No change to Skat #
• DIFF -2, -3: Skat # reduced by 1
• DIFF +2, +3: Skat # increased by 1  
• DIFF ≤ -4: Skat # reduced by 2
• DIFF ≥ +4: Skat # increased by 2''';
  }
}