import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/UI/enter_scores_UI_service.dart';
import '../../services/shared/league_purse_service.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../main_menu_screen.dart';
import '../../services/firebase_upload_service.dart';
import '../../widgets/responsive_wrapper.dart';

class MondayResultsScreen extends StatefulWidget {
  const MondayResultsScreen({super.key});

  @override
  State<MondayResultsScreen> createState() => _MondayResultsScreenState();
}

class _MondayResultsScreenState extends State<MondayResultsScreen> {
  final ScreenDataRetentionService _retentionService = ScreenDataRetentionService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();

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
    // Keep landscape mode locked when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// Saves the results data to the monday_scores table using 4-step process
  Future<void> _saveResultsToDatabase() async {
    try {
      final playerGroups = _retentionService.playerGroups ?? [];
      final selectedGolfCourse = _retentionService.selectedGolfCourse ?? 'Not Selected';
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final playerClosestPinWinnings = _retentionService.playerClosestPinWinnings ?? {};
      
      // Get player database records for lookups
      final allDbPlayers = await _databaseHelper.getPlayersByLeague(League.monday);
      
      // STEP A1: Create rows for ALL selected players from monday_enter_scores_screen
      List<PlayerData> allSelectedPlayers = [];
      for (int groupIndex = 0; groupIndex < playerGroups.length; groupIndex++) {
        for (var player in playerGroups[groupIndex]) {
          if (player.name.isNotEmpty) { // Only include players with names (not empty slots)
            allSelectedPlayers.add(player);
          }
        }
      }
      
      //print("Step A1: Creating rows for ${allSelectedPlayers.length} selected players");
      
      // Create initial rows for all selected players
      Map<String, int> playerToRecordId = {}; // Track record IDs for updates
      for (var player in allSelectedPlayers) {
        // Find matching player in database
        final dbPlayer = allDbPlayers.firstWhere(
          (p) => p['last'] == player.name, 
          orElse: () => <String, dynamic>{}
        );
        
        if (dbPlayer.isNotEmpty) {
          // Create initial score record with basic data
          Map<String, dynamic> scoreData = {
            'player_id': dbPlayer['id'],
            'name': player.name,
            'date_played': currentDate,
            'golf_course': selectedGolfCourse,
            'skats_score': null, // Will be updated in Step A4
            'close_pin_winnings': 0.0, // Will be updated in Step A2
            'skat_winnings': 0.0, // Will be updated in Step A3
            'skat_number': dbPlayer['skat_number'],
          };
          
          // Insert record and get the record ID
          int recordId = await _databaseHelper.insertScoreLeague(scoreData, League.monday);
          playerToRecordId[player.name] = recordId;
        }
      }
      
      // STEP A2: Update Closest Pin Winnings for winners
      //print("Step A2: Updating Closest Pin Winnings");
      for (String playerName in playerClosestPinWinnings.keys) {
        double closePinWinnings = playerClosestPinWinnings[playerName] ?? 0.0;
        
        if (closePinWinnings > 0.0 && playerToRecordId.containsKey(playerName)) {
          int recordId = playerToRecordId[playerName]!;
          await _databaseHelper.updateScoreField(
            recordId, 
            'close_pin_winnings', 
            closePinWinnings,
            League.monday
          );
        }
      }
      
      // STEP A3: Update SKAT Winnings for players with money earnings
      //print("Step A3: Updating SKAT Winnings");
      for (var player in allSelectedPlayers) {
        if (player.money.isNotEmpty && player.money.contains('\$') && playerToRecordId.containsKey(player.name)) {
          try {
            double skatWinnings = double.parse(player.money.replaceAll('\$', '').replaceAll(',', ''));
            if (skatWinnings > 0.0) {
              int recordId = playerToRecordId[player.name]!;
              await _databaseHelper.updateScoreField(
                recordId, 
                'skat_winnings', 
                skatWinnings,
                League.monday
              );
            }
          } catch (e) {
            //print("Error parsing SKAT winnings for ${player.name}: $e");
          }
        }
      }
      
      // STEP A4: Update SKAT data field with SKAT # from player profiles
      //print("Step A4: Updating SKAT data field with SKAT # from profiles");
      for (var player in allSelectedPlayers) {
        if (playerToRecordId.containsKey(player.name)) {
          // Find player's SKAT # from database
          final dbPlayer = allDbPlayers.firstWhere(
            (p) => p['last'] == player.name, 
            orElse: () => <String, dynamic>{}
          );
          
          if (dbPlayer.isNotEmpty && dbPlayer['skat_number'] != null) {
            int recordId = playerToRecordId[player.name]!;
            await _databaseHelper.updateScoreField(
              recordId, 
              'skats_score', 
              dbPlayer['skat_number'],
              League.monday
            );
          }
        }
      }
      
      // Upload scores to Firebase after successful database save
      await _uploadScoresToFirebase();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Results saved successfully! ${allSelectedPlayers.length} player records created and updated.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving results: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Upload player scores to Firebase after saving to database
  Future<void> _uploadScoresToFirebase() async {
    try {
      //print('Uploading/queuing player scores for Monday league...');
      final success = await _firebaseUploadService.uploadPlayerScoresTableWithQueue(League.monday);
      if (success) {
        //print('Player scores upload initiated or queued successfully');
      } else {
        //print('Failed to upload or queue player scores');
      }
    } catch (e) {
      //print('Error uploading/queuing player scores: $e');
    }
  }

  /// Saves results to database and returns to the main menu
  Future<void> _saveResultsAndReturnToMainMenu() async {
    // First save the results
    await _saveResultsToDatabase();
    
    // Clear all retained data for a fresh session
    _retentionService.clearAllData();
    
    // Immediately lock to landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Navigate back to main menu, removing all previous screens from stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) {
        // Ensure orientation is locked again after navigation
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet8: _buildTablet8Layout(),
      tablet10: _buildTablet10Layout(),
    );
  }

  Widget _buildPhoneLayout() {
    final double basePadding = 8.0;
    final double contentPadding = 12.0;
    final double iconSize = 18;
    final double buttonHeight = 4;
    final double buttonFontSize = 12;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
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
                      _buildDataSection(
                        '',
                        _buildUnifiedData(),
                        Icons.summarize,
                        true,
                        false,
                        iconSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildSaveButton(0.4, buttonHeight, buttonFontSize, iconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet8Layout() {
    final double basePadding = 12.0;
    final double contentPadding = 16.0;
    final double iconSize = 20;
    final double buttonHeight = 5;
    final double buttonFontSize = 13;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 56,
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
                      _buildDataSection(
                        '',
                        _buildUnifiedData(),
                        Icons.summarize,
                        false,
                        true,
                        iconSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            _buildSaveButton(0.35, buttonHeight, buttonFontSize, iconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet10Layout() {
    final double basePadding = 16.0;
    final double contentPadding = 20.0;
    final double iconSize = 22;
    final double buttonHeight = 6;
    final double buttonFontSize = 14;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
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
                      _buildDataSection(
                        '',
                        _buildUnifiedData(),
                        Icons.summarize,
                        false,
                        false,
                        iconSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildSaveButton(0.3, buttonHeight, buttonFontSize, iconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(double widthRatio, double buttonHeight, double buttonFontSize, double iconSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = MediaQuery.of(context).size.width * widthRatio;
        
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: buttonWidth,
            child: ElevatedButton(
              onPressed: _saveResultsAndReturnToMainMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: iconSize),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Save Results',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a data section with title, icon, and content
  Widget _buildDataSection(String title, Widget content, IconData icon, bool is6InchPhone, bool is8InchTablet, double iconSize) {
    final double sectionPadding = is6InchPhone ? 12 : (is8InchTablet ? 16 : 20);
    final double titleSize = is6InchPhone ? 16 : (is8InchTablet ? 18 : 20);
    final double spacingHeight = is6InchPhone ? 8 : (is8InchTablet ? 12 : 16);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sectionPadding),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Row(
              children: [
                Icon(icon, color: Colors.green[700], size: iconSize),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingHeight),
          ],
          content,
        ],
      ),
    );
  }

  /// Builds unified data display combining all sections
  Widget _buildUnifiedData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // League Setup Data
        if (_retentionService.hasParentScreenData()) 
          _buildParentScreenData(),
        
        // Player Selection and Game Results Data (combined row)
        if (_retentionService.hasPlayerSelectionData() || _retentionService.hasEnterScoresData()) ...[
          _buildPlayerAndGameResultsData(),
          const SizedBox(height: 16),
        ],
        
        // Closest Pin Data
        if (_retentionService.hasClosestPinData()) ...[
          _buildClosestPinData(),
          const SizedBox(height: 16),
        ],
        
        // Player Details Table
        if (_retentionService.hasEnterScoresData()) ...[
          _buildPlayerDetailsTableContent(),
        ],
        
        // Show message if no data available
        if (!_retentionService.hasParentScreenData() &&
            !_retentionService.hasPlayerSelectionData() &&
            !_retentionService.hasEnterScoresData() &&
            !_retentionService.hasClosestPinData())
          const Text(
            'No session data available',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
      ],
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
        // Single row layout for money amounts
        LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.of(context).size;
            final is6InchPhone = screenSize.width <= 900;
            
            final double fontSize = is6InchPhone ? 12 : 14;
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Players Ante: \$${_retentionService.playersAnte?.toStringAsFixed(2) ?? 'N/A'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Closest Pin: \$${_retentionService.closestPinAmount?.toStringAsFixed(2) ?? 'N/A'}',
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
                      'Mulligan: \$${_retentionService.mulliganAmount?.toStringAsFixed(2) ?? 'N/A'}',
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
          },
        ),
        // Total Players and Collect row
        _buildPlayersAndCollectRow(),
        // Golf Course row (separate line)
        _buildGolfCourseRow(),
      ],
    );
  }

  /// Builds Total Players, Collect amount, and Mulligan/Party funds on one row
  Widget _buildPlayersAndCollectRow() {
    final selectedPlayers = _retentionService.selectedPlayers ?? [];
    final selectedCount = selectedPlayers.length;
    
    // Calculate collect amount: (Players Ante + Closest Pin + Mulligan) * Total Players
    final playersAnte = _retentionService.playersAnte ?? 0.0;
    final closestPin = _retentionService.closestPinAmount ?? 0.0;
    final originalMulligan = _retentionService.mulliganAmount ?? 0.0;
    final collectAmount = (playersAnte + closestPin + originalMulligan) * selectedCount;
    
    // Get the adjusted Mulligan Purse amount after SKAT calculations
    final adjustedMulliganPurse = LeaguePurseService.mulliganPurse;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.of(context).size;
          final is6InchPhone = screenSize.width <= 900;
          final double fontSize = is6InchPhone ? 12 : 14;
          
          return Row(
            children: [
              Expanded(
                child: Text(
                  'Total Players = $selectedCount',
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
                  'Party Fund = \$${adjustedMulliganPurse.toStringAsFixed(2)}',
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
          );
        },
      ),
    );
  }

  /// Builds Golf Course on its own row
  Widget _buildGolfCourseRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.of(context).size;
          final is6InchPhone = screenSize.width <= 900;
          final double fontSize = is6InchPhone ? 12 : 14;
          
          return Text(
            'Golf Course: ${_retentionService.selectedGolfCourse ?? 'Not Selected'}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: fontSize,
            ),
          );
        },
      ),
    );
  }

  /// Builds combined player selection and game results data in one row
  Widget _buildPlayerAndGameResultsData() {
    // This method is now empty since player count is shown in the Golf Course row
    return const SizedBox.shrink();
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Total Players Selected: $selectedCount',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
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
        if (_retentionService.hasMoneyCalculations == true)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Winners (with money): $playersWithMoney',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
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
        if (winnersCount > 0)
          _buildClosestPinWinnersTable(),
      ],
    );
  }

  /// Builds player details table content without the outer container
  Widget _buildPlayerDetailsTableContent() {
    final playerGroups = _retentionService.playerGroups ?? [];
    if (playerGroups.isEmpty) return const SizedBox.shrink();

    // Flatten all players from all groups and filter for positive DIFF
    List<PlayerData> allPlayers = [];
    for (int groupIndex = 0; groupIndex < playerGroups.length; groupIndex++) {
      for (var player in playerGroups[groupIndex]) {
        // Only include players with positive DIFF
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

    // Calculate Skat Value: $$$ / DIFF (prefer whole numbers, fallback to rounded)
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
            // Check if division results in a whole number (no remainder)
            if (calculation == calculation.truncate()) {
              skatValue = calculation;
              break; // Use the first valid whole number calculation
            } else if (fallbackValue == null) {
              // Store first calculation with remainder as fallback
              fallbackValue = calculation;
            }
          }
        } catch (e) {
          // Skip if parsing fails
        }
      }
    }
    
    // If no whole number found, use rounded fallback value
    if (skatValue == 0.0 && fallbackValue != null) {
      skatValue = fallbackValue.round().toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.of(context).size;
            final is6InchPhone = screenSize.width <= 900;
            final double fontSize = is6InchPhone ? 14 : 16;
            
            // Always use single row layout with Skat Value on the left
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Skat Value: \$${skatValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'SKAT Winners: $playersWithMoney',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        
        // Table with responsive column widths
        LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.of(context).size;
            final is6InchPhone = screenSize.width <= 900;
            
            // Adjust column widths for smaller screens
            final Map<int, TableColumnWidth> columnWidths = is6InchPhone 
              ? {
                  0: const FlexColumnWidth(3), // Name - wider on small screens
                  1: const FlexColumnWidth(1), // SK#
                  2: const FlexColumnWidth(1), // Skats
                  3: const FlexColumnWidth(1), // Diff
                  4: const FlexColumnWidth(1.5), // Money - slightly wider
                }
              : {
                  0: const FlexColumnWidth(2), // Name
                  1: const FlexColumnWidth(1), // SK#
                  2: const FlexColumnWidth(1), // Skats
                  3: const FlexColumnWidth(1), // Diff
                  4: const FlexColumnWidth(1), // Money
                };
            
            return Table(
              border: TableBorder.all(color: Colors.grey[400]!, width: 1),
              columnWidths: columnWidths,
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(color: Colors.green[300]),
                  children: [
                    _buildTableCell('Player', isHeader: true, isCompact: false),
                    _buildTableCell('SK#', isHeader: true, isCompact: false),
                    _buildTableCell('Skats', isHeader: true, isCompact: false),
                    _buildTableCell('Diff', isHeader: true, isCompact: false),
                    _buildTableCell('\$\$\$', isHeader: true, isCompact: false),
                  ],
                ),
                
                // Player data rows
                ...allPlayers.map((player) => TableRow(
                  children: [
                    _buildTableCell(player.name, isCompact: false),
                    _buildTableCell(player.skNumber, isCompact: false),
                    _buildTableCell(player.skats.isEmpty ? '-' : player.skats, isCompact: false),
                    _buildTableCell(player.diff.isEmpty ? '-' : player.diff, isCompact: false),
                    _buildTableCell(
                      player.money.isEmpty ? '-' : player.money, 
                      isCompact: false,
                      isMoneyColumn: true,
                    ),
                  ],
                )).toList(),
              ],
            );
          },
        ),
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
    final screenSize = MediaQuery.of(context).size;
    final is6InchPhone = screenSize.width <= 900;
    final is8InchTablet = screenSize.width > 900 && screenSize.width <= 1200;
    
    // Responsive font sizes for table cells
    final double fontSize = is6InchPhone ? 9 : (is8InchTablet ? 11 : 12);
    final double cellPadding = is6InchPhone ? 4 : (is8InchTablet ? 6 : 8);
    
    return Padding(
      padding: EdgeInsets.all(cellPadding),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isMoneyColumn && text.contains('\$') ? Colors.green[700] : 
                 isHeader ? Colors.black87 : Colors.black,
        ),
        textAlign: isHeader || isMoneyColumn ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: isHeader ? 2 : 1,
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
              color: Colors.green[300],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenSize = MediaQuery.of(context).size;
                final is6InchPhone = screenSize.width <= 900;
                final double fontSize = is6InchPhone ? 12 : 14;
                
                return Row(
                  children: [
                    Expanded(
                      flex: is6InchPhone ? 3 : 2, 
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
                      child: Text(
                        'Winnings', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ), 
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ...winners.map((winner) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenSize = MediaQuery.of(context).size;
                final is6InchPhone = screenSize.width <= 900;
                final double fontSize = is6InchPhone ? 11 : 13;
                
                return Row(
                  children: [
                    Expanded(
                      flex: is6InchPhone ? 3 : 2, 
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
                  ],
                );
              },
            ),
          )).toList(),
        ],
      ),
    );
  }
}