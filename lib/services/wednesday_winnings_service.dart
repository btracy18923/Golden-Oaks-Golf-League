import 'csv_payout_service.dart';
import 'group_csv_payout_service.dart';

/// Service for calculating Wednesday league winnings and positions
/// Extracts business logic from the Wednesday Enter Scores screen
class WednesdayWinningsService {
  static final WednesdayWinningsService _instance = WednesdayWinningsService._internal();
  factory WednesdayWinningsService() => _instance;
  WednesdayWinningsService._internal();

  /// Calculates individual winnings based on net scores and purse amount
  /// Returns a map of player names to their calculated winnings
  Future<Map<String, WinningsResult>> calculateIndividualWinnings(
    List<Map<String, dynamic>> playerScores,
    double totalPurse,
  ) async {
    Map<String, WinningsResult> results = {};

    if (playerScores.isEmpty) return results;

    // Sort players by net score (ascending - lower is better)
    List<Map<String, dynamic>> sortedPlayers = List.from(playerScores);
    sortedPlayers.sort((a, b) {
      int netA = a['net_score'] ?? 999;
      int netB = b['net_score'] ?? 999;
      return netA.compareTo(netB);
    });

    // Get payout percentages from CSV service
    int playerCount = sortedPlayers.length;
    List<double> payoutPercentages = await _getPayoutPercentages(playerCount);

    // Calculate positions with tie handling
    int currentPlace = 1;
    int playersAtSameScore = 0;
    int? lastNetScore;

    for (int i = 0; i < sortedPlayers.length; i++) {
      var player = sortedPlayers[i];
      int netScore = player['net_score'] ?? 999;
      String playerName = player['last'] ?? '';

      // Check for ties
      if (lastNetScore != null && netScore == lastNetScore) {
        playersAtSameScore++;
      } else {
        currentPlace = i + 1;
        playersAtSameScore = 1;
      }

      // Calculate winnings based on position
      double winnings = 0.0;
      bool isTied = false;

      if (currentPlace <= payoutPercentages.length) {
        // Check for tie at this position
        int tiedPlayers = _countPlayersWithScore(sortedPlayers, netScore);
        if (tiedPlayers > 1) {
          isTied = true;
          // Split prize money among tied players
          double combinedPercentage = 0.0;
          for (int j = currentPlace - 1; j < currentPlace - 1 + tiedPlayers && j < payoutPercentages.length; j++) {
            combinedPercentage += payoutPercentages[j];
          }
          winnings = (combinedPercentage / tiedPlayers) * totalPurse / 100;
        } else {
          winnings = payoutPercentages[currentPlace - 1] * totalPurse / 100;
        }
      }

      results[playerName] = WinningsResult(
        place: currentPlace,
        winnings: winnings,
        isTied: isTied,
        netScore: netScore,
      );

      lastNetScore = netScore;
    }

    return results;
  }

  /// Gets payout percentages for a given player count
  Future<List<double>> _getPayoutPercentages(int playerCount) async {
    try {
      final csvService = CsvPayoutService();
      await csvService.loadPayoutData();

      // Get payout data for player count
      Map<String, double> payouts = await csvService.getPayoutAmounts(playerCount);

      if (payouts.isNotEmpty) {
        // Extract position payouts in order
        List<double> percentages = [];
        List<String> positions = ['1st', '2nd', '3rd', '4th', '5th', '6th'];
        for (String pos in positions) {
          double amount = payouts[pos] ?? 0.0;
          if (amount > 0) {
            percentages.add(amount);
          }
        }
        if (percentages.isNotEmpty) {
          return percentages;
        }
      }
    } catch (e) {
      // Fall back to default percentages
    }

    // Default payout percentages if CSV not available
    return _getDefaultPayoutPercentages(playerCount);
  }

  /// Default payout percentages based on player count
  List<double> _getDefaultPayoutPercentages(int playerCount) {
    if (playerCount <= 6) {
      return [50.0, 30.0, 20.0];
    } else if (playerCount <= 10) {
      return [40.0, 25.0, 18.0, 12.0, 5.0];
    } else if (playerCount <= 15) {
      return [35.0, 22.0, 16.0, 12.0, 8.0, 5.0, 2.0];
    } else {
      return [30.0, 20.0, 15.0, 12.0, 10.0, 7.0, 4.0, 2.0];
    }
  }

