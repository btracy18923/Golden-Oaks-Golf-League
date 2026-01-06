import 'package:url_launcher/url_launcher.dart';

/// Service to handle email functionality for sending player information to ProShop
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Sends an email with the list of selected players organized by groups
  ///
  /// Parameters:
  /// - [groups]: List of groups, where each group is a list of player maps
  /// - [recipientEmail]: Email address to send to (defaults to ProShop email)
  ///
  /// Returns:
  /// - true if email client was successfully opened
  /// - false if there was an error
  Future<bool> sendPlayerListEmailByGroups({
    required List<List<Map<String, dynamic>?>> groups,
    String recipientEmail = 'btracy18923@gmail.com', // Default email - change as needed
  }) async {
    try {
      // Filter out empty groups and empty players
      final validGroups = <List<Map<String, dynamic>>>[];
      for (var group in groups) {
        final validPlayers = group.where((player) {
          if (player == null) return false;
          final name = player['last']?.toString() ?? '';
          return name.isNotEmpty;
        }).cast<Map<String, dynamic>>().toList();

        if (validPlayers.isNotEmpty) {
          validGroups.add(validPlayers);
        }
      }

      if (validGroups.isEmpty) {
        return false;
      }

      // Build email subject
      final subject = 'Golden Oaks Wed. Players - ${DateTime.now().toString().split(' ')[0]}';

      // Build email body with groups
      final body = _buildEmailBodyByGroups(validGroups);

      // Create mailto URL with proper encoding
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body,
        }),
      );

      // Launch email client with mode set to externalApplication
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      return false;
    }
  }

  /// Sends an email with the list of selected players and their ID numbers
  ///
  /// Parameters:
  /// - [selectedPlayers]: List of player maps containing player information
  /// - [recipientEmail]: Email address to send to (defaults to ProShop email)
  ///
  /// Returns:
  /// - true if email client was successfully opened
  /// - false if there was an error
  Future<bool> sendPlayerListEmail({
    required List<Map<String, dynamic>> selectedPlayers,
    String recipientEmail = 'btracy18923@gmail.com', // Default email - change as needed
  }) async {
    try {
      // Filter out empty players
      final validPlayers = selectedPlayers.where((player) {
        final name = player['last']?.toString() ?? '';
        return name.isNotEmpty;
      }).toList();

      if (validPlayers.isEmpty) {
        return false;
      }

      // Build email subject
      final subject = 'Selected Players List - ${DateTime.now().toString().split(' ')[0]}';

      // Build email body
      final body = _buildEmailBody(validPlayers);

      // Create mailto URL with proper encoding
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body,
        }),
      );

      // Launch email client with mode set to externalApplication
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      return false;
    }
  }

  /// Builds the email body with players organized by groups
  String _buildEmailBodyByGroups(List<List<Map<String, dynamic>>> groups) {
    final buffer = StringBuffer();

    int totalPlayers = 0;
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      buffer.writeln('Group ${groupIndex + 1}:');

      for (int playerIndex = 0; playerIndex < group.length; playerIndex++) {
        final player = group[playerIndex];
        final playerNumberRaw = player['player_number']?.toString() ?? '';
        final playerNumber = playerNumberRaw.isEmpty ? 'N/A' : playerNumberRaw.padLeft(4, '0');
        final firstName = player['first']?.toString() ?? '';
        final lastName = player['last']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();

        buffer.writeln('  $playerNumber - $fullName');
        totalPlayers++;
      }

      buffer.writeln(); // Empty line between groups
    }

    buffer.writeln('Total Players: $totalPlayers');
    buffer.writeln();
    buffer.writeln('Generated on: ${DateTime.now()}');

    return buffer.toString();
  }

  /// Builds the email body with player information
  String _buildEmailBody(List<Map<String, dynamic>> players) {
    final buffer = StringBuffer();
    buffer.writeln('Selected Players:');
    buffer.writeln();

    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final playerNumberRaw = player['player_number']?.toString() ?? '';
      final playerNumber = playerNumberRaw.isEmpty ? 'N/A' : playerNumberRaw.padLeft(4, '0');
      final firstName = player['first']?.toString() ?? '';
      final lastName = player['last']?.toString() ?? '';
      final fullName = '$firstName $lastName'.trim();

      buffer.writeln('$playerNumber - $fullName');
    }

    buffer.writeln();
    buffer.writeln('Total Players: ${players.length}');
    buffer.writeln();
    buffer.writeln('Generated on: ${DateTime.now()}');

    return buffer.toString();
  }

  /// Encodes query parameters for mailto URL
  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Sends email with custom recipient
  Future<bool> sendPlayerListEmailToCustomRecipient({
    required List<Map<String, dynamic>> selectedPlayers,
    required String recipientEmail,
  }) async {
    return sendPlayerListEmail(
      selectedPlayers: selectedPlayers,
      recipientEmail: recipientEmail,
    );
  }

  /// Sends an email with Wednesday league results
  ///
  /// Parameters:
  /// - [groups]: List of groups with player data
  /// - [individualWinners]: List of individual winners
  /// - [playersAnte]: Amount each player contributed
  /// - [closestPinAmount]: Closest pin amount
  /// - [mulliganAmount]: Mulligan amount
  /// - [groupPayoutAmount]: Total group payout
  /// - [adjustedMulliganPurse]: Party fund amount
  /// - [selectedGolfCourse]: Name of the golf course
  /// - [playerClosestPinWinnings]: Map of closest pin winners and amounts
  /// - [recipientEmail]: Email address to send to
  ///
  /// Returns:
  /// - true if email client was successfully opened
  /// - false if there was an error
  Future<bool> sendWednesdayResultsEmail({
    required List<List<Map<String, dynamic>?>> groups,
    required List<Map<String, dynamic>> individualWinners,
    required double playersAnte,
    required double closestPinAmount,
    required double mulliganAmount,
    required double groupPayoutAmount,
    required double adjustedMulliganPurse,
    required String selectedGolfCourse,
    required Map<String, double> playerClosestPinWinnings,
    String recipientEmail = 'btracy18923@gmail.com',
  }) async {
    try {
      // Build email subject with date
      final currentDate = DateTime.now().toString().split(' ')[0];
      final subject = 'Wednesday League Results - $currentDate';

      // Build email body with results data
      final body = _buildWednesdayResultsBody(
        groups: groups,
        individualWinners: individualWinners,
        playersAnte: playersAnte,
        closestPinAmount: closestPinAmount,
        mulliganAmount: mulliganAmount,
        groupPayoutAmount: groupPayoutAmount,
        adjustedMulliganPurse: adjustedMulliganPurse,
        selectedGolfCourse: selectedGolfCourse,
        playerClosestPinWinnings: playerClosestPinWinnings,
        currentDate: currentDate,
      );

      // Create mailto URL with proper encoding
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body,
        }),
      );

      // Launch email client
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      return false;
    }
  }

  /// Builds the email body for Wednesday league results
  String _buildWednesdayResultsBody({
    required List<List<Map<String, dynamic>?>> groups,
    required List<Map<String, dynamic>> individualWinners,
    required double playersAnte,
    required double closestPinAmount,
    required double mulliganAmount,
    required double groupPayoutAmount,
    required double adjustedMulliganPurse,
    required String selectedGolfCourse,
    required Map<String, double> playerClosestPinWinnings,
    required String currentDate,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('WEDNESDAY LEAGUE RESULTS');
    buffer.writeln('Date: $currentDate');
    buffer.writeln('Golf Course: $selectedGolfCourse');
    buffer.writeln('=' * 50);
    buffer.writeln();

    // Count total players
    int totalPlayers = 0;
    for (var group in groups) {
      for (var player in group) {
        if (player != null && player['last'] != null && player['last'].toString().isNotEmpty) {
          totalPlayers++;
        }
      }
    }

    // League Setup
    buffer.writeln('LEAGUE SETUP:');
    buffer.writeln('  Players\' Ante: \$${playersAnte.toStringAsFixed(2)}');
    buffer.writeln('  Closest Pin: \$${closestPinAmount.toStringAsFixed(2)}');
    buffer.writeln('  Mulligans: \$${mulliganAmount.toStringAsFixed(2)}');
    buffer.writeln('  Total Players: $totalPlayers');
    final collectAmount = (playersAnte + closestPinAmount + mulliganAmount) * totalPlayers;
    buffer.writeln('  Collect: \$${collectAmount.toStringAsFixed(2)}');
    buffer.writeln('  Party Fund: \$${adjustedMulliganPurse.toStringAsFixed(2)}');
    buffer.writeln();

    // Closest Pin Winners
    if (playerClosestPinWinnings.isNotEmpty) {
      buffer.writeln('CLOSEST PIN WINNERS:');
      final sortedWinners = playerClosestPinWinnings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedWinners) {
        if (entry.value > 0) {
          buffer.writeln('  ${entry.key}: \$${entry.value.toStringAsFixed(2)}');
        }
      }
      buffer.writeln();
    }

    // Individual Winners
    int individualWinnersCount = 0;
    double totalIndividualPayout = 0.0;

    for (var player in individualWinners) {
      if (player['prize_money'] != null) {
        String prizeMoney = player['prize_money'].toString();
        if (prizeMoney.contains('\$')) {
          try {
            double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
            if (amount > 0) {
              individualWinnersCount++;
              totalIndividualPayout += amount;
            }
          } catch (e) {
            // Skip if parsing fails
          }
        }
      }
    }

    if (individualWinnersCount > 0) {
      buffer.writeln('INDIVIDUAL WINNERS:');
      buffer.writeln('  Winners: $individualWinnersCount');
      buffer.writeln('  Total Payout: \$${totalIndividualPayout.toStringAsFixed(2)}');
      buffer.writeln();

      for (var player in individualWinners) {
        if (player['prize_money'] != null && player['last'] != null) {
          String prizeMoney = player['prize_money'].toString();
          if (prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              if (amount > 0) {
                buffer.writeln('  ${player['last']}: $prizeMoney');
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }
        }
      }
      buffer.writeln();
    }

    // Group Winners
    int groupWinnersCount = 0;
    Map<String, double> groupWinnersMap = {};

    for (var group in groups) {
      for (var player in group) {
        if (player != null &&
            player['prize_money'] != null &&
            player['manual_group'] != null &&
            player['last'] != null) {
          String prizeMoney = player['prize_money'].toString();
          if (prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              if (amount > 0) {
                groupWinnersCount++;
                groupWinnersMap[player['last'].toString()] = amount;
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }
        }
      }
    }

    if (groupWinnersCount > 0) {
      buffer.writeln('GROUP WINNERS:');
      buffer.writeln('  Winners: $groupWinnersCount');
      buffer.writeln('  Total Payout: \$${groupPayoutAmount.toStringAsFixed(2)}');
      buffer.writeln();

      for (var entry in groupWinnersMap.entries) {
        buffer.writeln('  ${entry.key}: \$${entry.value.toStringAsFixed(2)}');
      }
      buffer.writeln();
    }

    // Consolidated Payout Table
    Map<String, Map<String, dynamic>> allWinners = {};

    // Add individual winners
    for (var player in individualWinners) {
      if (player['prize_money'] != null && player['last'] != null) {
        String prizeMoney = player['prize_money'].toString();
        if (prizeMoney.contains('\$')) {
          try {
            double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
            if (amount > 0) {
              String playerName = player['last'].toString();
              allWinners[playerName] = {
                'individual_winnings': amount,
                'group_winnings': 0.0,
              };
            }
          } catch (e) {
            // Skip if parsing fails
          }
        }
      }
    }

    // Add group winners
    for (var entry in groupWinnersMap.entries) {
      if (allWinners.containsKey(entry.key)) {
        allWinners[entry.key]!['group_winnings'] = entry.value;
      } else {
        allWinners[entry.key] = {
          'individual_winnings': 0.0,
          'group_winnings': entry.value,
        };
      }
    }

    if (allWinners.isNotEmpty) {
      buffer.writeln('CONSOLIDATED PAYOUT:');
      buffer.writeln('Player                Ind \$\$\$    Group \$\$\$  Total \$\$\$');
      buffer.writeln('-' * 60);

      // Sort by total winnings descending
      final sortedWinners = allWinners.entries.toList()
        ..sort((a, b) {
          double totalA = (a.value['individual_winnings'] as double) + (a.value['group_winnings'] as double);
          double totalB = (b.value['individual_winnings'] as double) + (b.value['group_winnings'] as double);
          return totalB.compareTo(totalA);
        });

      for (var entry in sortedWinners) {
        double individualWinnings = entry.value['individual_winnings'] as double;
        double groupWinnings = entry.value['group_winnings'] as double;
        double totalWinnings = individualWinnings + groupWinnings;

        String name = entry.key.padRight(20);
        String indStr = individualWinnings > 0
            ? '\$${individualWinnings.toStringAsFixed(2)}'.padLeft(10)
            : ''.padLeft(10);
        String grpStr = groupWinnings > 0
            ? '\$${groupWinnings.toStringAsFixed(2)}'.padLeft(11)
            : ''.padLeft(11);
        String totStr = '\$${totalWinnings.toStringAsFixed(2)}'.padLeft(11);

        buffer.writeln('$name $indStr $grpStr $totStr');
      }
      buffer.writeln();
    }

    buffer.writeln('Generated on: ${DateTime.now()}');

    return buffer.toString();
  }
}
