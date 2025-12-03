import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayPlayerScoresScreen extends StatefulWidget {
  const WednesdayPlayerScoresScreen({super.key});

  @override
  State<WednesdayPlayerScoresScreen> createState() => _WednesdayPlayerScoresScreenState();
}

class _WednesdayPlayerScoresScreenState extends State<WednesdayPlayerScoresScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _scores = [];
  bool _isLoading = false;

  // Hard-coded Wednesday league values
  static const MaterialColor _leagueColor = Colors.orange;
  static const String _leagueTitle = 'Wednesday League Player Scores';

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final players = await _databaseHelper.getPlayersByLeague(League.wednesday);
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading Wednesday players: $e');
    }
  }

  Future<void> _loadPlayerScores(String playerLast) async {
    setState(() => _isLoading = true);
    try {
      final scores = await _databaseHelper.getPlayerScoreHistory(playerLast, League.wednesday);
      setState(() {
        _scores = scores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading scores for $playerLast: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Wednesday Player Scores'),
        backgroundColor: _leagueColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            _buildPlayerSelectionSection(14, 8, 10),
            const SizedBox(height: 12),
            _buildScoresDisplaySection(16, 60),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTablet8Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(_leagueTitle),
        backgroundColor: _leagueColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 56,
      ),
      body: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildPlayerSelectionSection(16, 10, 12),
            const SizedBox(height: 16),
            _buildScoresDisplaySection(18, 80),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTablet10Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(_leagueTitle),
        backgroundColor: _leagueColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 64,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildPlayerSelectionSection(16, 12, 12),
            const SizedBox(height: 20),
            _buildScoresDisplaySection(18, 100),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayerSelectionSection(double fontSize, double padding, double spacing) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _leagueColor[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _leagueColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Wednesday League Player:',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _leagueColor[800],
            ),
          ),
          SizedBox(height: spacing),
          DropdownButtonFormField<String>(
            value: _selectedPlayer,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            hint: const Text('Choose a player'),
            items: _players.map((player) {
              String playerName = '${player['last']}, ${player['first']}';
              return DropdownMenuItem<String>(
                value: player['last'],
                child: Text(playerName),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedPlayer = value;
                _scores.clear();
              });
              if (value != null) {
                _loadPlayerScores(value);
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoresDisplaySection(double fontSize, double iconSize) {
    if (_selectedPlayer != null) {
      return Expanded(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _leagueColor[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _leagueColor, width: 1),
              ),
              child: Text(
                'Wednesday League Scores for $_selectedPlayer',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: _leagueColor[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _scores.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.score_outlined,
                                size: iconSize,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No scores found for this Wednesday league player',
                                style: TextStyle(fontSize: fontSize),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _buildScoresList(),
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search,
                size: iconSize,
                color: _leagueColor[300],
              ),
              const SizedBox(height: 20),
              Text(
                'Select a Wednesday League player to view their scores',
                style: TextStyle(
                  fontSize: fontSize,
                  color: _leagueColor[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildScoresList() {
    return ListView.builder(
      itemCount: _scores.length,
      itemBuilder: (context, index) {
        final score = _scores[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: _leagueColor[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _leagueColor[200]!, width: 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _leagueColor[300],
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              'Date: ${score['date_played'] ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Course: ${score['golf_course'] ?? 'Unknown'}'),
                Text('Gross Score: ${score['gross_score'] ?? 'N/A'}'),
                Text('Individual Winnings: \$${score['single_winnings']?.toStringAsFixed(2) ?? '0.00'}'),
                Text('Group Winnings: \$${score['group_winnings']?.toStringAsFixed(2) ?? '0.00'}'),
              ],
            ),
            trailing: Icon(
              Icons.golf_course,
              color: _leagueColor[600],
            ),
          ),
        );
      },
    );
  }
}