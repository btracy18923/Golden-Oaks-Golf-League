import 'package:shared_preferences/shared_preferences.dart';
import '../models/league.dart';

/// Service for persisting league-specific amounts (Player Ante, Closest Pin, Mulligan)
/// across app restarts using SharedPreferences
class LeagueAmountsPersistenceService {
  // SharedPreferences keys
  static const String _mondayPlayerAnteKey = 'monday_player_ante';
  static const String _mondayClosestPinKey = 'monday_closest_pin';
  static const String _mondayMulliganKey = 'monday_mulligan';

  static const String _wednesdayPlayerAnteKey = 'wednesday_player_ante';
  static const String _wednesdayClosestPinKey = 'wednesday_closest_pin';
  static const String _wednesdayMulliganKey = 'wednesday_mulligan';

  /// Saves Player Ante amount for a specific league
  static Future<void> savePlayerAnteAmount(double amount, League league) async {
    final prefs = await SharedPreferences.getInstance();
    final key = league == League.monday ? _mondayPlayerAnteKey : _wednesdayPlayerAnteKey;
    await prefs.setDouble(key, amount);
  }

  /// Loads Player Ante amount for a specific league
  /// Returns null if no saved value exists
  static Future<double?> loadPlayerAnteAmount(League league) async {
    final prefs = await SharedPreferences.getInstance();
    final key = league == League.monday ? _mondayPlayerAnteKey : _wednesdayPlayerAnteKey;
    return prefs.getDouble(key);
  }

  /// Saves Closest Pin amount for a specific league
  static Future<void> saveClosestPinAmount(double amount, League league) async {
    final prefs = await SharedPreferences.getInstance();
    final key = league == League.monday ? _mondayClosestPinKey : _wednesdayClosestPinKey;
    await prefs.setDouble(key, amount);
  }

  /// Loads Closest Pin amount for a specific league
  /// Returns null if no saved value exists
  static Future<double?> loadClosestPinAmount(League league) async {
    final prefs = await SharedPreferences.getInstance();
    final key = league == League.monday ? _mondayClosestPinKey : _wednesdayClosestPinKey;
    return prefs.getDouble(key);
  }

  /// Saves Mulligan amount for a specific league
  static Future<void> saveMulliganAmount(double amount, League league) async {
    final prefs = await SharedPreferences.getInstance();
    final key = league == League.monday ? _mondayMulliganKey : _wednesdayMulliganKey;
    await prefs.setDouble(key, amount);
  }

  /// Loads Mulligan amount for a specific league
  /// Returns null if no saved value exists
  static Future<double?> loadMulliganAmount(League league) async {
    final prefs = await SharedPreferences.getInstance();
    final key = league == League.monday ? _mondayMulliganKey : _wednesdayMulliganKey;
    return prefs.getDouble(key);
  }

  /// Loads all amounts for a specific league
  /// Returns a map with keys: 'playerAnte', 'closestPin', 'mulligan'
  /// Values are null if no saved value exists
  static Future<Map<String, double?>> loadAllAmounts(League league) async {
    return {
      'playerAnte': await loadPlayerAnteAmount(league),
      'closestPin': await loadClosestPinAmount(league),
      'mulligan': await loadMulliganAmount(league),
    };
  }

  /// Saves all amounts for a specific league
  static Future<void> saveAllAmounts({
    required double playerAnte,
    required double closestPin,
    required double mulligan,
    required League league,
  }) async {
    await savePlayerAnteAmount(playerAnte, league);
    await saveClosestPinAmount(closestPin, league);
    await saveMulliganAmount(mulligan, league);
  }

  /// Clears all saved amounts for a specific league
  static Future<void> clearLeagueAmounts(League league) async {
    final prefs = await SharedPreferences.getInstance();
    if (league == League.monday) {
      await prefs.remove(_mondayPlayerAnteKey);
      await prefs.remove(_mondayClosestPinKey);
      await prefs.remove(_mondayMulliganKey);
    } else {
      await prefs.remove(_wednesdayPlayerAnteKey);
      await prefs.remove(_wednesdayClosestPinKey);
      await prefs.remove(_wednesdayMulliganKey);
    }
  }

  /// Clears all saved amounts for all leagues
  static Future<void> clearAllAmounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mondayPlayerAnteKey);
    await prefs.remove(_mondayClosestPinKey);
    await prefs.remove(_mondayMulliganKey);
    await prefs.remove(_wednesdayPlayerAnteKey);
    await prefs.remove(_wednesdayClosestPinKey);
    await prefs.remove(_wednesdayMulliganKey);
  }
}
