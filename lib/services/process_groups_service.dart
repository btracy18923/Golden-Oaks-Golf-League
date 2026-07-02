import 'dart:math';
import 'group_csv_payout_service.dart';

/// Result object returned by the process groups service
class ProcessGroupsResult {
  final List<List<Map<String, dynamic>?>> newGroups;
  final double groupPurseAmount;
  final double groupPayoutAmount;
  final double mulliganPurseAmount;

  ProcessGroupsResult({
    required this.newGroups,
    required this.groupPurseAmount,
    required this.groupPayoutAmount,
    required this.mulliganPurseAmount,
  });
}

/// Service for processing groups in Wednesday league
/// Handles shuffling players into new groups, calculating group averages,
/// ranking groups, and assigning prizes from CSV data
class ProcessGroupsService {

  /// Processes groups by shuffling players, calculating averages, and assigning prizes
  ///
  /// Takes the current groups structure and returns new groups with:
  /// - Players randomly shuffled into new groups
  /// - Group numbers assigned to each player
  /// - Net score averages calculated per group
  /// - Group rankings and prizes assigned based on average net scores
  ///
  /// Parameters:
  /// - [currentGroups]: The existing groups structure with player data
  /// - [mulliganPurseCarryover]: The adjusted Mulligan Purse amount from the previous screen (simply carried over)
  ///
  /// Returns:
  /// - [ProcessGroupsResult]: Contains the new groups, group purse amount from CSV, group payout sum, and Mulligan Purse carryover
  Future<ProcessGroupsResult> processGroups(
    List<List<Map<String, dynamic>?>> currentGroups,
    double mulliganPurseCarryover,
  ) async {
    // Step 1: Collect all players from all groups (excluding wildcards)
    List<Map<String, dynamic>> allPlayers = _collectAllPlayers(currentGroups);

    // Step 2: Randomly shuffle all players
    allPlayers.shuffle(Random());

    // Step 3: Redistribute players into new groups (4 players per group, 10 groups)
    List<List<Map<String, dynamic>?>> newGroups = _redistributePlayersIntoGroups(allPlayers);

    // Step 4: Fill incomplete groups with wildcard copies
    _fillIncompleteGroupsWithWildcards(newGroups, allPlayers);

    // Step 5: Calculate group averages and create rankings
    List<Map<String, dynamic>> groupRankings = _calculateGroupRankings(newGroups);

    // Step 6: Sort groups by average net score (lowest to highest)
    groupRankings.sort((a, b) => a['average_net'].compareTo(b['average_net']));

    // Step 7: Assign group places and prizes from CSV
    Map<String, double> amounts = await _assignGroupPlacesAndPrizes(groupRankings, allPlayers.length);

    // Step 8: Adjust Mulligan Purse based on Group Purse vs Group Payout difference
    double groupPurse = amounts['groupPurse']!;
    double groupPayout = amounts['groupPayout']!;
    double difference = groupPurse - groupPayout;

    // If Group Payout < Group Purse: add difference to Mulligan Purse
    // If Group Payout > Group Purse: subtract difference from Mulligan Purse
    // If Group Payout == Group Purse: no change
    double adjustedMulliganPurse = mulliganPurseCarryover + difference;

    return ProcessGroupsResult(
      newGroups: newGroups,
      groupPurseAmount: groupPurse,
      groupPayoutAmount: groupPayout,
      mulliganPurseAmount: adjustedMulliganPurse,
    );
  }

  /// Collects all players from current groups into a flat list
  /// Only includes non-wildcard players with valid data (non-null entries)
  /// Excludes wildcard duplicates to avoid double-counting
  /// Keeps essential fields: first name, last name, player number, net score
  List<Map<String, dynamic>> _collectAllPlayers(List<List<Map<String, dynamic>?>> currentGroups) {
    List<Map<String, dynamic>> allPlayers = [];

    for (var group in currentGroups) {
      for (var player in group) {
        // Skip null players and wildcard duplicates
        if (player != null && player['is_wild_card'] != true) {
          // Create a clean copy, keeping only essential fields
          Map<String, dynamic> cleanedPlayer = {
            'first': player['first'],
            'last': player['last'],
            'player_number': player['player_number'],
            'net_score': player['net_score'],
          };
          allPlayers.add(cleanedPlayer);
        }
      }
    }

    return allPlayers;
  }

