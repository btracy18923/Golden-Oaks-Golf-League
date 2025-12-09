import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import 'monday_enter_scores_screen.dart';
import '../../widgets/responsive_wrapper.dart';

class MondayPlayerSelectionScreen extends StatefulWidget {
  final double? playersAnte;
  
  const MondayPlayerSelectionScreen({super.key, this.playersAnte});

  @override
  State<MondayPlayerSelectionScreen> createState() => _MondayPlayerSelectionScreenState();
}

class _MondayPlayerSelectionScreenState extends State<MondayPlayerSelectionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> players = [];
  Set<int> selectedPlayerIds = <int>{};
  List<List<Map<String, dynamic>>>? _cachedColumns;
  bool isLoading = true;
  
  // Hard-coded Monday league colors and values
  static const Color _leagueColor = Color.fromRGBO(179, 255, 179, 1); // Light green
  static const Color _appBarColor = Colors.green;
  
  @override
  void initState() {
    super.initState();
    loadPlayers();
    _setOrientation();
    
    // Clear shuffle state when starting with no players selected
    _clearShuffleStateOnInit();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use DeviceDetectionService for consistent device detection
      final deviceType = DeviceDetectionService.getDeviceType(context);
      final deviceName = DeviceDetectionService.getDeviceName(context);

      // Debug info
      DeviceDetectionService.printDebugInfo(context);

      // Lock to landscape mode for all devices
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    // Keep landscape mode locked for Monday screens
    super.dispose();
  }
  
  Future<void> loadPlayers() async {
    try {
      // Load Monday league players only
      List<Map<String, dynamic>> loadedPlayers = await _dbHelper.getPlayersByLeague(League.monday);
      
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
          content: Text('Error loading Monday players: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void togglePlayerSelection(int playerId) {
    setState(() {
      if (selectedPlayerIds.contains(playerId)) {
        selectedPlayerIds.remove(playerId);
        // Handle player removal after shuffle
        _handlePlayerRemoval(playerId);
      } else {
        selectedPlayerIds.add(playerId);
        // Handle player addition after shuffle
        _handlePlayerAddition(playerId);
      }
      
      // If all players are now unselected, clear the shuffle state
      if (selectedPlayerIds.isEmpty) {
        _clearShuffleState();
      }
    });
  }
  
  void selectAllPlayers() {
    setState(() {
      if (selectedPlayerIds.length == players.length) {
        selectedPlayerIds.clear();
        // If all players are now unselected, clear the shuffle state
        _clearShuffleState();
      } else {
        selectedPlayerIds = players.map((p) => p['player_number'] as int).toSet();
      }
    });
  }

  /// Clears the shuffle state when all players are unselected
  void _clearShuffleState() async {
    try {
      await _dbHelper.setSetting('monday_players_shuffled', 'false', league: League.monday);
      await _dbHelper.setSetting('monday_player_order', '', league: League.monday);
      //print("Shuffle state cleared - all players unselected");
    } catch (error) {
      //print("Error clearing shuffle state: $error");
    }
  }

  /// Clears the shuffle state when initializing with no players selected
  void _clearShuffleStateOnInit() async {
    // Since selectedPlayerIds starts empty, clear shuffle state to ensure Shuffle button is active
    if (selectedPlayerIds.isEmpty) {
      try {
        await _dbHelper.setSetting('monday_players_shuffled', 'false', league: League.monday);
        await _dbHelper.setSetting('monday_player_order', '', league: League.monday);
        //print("Shuffle state cleared on init - starting with no players selected");
      } catch (error) {
        //print("Error clearing shuffle state on init: $error");
      }
    }
  }

  /// Handles player removal when shuffle state exists - updates saved player order
  void _handlePlayerRemoval(int playerId) async {
    try {
      // Check if shuffle state exists
      final shuffleState = await _dbHelper.getSetting('monday_players_shuffled', league: League.monday);
      
      if (shuffleState == 'true') {
        // Get the current saved player order
        final playerOrder = await _dbHelper.getSetting('monday_player_order', league: League.monday);
        
        if (playerOrder != null && playerOrder.isNotEmpty) {
          // Find the player name to remove
          String? playerNameToRemove;
          for (var player in players) {
            if (player['player_number'] == playerId) {
              playerNameToRemove = player['last'];
              break;
            }
          }
          
          if (playerNameToRemove != null) {
            // Remove the player from the saved order
            String updatedOrder = _removePlayerFromOrder(playerOrder, playerNameToRemove);
            
            // Save the updated order
            await _dbHelper.setSetting('monday_player_order', updatedOrder, league: League.monday);
            //print("Removed player '$playerNameToRemove' from saved shuffle order");
          }
        }
      }
    } catch (error) {
      //print("Error handling player removal: $error");
    }
  }

  /// Handles player addition when shuffle state exists - adds player to existing groups
  void _handlePlayerAddition(int playerId) async {
    try {
      // Check if shuffle state exists
      final shuffleState = await _dbHelper.getSetting('monday_players_shuffled', league: League.monday);
      
      if (shuffleState == 'true') {
        // Get the current saved player order
        final playerOrder = await _dbHelper.getSetting('monday_player_order', league: League.monday);
        
        if (playerOrder != null && playerOrder.isNotEmpty) {
          // Find the player to add
          String? playerNameToAdd;
          String? playerSkNumber;
          for (var player in players) {
            if (player['player_number'] == playerId) {
              playerNameToAdd = player['last'];
              playerSkNumber = player['skat_number']?.toString() ?? '';
              break;
            }
          }
          
          if (playerNameToAdd != null) {
            // Add the player to the saved order
            String updatedOrder = _addPlayerToOrder(playerOrder, playerNameToAdd, playerSkNumber ?? '');
            
            // Save the updated order
            await _dbHelper.setSetting('monday_player_order', updatedOrder, league: League.monday);
            //print("Added player '$playerNameToAdd' to existing shuffle order");
          }
        }
      }
    } catch (error) {
      //print("Error handling player addition: $error");
    }
  }

  /// Removes a specific player from the serialized player order string
  String _removePlayerFromOrder(String orderData, String playerNameToRemove) {
    try {
      if (orderData.isEmpty) return '';
      
      List<String> playerEntries = orderData.split(';;');
      List<String> filteredEntries = [];
      
      // Filter out the player to remove and adjust group indices
      Map<int, int> groupIndexMap = {}; // old index -> new index
      int newGroupIndex = 0;
      
      // First pass: identify which groups will remain and create mapping
      Set<int> groupsWithPlayers = {};
      for (String entry in playerEntries) {
        List<String> parts = entry.split('|');
        if (parts.length >= 7) {
          int groupIndex = int.parse(parts[0]);
          String name = parts[2];
          
          if (name != playerNameToRemove) {
            groupsWithPlayers.add(groupIndex);
          }
        }
      }
      
      // Create mapping for group indices
      List<int> sortedGroups = groupsWithPlayers.toList()..sort();
      for (int i = 0; i < sortedGroups.length; i++) {
        groupIndexMap[sortedGroups[i]] = i;
      }
      
      // Second pass: rebuild entries with updated group indices
      Map<int, int> playerCountPerGroup = {}; // new group index -> player count
      
      for (String entry in playerEntries) {
        List<String> parts = entry.split('|');
        if (parts.length >= 7) {
          int originalGroupIndex = int.parse(parts[0]);
          String name = parts[2];
          
          // Skip the player to remove
          if (name == playerNameToRemove) {
            continue;
          }
          
          // Get new group index
          int newGroupIndex = groupIndexMap[originalGroupIndex] ?? 0;
          int playerIndex = playerCountPerGroup[newGroupIndex] ?? 0;
          playerCountPerGroup[newGroupIndex] = playerIndex + 1;
          
          // Rebuild the entry with updated indices
          String updatedEntry = '$newGroupIndex|$playerIndex|${parts[2]}|${parts[3]}|${parts[4]}|${parts[5]}|${parts[6]}';
          filteredEntries.add(updatedEntry);
        }
      }
      
      return filteredEntries.join(';;');
    } catch (e) {
      //print("Error removing player from order: $e");
      return orderData; // Return original if error
    }
  }

  /// Adds a new player to the existing serialized player order string
  String _addPlayerToOrder(String orderData, String playerName, String playerSkNumber) {
    try {
      if (orderData.isEmpty) {
        // If no existing order, create new entry in group 0
        return '0|0|$playerName|$playerSkNumber|||';
      }
      
      List<String> playerEntries = orderData.split(';;');
      
      // Analyze current group structure
      Map<int, int> groupPlayerCount = {}; // groupIndex -> player count
      int maxGroupIndex = -1;
      
      for (String entry in playerEntries) {
        List<String> parts = entry.split('|');
        if (parts.length >= 7) {
          int groupIndex = int.parse(parts[0]);
          maxGroupIndex = maxGroupIndex > groupIndex ? maxGroupIndex : groupIndex;
          groupPlayerCount[groupIndex] = (groupPlayerCount[groupIndex] ?? 0) + 1;
        }
      }
      
      // Find the group with the fewest players (for balance)
      int targetGroupIndex = 0;
      int minPlayerCount = 1000; // Large number
      
      for (var entry in groupPlayerCount.entries) {
        if (entry.value < minPlayerCount) {
          minPlayerCount = entry.value;
          targetGroupIndex = entry.key;
        }
      }
      
      // If all groups have 4 players, create a new group
      if (minPlayerCount >= 4) {
        targetGroupIndex = maxGroupIndex + 1;
        minPlayerCount = 0;
      }
      
      // Create new player entry
      String newPlayerEntry = '$targetGroupIndex|$minPlayerCount|$playerName|$playerSkNumber|||';
      
      // Add to existing entries
      List<String> updatedEntries = List.from(playerEntries);
      updatedEntries.add(newPlayerEntry);
      
      // Re-sort entries to maintain proper order (by group, then by player index)
      updatedEntries.sort((a, b) {
        List<String> partsA = a.split('|');
        List<String> partsB = b.split('|');
        
        int groupA = int.parse(partsA[0]);
        int groupB = int.parse(partsB[0]);
        
        if (groupA != groupB) {
          return groupA.compareTo(groupB);
        }
        
        int playerA = int.parse(partsA[1]);
        int playerB = int.parse(partsB[1]);
        return playerA.compareTo(playerB);
      });
      
      // Rebuild with corrected player indices within each group
      Map<int, int> groupPlayerIndex = {}; // groupIndex -> next player index
      List<String> finalEntries = [];
      
      for (String entry in updatedEntries) {
        List<String> parts = entry.split('|');
        if (parts.length >= 7) {
          int groupIndex = int.parse(parts[0]);
          int playerIndex = groupPlayerIndex[groupIndex] ?? 0;
          groupPlayerIndex[groupIndex] = playerIndex + 1;
          
          // Rebuild entry with correct player index
          String correctedEntry = '$groupIndex|$playerIndex|${parts[2]}|${parts[3]}|${parts[4]}|${parts[5]}|${parts[6]}';
          finalEntries.add(correctedEntry);
        }
      }
      
      return finalEntries.join(';;');
    } catch (e) {
      //print("Error adding player to order: $e");
      return orderData; // Return original if error
    }
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
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text("Select Players for Monday's Match - ${DeviceDetectionService.getDeviceName(context)}"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(4),
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
                                        'No Monday players found\nTry importing players first',
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

  Widget _buildTablet8Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text("Select Players for Monday's Match - ${DeviceDetectionService.getDeviceName(context)}"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
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
                                        'No Monday players found\nTry importing players first',
                                        style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : _buildTabletPlayerGrid(),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTablet8Footer(),
              ],
            ),
    );
  }

  Widget _buildTablet10Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text("Select Players for Monday's Match - ${DeviceDetectionService.getDeviceName(context)}"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
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
                                        'No Monday players found\nTry importing players first',
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
      
      // Capture data in the retention service before navigation
      ScreenDataRetentionService().capturePlayerSelectionData(
        selectedPlayerIds: selectedPlayerIds,
        selectedPlayers: selectedPlayers,
      );
      
      // Organize players into groups of 4
      List<List<Map<String, dynamic>?>> groups = [];
      
      for (int i = 0; i < selectedPlayers.length; i += 4) {
        List<Map<String, dynamic>?> group = [];
        
        // Add up to 4 players to each group
        for (int j = 0; j < 4; j++) {
          if (i + j < selectedPlayers.length) {
            group.add(selectedPlayers[i + j]);
          } else {
            group.add(null); // Empty slot
          }
        }
        
        groups.add(group);
      }
      
      // Navigate to Monday Enter Scores Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MondayEnterScoresScreen(
            selectedPlayers: selectedPlayers,
            playersAnte: widget.playersAnte,
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to Monday scores: $e'),
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
                              fontSize: 10,
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
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: selectAllPlayers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen[100],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  selectedPlayerIds.length == players.length
                      ? 'Uncheck All'
                      : 'Check All',
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: selectedPlayerIds.isEmpty ? null : _navigateToEnterScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.green[300],
                  disabledForegroundColor: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  "Enter Skats",
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablet8Footer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: selectAllPlayers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen[100],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  selectedPlayerIds.length == players.length
                      ? 'Uncheck All'
                      : 'Check All',
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: selectedPlayerIds.isEmpty ? null : _navigateToEnterScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.green[300],
                  disabledForegroundColor: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  "Enter Skats",
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablet10Footer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: selectAllPlayers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen[100],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  selectedPlayerIds.length == players.length
                      ? 'Uncheck All'
                      : 'Check All',
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: selectedPlayerIds.isEmpty ? null : _navigateToEnterScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.green[300],
                  disabledForegroundColor: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  "Enter Skats",
                  style: TextStyle(
                    fontSize: ResponsiveTypography.getButton(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Text(
              'Back',
              style: TextStyle(
                fontSize: ResponsiveTypography.getButton(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: selectedPlayerIds.isEmpty ? null : _navigateToEnterScores,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.green[300]!.withOpacity(0.6),
              disabledForegroundColor: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Text(
              "Enter Skats",
              style: TextStyle(
                fontSize: ResponsiveTypography.getButton(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}