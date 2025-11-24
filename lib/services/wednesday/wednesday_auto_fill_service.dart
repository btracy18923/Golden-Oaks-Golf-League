import '../shared/base_auto_fill_service.dart';
import '../UI/enter_scores_UI_service.dart';

/// Wednesday League auto fill implementation
/// Fills GROSS data field (using skats field) with random numbers between 39 and 49
class WednesdayAutoFillService extends BaseAutoFillService {
  
  @override
  String getLeagueType() => 'Wednesday';
  
  /// Fills GROSS field (skats field) with random values between 39-49 for all players in the groups
  /// Returns updated groups with random GROSS values
  @override
  List<List<PlayerData>> autoFillData(List<List<PlayerData>> groups) {
    print("WednesdayAutoFillService.autoFillData called!");
    
    // Create a deep copy of the groups to avoid modifying the original
    List<List<PlayerData>> updatedGroups = createGroupsCopy(groups);
    
    for (int groupIndex = 0; groupIndex < updatedGroups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < updatedGroups[groupIndex].length; playerIndex++) {
        PlayerData player = updatedGroups[groupIndex][playerIndex];
        
        // Only fill GROSS if player has data (is not empty)
        if (hasPlayerData(player)) {
          // Generate random number between 39 and 49 (inclusive)
          int randomGross = 39 + random.nextInt(11); // nextInt(11) gives 0-10, so 39-49
          logFillAction(player.name, "GROSS", randomGross.toString());
          
          updatedGroups[groupIndex][playerIndex] = PlayerData(
            name: player.name,
            skNumber: player.skNumber,
            skats: randomGross.toString(), // Using skats field for gross score
            diff: player.diff,
            money: player.money,
          );
        }
      }
    }
    
    return updatedGroups;
  }
  
  /// Fills GROSS field (skats field) for a specific group only
  /// Returns updated group with random GROSS values between 39-49
  @override
  List<PlayerData> autoFillDataForGroup(List<PlayerData> group) {
    return group.map((player) {
      // Only fill GROSS if player has data (is not empty)
      if (hasPlayerData(player)) {
        // Generate random number between 39 and 49 (inclusive)
        int randomGross = 39 + random.nextInt(11);
        logFillAction(player.name, "GROSS", randomGross.toString());
        
        return PlayerData(
          name: player.name,
          skNumber: player.skNumber,
          skats: randomGross.toString(), // Using skats field for gross score
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
  
  /// Clears all GROSS values (skats field) for all players in the groups
  /// Returns updated groups with empty GROSS values
  List<List<PlayerData>> clearGross(List<List<PlayerData>> groups) {
    return clearAllData(groups);
  }
}