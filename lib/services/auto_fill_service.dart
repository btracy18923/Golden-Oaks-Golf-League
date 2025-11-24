import 'dart:math';
import 'enter_scores_UI_service.dart';

/// Service for auto-filling SKATS data with random values
/// Generates random numbers between 30-40 for selected players
class AutoFillService {
  
  /// Fills SKATS field with random values between 30-40 for all players in the groups
  /// Returns updated groups with random SKATS values
  static List<List<PlayerData>> autoFillSkats(List<List<PlayerData>> groups) {
    print("AutoFillService.autoFillSkats called!");
    final random = Random();
    
    // Create a deep copy of the groups to avoid modifying the original
    List<List<PlayerData>> updatedGroups = groups.map((group) {
      return group.map((player) {
        // Only fill SKATS if player has a name (is not empty)
        if (player.name.isNotEmpty) {
          // Generate random number between 30 and 40 (inclusive)
          int randomSkats = 30 + random.nextInt(11); // nextInt(11) gives 0-10, so 30-40
          print("Filling ${player.name} with SKATS value: $randomSkats");
          
          return PlayerData(
            name: player.name,
            skNumber: player.skNumber,
            skats: randomSkats.toString(),
            diff: player.diff,
            money: player.money,
          );
        } else {
          // Return unchanged if no player assigned
          return PlayerData(
            name: player.name,
            skNumber: player.skNumber,
            skats: player.skats,
            diff: player.diff,
            money: player.money,
          );
        }
      }).toList();
    }).toList();
    
    return updatedGroups;
  }
  
  /// Fills SKATS field for a specific group only
  /// Returns updated group with random SKATS values
  static List<PlayerData> autoFillSkatsForGroup(List<PlayerData> group) {
    final random = Random();
    
    return group.map((player) {
      // Only fill SKATS if player has a name (is not empty)
      if (player.name.isNotEmpty) {
        // Generate random number between 30 and 40 (inclusive)
        int randomSkats = 30 + random.nextInt(11);
        
        return PlayerData(
          name: player.name,
          skNumber: player.skNumber,
          skats: randomSkats.toString(),
          diff: player.diff,
          money: player.money,
        );
      } else {
        // Return unchanged if no player assigned
        return PlayerData(
          name: player.name,
          skNumber: player.skNumber,
          skats: player.skats,
          diff: player.diff,
          money: player.money,
        );
      }
    }).toList();
  }
  
  /// Clears all SKATS values for all players in the groups
  /// Returns updated groups with empty SKATS values
  static List<List<PlayerData>> clearSkats(List<List<PlayerData>> groups) {
    return groups.map((group) {
      return group.map((player) {
        return PlayerData(
          name: player.name,
          skNumber: player.skNumber,
          skats: '', // Clear SKATS field
          diff: player.diff,
          money: player.money,
        );
      }).toList();
    }).toList();
  }
}