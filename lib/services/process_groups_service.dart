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

    // Debug output
    print('=== MULLIGAN PURSE ADJUSTMENT ===');
    print('Group Purse: \$${groupPurse.toStringAsFixed(2)}');
    print('Group Payout: \$${groupPayout.toStringAsFixed(2)}');
    print('Difference: \$${difference.toStringAsFixed(2)}');
    print('Initial Mulligan: \$${mulliganPurseCarryover.toStringAsFixed(2)}');
    print('Adjusted Mulligan: \$${adjustedMulliganPurse.toStringAsFixed(2)}');
    print('=================================');

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
  /// Creates 10 groups with 4 slots each
  /// Assigns group numbers to each player
  List<List<Map<String, dynamic>?>> _redistributePlayersIntoGroups(List<Map<String, dynamic>> allPlayers) {
    List<List<Map<String, dynamic>?>> newGroups = [];
    int playerIndex = 0;

    for (int groupIndex = 0; groupIndex < 10; groupIndex++) {
      List<Map<String, dynamic>?> group = [];

      for (int slotIndex = 0; slotIndex < 4; slotIndex++) {
        if (playerIndex < allPlayers.length) {
          // Assign group number to player (1-based)
          allPlayers[playerIndex]['manual_group'] = groupIndex + 1;
          group.add(allPlayers[playerIndex]);
          playerIndex++;
        } else {
          // Empty slot
          group.add(null);
        }
      }

      newGroups.add(group);
    }

    return newGroups;
  }

  /// Fills incomplete groups with wildcard copies of existing players
  /// Ensures all groups with at least 1 player have exactly 4 players
  /// Prevents duplicate players within the same group
  void _fillIncompleteGroupsWithWildcards(List<List<Map<String, dynamic>?>> groups, List<Map<String, dynamic>> allPlayers) {
    // Find the last group with players
    int lastGroupIndex = -1;
    for (int i = groups.length - 1; i >= 0; i--) {
      if (groups[i].any((player) => player != null)) {
        lastGroupIndex = i;
        break;
      }
    }

    if (lastGroupIndex == -1) return; // No groups with players

    // Count players in the last group
    int playersInLastGroup = groups[lastGroupIndex].where((player) => player != null).length;

    if (playersInLastGroup >= 4) return; // Last group is already full

    // Calculate how many wildcards are needed
    int playersNeeded = 4 - playersInLastGroup;

    // Get the list of players already in the last group (to avoid duplicates)
    Set<String> playersInGroup = {};
    for (var player in groups[lastGroupIndex]) {
      if (player != null) {
        String playerKey = '${player['first']}_${player['last']}';
        playersInGroup.add(playerKey);
      }
    }

    // Shuffle available players and filter out those already in the group
    List<Map<String, dynamic>> shuffledPlayers = List.from(allPlayers);
    shuffledPlayers.shuffle(Random());

    List<Map<String, dynamic>> availableWildcards = shuffledPlayers.where((player) {
      String playerKey = '${player['first']}_${player['last']}';
      return !playersInGroup.contains(playerKey);
    }).toList();

    if (availableWildcards.length < playersNeeded) {
      // Not enough unique players available for wildcards
      return;
    }

    // Fill empty slots in the last group with wildcard copies
    int wildcardIndex = 0;
    for (int slotIndex = 0; slotIndex < groups[lastGroupIndex].length && wildcardIndex < playersNeeded; slotIndex++) {
      if (groups[lastGroupIndex][slotIndex] == null) {
        // Create a wildcard copy of a player not already in the group
        Map<String, dynamic> wildcardPlayer = Map<String, dynamic>.from(availableWildcards[wildcardIndex]);
        wildcardPlayer['is_wild_card'] = true;
        wildcardPlayer['manual_group'] = lastGroupIndex + 1; // Assign to last group (1-based)

        groups[lastGroupIndex][slotIndex] = wildcardPlayer;
        wildcardIndex++;
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
      List<int> netScores = [];
      List<Map<String, dynamic>> playersInGroup = [];

      // Collect net scores from all players in the group
      for (var player in group) {
        if (player != null && player['net_score'] != null) {
          try {
            int netScore = player['net_score'] is int
                ? player['net_score']
                : int.parse(player['net_score'].toString());
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
          player['pos'] = place.toString();
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
