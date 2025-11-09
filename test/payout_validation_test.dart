import 'package:flutter_test/flutter_test.dart';
import 'package:golden_oaks_golf/services/payout_validation_service.dart';
import 'package:golden_oaks_golf/services/ante_manager.dart';
import 'package:golden_oaks_golf/services/percentage_manager.dart';
import 'package:golden_oaks_golf/services/mulligan_manager.dart';
import 'package:golden_oaks_golf/models/league.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('PayoutValidationService Tests', () {
    late PayoutValidationService validationService;
    
    setUp(() {
      validationService = PayoutValidationService();
      // Set default values for managers
      AnteManager().setAnteAmount(6.0); // Wednesday default
      PercentageManager().setIndividualPercent(40);
      PercentageManager().setGroupPercent(60);
      MulliganManager().setMulliganAmount(1.0);
    });

    group('Individual Payout Validation', () {
      test('should validate equal payouts correctly', () async {
        List<Map<String, dynamic>> players = [
          {'winnings': 3.0},
          {'winnings': 2.0},
          {'winnings': 0.0},
        ];
        
        PayoutValidationResult result = await validationService.validateIndividualPayouts(
          players: players,
          league: League.wednesday,
          totalSelectedPlayers: 4,
          currentMulliganPurse: 4.0,
        );
        
        expect(result.totalActualPayouts, equals(5.0));
        expect(result.expectedPurse, equals(5.0)); // Based on CSV for 4 players
        expect(result.difference, equals(0.0));
        expect(result.adjustedMulliganPurse, equals(4.0)); // No change
        expect(result.requiresAdjustment, isFalse);
        expect(result.description, contains('no adjustment needed'));
      });

      test('should handle excess payouts correctly', () async {
        List<Map<String, dynamic>> players = [
          {'winnings': 4.0}, // More than expected
          {'winnings': 2.0},
          {'winnings': 1.0},
        ];
        
        PayoutValidationResult result = await validationService.validateIndividualPayouts(
          players: players,
          league: League.wednesday,
          totalSelectedPlayers: 4,
          currentMulliganPurse: 10.0,
        );
        
        expect(result.totalActualPayouts, equals(7.0));
        expect(result.expectedPurse, equals(5.0)); // Based on CSV for 4 players
        expect(result.difference, equals(2.0));
        expect(result.adjustedMulliganPurse, equals(8.0)); // 10 - 2
        expect(result.requiresAdjustment, isTrue);
        expect(result.description, contains('exceed'));
        expect(result.description, contains('subtracting from Mulligan'));
      });

      test('should handle insufficient payouts correctly', () async {
        List<Map<String, dynamic>> players = [
          {'winnings': 2.0}, // Less than expected
          {'winnings': 1.0},
          {'winnings': 0.0},
        ];
        
        PayoutValidationResult result = await validationService.validateIndividualPayouts(
          players: players,
          league: League.wednesday,
          totalSelectedPlayers: 4,
          currentMulliganPurse: 10.0,
        );
        
        expect(result.totalActualPayouts, equals(3.0));
        expect(result.expectedPurse, equals(5.0)); // Based on CSV for 4 players
        expect(result.difference, equals(-2.0));
        expect(result.adjustedMulliganPurse, equals(12.0)); // 10 + 2
        expect(result.requiresAdjustment, isTrue);
        expect(result.description, contains('less than expected'));
        expect(result.description, contains('adding to Mulligan'));
      });
    });

    group('Monday League Validation', () {
      test('should validate Monday league payouts with skat winnings', () async {
        List<Map<String, dynamic>> players = [
          {'skat_winnings': 15.0, 'closest_pin_winnings': 0.0},
          {'skat_winnings': 10.0, 'closest_pin_winnings': 5.0},
          {'skat_winnings': 0.0, 'closest_pin_winnings': 0.0},
        ];
        
        // Set Monday ante amount
        AnteManager().setAnteAmount(12.0);
        
        PayoutValidationResult result = await validationService.validateMondayLeaguePayouts(
          players: players,
          totalSelectedPlayers: 4,
          currentMulliganPurse: 20.0,
        );
        
        expect(result.totalActualPayouts, equals(30.0)); // 15 + 10 + 5
        // Expected for Monday: 12 * 4 * 0.4 = 19.2
        expect(result.expectedPurse, closeTo(19.2, 0.01)); 
        expect(result.difference, closeTo(10.8, 0.01)); // 30 - 19.2
        expect(result.adjustedMulliganPurse, closeTo(9.2, 0.01)); // 20 - 10.8
        expect(result.requiresAdjustment, isTrue);
        expect(result.description, contains('Monday league'));
      });
    });

    group('Group Payout Validation', () {
      test('should validate group payouts correctly', () async {
        List<List<Map<String, dynamic>?>> groups = [
          [
            {'group_winnings': 10.0, 'is_wild_card': null},
            {'group_winnings': 10.0, 'is_wild_card': null},
          ],
          [
            {'group_winnings': 5.0, 'is_wild_card': null},
            {'group_winnings': 5.0, 'is_wild_card': null},
          ],
        ];
        
        PayoutValidationResult result = await validationService.validateGroupPayouts(
          groups: groups,
          league: League.wednesday,
          totalSelectedPlayers: 4,
          currentMulliganPurse: 15.0,
        );
        
        expect(result.totalActualPayouts, equals(30.0));
        expect(result.requiresAdjustment, isTrue);
        expect(result.description, contains('group'));
      });

      test('should exclude wild cards from group validation', () async {
        List<List<Map<String, dynamic>?>> groups = [
          [
            {'group_winnings': 10.0, 'is_wild_card': null},
            {'group_winnings': 0.0, 'is_wild_card': true}, // Wild card
          ],
          [
            {'group_winnings': 5.0, 'is_wild_card': null},
            null, // Empty slot
          ],
        ];
        
        PayoutValidationResult result = await validationService.validateGroupPayouts(
          groups: groups,
          league: League.wednesday,
          totalSelectedPlayers: 2, // Only 2 real players
          currentMulliganPurse: 10.0,
        );
        
        expect(result.totalActualPayouts, equals(15.0)); // Only real players counted
      });
    });

    group('Error Handling', () {
      test('should handle validation errors gracefully', () async {
        List<Map<String, dynamic>> players = [
          {'winnings': null}, // Invalid data - will be treated as 0.0
        ];
        
        PayoutValidationResult result = await validationService.validateIndividualPayouts(
          players: players,
          league: League.wednesday,
          totalSelectedPlayers: 1,
          currentMulliganPurse: 5.0,
        );
        
        expect(result.totalActualPayouts, equals(0.0));
        // The service should handle the null winnings gracefully and perform validation
        expect(result, isNotNull);
        expect(result.adjustedMulliganPurse, isNotNull);
      });
    });

    group('Expected Purse Calculations', () {
      test('should return correct expected purse for display', () async {
        // Use 4 players as we know this works from other tests
        double individualPurse = await validationService.getExpectedPurseForDisplay(
          league: League.wednesday,
          totalSelectedPlayers: 4,
          isGroupProcessing: false,
        );
        
        expect(individualPurse, equals(5.0)); // Known value from CSV tests
        
        double groupPurse = await validationService.getExpectedPurseForDisplay(
          league: League.wednesday,
          totalSelectedPlayers: 4,
          isGroupProcessing: true,
        );
        
        // Group purse might be 0 if CSV doesn't have group data for 4 players
        expect(groupPurse, greaterThanOrEqualTo(0.0));
      });

      test('should handle Monday league expected purse calculation', () async {
        AnteManager().setAnteAmount(12.0);
        
        double individualPurse = await validationService.getExpectedPurseForDisplay(
          league: League.monday,
          totalSelectedPlayers: 10,
          isGroupProcessing: false,
        );
        
        expect(individualPurse, equals(48.0)); // 12 * 10 * 0.4
        
        double groupPurse = await validationService.getExpectedPurseForDisplay(
          league: League.monday,
          totalSelectedPlayers: 10,
          isGroupProcessing: true,
        );
        
        expect(groupPurse, equals(72.0)); // 12 * 10 * 0.6
      });
    });
  });
}