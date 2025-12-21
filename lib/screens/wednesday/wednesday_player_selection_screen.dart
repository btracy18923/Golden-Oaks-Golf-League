import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../models/league.dart';
import 'wednesday_enter_scores_screen.dart';
import 'wednesday_closest_pin_screen.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayPlayerSelectionScreen extends StatefulWidget {
  const WednesdayPlayerSelectionScreen({super.key});

  @override
  State<WednesdayPlayerSelectionScreen> createState() => _WednesdayPlayerSelectionScreenState();
}

class _WednesdayPlayerSelectionScreenState extends State<WednesdayPlayerSelectionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> players = [];
  Set<int> selectedPlayerIds = <int>{};
  List<List<Map<String, dynamic>>>? _cachedColumns;
  bool isLoading = true;
  
  // Hard-coded Wednesday league colors and values
  static const Color _leagueColor = Color.fromRGBO(255, 214, 0, 1); // Gold

  @override
  void initState() {
    super.initState();
    loadPlayers();
    _setOrientation();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Wednesday League
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Print debug info
      DeviceDetectionService.printDebugInfo(context);
    });
  }
  
  Future<void> loadPlayers() async {
    try {
      // Load Wednesday league players only
      List<Map<String, dynamic>> loadedPlayers = await _dbHelper.getPlayersByLeague(League.wednesday);
      
      // Pre-calculate columns for better performance
      List<List<Map<String, dynamic>>> columns = [[], [], [], []];
      for (int i = 0; i < loadedPlayers.length; i++) {
        columns[i % 4].add(loadedPlayers[i]);
      }
      
      setState(() {
        players = loadedPlayers;
        _cachedColumns = columns;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading Wednesday players: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void togglePlayerSelection(int playerId) {
    setState(() {
      if (selectedPlayerIds.contains(playerId)) {
        selectedPlayerIds.remove(playerId);
      } else {
        selectedPlayerIds.add(playerId);
      }
    });
  }
  
  void selectAllPlayers() {
    setState(() {
      if (selectedPlayerIds.length == players.length) {
        selectedPlayerIds.clear();
      } else {
        selectedPlayerIds = players.map((p) => p['player_number'] as int).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet10: _buildTablet10Layout(),
    );
  }
  
  Widget _buildPhoneLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text("Select Wednesday Players - ${DeviceDetectionService.getDeviceName(context)}"),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: players.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No Wednesday players found\nTry importing players first',
                                        style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : Scrollbar(
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    child: _buildPhonePlayerGrid(),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPhoneFooter(),
              ],
            ),
    );
  }
  
  Widget _buildTablet10Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text("Select Players for Wednesday's Match - ${DeviceDetectionService.getDeviceName(context)}"),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 64,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Selected Players: ${selectedPlayerIds.length}/${players.length}',
                            style: TextStyle(
                              fontSize: ResponsiveTypography.getBodyText(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: players.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Wednesday players found\nTry importing players first',
                                        style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : _buildTablet10PlayerGrid(),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTablet10Footer(),
              ],
            ),
    );
  }

  Widget _buildPhonePlayerGrid() {
    List<List<Map<String, dynamic>>> columns = _cachedColumns ?? [[], [], [], []];
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int colIndex = 0; colIndex < 4; colIndex++)
          Expanded(
            child: Column(
              children: [
                for (var player in columns[colIndex])
                  _buildPhonePlayerCheckbox(player),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildTabletPlayerGrid() {
    List<List<Map<String, dynamic>>> columns = _cachedColumns ?? [[], [], [], []];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int colIndex = 0; colIndex < 4; colIndex++)
          Expanded(
            child: Column(
              children: [
                for (var player in columns[colIndex])
                  _buildTabletPlayerCheckbox(player),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTablet10PlayerGrid() {
    List<List<Map<String, dynamic>>> columns = _cachedColumns ?? [[], [], [], []];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int colIndex = 0; colIndex < 4; colIndex++)
          Expanded(
            child: Column(
              children: [
                for (var player in columns[colIndex])
                  _buildTablet10PlayerCheckbox(player),
              ],
            ),
          ),
      ],
    );
  }
  
  void _navigateToEnterScores() {
    try {
      // Get selected players
      List<Map<String, dynamic>> selectedPlayers = players
          .where((player) => selectedPlayerIds.contains(player['player_number'] as int))
          .toList();

      // Organize players into groups, ensuring each group has at least 3 players
      List<List<Map<String, dynamic>?>> groups = [];
      final totalPlayers = selectedPlayers.length;

      // Handle edge cases
      if (totalPlayers < 4) {
        // If less than 4 players, put all in Group 1
        List<Map<String, dynamic>?> group = [];
        for (var player in selectedPlayers) {
          group.add(player);
        }
        while (group.length < 4) {
          group.add(null);
        }
        groups.add(group);
      } else if (totalPlayers == 5) {
        // Special case: 5 players - put 3 in first group, 2 in second group
        List<Map<String, dynamic>?> group1 = [
          selectedPlayers[0],
          selectedPlayers[1],
          selectedPlayers[2],
          null,
        ];
        List<Map<String, dynamic>?> group2 = [
          selectedPlayers[3],
          selectedPlayers[4],
          null,
          null,
        ];
        groups.add(group1);
        groups.add(group2);
      } else {
        // Calculate optimal group distribution ensuring 3+ players per group
        int numGroups;
        if (totalPlayers <= 4) {
          numGroups = 1;
        } else if (totalPlayers <= 8) {
          numGroups = 2;
        } else if (totalPlayers <= 12) {
          numGroups = 3;
        } else if (totalPlayers <= 16) {
          numGroups = 4;
        } else if (totalPlayers <= 20) {
          numGroups = 5;
        } else if (totalPlayers <= 24) {
          numGroups = 6;
        } else if (totalPlayers <= 28) {
          numGroups = 7;
        } else if (totalPlayers <= 32) {
          numGroups = 8;
        } else if (totalPlayers <= 36) {
          numGroups = 9;
        } else {
          numGroups = 10;
        }

        // Distribute players evenly across calculated number of groups
        int playersPerGroup = totalPlayers ~/ numGroups;
        int remainingPlayers = totalPlayers % numGroups;

        int playerIndex = 0;
        for (int groupIndex = 0; groupIndex < numGroups; groupIndex++) {
          List<Map<String, dynamic>?> group = [];
          int playersInThisGroup = playersPerGroup;

          // Distribute remaining players to first groups
          if (groupIndex < remainingPlayers) {
            playersInThisGroup++;
          }

          // Add players to this group
          for (int i = 0; i < playersInThisGroup; i++) {
            if (playerIndex < selectedPlayers.length) {
              group.add(selectedPlayers[playerIndex]);
              playerIndex++;
            }
          }

          // Fill remaining slots with null
          while (group.length < 4) {
            group.add(null);
          }

          groups.add(group);
        }
      }
      
      // Navigate to Wednesday ores Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WednesdayEnterScoresScreen(
            initialPlayers: selectedPlayers,
            initialGroups: groups,
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to Wednesday scores: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToClosestPin() {
    try {
      // Get selected players
      List<Map<String, dynamic>> selectedPlayers = players
          .where((player) => selectedPlayerIds.contains(player['player_number'] as int))
          .toList();

      // Navigate to Wednesday Closest Pin Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WednesdayClosestPinScreen(
            selectedPlayers: selectedPlayers,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to Wednesday closest pin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPhonePlayerCheckbox(Map<String, dynamic> player) {
    final int playerId = player['player_number'] as int;
    final bool isSelected = selectedPlayerIds.contains(playerId);
    final String playerName = '${player['last']}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.5, horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => togglePlayerSelection(playerId),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected ? _leagueColor : Colors.grey[300],
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Text(
                            'X',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    playerName,
                    style: TextStyle(
                      fontSize: ResponsiveTypography.getBodyText(context),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabletPlayerCheckbox(Map<String, dynamic> player) {
    final int playerId = player['player_number'] as int;
    final bool isSelected = selectedPlayerIds.contains(playerId);
    final String playerName = '${player['last']}, ${player['first']}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => togglePlayerSelection(playerId),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? _leagueColor : Colors.grey[300],
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Text(
                            'X',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    playerName,
                    style: TextStyle(
                      fontSize: ResponsiveTypography.getSmall(context),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTablet10PlayerCheckbox(Map<String, dynamic> player) {
    final int playerId = player['player_number'] as int;
    final bool isSelected = selectedPlayerIds.contains(playerId);
    final String playerName = '${player['last']}, ${player['first']}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => togglePlayerSelection(playerId),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? _leagueColor : Colors.grey[300],
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Text(
                            'X',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhoneFooter() {
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[300]!,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: '◄---- Back',
          color: Colors.blue[300]!,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: selectedPlayerIds.length == players.length ? 'Uncheck All' : 'Check All',
          color: Colors.yellow[100]!,
          onPressed: selectAllPlayers,
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: "Enter Gross ---➤",
          color: Colors.orange[300]!,
          onPressed: selectedPlayerIds.isEmpty ? null : _navigateToEnterScores,
        ),
      ],
    );
  }
  
  Widget _buildTablet10Footer() {
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[300]!,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: '◄---- Back',
          color: Colors.orange[300]!,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: selectedPlayerIds.length == players.length ? 'Uncheck All' : 'Check All',
          color: Colors.yellow[100]!,
          onPressed: selectAllPlayers,
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: "Enter Player's Scores ---➤",
          color: _leagueColor,
          onPressed: selectedPlayerIds.isEmpty ? null : _navigateToEnterScores,
        ),
      ],
    );
  }
}