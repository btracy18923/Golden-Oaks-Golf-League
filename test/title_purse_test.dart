import 'package:flutter_test/flutter_test.dart';
import 'package:golden_oaks_golf/services/csv_payout_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Title Purse Calculation Tests', () {
    late CsvPayoutService payoutService;

    setUp(() {
      payoutService = CsvPayoutService();
    });

    test('should return correct total individual for 4 Wednesday players', () async {
      Map<String, double> payouts = await payoutService.getPayoutAmounts(4);
      double totalIndividual = payouts['total_individual'] ?? 0.0;
      
      expect(totalIndividual, equals(5.0));
    });

    test('should return correct total individual for 12 Wednesday players', () async {
      Map<String, double> payouts = await payoutService.getPayoutAmounts(12);
      double totalIndividual = payouts['total_individual'] ?? 0.0;
      
      expect(totalIndividual, equals(15.0));
    });

    test('should return correct total individual for 20 Wednesday players', () async {
      Map<String, double> payouts = await payoutService.getPayoutAmounts(20);
      double totalIndividual = payouts['total_individual'] ?? 0.0;
      
      expect(totalIndividual, equals(40.0));
    });

    test('should return correct total individual for 24 Wednesday players', () async {
      Map<String, double> payouts = await payoutService.getPayoutAmounts(24);
      double totalIndividual = payouts['total_individual'] ?? 0.0;
      
      expect(totalIndividual, equals(48.0));
    });
  });
}