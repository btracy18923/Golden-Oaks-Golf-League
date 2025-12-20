import 'package:flutter/material.dart';
import '../../models/league.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayPlayerPayoutScreen extends StatefulWidget {
  const WednesdayPlayerPayoutScreen({super.key});

  @override
  State<WednesdayPlayerPayoutScreen> createState() => _WednesdayPlayerPayoutScreenState();
}

class _WednesdayPlayerPayoutScreenState extends State<WednesdayPlayerPayoutScreen> {
  // Hard-coded Wednesday league
  League currentLeague = League.wednesday;
  List<Map<String, dynamic>> playerScores = [];
  double totalPurse = 0.0;
  int individualPercent = 40;
  int groupPercent = 60;
  double individualPurse = 0.0;
  double groupPurse = 0.0;
  bool winnersCalculated = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet10: _buildTablet10Layout(),
    );
  }
  
  Widget _buildPhoneLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(16),
          Expanded(child: _buildPayoutContent()),
          _buildPhoneFooter(),
        ],
      ),
    );
  }
  
  Widget _buildTablet10Layout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(20),
          Expanded(child: _buildPayoutContent()),
          _buildTabletFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(double fontSize) {
    return Container(
      color: const Color(0xFFE5E5E5),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          'WEDNESDAY LEAGUE - PLAYER PAYOUTS',
          style: TextStyle(
            fontSize: fontSize,
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

  Widget _buildPhoneFooter() {
    return Container(
      color: const Color(0xFFE5E5E5),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFooterButton(
                  'Main Menu',
                  const Color(0xFFB3FFFF),
                  () => Navigator.popUntil(context, (route) => route.isFirst),
                  12,
                  50,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildFooterButton(
                  'Enter Scores',
                  _getLeagueColor(),
                  () => Navigator.pop(context),
                  12,
                  50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildFooterButton(
                  'Calculate Winners',
                  const Color(0xFFE5E5E5),
                  _calculateWinners,
                  12,
                  50,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildFooterButton(
                  'Save Results',
                  const Color(0xFFB3FFB3),
                  _saveResults,
                  12,
                  50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabletFooter() {
    return Container(
      color: const Color(0xFFE5E5E5),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterButton(
            'Return to Main Menu',
            const Color(0xFFB3FFFF),
            () => Navigator.popUntil(context, (route) => route.isFirst),
            16,
            80,
          ),
          _buildFooterButton(
            'Return to Enter Scores',
            _getLeagueColor(),
            () => Navigator.pop(context),
            16,
            80,
          ),
          _buildFooterButton(
            'Calculate Winners',
            const Color(0xFFE5E5E5),
            _calculateWinners,
            16,
            80,
          ),
          _buildFooterButton(
            'Save Results',
            const Color(0xFFB3FFB3),
            _saveResults,
            16,
            80,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(String text, Color color, VoidCallback onPressed, double fontSize, double height) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(
          height: height,
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
              style: TextStyle(
                fontSize: fontSize,
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