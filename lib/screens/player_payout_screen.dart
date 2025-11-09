import 'package:flutter/material.dart';
import '../models/league.dart';

class PlayerPayoutScreen extends StatefulWidget {
  const PlayerPayoutScreen({super.key});

  @override
  State<PlayerPayoutScreen> createState() => _PlayerPayoutScreenState();
}

class _PlayerPayoutScreenState extends State<PlayerPayoutScreen> {
  League currentLeague = League.monday;
  List<Map<String, dynamic>> playerScores = [];
  double totalPurse = 0.0;
  int individualPercent = 40;
  int groupPercent = 60;
  double individualPurse = 0.0;
  double groupPurse = 0.0;
  bool winnersCalculated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildPayoutContent()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFE5E5E5), // Light grey
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: const Center(
        child: Text(
          'PLAYER PAYOUT SCREEN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutContent() {
    if (playerScores.isEmpty) {
      return const Center(
        child: Text(
          'No player data available.\nReturn to Enter Scores Screen to process players first.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPurseInfo(),
          const SizedBox(height: 20),
          _buildPlayersList(),
        ],
      ),
    );
  }

  Widget _buildPurseInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Purse Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPurseItem('Total Purse', '\$${totalPurse.toStringAsFixed(2)}'),
                _buildPurseItem('Individual ($individualPercent%)', '\$${individualPurse.toStringAsFixed(2)}'),
                _buildPurseItem('Group ($groupPercent%)', '\$${groupPurse.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurseItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildPlayersList() {
    // Sort players by net score (if available) or gross score
    List<Map<String, dynamic>> sortedPlayers = List.from(playerScores);
    sortedPlayers.sort((a, b) {
      double scoreA = a['net_score']?.toDouble() ?? a['gross_score']?.toDouble() ?? 999.0;
      double scoreB = b['net_score']?.toDouble() ?? b['gross_score']?.toDouble() ?? 999.0;
      return scoreA.compareTo(scoreB);
    });

    return Card(
      elevation: 4,
      child: Column(
        children: [
          Container(
            color: _getLeagueColor(),
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Gross', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Net', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Place', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Winnings', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...sortedPlayers.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> player = entry.value;
            return _buildPlayerRow(player, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player, int index) {
    String playerName = '${player['first'] ?? ''} ${player['last'] ?? ''}'.trim();
    String grossScore = player['gross_score']?.toString() ?? '-';
    String netScore = player['net_score']?.toString() ?? '-';
    String place = player['place']?.toString() ?? '${index + 1}';
    double winnings = player['winnings']?.toDouble() ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              playerName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(grossScore, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(netScore, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(place, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(
              winnings > 0 ? '\$${winnings.toStringAsFixed(2)}' : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: winnings > 0 ? Colors.green : Colors.black,
                fontWeight: winnings > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLeagueColor() {
    return currentLeague == League.monday 
        ? const Color(0xFFB3FFB3)  // Light green
        : const Color(0xFFFFD700); // Light gold
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFFE5E5E5), // Light grey
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterButton(
            'Return to Main Menu',
            const Color(0xFFB3FFFF), // Light cyan
            () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
          _buildFooterButton(
            'Return to Enter Scores',
            _getLeagueColor(),
            () => Navigator.pop(context),
          ),
          _buildFooterButton(
            'Calculate Winners',
            const Color(0xFFE5E5E5), // Light grey
            _calculateWinners,
          ),
          _buildFooterButton(
            'Save Results',
            const Color(0xFFB3FFB3), // Light green
            _saveResults,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(String text, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(
          height: 80,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void setLeague(League league) {
    setState(() {
      currentLeague = league;
    });
  }

  void setPlayerScoresAndGroups(
    List<Map<String, dynamic>> scores,
    List<List<Map<String, dynamic>?>> groups,
    double purse,
    League league,
  ) {
    setState(() {
      playerScores = scores;
      totalPurse = purse;
      currentLeague = league;
      individualPurse = totalPurse * (individualPercent / 100);
      groupPurse = totalPurse * (groupPercent / 100);
    });
  }

  void _calculateWinners() {
    if (playerScores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No player data to calculate winners!')),
      );
      return;
    }

    // Filter players with valid scores
    List<Map<String, dynamic>> validPlayers = playerScores
        .where((player) => player['net_score'] != null || player['gross_score'] != null)
        .toList();

    if (validPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid scores to calculate winners!')),
      );
      return;
    }

    // Sort by net score (or gross if net not available)
    validPlayers.sort((a, b) {
      double scoreA = a['net_score']?.toDouble() ?? a['gross_score']?.toDouble() ?? 999.0;
      double scoreB = b['net_score']?.toDouble() ?? b['gross_score']?.toDouble() ?? 999.0;
      return scoreA.compareTo(scoreB);
    });

    // Calculate winnings (50%, 30%, 20% for top 3)
    List<double> prizePercentages = [0.50, 0.30, 0.20];
    
    for (int i = 0; i < validPlayers.length && i < prizePercentages.length; i++) {
      validPlayers[i]['place'] = '${i + 1}${_getOrdinalSuffix(i + 1)}';
      validPlayers[i]['winnings'] = individualPurse * prizePercentages[i];
    }

    // Set remaining players' places without winnings
    for (int i = prizePercentages.length; i < validPlayers.length; i++) {
      validPlayers[i]['place'] = '${i + 1}${_getOrdinalSuffix(i + 1)}';
      validPlayers[i]['winnings'] = 0.0;
    }

    setState(() {
      winnersCalculated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Winners calculated! ${validPlayers.length} players processed.')),
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  void _saveResults() {
    if (!winnersCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please calculate winners first!')),
      );
      return;
    }

    // TODO: Implement save to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results saved successfully!')),
    );
  }
}