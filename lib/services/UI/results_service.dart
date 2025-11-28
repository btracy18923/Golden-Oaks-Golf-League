import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screen_data_retention_service.dart';
import 'enter_scores_UI_service.dart';
import '../../screens/main_menu_screen.dart';

class ResultsUIService {
  static void setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  static AppBar buildAppBar() {
    return AppBar(
      title: const Text(
        'Monday League Results',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  static Widget buildMainContent(BuildContext context, ScreenDataRetentionService retentionService) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final is6InchPhone = isLandscape && screenSize.width <= 900;

    return Padding(
      padding: EdgeInsets.all(is6InchPhone ? 8.0 : 16.0),
      child: Column(
        children: [
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
                    
                    buildDataSection(
                      'Session Results',
                      buildUnifiedData(retentionService),
                      Icons.summarize,
                      is6InchPhone,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: is6InchPhone ? 8 : 16),
          
          buildReturnToMenuButton(context, retentionService, screenSize, is6InchPhone),
        ],
      ),
    );
  }

  static Widget buildDataSection(String title, Widget content, IconData icon, bool isCompact) {
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

  static Widget buildUnifiedData(ScreenDataRetentionService retentionService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (retentionService.hasParentScreenData()) 
          buildParentScreenData(retentionService),
        
        if (retentionService.hasPlayerSelectionData() || retentionService.hasEnterScoresData()) ...[
          buildPlayerAndGameResultsData(retentionService),
          const SizedBox(height: 16),
        ],
        
        if (retentionService.hasClosestPinData()) ...[
          buildClosestPinData(retentionService),
          const SizedBox(height: 16),
        ],
        
        if (retentionService.hasEnterScoresData()) ...[
          buildPlayerDetailsTableContent(retentionService),
        ],
        
        if (!retentionService.hasParentScreenData() &&
            !retentionService.hasPlayerSelectionData() &&
            !retentionService.hasEnterScoresData() &&
            !retentionService.hasClosestPinData())
          const Text(
            'No session data available',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  static Widget buildParentScreenData(ScreenDataRetentionService retentionService) {
    if (!retentionService.hasParentScreenData()) {
      return const Text(
        'No league setup data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Players Ante: \$${retentionService.playersAnte?.toStringAsFixed(2) ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Closest Pin: \$${retentionService.closestPinAmount?.toStringAsFixed(2) ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Mulligan: \$${retentionService.mulliganAmount?.toStringAsFixed(2) ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Golf Course: ${retentionService.selectedGolfCourse ?? 'Not Selected'}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildPlayerAndGameResultsData(ScreenDataRetentionService retentionService) {
    final selectedPlayers = retentionService.selectedPlayers ?? [];
    final selectedCount = selectedPlayers.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total Players Selected: $selectedCount',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildClosestPinData(ScreenDataRetentionService retentionService) {
    if (!retentionService.hasClosestPinData()) {
      return const Text(
        'No closest pin data available',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final playerCounts = retentionService.playerClosestPinCounts ?? {};
    final winnersCount = playerCounts.values.where((count) => count > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (winnersCount > 0)
          buildClosestPinWinnersTable(retentionService),
      ],
    );
  }

  static Widget buildPlayerDetailsTableContent(ScreenDataRetentionService retentionService) {
    final playerGroups = retentionService.playerGroups ?? [];
    if (playerGroups.isEmpty) return const SizedBox.shrink();

    List<PlayerData> allPlayers = [];
    for (int groupIndex = 0; groupIndex < playerGroups.length; groupIndex++) {
      for (var player in playerGroups[groupIndex]) {
        if (player.diff.isNotEmpty && player.diff != '-') {
          try {
            final diffValue = double.parse(player.diff.replaceAll('+', ''));
            if (diffValue > 0) {
              allPlayers.add(player);
            }
          } catch (e) {
            // If parsing fails, skip this player
          }
        }
      }
    }

    if (allPlayers.isEmpty) return const SizedBox.shrink();

    final playersWithMoney = allPlayers.length;

    double skatValue = 0.0;
    double? fallbackValue;
    
    for (var player in allPlayers) {
      if (player.money.isNotEmpty && player.money.contains('\$') && 
          player.diff.isNotEmpty && player.diff != '-') {
        try {
          final moneyValue = double.parse(player.money.replaceAll('\$', '').replaceAll(',', ''));
          final diffValue = double.parse(player.diff.replaceAll('+', ''));
          if (diffValue > 0) {
            final calculation = moneyValue / diffValue;
            if (calculation == calculation.truncate()) {
              skatValue = calculation;
              break;
            } else if (fallbackValue == null) {
              fallbackValue = calculation;
            }
          }
        } catch (e) {
          // Skip if parsing fails
        }
      }
    }
    
    if (skatValue == 0.0 && fallbackValue != null) {
      skatValue = fallbackValue.round().toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKAT Winners: $playersWithMoney     Skat Value: \$${skatValue.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
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
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                buildTableCell('Player', isHeader: true, isCompact: false),
                buildTableCell('SK#', isHeader: true, isCompact: false),
                buildTableCell('Skats', isHeader: true, isCompact: false),
                buildTableCell('Diff', isHeader: true, isCompact: false),
                buildTableCell('\$\$\$', isHeader: true, isCompact: false),
              ],
            ),
            
            ...allPlayers.map((player) => TableRow(
              children: [
                buildTableCell(player.name, isCompact: false),
                buildTableCell(player.skNumber, isCompact: false),
                buildTableCell(player.skats.isEmpty ? '-' : player.skats, isCompact: false),
                buildTableCell(player.diff.isEmpty ? '-' : player.diff, isCompact: false),
                buildTableCell(
                  player.money.isEmpty ? '-' : player.money, 
                  isCompact: false,
                  isMoneyColumn: true,
                ),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  static Widget buildTableCell(String text, {bool isHeader = false, bool isCompact = false, bool isMoneyColumn = false}) {
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

  static Widget buildClosestPinWinnersTable(ScreenDataRetentionService retentionService) {
    final playerCounts = retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = retentionService.playerClosestPinWinnings ?? {};
    
    final winners = playerCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
          'name': entry.key,
          'pins': entry.value,
          'winnings': playerWinnings[entry.key] ?? 0.0,
        })
        .toList();

    if (winners.isEmpty) return const SizedBox.shrink();

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
                Expanded(flex: 2, child: Text('Closest Pin Winners', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Pins Won', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
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

  static Widget buildReturnToMenuButton(BuildContext context, ScreenDataRetentionService retentionService, Size screenSize, bool is6InchPhone) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: screenSize.width * 0.3,
        child: ElevatedButton(
          onPressed: () => returnToMainMenu(context, retentionService),
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
    );
  }

  static void returnToMainMenu(BuildContext context, ScreenDataRetentionService retentionService) {
    retentionService.clearAllData();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        });
        return const UnifiedMainMenuScreen();
      }),
      (Route<dynamic> route) => false,
    );
  }

  static int countPlayersWithMoney(List<List<PlayerData>> groups) {
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
}