  /// Counts players with a specific net score
  int _countPlayersWithScore(List<Map<String, dynamic>> players, int netScore) {
    return players.where((p) => p['net_score'] == netScore).length;
  }

  /// Calculates group winnings based on group average scores
  Future<Map<int, GroupWinningsResult>> calculateGroupWinnings(
    List<List<Map<String, dynamic>?>> groups,
    double groupPurse,
  ) async {
    Map<int, GroupWinningsResult> results = {};

    // Calculate average net score for each group
    List<GroupScore> groupScores = [];
    for (int i = 0; i < groups.length; i++) {
      var group = groups[i];
      List<int> netScores = [];

      for (var player in group) {
        if (player != null && player['net_score'] != null) {
          netScores.add(player['net_score'] as int);
        }
      }

      if (netScores.isNotEmpty) {
        double average = netScores.reduce((a, b) => a + b) / netScores.length;
        groupScores.add(GroupScore(groupIndex: i, averageScore: average, playerCount: netScores.length));
      }
    }

    // Sort groups by average score (ascending - lower is better)
    groupScores.sort((a, b) => a.averageScore.compareTo(b.averageScore));

    // Get group payout percentages
    List<double> groupPayoutPercentages = await _getGroupPayoutPercentages(groupScores.length);

    // Assign positions and winnings
    for (int i = 0; i < groupScores.length; i++) {
      var groupScore = groupScores[i];
      double winnings = 0.0;

      if (i < groupPayoutPercentages.length) {
        winnings = groupPayoutPercentages[i] * groupPurse / 100;
      }

      results[groupScore.groupIndex] = GroupWinningsResult(
        place: i + 1,
        averageScore: groupScore.averageScore,
        totalWinnings: winnings,
        playerCount: groupScore.playerCount,
      );
    }

    return results;
  }

  /// Gets group payout percentages
  Future<List<double>> _getGroupPayoutPercentages(int groupCount) async {
    try {
      final groupCsvService = GroupCsvPayoutService();
      await groupCsvService.loadPayoutData();

      // Use getPayoutList which returns team payouts
      List<double> payouts = await groupCsvService.getPayoutList(groupCount);

      if (payouts.isNotEmpty && payouts.any((p) => p > 0)) {
        return payouts.where((p) => p > 0).toList();
      }
    } catch (e) {
      // Fall back to default
    }

    // Default group payouts
    if (groupCount <= 3) {
      return [60.0, 40.0];
    } else if (groupCount <= 5) {
      return [45.0, 30.0, 25.0];
    } else {
      return [40.0, 28.0, 20.0, 12.0];
    }
  }

  /// Formats position string (handles ties)
  String formatPosition(int place, bool isTied) {
    if (isTied) {
      return 'T$place';
    }
    return place.toString();
  }

  /// Formats winnings as currency string
  String formatWinnings(double winnings) {
    int rounded = winnings.round();
    if (rounded > 0) {
      return '\$$rounded';
    }
    return '';
  }
}

/// Result of individual winnings calculation
class WinningsResult {
  final int place;
  final double winnings;
  final bool isTied;
  final int netScore;

  WinningsResult({
    required this.place,
    required this.winnings,
    required this.isTied,
    required this.netScore,
  });
}

/// Result of group winnings calculation
class GroupWinningsResult {
  final int place;
  final double averageScore;
  final double totalWinnings;
  final int playerCount;

  GroupWinningsResult({
    required this.place,
    required this.averageScore,
    required this.totalWinnings,
    required this.playerCount,
  });

  /// Calculates per-player winnings
  double get perPlayerWinnings => playerCount > 0 ? totalWinnings / playerCount : 0.0;
}

/// Helper class for group score calculation
class GroupScore {
  final int groupIndex;
  final double averageScore;
  final int playerCount;

  GroupScore({
    required this.groupIndex,
    required this.averageScore,
    required this.playerCount,
  });
}
