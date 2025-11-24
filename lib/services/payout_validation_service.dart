import '../models/league.dart';
import 'csv_payout_service.dart';
import 'group_csv_payout_service.dart';
import 'database_helper.dart';
import 'shared/league_purse_service.dart';

class PayoutValidationResult {
  final double totalActualPayouts;
  final double expectedPurse;
  final double difference;
  final double adjustedMulliganPurse;
  final bool requiresAdjustment;
  final String description;

  PayoutValidationResult({
    required this.totalActualPayouts,
    required this.expectedPurse,
    required this.difference,
    required this.adjustedMulliganPurse,
    required this.requiresAdjustment,
    required this.description,
  });
}

class PayoutValidationService {
  static final PayoutValidationService _instance = PayoutValidationService._internal();
  factory PayoutValidationService() => _instance;
  PayoutValidationService._internal();

  Future<PayoutValidationResult> validateIndividualPayouts({
    required List<Map<String, dynamic>> players,
    required League league,
    required int totalSelectedPlayers,
    required double currentMulliganPurse,
  }) async {
    try {
      print('=== PAYOUT VALIDATION SERVICE DEBUG (INDIVIDUAL) ===');
      print('Number of players received: ${players.length}');
      print('Total selected players: $totalSelectedPlayers');
      print('Current mulligan purse passed in: \$${currentMulliganPurse.toStringAsFixed(2)}');
      
      // Calculate total actual payouts using rounded amounts (same as displayed to user)
      double totalActualPayouts = 0.0;
      print('Individual player payout details:');
      for (int i = 0; i < players.length; i++) {
        var player = players[i];
        double winnings = player['winnings']?.toDouble() ?? 0.0;
        int roundedWinnings = winnings.round(); // Round to match display
        double roundedWinningsAsDouble = roundedWinnings.toDouble();
        totalActualPayouts += roundedWinningsAsDouble;
        
        String playerName = '${player['first'] ?? 'Unknown'} ${player['last'] ?? 'Player'}';
        print('  Player ${i+1}: $playerName');
        print('    Raw winnings: \$${winnings.toStringAsFixed(2)}');
        print('    Rounded winnings: \$${roundedWinnings.toStringAsFixed(2)}');
        print('    Prize money field: ${player['prize_money'] ?? 'null'}');
        print('    Position field: ${player['pos'] ?? 'null'}');
      }
      print('Calculated total actual payouts: \$${totalActualPayouts.toStringAsFixed(2)}');

      // Get expected purse based on league type
      double expectedPurse = await _getExpectedIndividualPurse(league, totalSelectedPlayers);
      print('Expected individual purse: \$${expectedPurse.toStringAsFixed(2)}');
      
      // Calculate difference (actual - expected)
      double difference = totalActualPayouts - expectedPurse;
      print('Difference (actual - expected): \$${difference.toStringAsFixed(2)}');
      
      // Calculate adjusted mulligan purse
      double adjustedMulliganPurse = currentMulliganPurse - difference;
      print('Adjusted mulligan purse: \$${adjustedMulliganPurse.toStringAsFixed(2)}');
      
      // Determine if adjustment is needed
      bool requiresAdjustment = difference.abs() > 0.01; // Allow for small rounding differences
      print('Requires adjustment: $requiresAdjustment (threshold: 0.01)');
      
      // Generate description
      String description = _generateDescription(difference, 'individual');
      print('Generated description: $description');
      
      print('Final validation result:');
      print('  Total actual payouts: \$${totalActualPayouts.toStringAsFixed(2)}');
      print('  Expected purse: \$${expectedPurse.toStringAsFixed(2)}');
      print('  Difference: \$${difference.toStringAsFixed(2)}');
      print('  Adjusted mulligan purse: \$${adjustedMulliganPurse.toStringAsFixed(2)}');
      print('  Requires adjustment: $requiresAdjustment');
      print('========================================================');

      return PayoutValidationResult(
        totalActualPayouts: totalActualPayouts,
        expectedPurse: expectedPurse,
        difference: difference,
        adjustedMulliganPurse: adjustedMulliganPurse,
        requiresAdjustment: requiresAdjustment,
        description: description,
      );
    } catch (e) {
      // Return neutral result if validation fails
      return PayoutValidationResult(
        totalActualPayouts: 0.0,
        expectedPurse: 0.0,
        difference: 0.0,
        adjustedMulliganPurse: currentMulliganPurse,
        requiresAdjustment: false,
        description: 'Validation failed: $e',
      );
    }
  }

