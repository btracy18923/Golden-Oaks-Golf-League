import 'package:flutter_test/flutter_test.dart';
import 'package:golden_oaks_golf/services/payout_validation_service.dart';
import 'package:golden_oaks_golf/services/ante_manager.dart';
import 'package:golden_oaks_golf/services/mulligan_manager.dart';
import 'package:golden_oaks_golf/models/league.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Debug Output Test', () {
    late PayoutValidationService validationService;
    
    setUp(() {
      validationService = PayoutValidationService();
      AnteManager().setAnteAmount(6.0);
      MulliganManager().setMulliganAmount(1.0);
    });

    test('Simulate Wednesday League debug output format', () async {
      // Simulate the scenario from the user: Total Payout $52, Expected $51
      List<Map<String, dynamic>> players = [
        {'winnings': 20.0},
        {'winnings': 15.0},
        {'winnings': 10.0},
        {'winnings': 5.0},
        {'winnings': 2.0},
      ];
      
      double currentMulliganPurse = 10.0;
      
      PayoutValidationResult result = await validationService.validateIndividualPayouts(
        players: players,
        league: League.wednesday,
        totalSelectedPlayers: 4, // Use 4 players as we know this returns $5 expected
        currentMulliganPurse: currentMulliganPurse,
      );
      
      // Simulate the debug output that will appear in the app
      String selectedLeague = 'wednesday';
      double adjustedMulliganPurse = result.adjustedMulliganPurse;
      
      if (selectedLeague == 'wednesday') {
        print('=== WEDNESDAY LEAGUE INDIVIDUAL PROCESSING DEBUG ===');
        print('Total Payout Amount: \$${result.totalActualPayouts.toStringAsFixed(2)}');
        print('Total Players\' Purse Amount: \$${result.expectedPurse.toStringAsFixed(2)}');
        print('Total Mulligan\'s Purse Amount: \$${adjustedMulliganPurse.toStringAsFixed(2)}');
        print('Difference (Actual - Expected): \$${result.difference.toStringAsFixed(2)}');
        print('Adjustment Required: ${result.requiresAdjustment}');
        if (result.requiresAdjustment) {
          print('Adjustment Description: ${result.description}');
        }
        print('================================================');
      }
      
      // Verify the values are correct
      expect(result.totalActualPayouts, equals(52.0));
      expect(result.expectedPurse, equals(5.0)); // Known CSV value for 4 players
      expect(result.difference, equals(47.0)); // 52 - 5
      expect(result.requiresAdjustment, isTrue);
      expect(adjustedMulliganPurse, equals(-37.0)); // 10 - 47
    });
  });
}