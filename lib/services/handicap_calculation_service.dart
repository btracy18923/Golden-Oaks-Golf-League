/// Service for calculating golf handicaps for Wednesday league
///
/// Implements a simplified handicap calculation algorithm based on recent scores
class HandicapCalculationService {
  /// Rounds a value to 1 decimal place
  double _roundToOneDecimal(double value) {
    return (value * 10).round() / 10;
  }

  /// Calculates handicap for Wednesday league using OHC padding algorithm
  ///
  /// Algorithm based on the first 6 latest scores with positive gross data:
  /// - 1 score: Add 5 (OHC + 35) as the 2nd-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 2 scores: Add 4 (OHC + 35) as the 3rd-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 3 scores: Add 3 (OHC + 35) as the 4th-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 4 scores: Add 2 (OHC + 35) as the 5th-6th scores, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 5 scores: Add 1 (OHC + 35) as the 6th score, drop 2 highest, HC = (Avg of 4 remaining) - 35
  /// - 6+ scores: Drop 2 highest, HC = (Avg of 4 remaining) - 35
  ///
  /// [grossScores] - List of gross scores (most recent first recommended)
  /// [originalHandicap] - The player's OHC (Original Handicap) value
  ///
  /// Returns the calculated handicap rounded to 1 decimal place
  double calculateWednesdayHandicap({
    required List<int> grossScores,
    required double originalHandicap,
  }) {
    if (grossScores.isEmpty) {
      return 0.0;
    }

    // Only use the first 6 scores
    List<double> scoresToUse = grossScores.take(6).map((s) => s.toDouble()).toList();
    int scoreCount = scoresToUse.length;

    // Calculate the padding value: OHC + 35
    double paddingValue = originalHandicap + 35;

    // Pad the scores list to 6 total scores using (OHC + 35)
    while (scoresToUse.length < 6) {
      scoresToUse.add(paddingValue);
    }

    // Sort the 6 scores
    List<double> sorted = List.from(scoresToUse)..sort();

    // Drop the 2 highest scores (last 2 in sorted list)
    sorted.removeLast();
    sorted.removeLast();

    // Calculate average of remaining 4 scores
    double avg = sorted.reduce((a, b) => a + b) / 4.0;

    // Calculate handicap: Avg - 35
    double handicap = avg - 35;

    // Round to 1 decimal place
    return _roundToOneDecimal(handicap);
  }
}
