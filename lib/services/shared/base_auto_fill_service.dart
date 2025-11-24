import 'dart:math';
import '../UI/enter_scores_UI_service.dart';

/// Abstract base class for auto-filling score data
/// Provides common functionality and defines interface for league-specific implementations
abstract class BaseAutoFillService {
  
  /// Random number generator instance
  final Random random = Random();
  
  /// Abstract method for auto-filling data for all groups
  /// Must be implemented by league-specific subclasses
  List<List<PlayerData>> autoFillData(List<List<PlayerData>> groups);
  
  /// Abstract method for auto-filling data for a single group
  /// Must be implemented by league-specific subclasses
  List<PlayerData> autoFillDataForGroup(List<PlayerData> group);
  
  /// Abstract method to get the league type
  String getLeagueType();
  
  /// Common method to check if a player has data (not empty)
  bool hasPlayerData(PlayerData player) {
    return player.name.isNotEmpty;
  }
  
  /// Common method to create a deep copy of groups
  List<List<PlayerData>> createGroupsCopy(List<List<PlayerData>> groups) {
    return groups.map((group) {
      return group.map((player) {
        return PlayerData(
          name: player.name,
          skNumber: player.skNumber,
          skats: player.skats,
          diff: player.diff,
          money: player.money,
        );
      }).toList();
    }).toList();
  }
  
  /// Common method to clear all data fields for all players in groups
  List<List<PlayerData>> clearAllData(List<List<PlayerData>> groups) {
    return groups.map((group) {
      return group.map((player) {
        return PlayerData(
          name: player.name,
          skNumber: player.skNumber,
          skats: '', // Clear score fields
          diff: player.diff,
          money: player.money,
        );
      }).toList();
    }).toList();
  }
  
  /// Common method to print debug information
  void logFillAction(String playerName, String fieldName, String value) {
    print("${getLeagueType()} League: Filling $playerName with $fieldName value: $value");
  }
}