import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:golden_oaks_golf/services/csv_payout_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CSV Payout Service Tests', () {
    late CsvPayoutService payoutService;

    setUp(() {
      payoutService = CsvPayoutService();
    });

    test('should load payout data successfully', () async {
      await payoutService.loadPayoutData();
      expect(payoutService, isNotNull);
    });

    test('should return correct payout amounts for 4 players', () async {
      Map<String, double> payouts = await payoutService.getPayoutAmounts(4);
      
      expect(payouts['total_purse'], equals(20.0));
      expect(payouts['total_individual'], equals(5.0));
      expect(payouts['1st'], equals(3.0));
      expect(payouts['2nd'], equals(2.0));
      expect(payouts['3rd'], equals(0.0));
    });

    test('should return correct payout amounts for 20 players', () async {
      Map<String, double> payouts = await payoutService.getPayoutAmounts(20);
      
      expect(payouts['total_purse'], equals(100.0));
      expect(payouts['total_individual'], equals(40.0));
      expect(payouts['1st'], equals(13.0));
      expect(payouts['2nd'], equals(11.0));
      expect(payouts['3rd'], equals(8.0));
      expect(payouts['4th'], equals(5.0));
      expect(payouts['5th'], equals(3.0));
      expect(payouts['6th'], equals(0.0));
    });

    test('should return payout list for 8 players', () async {
      List<double> payouts = await payoutService.getPayoutList(8);
      
      expect(payouts.length, equals(6));
      expect(payouts[0], equals(5.0)); // 1st place
      expect(payouts[1], equals(3.0)); // 2nd place
      expect(payouts[2], equals(2.0)); // 3rd place
      expect(payouts[3], equals(0.0)); // 4th place
      expect(payouts[4], equals(0.0)); // 5th place
      expect(payouts[5], equals(0.0)); // 6th place
    });

    test('should return exact payout for 15 players', () async {
      Map<String, double> payouts = await payoutService.getPayoutAmounts(15); // Should be in table
      
      // Should use exact 15 player payout
      expect(payouts['1st'], equals(9.0));
      expect(payouts['2nd'], equals(6.0));
      expect(payouts['3rd'], equals(4.0));
    });
  });
}