  Future<PayoutValidationResult> validateGroupPayouts({
    required List<List<Map<String, dynamic>?>> groups,
    required League league,
    required int totalSelectedPlayers,
    required double currentMulliganPurse,
  }) async {
    try {
      print('=== PAYOUT VALIDATION SERVICE DEBUG (GROUPS) ===');
      print('Number of groups received: ${groups.length}');
      print('Total selected players: $totalSelectedPlayers');
      print('Current mulligan purse passed in: \$${currentMulliganPurse.toStringAsFixed(2)}');
      
      // Check for stored adjusted mulligan purse first
      String leagueStr = league == League.monday ? 'monday' : 'wednesday';
      double? storedAdjustedAmount = await DatabaseHelper().getAdjustedMulliganPurse(leagueStr);
      double effectiveMulliganPurse = storedAdjustedAmount ?? currentMulliganPurse;
      
      print('Stored adjusted mulligan purse: ${storedAdjustedAmount != null ? '\$${storedAdjustedAmount.toStringAsFixed(2)}' : 'None'}');
      print('Effective mulligan purse being used: \$${effectiveMulliganPurse.toStringAsFixed(2)}');
      
      // Calculate total actual group payouts using rounded amounts
      double totalActualPayouts = 0.0;
      print('Group payout details:');
      for (int i = 0; i < groups.length; i++) {
        var group = groups[i];
        print('  Group ${i+1}:');
        for (int j = 0; j < group.length; j++) {
          var player = group[j];
          if (player != null) {
            double groupWinnings = player['group_winnings']?.toDouble() ?? 0.0;
            int roundedGroupWinnings = groupWinnings.round(); // Round to match display
            totalActualPayouts += roundedGroupWinnings.toDouble();
            
            String playerName = '${player['first'] ?? 'Unknown'} ${player['last'] ?? 'Player'}';
            print('    Player ${j+1}: $playerName');
            print('      Raw group winnings: \$${groupWinnings.toStringAsFixed(2)}');
            print('      Rounded group winnings: \$${roundedGroupWinnings.toStringAsFixed(2)}');
            print('      Group position: ${player['group_position'] ?? 'null'}');
          }
        }
      }
      print('Calculated total actual group payouts: \$${totalActualPayouts.toStringAsFixed(2)}');

      // Get expected group purse based on league type
      double expectedPurse = await _getExpectedGroupPurse(league, totalSelectedPlayers);
      print('Expected group purse: \$${expectedPurse.toStringAsFixed(2)}');
      
      // Calculate difference (actual - expected)
      double difference = totalActualPayouts - expectedPurse;
      print('Difference (actual - expected): \$${difference.toStringAsFixed(2)}');
      
      // Calculate adjusted mulligan purse using the effective amount
      double adjustedMulliganPurse = effectiveMulliganPurse - difference;
      print('Adjusted mulligan purse calculation:');
      print('  Effective mulligan purse: \$${effectiveMulliganPurse.toStringAsFixed(2)}');
      print('  Minus difference: \$${difference.toStringAsFixed(2)}');
      print('  Equals adjusted: \$${adjustedMulliganPurse.toStringAsFixed(2)}');
      
      // Determine if adjustment is needed
      bool requiresAdjustment = difference.abs() > 0.01; // Allow for small rounding differences
      print('Requires adjustment: $requiresAdjustment (threshold: 0.01)');
      
      // Generate description
      String description = _generateDescription(difference, 'group');
      print('Generated description: $description');
      
      print('Final group validation result:');
      print('  Total actual group payouts: \$${totalActualPayouts.toStringAsFixed(2)}');
      print('  Expected group purse: \$${expectedPurse.toStringAsFixed(2)}');
      print('  Difference: \$${difference.toStringAsFixed(2)}');
      print('  Adjusted mulligan purse: \$${adjustedMulliganPurse.toStringAsFixed(2)}');
      print('  Requires adjustment: $requiresAdjustment');
      print('============================================================');

      return PayoutValidationResult(
        totalActualPayouts: totalActualPayouts,
        expectedPurse: expectedPurse,
        difference: difference,
        adjustedMulliganPurse: adjustedMulliganPurse,
        requiresAdjustment: requiresAdjustment,
        description: description,
      );
    } catch (e) {
      // Check for stored adjusted mulligan purse for error case too
      String leagueStr = league == League.monday ? 'monday' : 'wednesday';
      double? storedAdjustedAmount = await DatabaseHelper().getAdjustedMulliganPurse(leagueStr);
      double effectiveMulliganPurse = storedAdjustedAmount ?? currentMulliganPurse;
      
      // Return neutral result if validation fails
      return PayoutValidationResult(
        totalActualPayouts: 0.0,
        expectedPurse: 0.0,
        difference: 0.0,
        adjustedMulliganPurse: effectiveMulliganPurse,
        requiresAdjustment: false,
        description: 'Validation failed: $e',
      );
    }
  }

