import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/firebase_service.dart';
import '../models/league.dart';

class SyncDemoScreen extends StatefulWidget {
  const SyncDemoScreen({Key? key}) : super(key: key);

  @override
  _SyncDemoScreenState createState() => _SyncDemoScreenState();
}

class _SyncDemoScreenState extends State<SyncDemoScreen> {
  final SyncService _syncService = SyncService();
  final FirebaseService _firebaseService = FirebaseService();
  
  Map<String, dynamic> _syncStats = {};
  bool _isLoading = false;
  String _lastOperation = '';
  String _operationResult = '';

  @override
  void initState() {
    super.initState();
    _loadSyncStats();
  }

  Future<void> _loadSyncStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> stats = await _syncService.getDetailedSyncStats();
      setState(() {
        _syncStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationResult = 'Error loading stats: $e';
      });
    }
  }

  Future<void> _performOperation(String operation, Future<bool> Function() action) async {
    setState(() {
      _isLoading = true;
      _lastOperation = operation;
      _operationResult = '';
    });

    try {
      bool success = await action();
      setState(() {
        _operationResult = success ? '$operation completed successfully!' : '$operation failed!';
      });
      
      // Reload stats after operation
      await _loadSyncStats();
    } catch (e) {
      setState(() {
        _operationResult = '$operation error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Sync Demo'),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSyncStatusCard(),
                  const SizedBox(height: 16),
                  _buildOperationButtons(),
                  const SizedBox(height: 16),
                  _buildResultCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatusCard() {
    String status = _syncStats['sync_service_status']?['current_status'] ?? 'Unknown';
    String lastSync = _syncStats['sync_service_status']?['last_sync_time'] ?? 'Never';
    String? lastError = _syncStats['sync_service_status']?['last_error'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Current Status: $status'),
            Text('Last Sync: ${lastSync != 'Never' ? DateTime.tryParse(lastSync)?.toString() ?? lastSync : lastSync}'),
            if (lastError != null) Text('Last Error: $lastError', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _performOperation(
                      'Full Sync (Both Leagues)', 
                      () => _syncService.performFullSync()
                    ),
                    child: const Text('Full Sync'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _performOperation(
                      'Enable Sync', 
                      () async {
                        await _firebaseService.setSyncEnabled(true);
                        return true;
                      }
                    ),
                    child: const Text('Enable Sync'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _performOperation(
                      'Monday League Sync', 
                      () => _syncService.syncMondayLeagueOnly()
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    child: const Text('Sync Monday'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _performOperation(
                      'Wednesday League Sync', 
                      () => _syncService.syncWednesdayLeagueOnly()
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
                    child: const Text('Sync Wednesday'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _performOperation(
                      'Upload to Firebase', 
                      () => _syncService.syncToFirebase()
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
                    child: const Text('Upload to Cloud'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _performOperation(
                      'Download from Firebase', 
                      () => _syncService.syncFromFirebase()
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]),
                    child: const Text('Download from Cloud'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_lastOperation.isEmpty && _operationResult.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Operation Result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_lastOperation.isNotEmpty) Text('Operation: $_lastOperation'),
            if (_operationResult.isNotEmpty) 
              Text(
                'Result: $_operationResult',
                style: TextStyle(
                  color: _operationResult.contains('successfully') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLeagueStats('Monday League', _syncStats['monday_league']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLeagueStats('Wednesday League', _syncStats['wednesday_league']),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _loadSyncStats,
              child: const Text('Refresh Stats'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueStats(String title, Map<String, dynamic>? stats) {
    if (stats == null) {
      return Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text('No data available'),
        ],
      );
    }

    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Players: ${stats['players'] ?? 0}'),
        Text('Games: ${stats['games'] ?? 0}'),
      ],
    );
  }
}