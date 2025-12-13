import 'package:flutter/material.dart';
import '../../services/firebase_player_import_service.dart';
import '../../services/responsive_typography.dart';

/// Screen for importing Monday league players from Firebase into Wednesday league
class WednesdayImportPlayersScreen extends StatefulWidget {
  const WednesdayImportPlayersScreen({Key? key}) : super(key: key);

  @override
  State<WednesdayImportPlayersScreen> createState() => _WednesdayImportPlayersScreenState();
}

class _WednesdayImportPlayersScreenState extends State<WednesdayImportPlayersScreen> {
  final FirebasePlayerImportService _importService = FirebasePlayerImportService();

  bool _isLoading = false;
  bool _isPreviewLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _importResult;
  List<Map<String, dynamic>> _previewPlayers = [];
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isPreviewLoading = true;
      _statusMessage = 'Loading preview from Firebase...';
    });

    try {
      List<Map<String, dynamic>> players = await _importService.previewMondayPlayers();

      setState(() {
        _previewPlayers = players;
        _isPreviewLoading = false;
        _statusMessage = 'Found ${players.length} players in M_player_profile collection';
      });
    } catch (e) {
      setState(() {
        _isPreviewLoading = false;
        _statusMessage = 'Error loading preview: $e';
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing Firebase connection...';
    });

    bool canAccess = await _importService.testMondayPlayerCollectionAccess();

    setState(() {
      _isLoading = false;
      _statusMessage = canAccess
          ? 'Successfully connected to M_player_profile collection'
          : 'Failed to connect to M_player_profile collection';
    });
  }

  Future<void> _importPlayers({bool skipExisting = true, bool updateExisting = false}) async {
    // Confirm with user
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text(
          updateExisting
              ? 'This will import Monday league players from Firebase and update existing Wednesday players with matching names. Continue?'
              : skipExisting
                  ? 'This will import Monday league players from Firebase, skipping players that already exist in Wednesday league. Continue?'
                  : 'This will import ALL Monday league players from Firebase, even if they already exist in Wednesday league. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Importing players from Firebase...';
      _importResult = null;
    });

    try {
      Map<String, dynamic> result = await _importService.importMondayPlayersToWednesday(
        skipExisting: skipExisting,
        updateExisting: updateExisting,
      );

      setState(() {
        _isLoading = false;
        _importResult = result;
        _statusMessage = result['success']
            ? 'Import completed successfully!\nDownloaded: ${result['total_downloaded']}\nImported: ${result['total_imported']}\nSkipped: ${result['skipped'].length}'
            : 'Import failed. Check errors below.';
      });

      // Reload preview to show updated player count
      _loadPreview();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error during import: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Import Monday Players',
          style: TextStyle(fontSize: ResponsiveTypography.getHeading(context)),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading || _isPreviewLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage, style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Status',
                            style: TextStyle(
                              fontSize: ResponsiveTypography.getHeading(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_statusMessage, style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context))),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Import Options',
                            style: TextStyle(
                              fontSize: ResponsiveTypography.getHeading(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.cloud_sync),
                            label: Text('Test Firebase Connection', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _importPlayers(skipExisting: true, updateExisting: false),
                            icon: const Icon(Icons.download),
                            label: Text('Import New Players Only', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _importPlayers(skipExisting: false, updateExisting: true),
                            icon: const Icon(Icons.sync),
                            label: Text('Import & Update Existing', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadPreview,
                            icon: const Icon(Icons.refresh),
                            label: Text('Refresh Preview', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Preview section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Preview (${_previewPlayers.length} players)',
                                style: TextStyle(
                                  fontSize: ResponsiveTypography.getHeading(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showPreview ? Icons.expand_less : Icons.expand_more),
                                onPressed: () {
                                  setState(() {
                                    _showPreview = !_showPreview;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_showPreview) ...[
                            const Divider(),
                            SizedBox(
                              height: 400,
                              child: ListView.builder(
                                itemCount: _previewPlayers.length,
                                itemBuilder: (context, index) {
                                  var player = _previewPlayers[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(
                                      '${player['first']} ${player['last']}',
                                      style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context)),
                                    ),
                                    subtitle: Text(
                                      'Player #${player['player_number'] ?? 'N/A'} | Skat #${player['skat_number'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: ResponsiveTypography.getSmall(context)),
                                    ),
                                    trailing: player['cell'] != null
                                        ? Icon(Icons.phone, size: ResponsiveTypography.getSmall(context))
                                        : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Import results
                  if (_importResult != null) ...[
                    Card(
                      color: _importResult!['success'] ? Colors.green[50] : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Results',
                              style: TextStyle(
                                fontSize: ResponsiveTypography.getHeading(context),
                                fontWeight: FontWeight.bold,
                                color: _importResult!['success'] ? Colors.green[900] : Colors.red[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Downloaded: ${_importResult!['total_downloaded']}',
                              style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context)),
                            ),
                            Text(
                              'Imported: ${_importResult!['total_imported']}',
                              style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context)),
                            ),
                            Text(
                              'Skipped: ${_importResult!['skipped'].length}',
                              style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context)),
                            ),

                            if (_importResult!['errors'].isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Errors:',
                                style: TextStyle(
                                  fontSize: ResponsiveTypography.getBodyText(context),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[900],
                                ),
                              ),
                              ...(_importResult!['errors'] as List).map((error) => Text(
                                    '• $error',
                                    style: TextStyle(fontSize: ResponsiveTypography.getSmall(context), color: Colors.red[900]),
                                  )),
                            ],

                            if (_importResult!['skipped'].isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Skipped Players:',
                                style: TextStyle(
                                  fontSize: ResponsiveTypography.getBodyText(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ...(_importResult!['skipped'] as List).take(10).map((skipped) => Text(
                                    '• $skipped',
                                    style: TextStyle(fontSize: ResponsiveTypography.getSmall(context)),
                                  )),
                              if (_importResult!['skipped'].length > 10)
                                Text(
                                  '... and ${_importResult!['skipped'].length - 10} more',
                                  style: TextStyle(fontSize: ResponsiveTypography.getSmall(context), fontStyle: FontStyle.italic),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
