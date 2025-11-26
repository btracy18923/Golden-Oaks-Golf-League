import '../services/screen_data_retention_service.dart';
import '../services/UI/enter_scores_UI_service.dart';

/// Simple test function to verify screen data retention service functionality
void testScreenDataRetention() {
  print('=== Testing Screen Data Retention Service ===');
  
  final retentionService = ScreenDataRetentionService();
  
  // Test 1: Capture Parent Screen Data
  print('\n1. Testing Parent Screen Data Capture:');
  retentionService.captureParentScreenData(
    playersAnte: 5.00,
    closestPinAmount: 4.00,
    mulliganAmount: 2.00,
    selectedGolfCourse: 'Golden Oaks Golf Course',
  );
  
  print('   Has Parent Data: ${retentionService.hasParentScreenData()}');
  print('   Players Ante: \$${retentionService.playersAnte?.toStringAsFixed(2)}');
  print('   Closest Pin: \$${retentionService.closestPinAmount?.toStringAsFixed(2)}');
  print('   Mulligan: \$${retentionService.mulliganAmount?.toStringAsFixed(2)}');
  print('   Golf Course: ${retentionService.selectedGolfCourse}');
  
  // Test 2: Capture Player Selection Data
  print('\n2. Testing Player Selection Data Capture:');
  final selectedPlayerIds = {1, 2, 3, 4, 5};
  final selectedPlayers = [
    {'id': 1, 'last': 'Smith', 'skat_number': 32},
    {'id': 2, 'last': 'Johnson', 'skat_number': 28},
    {'id': 3, 'last': 'Williams', 'skat_number': 35},
    {'id': 4, 'last': 'Brown', 'skat_number': 30},
    {'id': 5, 'last': 'Jones', 'skat_number': 33},
  ];
  
  retentionService.capturePlayerSelectionData(
    selectedPlayerIds: selectedPlayerIds,
    selectedPlayers: selectedPlayers,
  );
  
  print('   Has Player Selection Data: ${retentionService.hasPlayerSelectionData()}');
  print('   Selected Player IDs: ${retentionService.selectedPlayerIds}');
  print('   Selected Players Count: ${retentionService.selectedPlayers?.length}');
  
  // Test 3: Capture Enter Scores Data
  print('\n3. Testing Enter Scores Data Capture:');
  final playerGroups = [
    [
      PlayerData(name: 'Smith', skNumber: '32', skats: '34', diff: '+2', money: '\$15'),
      PlayerData(name: 'Johnson', skNumber: '28', skats: '30', diff: '+2', money: '\$15'),
      PlayerData(name: 'Williams', skNumber: '35', skats: '38', diff: '+3', money: '\$20'),
      PlayerData(name: 'Brown', skNumber: '30', skats: '28', diff: '-2', money: ''),
    ],
    [
      PlayerData(name: 'Jones', skNumber: '33', skats: '35', diff: '+2', money: '\$15'),
    ],
    [], // Empty group
  ];
  
  retentionService.captureEnterScoresData(
    playerGroups: playerGroups,
    hasMoneyCalculations: true,
    playersShuffled: true,
  );
  
  print('   Has Enter Scores Data: ${retentionService.hasEnterScoresData()}');
  print('   Groups with players: ${_countNonEmptyGroups(playerGroups)}');
  print('   Has money calculations: ${retentionService.hasMoneyCalculations}');
  print('   Players shuffled: ${retentionService.playersShuffled}');
  
  // Test 4: Data Summary
  print('\n4. Testing Data Summary:');
  retentionService.printRetainedData();
  
  // Test 5: Clear All Data
  print('\n5. Testing Clear All Data:');
  retentionService.clearAllData();
  print('   Has Parent Data: ${retentionService.hasParentScreenData()}');
  print('   Has Player Selection Data: ${retentionService.hasPlayerSelectionData()}');
  print('   Has Enter Scores Data: ${retentionService.hasEnterScoresData()}');
  
  print('\n=== Screen Data Retention Service Test Complete ===');
}

/// Helper function to count non-empty groups
int _countNonEmptyGroups(List<List<PlayerData>> groups) {
  return groups.where((group) => group.isNotEmpty).length;
}