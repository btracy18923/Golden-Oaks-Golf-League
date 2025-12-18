import 'package:flutter/foundation.dart';
import 'UI/enter_scores_UI_service.dart';

/// Service that retains screen data across screen transitions
/// Captures and stores data when users click transition buttons like "Player Selection", "Enter Skats", and "Results"
class ScreenDataRetentionService {
  static final ScreenDataRetentionService _instance = ScreenDataRetentionService._internal();
  
  factory ScreenDataRetentionService() {
    return _instance;
  }
  
  ScreenDataRetentionService._internal();

  // Monday Parent Screen data
  double? _playersAnte;
  double? _closestPinAmount;
  double? _mulliganAmount;
  String? _selectedGolfCourse;
  
  // Monday Player Selection Screen data
  Set<int>? _selectedPlayerIds;
  List<Map<String, dynamic>>? _selectedPlayers;
  
  // Monday Enter Scores Screen data
  List<List<PlayerData>>? _playerGroups;
  bool? _hasMoneyCalculations;
  bool? _playersShuffled;
  
  // Monday Closest Pin Screen data
  Map<String, int>? _playerClosestPinCounts;
  Map<String, double>? _playerClosestPinWinnings;
  double? _remainingClosestPinPurse;
  int? _totalClosestPins;
  int? _remainingClosestPins;

  /// Captures data from Monday Parent Screen when "Player Selection" button is clicked
  void captureParentScreenData({
    required double playersAnte,
    required double closestPinAmount,
    required double mulliganAmount,
    required String? selectedGolfCourse,
  }) {
    _playersAnte = playersAnte;
    _closestPinAmount = closestPinAmount;
    _mulliganAmount = mulliganAmount;
    _selectedGolfCourse = selectedGolfCourse;
    
    if (kDebugMode) {
      print('Screen Data Retention: Captured Parent Screen Data');
      print('  Players Ante: \$${_playersAnte?.toStringAsFixed(2)}');
      print('  Closest Pin: \$${_closestPinAmount?.toStringAsFixed(2)}');
      print('  Mulligan: \$${_mulliganAmount?.toStringAsFixed(2)}');
      print('  Golf Course: $_selectedGolfCourse');
    }
  }

  /// Captures data from Monday Player Selection Screen when "Enter Skats" button is clicked
  void capturePlayerSelectionData({
    required Set<int> selectedPlayerIds,
    required List<Map<String, dynamic>> selectedPlayers,
  }) {
    _selectedPlayerIds = selectedPlayerIds;
    _selectedPlayers = selectedPlayers;
    
    if (kDebugMode) {
      print('Screen Data Retention: Captured Player Selection Data');
      print('  Selected Player IDs: $_selectedPlayerIds');
      print('  Selected Players Count: ${_selectedPlayers?.length}');
    }
  }

  /// Captures data from Monday Enter Scores Screen when "Results" button is clicked
  void captureEnterScoresData({
    required List<List<PlayerData>> playerGroups,
    required bool hasMoneyCalculations,
    required bool playersShuffled,
  }) {
    _playerGroups = playerGroups;
    _hasMoneyCalculations = hasMoneyCalculations;
    _playersShuffled = playersShuffled;
    
    if (kDebugMode) {
      print('Screen Data Retention: Captured Enter Scores Data');
      print('  Groups with players: ${_countGroupsWithPlayers()}');
      print('  Has money calculations: $_hasMoneyCalculations');
      print('  Players shuffled: $_playersShuffled');
    }
  }

  /// Captures data from Monday Closest Pin Screen when "Save Results" button is clicked
  void captureClosestPinData({
    required Map<String, int> playerClosestPinCounts,
    required Map<String, double> playerClosestPinWinnings,
    required double remainingClosestPinPurse,
    required int totalClosestPins,
    required int remainingClosestPins,
  }) {
    _playerClosestPinCounts = Map.from(playerClosestPinCounts);
    _playerClosestPinWinnings = Map.from(playerClosestPinWinnings);
    _remainingClosestPinPurse = remainingClosestPinPurse;
    _totalClosestPins = totalClosestPins;
    _remainingClosestPins = remainingClosestPins;
    
    if (kDebugMode) {
      print('Screen Data Retention: Captured Closest Pin Data');
      print('  Total closest pins: $_totalClosestPins');
      print('  Remaining closest pins: $_remainingClosestPins');
      print('  Remaining purse: \$${_remainingClosestPinPurse?.toStringAsFixed(2)}');
      print('  Winners: ${_countClosestPinWinners()}');
    }
  }

  /// Counts the number of groups that contain players
  int _countGroupsWithPlayers() {
    if (_playerGroups == null) return 0;
    return _playerGroups!.where((group) => group.isNotEmpty).length;
  }

  /// Counts the number of players who won closest pins
  int _countClosestPinWinners() {
    if (_playerClosestPinCounts == null) return 0;
    return _playerClosestPinCounts!.values.where((count) => count > 0).length;
  }

  // Getters for accessing retained data
  
