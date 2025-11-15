import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';

class MondayPlayerProfileScreen extends StatefulWidget {
  const MondayPlayerProfileScreen({super.key});

  @override
  State<MondayPlayerProfileScreen> createState() => _MondayPlayerProfileScreenState();
}

class _MondayPlayerProfileScreenState extends State<MondayPlayerProfileScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, dynamic>? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  
  // Form controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _lastController = TextEditingController();
  final TextEditingController _skatController = TextEditingController();
  final TextEditingController _cellController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Focus nodes for TAB navigation
  final FocusNode _idFocus = FocusNode();
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _lastFocus = FocusNode();
  final FocusNode _skatFocus = FocusNode();
  final FocusNode _cellFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  // Hard-coded Monday league values
  static const Color _leagueColor = Colors.green;
  static const String _leagueTitle = 'Monday League Player Profiles';

  @override
  void initState() {
    super.initState();
    _refreshPlayerList();
  }

  @override
  void dispose() {
    _idController.dispose();
    _firstController.dispose();
    _lastController.dispose();
    _skatController.dispose();
    _cellController.dispose();
    _emailController.dispose();
    
    _idFocus.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    _skatFocus.dispose();
    _cellFocus.dispose();
    _emailFocus.dispose();
    
    super.dispose();
  }

  Future<void> _refreshPlayerList() async {
    try {
      final players = await _databaseHelper.getPlayersByLeague(League.monday);
      setState(() {
        _players = players;
      });
    } catch (e) {
      _showErrorDialog('Error loading Monday players: $e');
    }
  }

  void _clearForm() {
    _idController.clear();
    _firstController.clear();
    _lastController.clear();
    _skatController.clear();
    _cellController.clear();
    _emailController.clear();
    setState(() {
      _selectedPlayer = null;
    });
  }

  void _populateForm(Map<String, dynamic> player) {
    _idController.text = player['id']?.toString() ?? '';
    _firstController.text = player['first'] ?? '';
    _lastController.text = player['last'] ?? '';
    _skatController.text = player['skat_number']?.toString() ?? '';
    _cellController.text = player['cell'] ?? '';
    _emailController.text = player['email'] ?? '';
    
    setState(() {
      _selectedPlayer = player;
    });
  }

  Future<void> _savePlayer() async {
    try {
      Map<String, dynamic> playerData = {
        'first': _firstController.text,
        'last': _lastController.text,
        'skat_number': int.tryParse(_skatController.text) ?? 0,
        'cell': _cellController.text,
        'email': _emailController.text,
        'league': 'monday', // Hard-coded for Monday league
      };

      if (_selectedPlayer != null) {
        // Update existing player
        await _databaseHelper.updatePlayer(_selectedPlayer!['id'], playerData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monday player updated successfully')),
        );
      } else {
        // Add new player
        await _databaseHelper.insertPlayer(playerData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monday player added successfully')),
        );
      }
      
      _refreshPlayerList();
      _clearForm();
    } catch (e) {
      _showErrorDialog('Error saving Monday player: $e');
    }
  }

  Future<void> _deletePlayer() async {
    if (_selectedPlayer == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${_selectedPlayer!['first']} ${_selectedPlayer!['last']} from the Monday league?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _databaseHelper.deletePlayer(_selectedPlayer!['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monday player deleted successfully')),
        );
        _refreshPlayerList();
        _clearForm();
      } catch (e) {
        _showErrorDialog('Error deleting Monday player: $e');
      }
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
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(_leagueTitle),
        backgroundColor: _leagueColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Left side - Player List
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _leagueColor[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Monday League Players',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _leagueColor[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        final player = _players[index];
                        final isSelected = _selectedPlayer != null && _selectedPlayer!['id'] == player['id'];
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            title: Text(
                              '${player['last']}, ${player['first']}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('SKAT #${player['skat_number'] ?? 'N/A'}'),
                            selected: isSelected,
                            selectedTileColor: _leagueColor[200],
                            onTap: () => _populateForm(player),
                            leading: CircleAvatar(
                              backgroundColor: _leagueColor[400],
                              child: Text(
                                '${player['first']?[0] ?? ''}${player['last']?[0] ?? ''}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Right side - Form
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _leagueColor[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedPlayer == null ? 'Add New Monday Player' : 'Edit Monday Player',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _leagueColor[800],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Form fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // First Name
                          TextField(
                            controller: _firstController,
                            focusNode: _firstFocus,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _lastFocus.requestFocus(),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Last Name
                          TextField(
                            controller: _lastController,
                            focusNode: _lastFocus,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _skatFocus.requestFocus(),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // SKAT Number
                          TextField(
                            controller: _skatController,
                            focusNode: _skatFocus,
                            decoration: const InputDecoration(
                              labelText: 'SKAT Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onSubmitted: (_) => _cellFocus.requestFocus(),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Cell Phone
                          TextField(
                            controller: _cellController,
                            focusNode: _cellFocus,
                            decoration: const InputDecoration(
                              labelText: 'Cell Phone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            onSubmitted: (_) => _emailFocus.requestFocus(),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Email
                          TextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: _clearForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[400],
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Clear'),
                              ),
                              ElevatedButton(
                                onPressed: _savePlayer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _leagueColor[400],
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(_selectedPlayer == null ? 'Add' : 'Update'),
                              ),
                              if (_selectedPlayer != null)
                                ElevatedButton(
                                  onPressed: _deletePlayer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[400],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}