  Future<PayoutValidationResult> validateMondayLeaguePayouts({
    required List<Map<String, dynamic>> players,
    required int totalSelectedPlayers,
    required double currentMulliganPurse,
  }) async {
    try {
      // Calculate total actual Monday league payouts (skat winnings + closest pin) using rounded amounts
      double totalActualPayouts = 0.0;
      for (var player in players) {
        double skatWinnings = player['skat_winnings']?.toDouble() ?? 0.0;
        double closestPinWinnings = player['closest_pin_winnings']?.toDouble() ?? 0.0;
        
        // Round individual components to match display
        int roundedSkatWinnings = skatWinnings.round();
        int roundedClosestPinWinnings = closestPinWinnings.round();
        
        totalActualPayouts += (roundedSkatWinnings + roundedClosestPinWinnings).toDouble();
      }

      // Get expected purse for Monday league from Skat purse
      double expectedPurse = await _getExpectedIndividualPurse(League.monday, totalSelectedPlayers);
      
      // Calculate difference (actual - expected)
      double difference = totalActualPayouts - expectedPurse;
      
      // Calculate adjusted mulligan purse
      double adjustedMulliganPurse = currentMulliganPurse - difference;
      
      // Determine if adjustment is needed
      bool requiresAdjustment = difference.abs() > 0.01; // Allow for small rounding differences
      
      // Generate description
      String description = _generateDescription(difference, 'Monday league');

      return PayoutValidationResult(
        totalActualPayouts: totalActualPayouts,
        expectedPurse: expectedPurse,
        difference: difference,
        adjustedMulliganPurse: adjustedMulliganPurse,
        requiresAdjustment: requiresAdjustment,
        description: description,
      );
    } catch (e) {
      // Return neutral result if validation fails
      return PayoutValidationResult(
        totalActualPayouts: 0.0,
        expectedPurse: 0.0,
        difference: 0.0,
        adjustedMulliganPurse: currentMulliganPurse,
        requiresAdjustment: false,
        description: 'Validation failed: $e',
      );
    }
  }

