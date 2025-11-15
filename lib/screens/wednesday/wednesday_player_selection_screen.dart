import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import 'wednesday_enter_scores_screen.dart';

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
  static const Color _appBarColor = Colors.orange;
  
  @override
  void initState() {
    super.initState();
    loadPlayers();
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
        selectedPlayerIds = players.map((p) => p['id'] as int).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text("Select Players for Wednesday's Match"),
        backgroundColor: _appBarColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Main content area with white background
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
                        // Selected count info
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Selected Players: ${selectedPlayerIds.length}/${players.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // 4-column player grid
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
                                      const Text(
                                        'No Wednesday players found\nTry importing players first',
                                        style: TextStyle(fontSize: 18),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : _buildPlayerGrid(),
                        ),
                        
                        // Check All button
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: selectAllPlayers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _leagueColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.black, width: 1),
                            ),
                          ),
                          child: Text(
                            selectedPlayerIds.length == players.length 
                                ? 'Uncheck All' 
                                : 'Check All',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _leagueColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                        child: const Text(
                          'Return to Wednesday Menu',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: selectedPlayerIds.isEmpty 
                            ? null 
                            : _navigateToEnterScores,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _leagueColor,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: _leagueColor.withOpacity(0.6),
                          disabledForegroundColor: Colors.black.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                        child: const Text(
                          "Enter Player's Scores",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildPlayerGrid() {
    // Use cached columns if available, otherwise create them
    List<List<Map<String, dynamic>>> columns = _cachedColumns ?? [[], [], [], []];
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int colIndex = 0; colIndex < 4; colIndex++)
          Expanded(
            child: Column(
              children: [
                for (var player in columns[colIndex])
                  _buildPlayerCheckbox(player),
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
          .where((player) => selectedPlayerIds.contains(player['id'] as int))
          .toList();
      
      // Randomly shuffle the players before assigning to groups
      final random = Random();
      selectedPlayers.shuffle(random);
      
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
      
      // Navigate to Wednesday Enter Scores Screen
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
  
  Widget _buildPlayerCheckbox(Map<String, dynamic> player) {
    final int playerId = player['id'] as int;
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
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      fontSize: 14,
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
}