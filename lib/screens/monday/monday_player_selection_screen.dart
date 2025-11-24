import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import 'monday_enter_scores_screen.dart';
import 'new_monday_enter_scores_screen.dart';

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
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use consistent device detection with main menu screen
      final screenWidth = MediaQuery.of(context).size.width;
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      final is6Point5Phone = isLandscape && screenWidth >= 750 && screenWidth < 900; // 6.5" phone range
      
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
        title: const Text("Select Players for Monday's Match"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                final is6Point5Phone = isLandscape && screenWidth >= 750 && screenWidth < 900;
                
                return Column(
                  children: [
                    // Main content area with white background
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(is6Point5Phone ? 4 : 16), // Further reduced margin for 6" landscape
                        padding: EdgeInsets.all(is6Point5Phone ? 4 : 16), // Further reduced padding for 6" landscape
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(is6Point5Phone ? 4 : 8),
                        ),
                        child: Column(
                          children: [
                            // Selected count info (hide for 6" landscape to save space)
                            if (!is6Point5Phone) 
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
                            
                            if (!is6Point5Phone) const SizedBox(height: 10),
                        
                        // 4-column player grid
                        Expanded(
                          child: players.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: is6Point5Phone ? 60 : 80,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: is6Point5Phone ? 8 : 16),
                                      Text(
                                        'No Monday players found\nTry importing players first',
                                        style: TextStyle(fontSize: is6Point5Phone ? 14 : 18),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : is6Point5Phone
                                  ? Scrollbar(
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        child: _buildPlayerGrid(),
                                      ),
                                    )
                                  : _buildPlayerGrid(),
                        ),
                        
                        // Check All button (hidden for 6" phone landscape mode)
                        Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                            final is6Point5Phone = isLandscape && screenWidth <= 900;
                            
                            if (is6Point5Phone) {
                              return const SizedBox.shrink(); // Hide for 6" landscape
                            }
                            
                            return Column(
                              children: [
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
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer buttons
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                    final is6Point5Phone = isLandscape && screenWidth <= 900;
                    
                    return Container(
                      padding: EdgeInsets.all(is6Point5Phone ? 8.0 : 16.0), // 50% height reduction for 6" landscape
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                      ),
                      child: is6Point5Phone
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Return button (swapped position)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _leagueColor,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(color: Colors.black, width: 1),
                                        ),
                                      ),
                                      child: const Text(
                                        'Return',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Check All button (swapped position)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: selectAllPlayers,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _leagueColor,
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
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Enter Scores button
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: selectedPlayerIds.isEmpty 
                                          ? null 
                                          : _navigateToEnterScores,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _leagueColor,
                                        foregroundColor: Colors.black,
                                        disabledBackgroundColor: _leagueColor,
                                        disabledForegroundColor: Colors.black.withOpacity(0.6),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(color: Colors.black, width: 1),
                                        ),
                                      ),
                                      child: const Text(
                                        "Enter Skats",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // New button
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: _navigateToNewEnterScores,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[200],
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(color: Colors.black, width: 1),
                                        ),
                                      ),
                                      child: const Text(
                                        "New",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
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
                                    'Return to Monday Menu',
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
                                    "Enter Player's Skats",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _navigateToNewEnterScores,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[200],
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Colors.black, width: 1),
                                    ),
                                  ),
                                  child: const Text(
                                    "New",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ],
                );
              },
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
  
  void _navigateToNewEnterScores() {
    // Get selected players
    List<Map<String, dynamic>> selectedPlayers = players
        .where((player) => selectedPlayerIds.contains(player['id'] as int))
        .toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewMondayEnterScoresScreen(
          selectedPlayers: selectedPlayers,
          playersAnte: widget.playersAnte, // Pass through the Players Ante value
        ),
      ),
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
      
      // Navigate to Monday Enter Scores Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnterScoresScreenWithData(
            selectedPlayers: selectedPlayers,
            groups: groups,
            leagueType: 'monday',
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
  
  Widget _buildPlayerCheckbox(Map<String, dynamic> player) {
    final int playerId = player['id'] as int;
    final bool isSelected = selectedPlayerIds.contains(playerId);
    
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final is6Point5Phone = isLandscape && screenWidth <= 900;
        
        // Choose player name format based on screen size
        final String playerName = is6Point5Phone 
            ? '${player['last']}'  // Only last name for 6" landscape
            : '${player['last']}, ${player['first']}';  // Full name for other sizes
        
        return Container(
          margin: EdgeInsets.symmetric(
            vertical: is6Point5Phone ? 0.5 : 1, 
            horizontal: 2
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => togglePlayerSelection(playerId),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: is6Point5Phone ? 2 : 4, 
                  horizontal: 4
                ),
                child: Row(
                  children: [
                    Container(
                      width: is6Point5Phone ? 24 : 32,
                      height: is6Point5Phone ? 24 : 32,
                      decoration: BoxDecoration(
                        color: isSelected ? _leagueColor : Colors.grey[300],
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? Center(
                              child: Text(
                                'X',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: is6Point5Phone ? 14 : 18,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: is6Point5Phone ? 6 : 8),
                    Expanded(
                      child: Text(
                        playerName,
                        style: TextStyle(
                          fontSize: is6Point5Phone ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: is6Point5Phone ? 1 : 2, // Single line for 6" landscape
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}