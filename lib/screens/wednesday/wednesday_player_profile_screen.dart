import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayPlayerProfileScreen extends StatefulWidget {
  const WednesdayPlayerProfileScreen({super.key});

  @override
  State<WednesdayPlayerProfileScreen> createState() => _WednesdayPlayerProfileScreenState();
}

class _WednesdayPlayerProfileScreenState extends State<WednesdayPlayerProfileScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, dynamic>? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  
  // Form controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _lastController = TextEditingController();
  final TextEditingController _playerNumberController = TextEditingController();
  final TextEditingController _cellController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Focus nodes for TAB navigation
  final FocusNode _idFocus = FocusNode();
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _lastFocus = FocusNode();
  final FocusNode _playerNumberFocus = FocusNode();
  final FocusNode _cellFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  // Hard-coded Wednesday league values
  static const MaterialColor _leagueColor = Colors.orange;
  static const String _leagueTitle = 'Wednesday League Player Profiles';

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
    _playerNumberController.dispose();
    _cellController.dispose();
    _emailController.dispose();
    
    _idFocus.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    _playerNumberFocus.dispose();
    _cellFocus.dispose();
    _emailFocus.dispose();
    
    super.dispose();
  }

  Future<void> _refreshPlayerList() async {
    try {
      final players = await _databaseHelper.getPlayersByLeague(League.wednesday);
      setState(() {
        _players = players;
      });
    } catch (e) {
      _showErrorDialog('Error loading Wednesday players: $e');
    }
  }

  void _clearForm() {
    _idController.clear();
    _firstController.clear();
    _lastController.clear();
    _playerNumberController.clear();
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
    _playerNumberController.text = player['player_number']?.toString() ?? '';
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
        'player_number': int.tryParse(_playerNumberController.text) ?? 0,
        'cell': _cellController.text,
        'email': _emailController.text,
        'league': 'wednesday', // Hard-coded for Wednesday league
      };

      if (_selectedPlayer != null) {
        // Update existing player
        await _databaseHelper.updatePlayer(_selectedPlayer!['id'], playerData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wednesday player updated successfully')),
        );
      } else {
        // Add new player
        await _databaseHelper.insertPlayer(playerData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wednesday player added successfully')),
        );
      }
      
      _refreshPlayerList();
      _clearForm();
    } catch (e) {
      _showErrorDialog('Error saving Wednesday player: $e');
    }
  }

  Future<void> _deletePlayer() async {
    if (_selectedPlayer == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${_selectedPlayer!['first']} ${_selectedPlayer!['last']} from the Wednesday league?'),
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
          const SnackBar(content: Text('Wednesday player deleted successfully')),
        );
        _refreshPlayerList();
        _clearForm();
      } catch (e) {
        _showErrorDialog('Error deleting Wednesday player: $e');
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
        title: const Text('Wednesday Player Profiles'),
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
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: _leagueColor[800],
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: _leagueColor[600],
                      tabs: const [
                        Tab(text: 'Players'),
                        Tab(text: 'Form'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPhonePlayerList(),
                          _buildPhoneForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildPlayerListSection(16, 12),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildFormSection(16, 12),
            ),
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
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildPlayerListSection(18, 12),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: _buildFormSection(18, 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhonePlayerList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _leagueColor[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Wednesday League Players',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _leagueColor[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              final isSelected = _selectedPlayer != null && _selectedPlayer!['id'] == player['id'];
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 1),
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${player['last']}, ${player['first']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text('Player #${player['player_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedTileColor: _leagueColor[200],
                  onTap: () => _populateForm(player),
                  leading: CircleAvatar(
                    backgroundColor: _leagueColor[400],
                    radius: 16,
                    child: Text(
                      '${player['first']?[0] ?? ''}${player['last']?[0] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPhoneForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _leagueColor[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _selectedPlayer == null ? 'Add New Player' : 'Edit Player',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _leagueColor[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          _buildFormFields(12, 10),
          const SizedBox(height: 16),
          _buildPhoneActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildPlayerListSection(double fontSize, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: _leagueColor[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Wednesday League Players',
            style: TextStyle(
              fontSize: fontSize,
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
                  subtitle: Text('Player #${player['player_number'] ?? 'N/A'}'),
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
    );
  }
  
  Widget _buildFormSection(double fontSize, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: _leagueColor[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _selectedPlayer == null ? 'Add New Wednesday Player' : 'Edit Wednesday Player',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: _leagueColor[800],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildFormFields(16, 12),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFormFields(double spacing, double fieldSpacing) {
    return Column(
      children: [
        TextField(
          controller: _firstController,
          focusNode: _firstFocus,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _lastFocus.requestFocus(),
        ),
        SizedBox(height: fieldSpacing),
        TextField(
          controller: _lastController,
          focusNode: _lastFocus,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _playerNumberFocus.requestFocus(),
        ),
        SizedBox(height: fieldSpacing),
        TextField(
          controller: _playerNumberController,
          focusNode: _playerNumberFocus,
          decoration: const InputDecoration(
            labelText: 'Player Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _cellFocus.requestFocus(),
        ),
        SizedBox(height: fieldSpacing),
        TextField(
          controller: _cellController,
          focusNode: _cellFocus,
          decoration: const InputDecoration(
            labelText: 'Cell Phone',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          onSubmitted: (_) => _emailFocus.requestFocus(),
        ),
        SizedBox(height: fieldSpacing),
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
  
  Widget _buildPhoneActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _savePlayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _leagueColor[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(_selectedPlayer == null ? 'Add Player' : 'Update Player'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _clearForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Clear'),
              ),
            ),
            if (_selectedPlayer != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _deletePlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
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
    );
  }
}