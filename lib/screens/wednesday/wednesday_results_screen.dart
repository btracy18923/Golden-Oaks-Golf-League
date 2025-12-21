import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../models/league.dart';
import '../main_menu_screen.dart';
import '../../services/firebase_upload_service.dart';

class WednesdayResultsScreen extends StatefulWidget {
  final double groupPurseAmount;
  final double groupPayoutAmount;
  final double adjustedMulliganPurse;
  final List<List<Map<String, dynamic>?>> groups;
  final List<Map<String, dynamic>> individualWinners;
  final double playersAnte;
  final double closestPinAmount;
  final double mulliganAmount;

  const WednesdayResultsScreen({
    super.key,
    required this.groupPurseAmount,
    required this.groupPayoutAmount,
    required this.adjustedMulliganPurse,
    required this.groups,
    required this.individualWinners,
    required this.playersAnte,
    required this.closestPinAmount,
    required this.mulliganAmount,
  });

  @override
  State<WednesdayResultsScreen> createState() => _WednesdayResultsScreenState();
}

class _WednesdayResultsScreenState extends State<WednesdayResultsScreen> {
  final ScreenDataRetentionService _retentionService = ScreenDataRetentionService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setOrientation();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Wednesday League
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    // Keep landscape mode locked when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// Saves the results data to the wednesday_scores table
  Future<void> _saveResultsToDatabase() async {
    try {
      final selectedGolfCourse = _retentionService.selectedGolfCourse ?? 'Not Selected';
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final playerClosestPinWinnings = _retentionService.playerClosestPinWinnings ?? {};

      // Get player database records for lookups
      final allDbPlayers = await _databaseHelper.getPlayersByLeague(League.wednesday);

      // Collect all selected players from groups
      List<Map<String, dynamic>> allSelectedPlayers = [];
      for (var group in widget.groups) {
        for (var player in group) {
          if (player != null && player['last'] != null && player['last'].toString().isNotEmpty) {
            allSelectedPlayers.add(player);
          }
        }
      }

      // CRITICAL: Check for duplicate dates BEFORE saving anything
      bool duplicateFound = false;
      for (var player in allSelectedPlayers) {
        final playerName = player['last'].toString();
        final dbPlayer = allDbPlayers.firstWhere(
          (p) => p['last'] == playerName,
          orElse: () => <String, dynamic>{}
        );

        if (dbPlayer.isNotEmpty) {
          final playerId = dbPlayer['player_number'];
          final existingScoreForDate = await _databaseHelper.getPlayerScoreByDate(playerId, currentDate, League.wednesday);

          if (existingScoreForDate != null) {
            duplicateFound = true;
            break;
          }
        }
      }

      // If duplicate date found, show error and DO NOT SAVE
      if (duplicateFound) {
        if (!mounted) return;
        final fontSize = ResponsiveTypography.getBodyText(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Duplicate Play Dates - data not saved',
              style: TextStyle(fontSize: fontSize + 4),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Create initial rows for all selected players
      Map<String, int> playerToRecordId = {};
      for (var player in allSelectedPlayers) {
        final playerName = player['last'].toString();
        final dbPlayer = allDbPlayers.firstWhere(
          (p) => p['last'] == playerName,
          orElse: () => <String, dynamic>{}
        );

        if (dbPlayer.isNotEmpty) {
          // Get player data
          int? grossScore = player['gross_score'] as int?;
          int? netScore = player['net_score'] as int?;
          int? manualGroup = player['manual_group'] as int?;
          String position = player['pos']?.toString() ?? '';
          String prizeMoney = player['prize_money']?.toString() ?? '';

          // Parse prize money
          double individualWinnings = 0.0;
          double teamWinnings = 0.0;
          if (prizeMoney.isNotEmpty && prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              // Check if player has a position to determine if it's team or individual winnings
              if (position.isNotEmpty && manualGroup != null) {
                teamWinnings = amount;
              } else {
                individualWinnings = amount;
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }

          // Create initial score record
          Map<String, dynamic> scoreData = {
            'player_id': dbPlayer['player_number'],
            'name': playerName,
            'date_played': currentDate,
            'golf_course': selectedGolfCourse,
            'gross_score': grossScore,
            'net_score': netScore,
            'manual_group': manualGroup,
            'team_place': position.isNotEmpty ? int.tryParse(position) : null,
            'individual_winnings': individualWinnings,
            'team_winnings': teamWinnings,
            'close_pin_winnings': 0.0,
          };

          int recordId = await _databaseHelper.insertScoreLeague(scoreData, League.wednesday);
          playerToRecordId[playerName] = recordId;
        }
      }

      // Update Closest Pin Winnings for winners
      for (String playerName in playerClosestPinWinnings.keys) {
        double closePinWinnings = playerClosestPinWinnings[playerName] ?? 0.0;

        if (closePinWinnings > 0.0 && playerToRecordId.containsKey(playerName)) {
          int recordId = playerToRecordId[playerName]!;
          await _databaseHelper.updateScoreField(
            recordId,
            'close_pin_winnings',
            closePinWinnings,
            League.wednesday
          );
        }
      }

      // Upload scores to Firebase after successful database save
      await _uploadScoresToFirebase();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Results saved successfully! ${allSelectedPlayers.length} player records created.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving results: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Upload player scores to Firebase after saving to database
  Future<void> _uploadScoresToFirebase() async {
    try {
      final success = await _firebaseUploadService.uploadPlayerScoresTableWithQueue(League.wednesday);
      if (!success) {
        // Log failure but don't show to user
      }
    } catch (e) {
      // Log error but don't show to user
    }
  }

  /// Saves results to database and returns to the main menu
  Future<void> _saveResultsAndReturnToMainMenu() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _saveResultsToDatabase();
      _retentionService.clearAllData();

      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    final basePadding = isPhone ? 8.0 : 16.0;
    final contentPadding = isPhone ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Wednesday League Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveTypography.getHeading(context),
          ),
        ),
        backgroundColor: Colors.orange[300],
        foregroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: isPhone ? 48 : 64,
      ),
      body: Padding(
        padding: EdgeInsets.all(basePadding),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: basePadding),
                      _buildDataSection(),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: isPhone ? 4 : 6),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[100]!,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: _isSaving ? 'Saving...' : 'Save Results',
          color: Colors.orange[600]!,
          onPressed: _isSaving ? null : _saveResultsAndReturnToMainMenu,
        ),
        ButtonBarUIService.buildSpacer(),
        ButtonBarUIService.buildSpacer(),
      ],
    );
  }

  Widget _buildDataSection() {
    final isPhone = DeviceDetectionService.isPhone(context);
    final sectionPadding = isPhone ? 12.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sectionPadding),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // League Setup Data
          _buildLeagueSetupData(),

          const SizedBox(height: 16),

          // Closest Pin Data
          if (_retentionService.hasClosestPinData()) ...[
            _buildClosestPinData(),
            const SizedBox(height: 16),
          ],

          // Individual Payout Section (moved after Closest Pin)
          _buildIndividualPayoutSection(),

          const SizedBox(height: 16),

          // Individual Player Details Table
          _buildIndividualPlayerDetailsTable(),

          const SizedBox(height: 16),

          // Groups Payout Section (moved after Individual Winners)
          _buildGroupsPayoutSection(),

          const SizedBox(height: 16),

          // Groups Player Details Table
          _buildGroupsPlayerDetailsTable(),
        ],
      ),
    );
  }

  Widget _buildLeagueSetupData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: Players' Ante, Closest Pin, Mulligans
        _buildParentScreenDataRow(),
        // Second row: Total Players, Collect, Party Fund
        _buildPlayersAndCollectRow(),
        // Third row: Golf Course
        _buildGolfCourseRow(),
      ],
    );
  }

  /// Builds first row with Players' Ante, Closest Pin, and Mulligans
  Widget _buildParentScreenDataRow() {
    final isPhone = DeviceDetectionService.isPhone(context);
    final fontSize = isPhone ? 22.0 : 18.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.orange[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Text(
              'Players\' Ante: \$${widget.playersAnte.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Closest Pin: \$${widget.closestPinAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Mulligans: \$${widget.mulliganAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds second row with Total Players, Collect amount, and Party Fund
  Widget _buildPlayersAndCollectRow() {
    final isPhone = DeviceDetectionService.isPhone(context);
    final fontSize = isPhone ? 22.0 : 18.0;

    // Count total players from groups
    int totalPlayers = 0;
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null && player['last'] != null && player['last'].toString().isNotEmpty) {
          totalPlayers++;
        }
      }
    }

    // Calculate collect amount: (Players Ante + Closest Pin + Mulligan) * Total Players
    final collectAmount = (widget.playersAnte + widget.closestPinAmount + widget.mulliganAmount) * totalPlayers;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total Players = $totalPlayers',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Collect \$${collectAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Party Fund = \$${widget.adjustedMulliganPurse.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds third row with Golf Course
  Widget _buildGolfCourseRow() {
    final isPhone = DeviceDetectionService.isPhone(context);
    final fontSize = isPhone ? 22.0 : 18.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Golf Course: ${_retentionService.selectedGolfCourse ?? 'The Hideout'}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildIndividualPayoutSection() {
    final isPhone = DeviceDetectionService.isPhone(context);
    final fontSize = isPhone ? 22.0 : 18.0;

    // Get individual payout data from the saved individual winners (only count those with positive prize money)
    int individualWinnersCount = 0;
    double totalIndividualPayout = 0.0;

    for (var player in widget.individualWinners) {
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

    // Only show if there are individual winners with positive prize money
    if (individualWinnersCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Center(
        child: Text(
          'Individual Payout Summary:  Winners: $individualWinnersCount  Total Payout: \$${totalIndividualPayout.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsPayoutSection() {
    final isPhone = DeviceDetectionService.isPhone(context);
    final fontSize = isPhone ? 22.0 : 18.0;

    // Count group winners (players with manual_group and positive prize_money)
    int groupWinnersCount = 0;
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null &&
            player['prize_money'] != null &&
            player['manual_group'] != null) {
          // Check if prize money is positive
          String prizeMoney = player['prize_money'].toString();
          if (prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              if (amount > 0) {
                groupWinnersCount++;
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Center(
        child: Text(
          'Group Payout Summary:  Winners: $groupWinnersCount  Total Payout: \$${widget.groupPayoutAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.green[900],
          ),
        ),
      ),
    );
  }

  Widget _buildClosestPinData() {
    if (!_retentionService.hasClosestPinData()) {
      return const SizedBox.shrink();
    }

    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};

    final winnersCount = playerCounts.values.where((count) => count > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (winnersCount > 0)
          _buildClosestPinWinnersTable(),
      ],
    );
  }

  Widget _buildClosestPinWinnersTable() {
    final playerCounts = _retentionService.playerClosestPinCounts ?? {};
    final playerWinnings = _retentionService.playerClosestPinWinnings ?? {};
    final isPhone = DeviceDetectionService.isPhone(context);
    final fontSize = isPhone ? 22.0 : 18.0;

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

    // Create the table widget
    final tableWidget = Container(
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
              color: Colors.green[300],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: isPhone ? 3 : 2,
                  child: Text(
                    'Closest Pin Winners',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Pins Won',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '\$\$\$',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
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
                Expanded(
                  flex: isPhone ? 3 : 2,
                  child: Text(
                    winner['name'] as String,
                    style: TextStyle(fontSize: fontSize),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${winner['pins']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.yellow[200],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      '\$${(winner['winnings'] as double).round()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );

    // Wrap in IntrinsicWidth and Align to constrain table width (same as Monday)
    return Align(
      alignment: Alignment.center,
      child: IntrinsicWidth(
        child: tableWidget,
      ),
    );
  }

  Widget _buildIndividualPlayerDetailsTable() {
    final labelFontSize = ResponsiveTypography.getLabel(context);
    final bodyFontSize = ResponsiveTypography.getSmall(context);

    // Filter to only include players with positive prize money
    List<Map<String, dynamic>> winnersWithPrize = widget.individualWinners.where((player) {
      if (player['prize_money'] == null) return false;
      String prizeMoney = player['prize_money'].toString();
      if (!prizeMoney.contains('\$')) return false;
      try {
        double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
        return amount > 0;
      } catch (e) {
        return false;
      }
    }).toList();

    if (winnersWithPrize.isEmpty) return const SizedBox.shrink();

    return Table(
          border: TableBorder.all(color: Colors.grey[400]!, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blue[300]),
              children: [
                _buildTableCell('Player', isHeader: true),
                _buildTableCell('Gross', isHeader: true),
                _buildTableCell('Net', isHeader: true),
                _buildTableCell('\$\$\$', isHeader: true),
              ],
            ),
            ...winnersWithPrize.map((player) => TableRow(
              children: [
                _buildTableCell(player['last']?.toString() ?? ''),
                _buildTableCell(player['gross_score']?.toString() ?? ''),
                _buildTableCell(player['net_score']?.toString() ?? ''),
                _buildTableCell(player['prize_money']?.toString() ?? '', isMoneyColumn: true),
              ],
            )),
          ],
        );
  }

  Widget _buildGroupsPlayerDetailsTable() {
    final labelFontSize = ResponsiveTypography.getLabel(context);
    final bodyFontSize = ResponsiveTypography.getSmall(context);

    // Collect players with group winnings (after groups processing) - only those with positive prize money
    List<Map<String, dynamic>> groupWinners = [];
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null &&
            player['prize_money'] != null &&
            player['manual_group'] != null &&
            player['last'] != null) {
          // Check if prize money is positive
          String prizeMoney = player['prize_money'].toString();
          if (prizeMoney.contains('\$')) {
            try {
              double amount = double.parse(prizeMoney.replaceAll('\$', '').replaceAll(',', ''));
              if (amount > 0) {
                groupWinners.add(player);
              }
            } catch (e) {
              // Skip if parsing fails
            }
          }
        }
      }
    }

    if (groupWinners.isEmpty) return const SizedBox.shrink();

    // Sort by group number, then by name
    groupWinners.sort((a, b) {
      int groupA = a['manual_group'] ?? 0;
      int groupB = b['manual_group'] ?? 0;
      if (groupA != groupB) return groupA.compareTo(groupB);
      return (a['last'] ?? '').toString().compareTo((b['last'] ?? '').toString());
    });

    return Table(
          border: TableBorder.all(color: Colors.grey[400]!, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.green[300]),
              children: [
                _buildTableCell('Player', isHeader: true),
                _buildTableCell('Grp#', isHeader: true),
                _buildTableCell('Net', isHeader: true),
                _buildTableCell('AVG', isHeader: true),
                _buildTableCell('Pos', isHeader: true),
                _buildTableCell('\$\$\$', isHeader: true),
              ],
            ),
            ...groupWinners.map((player) => TableRow(
              children: [
                _buildTableCell(player['last']?.toString() ?? ''),
                _buildTableCell(player['manual_group']?.toString() ?? ''),
                _buildTableCell(player['net_score']?.toString() ?? ''),
                _buildTableCell(player['avg_net']?.toString() ?? ''),
                _buildTableCell(player['pos']?.toString() ?? ''),
                _buildTableCell(player['prize_money']?.toString() ?? '', isMoneyColumn: true),
              ],
            )),
          ],
        );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isMoneyColumn = false}) {
    final bodyFontSize = ResponsiveTypography.getSmall(context);
    final cellPadding = DeviceDetectionService.isPhone(context) ? 4.0 : 8.0;

    return Container(
      color: isMoneyColumn ? Colors.yellow[200] : null,
      padding: EdgeInsets.all(cellPadding),
      child: Text(
        text,
        style: TextStyle(
          fontSize: bodyFontSize,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isMoneyColumn && text.contains('\$') ? Colors.black :
                 isHeader ? Colors.black87 : Colors.black,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: isHeader ? 2 : 1,
      ),
    );
  }
}
