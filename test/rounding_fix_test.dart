import 'package:flutter_test/flutter_test.dart';
import 'package:golden_oaks_golf/services/payout_validation_service.dart';
import 'package:golden_oaks_golf/services/ante_manager.dart';
import 'package:golden_oaks_golf/services/mulligan_manager.dart';
import 'package:golden_oaks_golf/models/league.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Rounding Fix Test', () {
    late PayoutValidationService validationService;
    
    setUp(() {
      validationService = PayoutValidationService();
      AnteManager().setAnteAmount(6.0);
      MulliganManager().setMulliganAmount(1.0);
    });

    test('Test exact scenario from user report: Three players with \$2.67 each', () async {
      // Simulate the exact scenario: 3 players with $2.67 each
      List<Map<String, dynamic>> players = [
        {'first': 'Testa', 'last': 'Player', 'winnings': 2.67},
        {'first': 'Grohol', 'last': 'Player', 'winnings': 2.67},
        {'first': 'Ramerize', 'last': 'Player', 'winnings': 2.67},
      ];
      
      double currentMulliganPurse = 27.0; // As shown in user's debug output
      
      PayoutValidationResult result = await validationService.validateIndividualPayouts(
        players: players,
        league: League.wednesday,
        totalSelectedPlayers: 17, // Estimate based on the expected purse amount
        currentMulliganPurse: currentMulliganPurse,
      );
      
      // Manual calculation with exact amounts
      double exactTotal = 3 * 2.67; // = 8.01
      
      // Manual calculation with rounded amounts (as user sees on screen)
      double roundedTotal = 3 * 3.0; // = 9.00
      
      // The validation service should now use rounded amounts (9.00) not exact amounts (8.01)
      expect(result.totalActualPayouts, equals(9.0), reason: 'Should use rounded amounts like display');
      
      // If expected purse is around $51 (as in user's output), difference should be negative
      // indicating payouts are less than expected, so mulligan purse should increase
      if (result.expectedPurse >= 50.0) {
        expect(result.difference, lessThan(0), reason: 'Payouts should be less than expected purse');
        expect(result.adjustedMulliganPurse, greaterThan(currentMulliganPurse), reason: 'Mulligan purse should increase');
      }
    });

    test('Test rounding with various decimal amounts', () async {
      List<Map<String, dynamic>> players = [
        {'first': 'Player1', 'last': 'Test', 'winnings': 1.49}, // rounds to $1
        {'first': 'Player2', 'last': 'Test', 'winnings': 1.50}, // rounds to $2  
        {'first': 'Player3', 'last': 'Test', 'winnings': 2.33}, // rounds to $2
        {'first': 'Player4', 'last': 'Test', 'winnings': 2.67}, // rounds to $3
      ];
      
      PayoutValidationResult result = await validationService.validateIndividualPayouts(
        players: players,
        league: League.wednesday,
        totalSelectedPlayers: 4,
        currentMulliganPurse: 10.0,
      );
      
      // Exact total: 1.49 + 1.50 + 2.33 + 2.67 = 7.99
      // Rounded total: 1 + 2 + 2 + 3 = 8.00
      double expectedRoundedTotal = 1.0 + 2.0 + 2.0 + 3.0; // = 8.00
      
      
      expect(result.totalActualPayouts, equals(expectedRoundedTotal));
    });
  });
}