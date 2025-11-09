import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../models/league.dart';

class PlayerProfileScreen extends StatefulWidget {
  final League? league;
  
  const PlayerProfileScreen({super.key, this.league});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  League _selectedLeague = League.monday;
  Map<String, dynamic>? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  
  // Form controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _lastController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();
  final TextEditingController _skatController = TextEditingController();
  final TextEditingController _cellController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Focus nodes for TAB navigation
  final FocusNode _idFocus = FocusNode();
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _lastFocus = FocusNode();
  final FocusNode _handicapFocus = FocusNode();
  final FocusNode _skatFocus = FocusNode();
  final FocusNode _cellFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedLeague = widget.league ?? League.monday;
    _refreshPlayerList();
  }

  @override
  void dispose() {
    _idController.dispose();
    _firstController.dispose();
    _lastController.dispose();
    _handicapController.dispose();
    _skatController.dispose();
    _cellController.dispose();
    _emailController.dispose();
    
    _idFocus.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    _handicapFocus.dispose();
    _skatFocus.dispose();
    _cellFocus.dispose();
    _emailFocus.dispose();
    
    super.dispose();
  }

  Future<void> _refreshPlayerList() async {
    try {
      final players = await _databaseHelper.getPlayersByLeague(_selectedLeague);
      setState(() {
        _players = players;
      });
    } catch (e) {
      _showErrorDialog('Error loading players: $e');
    }
  }

  void _clearForm() {
    _idController.clear();
    _firstController.clear();
    _lastController.clear();
    _handicapController.clear();
    _skatController.clear();
    _cellController.clear();
    _emailController.clear();
    setState(() {
      _selectedPlayer = null;
    });
  }

  void _selectPlayer(Map<String, dynamic> player) {
    setState(() {
      _selectedPlayer = player;
      _idController.text = player['player_number']?.toString() ?? '';
      _firstController.text = player['first'] ?? '';
      _lastController.text = player['last'] ?? '';
      _handicapController.text = player['handicap']?.toString() ?? '';
      _skatController.text = player['skat_number']?.toString() ?? '';
      _cellController.text = player['cell'] ?? '';
      _emailController.text = player['email'] ?? '';
    });
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '${digits.substring(1, 4)}-${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone;
  }

  bool _validateForm() {
    if (_idController.text.trim().isEmpty) {
      _showErrorDialog('ID Number is required!');
      return false;
    }
    
    if (_firstController.text.trim().isEmpty) {
      _showErrorDialog('First Name is required!');
      return false;
    }
    
    if (_lastController.text.trim().isEmpty) {
      _showErrorDialog('Last Name is required!');
      return false;
    }
    
    return true;
  }

  Future<void> _addPlayer() async {
    if (!_validateForm()) return;
    
    try {
      final leagueStr = _selectedLeague == League.monday ? 'monday' : 'wednesday';
      
      await _databaseHelper.insertPlayer({
        'player_number': int.tryParse(_idController.text) ?? 0,
        'first': _firstController.text.trim(),
        'last': _lastController.text.trim(),
        'handicap': double.tryParse(_handicapController.text) ?? 0.0,
        'skat_number': int.tryParse(_skatController.text),
        'league': leagueStr,
        'cell': _cellController.text.trim(),
        'email': _emailController.text.trim(),
      });
      
      _clearForm();
      _refreshPlayerList();
      _showSuccessDialog('Player added successfully!');
    } catch (e) {
      _showErrorDialog('Error adding player: $e');
    }
  }

  Future<void> _updatePlayer() async {
    if (_selectedPlayer == null) {
      _showErrorDialog('Please select a player to update');
      return;
    }
    
    if (!_validateForm()) return;
    
    try {
      final leagueStr = _selectedLeague == League.monday ? 'monday' : 'wednesday';
      
      await _databaseHelper.updatePlayer(_selectedPlayer!['id'], {
        'player_number': int.tryParse(_idController.text) ?? 0,
        'first': _firstController.text.trim(),
        'last': _lastController.text.trim(),
        'handicap': double.tryParse(_handicapController.text) ?? 0.0,
        'skat_number': int.tryParse(_skatController.text),
        'league': leagueStr,
        'cell': _cellController.text.trim(),
        'email': _emailController.text.trim(),
      });
      
      _clearForm();
      _refreshPlayerList();
      _showSuccessDialog('Player updated successfully!');
    } catch (e) {
      _showErrorDialog('Error updating player: $e');
    }
  }

  Future<void> _deletePlayer() async {
    if (_selectedPlayer == null) {
      _showErrorDialog('Please select a player to delete');
      return;
    }
    
    final playerName = '${_selectedPlayer!['first']} ${_selectedPlayer!['last']}';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $playerName?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _databaseHelper.deletePlayer(_selectedPlayer!['id']);
        _clearForm();
        _refreshPlayerList();
        _showSuccessDialog('Player deleted successfully!');
      } catch (e) {
        _showErrorDialog('Error deleting player: $e');
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, FocusNode focusNode, FocusNode? nextFocus, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onFieldSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildHeaderCell('ID#', 60),
                  _buildHeaderCell('First', 120),
                  _buildHeaderCell('Last', 120),
                  _buildHeaderCell('HC', 60),
                  _buildHeaderCell('SKAT#', 80),
                  _buildHeaderCell('Cell', 130),
                  _buildHeaderCell('Email', 200),
                ],
              ),
            ),
          ),
          // Player rows
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 770,
                child: ListView.builder(
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    final isSelected = _selectedPlayer?['id'] == player['id'];
                    
                    return GestureDetector(
                      onTap: () => _selectPlayer(player),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.lightGreen[200] : Colors.transparent,
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: Row(
                          children: [
                            _buildDataCell(player['player_number']?.toString() ?? '', 60),
                            _buildDataCell(player['first'] ?? '', 120),
                            _buildDataCell(player['last'] ?? '', 120),
                            _buildDataCell(player['handicap']?.toString() ?? '', 60),
                            _buildDataCell(player['skat_number']?.toString() ?? '', 80),
                            _buildDataCell(_formatPhoneNumber(player['cell']), 130),
                            _buildDataCell(player['email'] ?? '', 200),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Profile - ${_selectedLeague == League.monday ? 'Monday' : 'Wednesday'} League'),
        backgroundColor: _selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Form (30%)
              Expanded(
                flex: 30,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Form fields
                      _buildFormField('ID#', _idController, _idFocus, _firstFocus, 
                        keyboardType: TextInputType.number, 
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      _buildFormField('First Name', _firstController, _firstFocus, _lastFocus),
                      _buildFormField('Last Name', _lastController, _lastFocus, _handicapFocus),
                      _buildFormField('Handicap', _handicapController, _handicapFocus, _skatFocus, 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      _buildFormField('SKAT#', _skatController, _skatFocus, _cellFocus, 
                        keyboardType: TextInputType.number, 
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      _buildFormField('Cell Phone', _cellController, _cellFocus, _emailFocus, 
                        keyboardType: TextInputType.phone),
                      _buildFormField('Email', _emailController, _emailFocus, null),
                      
                      const SizedBox(height: 20),
                      
                      // Action buttons
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _addPlayer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightGreen,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Add Player'),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _updatePlayer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Edit Player'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _deletePlayer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[300],
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Delete Player'),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _clearForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[300],
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Clear Form'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[300],
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Return to Main Menu'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Right side - Player list (70%)
              Expanded(
                flex: 70,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 140,
                  child: _buildPlayerTable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}