  /// Redistributes players into new groups
  /// Creates groups of 4 real players (full groups) and groups of 3 real players
  /// (partial groups), so each partial group needs only 1 wildcard.
  ///
  /// Distribution rules (N = total players, r = N % 4):
  ///   r == 0: all full groups, no wildcards
  ///   r == 3: (N÷4) full groups + 1 partial group of 3
  ///   r == 2, N≥6: (N-6)÷4 full groups + 2 partial groups of 3
  ///   r == 1, N≥9: (N-9)÷4 full groups + 3 partial groups of 3
  ///   edge cases (N<9 with r=1, N<6 with r=2): fallback to original behaviour
  List<List<Map<String, dynamic>?>> _redistributePlayersIntoGroups(List<Map<String, dynamic>> allPlayers) {
    int n = allPlayers.length;
    if (n == 0) return [];

    int r = n % 4;
    int numFullGroups;
    int numPartialGroups;

    if (r == 0) {
      numFullGroups = n ~/ 4;
      numPartialGroups = 0;
    } else if (r == 3) {
      numFullGroups = n ~/ 4;
      numPartialGroups = 1;
    } else if (r == 2) {
      if (n >= 6) {
        numPartialGroups = 2;
        numFullGroups = (n - 6) ~/ 4;
      } else {
        numFullGroups = 0;
        numPartialGroups = 1;
      }
    } else { // r == 1
      if (n >= 9) {
        numPartialGroups = 3;
        numFullGroups = (n - 9) ~/ 4;
      } else {
        numFullGroups = n ~/ 4;
        numPartialGroups = 1;
      }
    }

    List<List<Map<String, dynamic>?>> newGroups = [];
    int playerIndex = 0;

    // Full groups: 4 real players each
    for (int gi = 0; gi < numFullGroups; gi++) {
      List<Map<String, dynamic>?> group = [];
      for (int slot = 0; slot < 4; slot++) {
        allPlayers[playerIndex]['manual_group'] = gi + 1;
        group.add(allPlayers[playerIndex]);
        playerIndex++;
      }
      newGroups.add(group);
    }

    // Partial groups: remaining players distributed as evenly as possible
    // (each partial group gets 3 players when N satisfies the constraints above)
    if (numPartialGroups > 0) {
      int remaining = n - playerIndex;
      int base = remaining ~/ numPartialGroups;
      int extra = remaining % numPartialGroups;

      for (int p = 0; p < numPartialGroups; p++) {
        int groupIndex = numFullGroups + p;
        int realCount = base + (p < extra ? 1 : 0);
        List<Map<String, dynamic>?> group = [];

        for (int slot = 0; slot < 4; slot++) {
          if (slot < realCount) {
            allPlayers[playerIndex]['manual_group'] = groupIndex + 1;
            group.add(allPlayers[playerIndex]);
            playerIndex++;
          } else {
            group.add(null);
          }
        }
        newGroups.add(group);
      }
    }

    return newGroups;
  }

