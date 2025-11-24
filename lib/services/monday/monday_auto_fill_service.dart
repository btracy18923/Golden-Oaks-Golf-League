import '../shared/base_auto_fill_service.dart';
import '../UI/enter_scores_UI_service.dart';

/// Monday League auto fill implementation
/// Fills SKATS data fields with random numbers between 30 and 40
class MondayAutoFillService extends BaseAutoFillService {
  
  @override
  String getLeagueType() => 'Monday';
  
  /// Fills SKATS field with random values between 30-40 for all players in the groups
  /// Returns updated groups with random SKATS values
  @override
  List<List<PlayerData>> autoFillData(List<List<PlayerData>> groups) {
    print("MondayAutoFillService.autoFillData called!");
    
    // Create a deep copy of the groups to avoid modifying the original
    List<List<PlayerData>> updatedGroups = createGroupsCopy(groups);
    
    for (int groupIndex = 0; groupIndex < updatedGroups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < updatedGroups[groupIndex].length; playerIndex++) {
        PlayerData player = updatedGroups[groupIndex][playerIndex];
        
        // Only fill SKATS if player has data (is not empty)
        if (hasPlayerData(player)) {
          // Generate random number between 30 and 40 (inclusive)
          int randomSkats = 30 + random.nextInt(11); // nextInt(11) gives 0-10, so 30-40
          logFillAction(player.name, "SKATS", randomSkats.toString());
          
          updatedGroups[groupIndex][playerIndex] = PlayerData(
            name: player.name,
            skNumber: player.skNumber,
            skats: randomSkats.toString(),
            diff: player.diff,
            money: player.money,
          );
        }
      }
    }
    
    return updatedGroups;
  }
  
  /// Fills SKATS field for a specific group only
  /// Returns updated group with random SKATS values between 30-40
  @override
  List<PlayerData> autoFillDataForGroup(List<PlayerData> group) {
    return group.map((player) {
      // Only fill SKATS if player has data (is not empty)
      if (hasPlayerData(player)) {
        // Generate random number between 30 and 40 (inclusive)
        int randomSkats = 30 + random.nextInt(11);
        logFillAction(player.name, "SKATS", randomSkats.toString());
        
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
  List<List<PlayerData>> clearSkats(List<List<PlayerData>> groups) {
    return clearAllData(groups);
  }
}