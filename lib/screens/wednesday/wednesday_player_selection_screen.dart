import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
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
      tablet8: _buildTablet8Layout(),
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
  
  Widget _buildTablet8Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text("Select Players for Wednesday's Match - ${DeviceDetectionService.getDeviceName(context)}"),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 56,
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
                                        'No Wednesday players found\nTry importing players first',
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
                  backgroundColor: Colors.blue[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  '◄---- Back      ',
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
                  backgroundColor: Colors.yellow[100],
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
                  backgroundColor: Colors.orange[300],
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.orange[300]!.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  "Enter Gross ---➤",
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
                  backgroundColor: Colors.orange[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  '◄---- Back     ',
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
                  backgroundColor: Colors.yellow[100],
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
                  backgroundColor: _leagueColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: _leagueColor.withValues (alpha: 0.6),
                  disabledForegroundColor: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  "Enter Player's Scores",
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
                  backgroundColor: Colors.orange[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  '◄---- Back      ',
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
                  backgroundColor: Colors.yellow[100],
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
                  backgroundColor: _leagueColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: _leagueColor.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  "Enter Player's Scores ---➤",
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
}