  /// Gets the Players Ante amount from Monday Parent Screen
  double? get playersAnte => _playersAnte;
  
  /// Gets the Closest Pin amount from Monday Parent Screen
  double? get closestPinAmount => _closestPinAmount;
  
  /// Gets the Mulligan amount from Monday Parent Screen
  double? get mulliganAmount => _mulliganAmount;
  
  /// Gets the selected golf course from Monday Parent Screen
  String? get selectedGolfCourse => _selectedGolfCourse;
  
  /// Gets the selected player IDs from Monday Player Selection Screen
  Set<int>? get selectedPlayerIds => _selectedPlayerIds;
  
  /// Gets the selected players list from Monday Player Selection Screen
  List<Map<String, dynamic>>? get selectedPlayers => _selectedPlayers;
  
  /// Gets the player groups from Monday Enter Scores Screen
  List<List<PlayerData>>? get playerGroups => _playerGroups;
  
  /// Gets whether money calculations were performed
  bool? get hasMoneyCalculations => _hasMoneyCalculations;
  
  /// Gets whether players were shuffled
  bool? get playersShuffled => _playersShuffled;
  
  /// Gets the player closest pin counts from Monday Closest Pin Screen
  Map<String, int>? get playerClosestPinCounts => _playerClosestPinCounts;
  
  /// Gets the player closest pin winnings from Monday Closest Pin Screen
  Map<String, double>? get playerClosestPinWinnings => _playerClosestPinWinnings;
  
  /// Gets the remaining closest pin purse amount
  double? get remainingClosestPinPurse => _remainingClosestPinPurse;
  
  /// Gets the total number of closest pins
  int? get totalClosestPins => _totalClosestPins;
  
  /// Gets the remaining number of closest pins
  int? get remainingClosestPins => _remainingClosestPins;

  /// Checks if Parent Screen data is available
  bool hasParentScreenData() {
    return _playersAnte != null && 
           _closestPinAmount != null && 
           _mulliganAmount != null;
  }

  /// Checks if Player Selection data is available
  bool hasPlayerSelectionData() {
    return _selectedPlayerIds != null && 
           _selectedPlayers != null;
  }

  /// Checks if Enter Scores data is available
  bool hasEnterScoresData() {
    return _playerGroups != null && 
           _hasMoneyCalculations != null && 
           _playersShuffled != null;
  }

  /// Checks if Closest Pin data is available
  bool hasClosestPinData() {
    return _playerClosestPinCounts != null && 
           _playerClosestPinWinnings != null && 
           _remainingClosestPinPurse != null;
  }

  /// Clears Enter Scores data (useful when navigating from Player Selection)
  void clearEnterScoresData() {
    _playerGroups = null;
    _hasMoneyCalculations = null;
    _playersShuffled = null;

    if (kDebugMode) {
      print('Screen Data Retention: Enter Scores data cleared');
    }
  }

  /// Clears all retained data (useful for starting fresh session)
  void clearAllData() {
    _playersAnte = null;
    _closestPinAmount = null;
    _mulliganAmount = null;
    _selectedGolfCourse = null;
    _selectedPlayerIds = null;
    _selectedPlayers = null;
    _playerGroups = null;
    _hasMoneyCalculations = null;
    _playersShuffled = null;
    _playerClosestPinCounts = null;
    _playerClosestPinWinnings = null;
    _remainingClosestPinPurse = null;
    _totalClosestPins = null;
    _remainingClosestPins = null;

    if (kDebugMode) {
      print('Screen Data Retention: All data cleared');
    }
  }

  /// Gets a summary of all retained data for debugging
  Map<String, dynamic> getDataSummary() {
    return {
      'parentScreen': {
        'playersAnte': _playersAnte,
        'closestPinAmount': _closestPinAmount,
        'mulliganAmount': _mulliganAmount,
        'selectedGolfCourse': _selectedGolfCourse,
      },
      'playerSelection': {
        'selectedPlayerIds': _selectedPlayerIds?.toList(),
        'selectedPlayersCount': _selectedPlayers?.length,
      },
      'enterScores': {
        'groupsWithPlayersCount': _countGroupsWithPlayers(),
        'hasMoneyCalculations': _hasMoneyCalculations,
        'playersShuffled': _playersShuffled,
      },
      'closestPin': {
        'totalClosestPins': _totalClosestPins,
        'remainingClosestPins': _remainingClosestPins,
        'remainingPurse': _remainingClosestPinPurse,
        'winnersCount': _countClosestPinWinners(),
      },
    };
  }

  /// Prints current retained data for debugging
  void printRetainedData() {
    if (kDebugMode) {
      print('=== Screen Data Retention Service - Current Data ===');
      final summary = getDataSummary();
      print('Parent Screen: ${summary['parentScreen']}');
      print('Player Selection: ${summary['playerSelection']}');
      print('Enter Scores: ${summary['enterScores']}');
      print('Closest Pin: ${summary['closestPin']}');
      print('===================================================');
    }
  }
}