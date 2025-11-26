import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../main_menu_screen.dart';

class MondayResultsScreen extends StatefulWidget {
  const MondayResultsScreen({super.key});

  @override
  State<MondayResultsScreen> createState() => _MondayResultsScreenState();
}

class _MondayResultsScreenState extends State<MondayResultsScreen> {
  final ScreenDataRetentionService _retentionService = ScreenDataRetentionService();

  @override
  void initState() {
    super.initState();
    _setOrientation();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Monday League
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    // Allow all orientations when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// Returns to the main menu and clears retained data
  void _returnToMainMenu() {
    // Clear all retained data for a fresh session
    _retentionService.clearAllData();
    
    // Navigate back to main menu, removing all previous screens from stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const UnifiedMainMenuScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final is6InchPhone = isLandscape && screenSize.width <= 900;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: EdgeInsets.all(is6InchPhone ? 8.0 : 16.0),
        child: Column(
          children: [
            // Main content area with white background
            Expanded(
              child: Container(
                padding: EdgeInsets.all(is6InchPhone ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Center(
                        child: Text(
                          'Game Session Summary',
                          style: TextStyle(
                            fontSize: is6InchPhone ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: is6InchPhone ? 16 : 24),
                      
                      // Parent Screen Data Section
                      _buildDataSection(
                        'League Setup',
                        _buildParentScreenData(),
                        Icons.settings,
                        is6InchPhone,
                      ),
                      
                      SizedBox(height: is6InchPhone ? 12 : 16),
                      
                      // Player Selection Data Section
                      _buildDataSection(
                        'Player Selection',
                        _buildPlayerSelectionData(),
                        Icons.people,
                        is6InchPhone,
                      ),
                      
                      SizedBox(height: is6InchPhone ? 12 : 16),
                      
                      // Enter Scores Data Section
                      _buildDataSection(
                        'Game Results',
                        _buildEnterScoresData(),
                        Icons.scoreboard,
                        is6InchPhone,
                      ),
                      
                      SizedBox(height: is6InchPhone ? 12 : 16),
                      
                      // Closest Pin Data Section
                      _buildDataSection(
                        'Closest Pin Results',
                        _buildClosestPinData(),
                        Icons.flag,
                        is6InchPhone,
                      ),
                      
                      SizedBox(height: is6InchPhone ? 16 : 24),
                      
                      // Player Details Table
                      if (_retentionService.hasEnterScoresData())
                        _buildPlayerDetailsTable(is6InchPhone),
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: is6InchPhone ? 8 : 16),
            
            // Return to Main Menu Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: is6InchPhone ? 16 : 32,
              ),
              child: ElevatedButton(
                onPressed: _returnToMainMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: is6InchPhone ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Return to Main Menu',
                      style: TextStyle(
                        fontSize: is6InchPhone ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a data section with title, icon, and content
  Widget _buildDataSection(String title, Widget content, IconData icon, bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green[700], size: isCompact ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 12),
          content,
        ],
      ),
    );
  }

  /// Builds the parent screen data display
  Widget _buildParentScreenData() {
    if (!_retentionService.hasParentScreenData()) {
      return const Text(
        'No league setup data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Players Ante', '\$${_retentionService.playersAnte?.toStringAsFixed(2) ?? 'N/A'}'),
        _buildDataRow('Closest Pin', '\$${_retentionService.closestPinAmount?.toStringAsFixed(2) ?? 'N/A'}'),
        _buildDataRow('Mulligan Amount', '\$${_retentionService.mulliganAmount?.toStringAsFixed(2) ?? 'N/A'}'),
        _buildDataRow('Golf Course', _retentionService.selectedGolfCourse ?? 'Not Selected'),
      ],
    );
  }

  /// Builds the player selection data display
  Widget _buildPlayerSelectionData() {
    if (!_retentionService.hasPlayerSelectionData()) {
      return const Text(
        'No player selection data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final selectedPlayers = _retentionService.selectedPlayers ?? [];
    final selectedCount = selectedPlayers.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Total Players Selected', '$selectedCount'),
        _buildDataRow('Player Names', _buildPlayerNamesList(selectedPlayers)),
      ],
    );
  }

  /// Builds the enter scores data display
  Widget _buildEnterScoresData() {
    if (!_retentionService.hasEnterScoresData()) {
      return const Text(
        'No game results data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final playerGroups = _retentionService.playerGroups ?? [];
    final groupsWithPlayers = playerGroups.where((group) => group.isNotEmpty).length;
    final totalPlayers = playerGroups.fold<int>(0, (sum, group) => sum + group.length);
    final playersWithMoney = _countPlayersWithMoney(playerGroups);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Active Groups', '$groupsWithPlayers'),
        _buildDataRow('Total Players', '$totalPlayers'),
        _buildDataRow('Players Shuffled', _retentionService.playersShuffled == true ? 'Yes' : 'No'),
        _buildDataRow('Money Calculated', _retentionService.hasMoneyCalculations == true ? 'Yes' : 'No'),
        if (_retentionService.hasMoneyCalculations == true)
          _buildDataRow('Winners (with money)', '$playersWithMoney'),
      ],
    );
  }

  /// Builds the closest pin data display
  Widget _buildClosestPinData() {
    if (!_retentionService.hasClosestPinData()) {
      return const Text(
        'No closest pin data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final totalPins = _retentionService.totalClosestPins ?? 0;
    final remainingPins = _retentionService.remainingClosestPins ?? 0;
    final remainingPurse = _retentionService.remainingClosestPinPurse ?? 0.0;
    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};
    
    final winnersCount = playerCounts.values.where((count) => count > 0).length;
    final totalWinnings = playerWinnings.values.fold<double>(0.0, (sum, amount) => sum + amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Total Closest Pins', '$totalPins'),
        _buildDataRow('Pins Awarded', '${totalPins - remainingPins}'),
        _buildDataRow('Remaining Pins', '$remainingPins'),
        _buildDataRow('Remaining Purse', '\$${remainingPurse.toStringAsFixed(2)}'),
        _buildDataRow('Winners', '$winnersCount'),
        _buildDataRow('Total Winnings', '\$${totalWinnings.toStringAsFixed(2)}'),
        if (winnersCount > 0) ...[
          const SizedBox(height: 8),
          _buildClosestPinWinnersTable(),
        ],
      ],
    );
  }

  /// Builds a player details table showing scores and winnings
  Widget _buildPlayerDetailsTable(bool isCompact) {
    final playerGroups = _retentionService.playerGroups ?? [];
    if (playerGroups.isEmpty) return const SizedBox.shrink();

    // Flatten all players from all groups
    List<PlayerData> allPlayers = [];
    for (int groupIndex = 0; groupIndex < playerGroups.length; groupIndex++) {
      for (var player in playerGroups[groupIndex]) {
        allPlayers.add(player);
      }
    }

    if (allPlayers.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: Colors.blue[700], size: isCompact ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                'Player Details',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 12),
          
          // Table
          Table(
            border: TableBorder.all(color: Colors.grey[400]!, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(2), // Name
              1: FlexColumnWidth(1), // SK#
              2: FlexColumnWidth(1), // Skats
              3: FlexColumnWidth(1), // Diff
              4: FlexColumnWidth(1), // Money
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[200]),
                children: [
                  _buildTableCell('Player', isHeader: true, isCompact: isCompact),
                  _buildTableCell('SK#', isHeader: true, isCompact: isCompact),
                  _buildTableCell('Skats', isHeader: true, isCompact: isCompact),
                  _buildTableCell('Diff', isHeader: true, isCompact: isCompact),
                  _buildTableCell('Money', isHeader: true, isCompact: isCompact),
                ],
              ),
              
              // Player data rows
              ...allPlayers.map((player) => TableRow(
                children: [
                  _buildTableCell(player.name, isCompact: isCompact),
                  _buildTableCell(player.skNumber, isCompact: isCompact),
                  _buildTableCell(player.skats.isEmpty ? '-' : player.skats, isCompact: isCompact),
                  _buildTableCell(player.diff.isEmpty ? '-' : player.diff, isCompact: isCompact),
                  _buildTableCell(
                    player.money.isEmpty ? '-' : player.money, 
                    isCompact: isCompact,
                    isMoneyColumn: true,
                  ),
                ],
              )).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a table cell with proper styling
  Widget _buildTableCell(String text, {bool isHeader = false, bool isCompact = false, bool isMoneyColumn = false}) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? 6 : 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isCompact ? 10 : 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isMoneyColumn && text.contains('\$') ? Colors.green[700] : 
                 isHeader ? Colors.black87 : Colors.black,
        ),
        textAlign: isHeader || isMoneyColumn ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  /// Builds a data row with label and value
  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value.toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds a formatted list of player names
  Widget _buildPlayerNamesList(List<Map<String, dynamic>> players) {
    if (players.isEmpty) {
      return const Text('No players selected', style: TextStyle(color: Colors.grey));
    }

    final names = players
        .map((player) => player['last']?.toString() ?? 'Unknown')
        .toList();

    return Text(
      names.join(', '),
      style: const TextStyle(color: Colors.black),
    );
  }

  /// Counts players who have money earnings
  int _countPlayersWithMoney(List<List<PlayerData>> groups) {
    int count = 0;
    for (var group in groups) {
      for (var player in group) {
        if (player.money.isNotEmpty && player.money.contains('\$')) {
          count++;
        }
      }
    }
    return count;
  }

  /// Builds a table showing closest pin winners and their winnings
  Widget _buildClosestPinWinnersTable() {
    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};
    
    // Get only players who won closest pins
    final winners = playerCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
          'name': entry.key,
          'pins': entry.value,
          'winnings': playerWinnings[entry.key] ?? 0.0,
        })
        .toList();

    if (winners.isEmpty) return const SizedBox.shrink();

    // Sort by number of pins won (descending)
    winners.sort((a, b) => (b['pins'] as int).compareTo(a['pins'] as int));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Pins', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('Winnings', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...winners.map((winner) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(winner['name'] as String)),
                Expanded(flex: 1, child: Text('${winner['pins']}', textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text(
                  '\$${(winner['winnings'] as double).round()}', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                )),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}