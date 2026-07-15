/// Service for calculating golf handicaps for Wednesday league
///
/// Implements a simplified handicap calculation algorithm based on recent scores
class HandicapCalculationService {
  /// Fixed padding score used when a player has fewer than 6 recorded rounds.
  static const double paddingScore = 44;

  /// Rounds a value to 1 decimal place
  double _roundToOneDecimal(double value) {
    return (value * 10).round() / 10;
  }

  /// Calculates handicap for Wednesday league
  ///
  /// Algorithm based on the first 6 latest scores with positive gross data:
  /// - Fewer than 6 scores: pad the remaining slots with [paddingScore]
  /// - Drop the highest and lowest of the 6 scores
  /// - HC = (Average of the remaining 4 scores) - 35
  ///
  /// [grossScores] - List of gross scores (most recent first recommended)
  ///
  /// Returns the calculated handicap rounded to 1 decimal place
  double calculateWednesdayHandicap({
    required List<int> grossScores,
  }) {
    if (grossScores.isEmpty) {
      return 0.0;
    }

    // Only use the first 6 scores
    List<double> scoresToUse = grossScores.take(6).map((s) => s.toDouble()).toList();

    // Pad the scores list to 6 total scores using the fixed padding score
    while (scoresToUse.length < 6) {
      scoresToUse.add(paddingScore);
    }

    // Sort the 6 scores
    List<double> sorted = List.from(scoresToUse)..sort();

    // Drop the highest score (last) and lowest score (first)
    sorted.removeLast();
    sorted.removeAt(0);

    // Calculate average of remaining 4 scores
    double avg = sorted.reduce((a, b) => a + b) / 4.0;

    // Calculate handicap: Avg - 35
    double handicap = avg - 35;

    // Round to 1 decimal place
    return _roundToOneDecimal(handicap);
  }
}