  Future<double> _getExpectedIndividualPurse(League league, int totalSelectedPlayers) async {
    print('Calculating expected individual purse for $league league with $totalSelectedPlayers players');
    
    if (league == League.wednesday) {
      // Use CSV individual amounts for Wednesday league
      print('Using CSV payout service for Wednesday league');
      Map<String, double> payoutData = await CsvPayoutService().getPayoutAmounts(totalSelectedPlayers);
      print('CSV payout data: $payoutData');
      double expectedPurse = payoutData['total_individual'] ?? 0.0;
      print('Expected individual purse from CSV: \$${expectedPurse.toStringAsFixed(2)}');
      return expectedPurse;
    } else {
      // Use Skat Purse calculation for Monday league
      double skatPurse = LeaguePurseService.skatPurse;
      print('Monday league Skat purse: \$${skatPurse.toStringAsFixed(2)}');
      print('Expected individual purse equals Skat purse: \$${skatPurse.toStringAsFixed(2)}');
      return skatPurse;
    }
  }

  Future<double> _getExpectedGroupPurse(League league, int totalSelectedPlayers) async {
    print('Calculating expected group purse for $league league with $totalSelectedPlayers players');
    
    if (league == League.wednesday) {
      // Use CSV group amounts for Wednesday league
      print('Using Group CSV payout service for Wednesday league');
      Map<String, double> groupPayoutData = await GroupCsvPayoutService().getPayoutAmounts(totalSelectedPlayers);
      print('Group CSV payout data: $groupPayoutData');
      double expectedPurse = groupPayoutData['groups_total'] ?? 0.0;
      print('Expected group purse from CSV: \$${expectedPurse.toStringAsFixed(2)}');
      return expectedPurse;
    } else {
      // Monday league doesn't use group payouts - return 0
      print('Monday league does not use group payouts');
      return 0.0;
    }
  }

  String _generateDescription(double difference, String payoutType) {
    if (difference.abs() <= 0.01) {
      return 'Payouts match expected $payoutType purse - no adjustment needed';
    } else if (difference > 0) {
      return 'Payouts exceed expected $payoutType purse by \$${difference.toStringAsFixed(2)} - subtracting from Mulligan purse';
    } else {
      return 'Payouts are \$${(-difference).toStringAsFixed(2)} less than expected $payoutType purse - adding to Mulligan purse';
    }
  }

  Future<double> getExpectedPurseForDisplay({
    required League league,
    required int totalSelectedPlayers,
    required bool isGroupProcessing,
  }) async {
    if (isGroupProcessing) {
      return await _getExpectedGroupPurse(league, totalSelectedPlayers);
    } else {
      return await _getExpectedIndividualPurse(league, totalSelectedPlayers);
    }
  }

  /// Calculates Skat money payouts based on positive DIFF values
  /// Skat Purse / sum of positive DIFF values = Skat Value
  /// Each player's payout = Skat Value * their positive DIFF value
  Map<String, double> calculateSkatPayouts(List<List<dynamic>> groups) {
    Map<String, double> payouts = {};
    
    // Get the Skat Purse amount
    double skatPurse = LeaguePurseService.skatPurse;
    
    // Calculate sum of all positive DIFF values
    double totalPositiveDiff = 0.0;
    List<Map<String, dynamic>> playersWithPositiveDiff = [];
    
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player.diff.isNotEmpty) {
          // Parse the DIFF value (remove + sign if present)
          String diffStr = player.diff.replaceAll('+', '');
          double diffValue = double.tryParse(diffStr) ?? 0.0;
          
          if (diffValue > 0) {
            totalPositiveDiff += diffValue;
            playersWithPositiveDiff.add({
              'name': player.name,
              'diff': diffValue,
            });
          }
        }
      }
    }
    
    // Calculate Skat Value (Skat Purse / sum of positive DIFF values)
    if (totalPositiveDiff > 0) {
      double skatValue = skatPurse / totalPositiveDiff;
      
      // Calculate each player's payout
      for (var playerData in playersWithPositiveDiff) {
        double playerDiff = playerData['diff'];
        double payout = skatValue * playerDiff;
        payouts[playerData['name']] = payout;
      }
    }
    
    return payouts;
  }
}