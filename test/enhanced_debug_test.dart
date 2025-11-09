import 'package:flutter_test/flutter_test.dart';
import 'package:golden_oaks_golf/services/payout_validation_service.dart';
import 'package:golden_oaks_golf/services/ante_manager.dart';
import 'package:golden_oaks_golf/services/mulligan_manager.dart';
import 'package:golden_oaks_golf/models/league.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Enhanced Debug Output Test', () {
    late PayoutValidationService validationService;
    
    setUp(() {
      validationService = PayoutValidationService();
      AnteManager().setAnteAmount(6.0);
      MulliganManager().setMulliganAmount(1.0);
    });

    test('Test enhanced debug output with detailed player winnings', () async {
      // Create a scenario that should total $53 like the user reported
      List<Map<String, dynamic>> players = [
        {'first': 'John', 'last': 'Smith', 'winnings': 20.0},
        {'first': 'Mike', 'last': 'Jones', 'winnings': 15.0},
        {'first': 'Bob', 'last': 'Wilson', 'winnings': 10.0},
        {'first': 'Tom', 'last': 'Brown', 'winnings': 5.0},
        {'first': 'Dave', 'last': 'Davis', 'winnings': 3.0},
        // Total should be: 20 + 15 + 10 + 5 + 3 = 53
      ];
      
      double currentMulliganPurse = 10.0;
      
      PayoutValidationResult result = await validationService.validateIndividualPayouts(
        players: players,
        league: League.wednesday,
        totalSelectedPlayers: 4, // Use 4 players for known CSV values
        currentMulliganPurse: currentMulliganPurse,
      );
      
      // Verify the total is calculated correctly
      expect(result.totalActualPayouts, equals(53.0));
      
      // Manual verification of the calculation
      double manualTotal = 0.0;
      print('=== TEST DEBUG OUTPUT ===');
      print('Individual player winnings:');
      for (int i = 0; i < players.length; i++) {
        var player = players[i];
        double winnings = player['winnings']?.toDouble() ?? 0.0;
        manualTotal += winnings;
        String playerName = '${player['first'] ?? 'Unknown'} ${player['last'] ?? 'Player'}';
        print('  $playerName: \$${winnings.toStringAsFixed(2)}');
      }
      print('Manual total calculation: \$${manualTotal.toStringAsFixed(2)}');
      print('Validation service total: \$${result.totalActualPayouts.toStringAsFixed(2)}');
      print('========================');
      
      expect(manualTotal, equals(53.0));
      expect(result.totalActualPayouts, equals(manualTotal));
    });

    test('Test with null winnings handling', () async {
      // Test scenario where some players might have null winnings
      List<Map<String, dynamic>> players = [
        {'first': 'John', 'last': 'Smith', 'winnings': 20.0},
        {'first': 'Mike', 'last': 'Jones', 'winnings': null}, // null winnings
        {'first': 'Bob', 'last': 'Wilson', 'winnings': 10.0},
        {'first': 'Tom', 'last': 'Brown'}, // no winnings field
      ];
      
      PayoutValidationResult result = await validationService.validateIndividualPayouts(
        players: players,
        league: League.wednesday,
        totalSelectedPlayers: 4,
        currentMulliganPurse: 10.0,
      );
      
      // Should only count players with valid winnings: 20 + 0 + 10 + 0 = 30
      expect(result.totalActualPayouts, equals(30.0));
    });
  });
}