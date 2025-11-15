import 'package:flutter_test/flutter_test.dart';
import 'package:golden_oaks_golf/services/payout_validation_service.dart';
import 'package:golden_oaks_golf/services/ante_manager.dart';
import 'package:golden_oaks_golf/services/mulligan_manager.dart';
import 'package:golden_oaks_golf/models/league.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Integration Test for Reported Issue', () {
    late PayoutValidationService validationService;
    
    setUp(() {
      validationService = PayoutValidationService();
      // Set default Wednesday values
      AnteManager().setAnteAmount(6.0);
      MulliganManager().setMulliganAmount(1.0);
    });

    test('Wednesday League: Total Payout \$52 vs Total Players Purse \$51 should adjust Mulligan Purse', () async {
      // Simulate the exact scenario reported: Total Payout $52, Total Players Purse $51
      List<Map<String, dynamic>> players = [
        // Create players that total $52 in winnings
        {'winnings': 20.0},
        {'winnings': 15.0},
        {'winnings': 10.0},
        {'winnings': 5.0},
        {'winnings': 2.0},
        // Total: $52
      ];
      
      // Simulate a scenario where CSV would return $51 for total individual
      // This would happen with a specific number of players that results in $51 from CSV
      int totalSelectedPlayers = 17; // Use a player count that should result in close to $51
      
      // Start with $20 mulligan purse
      double currentMulliganPurse = 20.0;
      
      PayoutValidationResult result = await validationService.validateIndividualPayouts(
        players: players,
        league: League.wednesday,
        totalSelectedPlayers: totalSelectedPlayers,
        currentMulliganPurse: currentMulliganPurse,
      );
      
      // Verify the validation detects the issue
      expect(result.totalActualPayouts, equals(52.0));
      expect(result.requiresAdjustment, isTrue);
      expect(result.description, contains('exceed'));
      expect(result.description, contains('subtracting from Mulligan'));
      
      // The exact expected purse will depend on CSV data, but the difference should be calculated correctly
      double difference = result.totalActualPayouts - result.expectedPurse;
      expect(difference, greaterThan(0)); // Should be positive (overage)
      expect(result.adjustedMulliganPurse, equals(currentMulliganPurse - difference));
      
      print('Test Results:');
      print('  Total Actual Payouts: \$${result.totalActualPayouts}');
      print('  Expected Purse: \$${result.expectedPurse}');
      print('  Difference: \$${result.difference}');
      print('  Original Mulligan Purse: \$${currentMulliganPurse}');
      print('  Adjusted Mulligan Purse: \$${result.adjustedMulliganPurse}');
      print('  Description: ${result.description}');
    });

    test('Verify basic Wednesday League functionality with known values', () async {
      // Use a known scenario from existing tests
      List<Map<String, dynamic>> players = [
        {'winnings': 3.0},
        {'winnings': 2.0},
        {'winnings': 0.0},
        {'winnings': 0.0},
      ];
      
      PayoutValidationResult result = await validationService.validateIndividualPayouts(
        players: players,
        league: League.wednesday,
        totalSelectedPlayers: 4, // Known to work from CSV tests
        currentMulliganPurse: 10.0,
      );
      
      expect(result.totalActualPayouts, equals(5.0));
      expect(result.expectedPurse, equals(5.0)); // From CSV for 4 players
      expect(result.difference, equals(0.0));
      expect(result.requiresAdjustment, isFalse);
      expect(result.description, contains('no adjustment needed'));
    });
  });
}