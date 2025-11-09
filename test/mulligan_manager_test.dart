import 'package:flutter_test/flutter_test.dart';
import 'package:golden_oaks_golf/services/mulligan_manager.dart';

void main() {
  group('Mulligan Manager Tests', () {
    late MulliganManager mulliganManager;

    setUp(() {
      mulliganManager = MulliganManager();
    });

    test('should have default mulligan amount of 1.0', () {
      expect(mulliganManager.currentMulliganAmount, equals(1.0));
    });

    test('should set mulligan amount correctly', () {
      mulliganManager.setMulliganAmount(2.5);
      expect(mulliganManager.currentMulliganAmount, equals(2.5));
    });

    test('should set mulligan amount from string correctly', () {
      mulliganManager.setMulliganAmountFromString('\$3.00');
      expect(mulliganManager.currentMulliganAmount, equals(3.0));
    });

    test('should handle invalid string input', () {
      mulliganManager.setMulliganAmountFromString('invalid');
      expect(mulliganManager.currentMulliganAmount, equals(1.0)); // Default fallback
    });

    test('should calculate correct mulligan purse for multiple players', () {
      mulliganManager.setMulliganAmount(2.0);
      
      // Test with different player counts
      expect(mulliganManager.currentMulliganAmount * 4, equals(8.0)); // 4 players
      expect(mulliganManager.currentMulliganAmount * 13, equals(26.0)); // 13 players
      expect(mulliganManager.currentMulliganAmount * 20, equals(40.0)); // 20 players
    });

    test('should be singleton instance', () {
      MulliganManager instance1 = MulliganManager();
      MulliganManager instance2 = MulliganManager();
      
      expect(identical(instance1, instance2), isTrue);
      
      instance1.setMulliganAmount(5.0);
      expect(instance2.currentMulliganAmount, equals(5.0));
    });
  });
}