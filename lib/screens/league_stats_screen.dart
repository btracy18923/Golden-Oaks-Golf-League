import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';
import '../services/sync_service.dart';
import '../models/league.dart';

class LeagueStatsScreen extends StatefulWidget {
  const LeagueStatsScreen({Key? key}) : super(key: key);

  @override
  _LeagueStatsScreenState createState() => _LeagueStatsScreenState();
}

class _LeagueStatsScreenState extends State<LeagueStatsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();
  
  Map<String, dynamic> _mondayStats = {};
  Map<String, dynamic> _wednesdayStats = {};
  Map<String, dynamic> _syncStatus = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadLeagueStats(League.monday),
        _loadLeagueStats(League.wednesday),
        _loadSyncStatus(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading stats: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLeagueStats(League league) async {
    try {
      // Get players
      List<Map<String, dynamic>> players = await _dbHelper.getPlayersByLeague(league);
      
      // Get games
      List<Map<String, dynamic>> games = await _dbHelper.getGamesByLeague(league);
      
      // Calculate total games played this month
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      List<Map<String, dynamic>> thisMonthGames = games.where((game) {
        DateTime? gameDate = DateTime.tryParse(game['date'] ?? '');
        return gameDate != null && gameDate.isAfter(startOfMonth);
      }).toList();

      // Calculate player statistics
      Map<String, dynamic> playerStats = await _calculatePlayerStats(players, league);
      
      // Calculate financial statistics
      Map<String, dynamic> financialStats = await _calculateFinancialStats(games, league);

      Map<String, dynamic> stats = {
        'total_players': players.length,
        'active_players': players.where((p) => p['active'] == 1).length,
        'total_games': games.length,
        'games_this_month': thisMonthGames.length,
        'player_statistics': playerStats,
        'financial_statistics': financialStats,
        'last_game_date': games.isNotEmpty ? games.first['date'] : 'No games yet',
      };

      setState(() {
        if (league == League.monday) {
          _mondayStats = stats;
        } else {
          _wednesdayStats = stats;
        }
      });
    } catch (e) {
      print('Error loading ${league.toString()} stats: $e');
    }
  }

  Future<Map<String, dynamic>> _calculatePlayerStats(List<Map<String, dynamic>> players, League league) async {
    if (players.isEmpty) return {};

    List<double> handicaps = [];
    int playersWithScores = 0;
    double totalWinnings = 0;

    for (var player in players) {
      double handicap = (player['handicap'] ?? 0.0).toDouble();
      if (handicap > 0) handicaps.add(handicap);

      // Get player scores to check if they have recent activity
      List<Map<String, dynamic>> scores = await _dbHelper.getPlayerScoresWithWinnings(player['id'], league);
      if (scores.isNotEmpty) {
        playersWithScores++;
        
        // Calculate total winnings
        for (var score in scores) {
          totalWinnings += (score['skat_winnings'] ?? 0.0).toDouble();
          totalWinnings += (score['group_winnings'] ?? 0.0).toDouble();
          totalWinnings += (score['single_winnings'] ?? 0.0).toDouble();
          totalWinnings += (score['individual_winnings'] ?? 0.0).toDouble();
        }
      }
    }

    double avgHandicap = handicaps.isNotEmpty 
        ? handicaps.reduce((a, b) => a + b) / handicaps.length 
        : 0.0;

    return {
      'average_handicap': avgHandicap,
      'players_with_scores': playersWithScores,
      'total_winnings_paid': totalWinnings,
      'handicap_range': handicaps.isNotEmpty 
          ? '${handicaps.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)} - ${handicaps.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}'
          : 'No handicaps recorded',
    };
  }

  Future<Map<String, dynamic>> _calculateFinancialStats(List<Map<String, dynamic>> games, League league) async {
    if (games.isEmpty) return {};

    double totalAnteCollected = 0;
    double totalMulligansCollected = await _dbHelper.getTotalMulligans(league);

    for (var game in games) {
      totalAnteCollected += (game['ante_amount'] ?? 0.0).toDouble();
    }

    return {
      'total_ante_collected': totalAnteCollected,
      'total_mulligans_collected': totalMulligansCollected,
      'total_purse': totalAnteCollected + totalMulligansCollected,
      'average_game_purse': games.isNotEmpty ? (totalAnteCollected + totalMulligansCollected) / games.length : 0.0,
    };
  }

  Future<void> _loadSyncStatus() async {
    try {
      Map<String, dynamic> status = await _syncService.getDetailedSyncStats();
      setState(() {
        _syncStatus = status;
      });
    } catch (e) {
      print('Error loading sync status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('League Statistics'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAllStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _loadAllStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSyncStatusCard(),
                      const SizedBox(height: 16),
                      _buildLeagueComparisonCard(),
                      const SizedBox(height: 16),
                      _buildMondayLeagueCard(),
                      const SizedBox(height: 16),
                      _buildWednesdayLeagueCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Firebase Sync Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_syncStatus.isNotEmpty) ...[
              _buildSyncStatusRow('Sync Enabled', _syncStatus['firebase_status']?['sync_enabled']?.toString() ?? 'Unknown'),
              _buildSyncStatusRow('Last Sync', _formatLastSync(_syncStatus['firebase_status']?['last_sync'])),
              _buildSyncStatusRow('Authentication', _syncStatus['firebase_status']?['authenticated']?.toString() ?? 'Unknown'),
              if (_syncStatus['sync_service_status']?['last_error'] != null)
                _buildSyncStatusRow('Last Error', _syncStatus['sync_service_status']['last_error'], isError: true),
            ] else
              const Text('Loading sync status...'),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusRow(String label, String? value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value ?? 'Unknown',
            style: TextStyle(
              color: isError ? Colors.red : null,
              fontWeight: isError ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync(String? lastSync) {
    if (lastSync == null || lastSync.isEmpty) return 'Never';
    try {
      DateTime syncTime = DateTime.parse(lastSync);
      Duration difference = DateTime.now().difference(syncTime);
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return lastSync;
    }
  }

  Widget _buildLeagueComparisonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'League Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonColumn('Monday League', _mondayStats, Colors.green[600]!),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildComparisonColumn('Wednesday League', _wednesdayStats, Colors.orange[600]!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonColumn(String title, Map<String, dynamic> stats, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8.0),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatRow('Players', '${stats['active_players'] ?? 0}'),
          _buildStatRow('Games', '${stats['total_games'] ?? 0}'),
          _buildStatRow('This Month', '${stats['games_this_month'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMondayLeagueCard() {
    return _buildLeagueDetailCard('Monday League', _mondayStats, Colors.green[600]!);
  }

  Widget _buildWednesdayLeagueCard() {
    return _buildLeagueDetailCard('Wednesday League', _wednesdayStats, Colors.orange[600]!);
  }

  Widget _buildLeagueDetailCard(String title, Map<String, dynamic> stats, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn('Players', [
                      'Total: ${stats['total_players'] ?? 0}',
                      'Active: ${stats['active_players'] ?? 0}',
                      'With Scores: ${stats['player_statistics']?['players_with_scores'] ?? 0}',
                    ]),
                  ),
                  Expanded(
                    child: _buildDetailColumn('Games', [
                      'Total: ${stats['total_games'] ?? 0}',
                      'This Month: ${stats['games_this_month'] ?? 0}',
                      'Last Game: ${stats['last_game_date'] ?? 'Never'}',
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn('Player Stats', [
                      'Avg Handicap: ${(stats['player_statistics']?['average_handicap'] ?? 0.0).toStringAsFixed(1)}',
                      'Handicap Range: ${stats['player_statistics']?['handicap_range'] ?? 'N/A'}',
                    ]),
                  ),
                  Expanded(
                    child: _buildDetailColumn('Financials', [
                      'Total Ante: \$${(stats['financial_statistics']?['total_ante_collected'] ?? 0.0).toStringAsFixed(2)}',
                      'Total Mulligans: \$${(stats['financial_statistics']?['total_mulligans_collected'] ?? 0.0).toStringAsFixed(2)}',
                      'Total Purse: \$${(stats['financial_statistics']?['total_purse'] ?? 0.0).toStringAsFixed(2)}',
                      'Total Winnings: \$${(stats['player_statistics']?['total_winnings_paid'] ?? 0.0).toStringAsFixed(2)}',
                    ]),
                  ),
                ],
              ),
            ] else
              const Text('No data available for this league'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(item, style: const TextStyle(fontSize: 14)),
        )).toList(),
      ],
    );
  }
}