  /// Fills every incomplete group with wildcard copies of existing players
  /// so that each such group reaches exactly 4 players.
  /// With the smart distribution from _redistributePlayersIntoGroups, each
  /// partial group has 3 real players and receives exactly 1 wildcard.
  /// Prevents duplicate players within the same group.
  void _fillIncompleteGroupsWithWildcards(List<List<Map<String, dynamic>?>> groups, List<Map<String, dynamic>> allPlayers) {
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      var group = groups[groupIndex];

      int realCount = group.where((p) => p != null).length;
      if (realCount == 0 || realCount >= 4) continue;

      int wildcardsNeeded = 4 - realCount;

      // Build set of players already in this group to avoid duplicates
      Set<String> playersInGroup = {};
      for (var player in group) {
        if (player != null) {
          playersInGroup.add('${player['first']}_${player['last']}');
        }
      }

      // Shuffle all players and pick from those not already in this group
      List<Map<String, dynamic>> shuffledPlayers = List.from(allPlayers);
      shuffledPlayers.shuffle(Random());
      List<Map<String, dynamic>> available = shuffledPlayers.where((p) {
        return !playersInGroup.contains('${p['first']}_${p['last']}');
      }).toList();

      if (available.length < wildcardsNeeded) continue;

      // Fill null slots with wildcard copies
      int wi = 0;
      for (int si = 0; si < group.length && wi < wildcardsNeeded; si++) {
        if (group[si] == null) {
          Map<String, dynamic> wildcardPlayer = Map<String, dynamic>.from(available[wi]);
          wildcardPlayer['is_wild_card'] = true;
          wildcardPlayer['manual_group'] = groupIndex + 1;
          group[si] = wildcardPlayer;
          wi++;
        }
      }
    }
  }

  /// Calculates group rankings based on average net scores
  /// For each group:
  /// - Calculates the average net score
  /// - Assigns the average to all players in the group
  /// - Creates a ranking entry with group info
  List<Map<String, dynamic>> _calculateGroupRankings(List<List<Map<String, dynamic>?>> groups) {
    List<Map<String, dynamic>> groupRankings = [];

    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      var group = groups[groupIndex];
      List<double> netScores = [];
      List<Map<String, dynamic>> playersInGroup = [];

      // Collect net scores from all players in the group
      for (var player in group) {
        if (player != null && player['net_score'] != null) {
          try {
            double netScore = (player['net_score']).toDouble();
            netScores.add(netScore);
            playersInGroup.add(player);
          } catch (e) {
            // Skip players with invalid net scores
          }
        }
      }

      // Calculate average and create ranking entry
      if (netScores.isNotEmpty) {
        double averageNet = netScores.reduce((a, b) => a + b) / netScores.length;

        // Assign average to all players in group
        for (var player in playersInGroup) {
          player['avg_net'] = averageNet.toStringAsFixed(1);
        }

        groupRankings.add({
          'group_index': groupIndex,
          'average_net': averageNet,
          'players': playersInGroup,
        });
      }
    }

    return groupRankings;
  }

  /// Assigns group places and prize money using CSV data
  /// Loads payout amounts from Group_Payouts.csv based on player count
  /// Assigns prizes to each player based on their group's ranking
  ///
  /// Parameters:
  /// - [groupRankings]: The ranked groups with player data
  /// - [originalPlayerCount]: The count of non-wildcard players for CSV lookup
  ///
  /// Returns a map with:
  /// - 'groupPurse': Team Total amount from CSV for "Group Purse" display
  /// - 'groupPayout': Sum of all prize money from $$$ column for "Group Payout" display
  Future<Map<String, double>> _assignGroupPlacesAndPrizes(List<Map<String, dynamic>> groupRankings, int originalPlayerCount) async {
    if (groupRankings.isEmpty) return {'groupPurse': 0.0, 'groupPayout': 0.0};

    try {
      // Load prize amounts from CSV using original player count (excluding wildcards)
      final csvService = GroupCsvPayoutService();
      Map<String, double> payouts = await csvService.getPayoutAmounts(originalPlayerCount);

      // Extract the Team Total amount from CSV for "Group Purse" display
      double teamTotalAmount = payouts['team_total'] ?? 0.0;

      // Individual team amounts for each place (1st through 4th)
      Map<int, double> individualTeamAmounts = {
        1: payouts['1st_team_ind'] ?? 0.0,
        2: payouts['2nd_team_ind'] ?? 0.0,
        3: payouts['3rd_team_ind'] ?? 0.0,
        4: payouts['4th_team_ind'] ?? 0.0,
      };

      // Track total prize money distributed (sum of $$$ column)
      double totalPrizeMoney = 0.0;

      // Assign places and prizes to each group
      for (int rankIndex = 0; rankIndex < groupRankings.length; rankIndex++) {
        int place = rankIndex + 1;
        var groupData = groupRankings[rankIndex];
        List<Map<String, dynamic>> players = groupData['players'];

        // Get the prize amount for this place (or 0 if beyond 4th place)
        double individualTeamAmount = individualTeamAmounts[place] ?? 0.0;
        int roundedAmount = individualTeamAmount.round();

        // Assign place and prize money to all players in the group
        // Each player in the winning group receives the full prize amount
        for (var player in players) {
          player['grp_pos'] = place.toString();
          player['prize_money'] = '\$$roundedAmount';
          // Add each player's prize to total payout sum
          totalPrizeMoney += roundedAmount;
        }
      }

      return {
        'groupPurse': teamTotalAmount,
        'groupPayout': totalPrizeMoney,
      };
    } catch (e) {
      // Return 0 if CSV fails to load
      return {'groupPurse': 0.0, 'groupPayout': 0.0};
    }
  }
}
