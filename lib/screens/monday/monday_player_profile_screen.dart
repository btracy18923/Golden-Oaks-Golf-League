import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/UI/player_profile_service.dart';

class MondayPlayerProfileScreen extends StatefulWidget {
  final League? league;
  
  const MondayPlayerProfileScreen({super.key, this.league});

  @override
  State<MondayPlayerProfileScreen> createState() => _MondayPlayerProfileScreenState();
}

class _MondayPlayerProfileScreenState extends State<MondayPlayerProfileScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  League _selectedLeague = League.monday;
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
    _skatController.clear();
    _cellController.clear();
    _emailController.clear();
    
    // Remove focus from all form fields
    FocusScope.of(context).unfocus();
    
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

  Widget _buildCompactFormField(String label, TextEditingController controller, FocusNode focusNode, FocusNode? nextFocus, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return PlayerProfileService.buildCompactFormField(
      context,
      label,
      controller,
      focusNode,
      nextFocus,
      _selectedPlayer != null ? _updatePlayer : null,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, FocusNode focusNode, FocusNode? nextFocus, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return PlayerProfileService.buildFormField(
      context,
      label,
      controller,
      focusNode,
      nextFocus,
      _selectedPlayer != null ? _updatePlayer : null,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildPlayerTable() {
    return PlayerProfileService.buildPlayerTable(
      context,
      _players,
      _selectedPlayer,
      _selectPlayer,
      _formatPhoneNumber,
    );
  }
  

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = size.width;
    final screenHeight = size.height;
    
    // Improved responsive breakpoints
    final isLargeTablet = screenWidth >= 1200; // 10"+ tablets
    final isMediumTablet = screenWidth >= 800 && screenWidth < 1200; // 8" tablets
    final isSmallTablet = screenWidth >= 600 && screenWidth < 800; // Small tablets
    final isPhone = screenWidth < 600; // Phones
    final isTablet = isLargeTablet || isMediumTablet || isSmallTablet;
    final isLandscape = orientation == Orientation.landscape;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Profile - ${_selectedLeague == League.monday ? 'Monday' : 'Wednesday'} League'),
        backgroundColor: _selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[100],
                padding: _getAdaptivePadding(isTablet, isPhone, isLandscape),
                child: _buildAdaptiveLayout(isTablet, isPhone, isLandscape, screenWidth, screenHeight),
              ),
            ),
            _buildFullScreenButtonBar(),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildTabletLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PlayerProfileService.buildTabletLayout(
          context,
          constraints,
          _buildFormSectionWithoutButtons(),
          _buildPlayerTable(),
        );
      },
    );
  }
  
  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PlayerProfileService.buildMobileLayout(
          context,
          constraints,
          _buildFormSectionWithoutButtons(),
          _buildPlayerTable(),
          _buildButtonFooterLandscape(),
        );
      },
    );
  }
  
  Widget _buildFormSection() {
    return PlayerProfileService.buildFormSection(
      context,
      _buildFormField,
      _idController,
      _firstController,
      _lastController,
      _skatController,
      _cellController,
      _emailController,
      _idFocus,
      _firstFocus,
      _lastFocus,
      _skatFocus,
      _cellFocus,
      _emailFocus,
      _buildActionButtons(),
    );
  }
  
  Widget _buildFormSectionWithoutButtons() {
    return PlayerProfileService.buildFormSectionWithoutButtons(
      context,
      _buildCompactFormField,
      _idController,
      _firstController,
      _lastController,
      _skatController,
      _cellController,
      _emailController,
      _idFocus,
      _firstFocus,
      _lastFocus,
      _skatFocus,
      _cellFocus,
      _emailFocus,
    );
  }
  
  
  
  Widget _buildButtonFooterLandscape() {
    return PlayerProfileService.buildButtonFooterLandscape(
      _addPlayer,
      _deletePlayer,
      _clearForm,
      () => Navigator.of(context).pop(),
    );
  }
  
  Widget _buildActionButtons() {
    return PlayerProfileService.buildActionButtons(
      _addPlayer,
      _updatePlayer,
      _deletePlayer,
      _clearForm,
      () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }
  
  EdgeInsets _getAdaptivePadding(bool isTablet, bool isPhone, bool isLandscape) {
    if (isTablet) {
      return const EdgeInsets.all(24.0);
    } else if (isPhone && isLandscape) {
      return const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }
  
  Widget _buildAdaptiveLayout(bool isTablet, bool isPhone, bool isLandscape, double screenWidth, double screenHeight) {
    if (isTablet) {
      return _buildTabletLayout();
    } else if (isPhone && isLandscape) {
      return _buildPhoneLandscapeLayout();
    } else {
      return _buildPhonePortraitLayout();
    }
  }
  
  Widget _buildPhoneLandscapeLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form section (35% width)
            Expanded(
              flex: 35,
              child: Container(
                height: constraints.maxHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(12.0),
                child: _buildFormSectionWithoutButtons(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Player table (65% width)
            Expanded(
              flex: 65,
              child: Container(
                height: constraints.maxHeight,
                child: _buildPlayerTable(),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPhonePortraitLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final formHeight = constraints.maxHeight * 0.5;
        final tableHeight = constraints.maxHeight * 0.5;
        
        return Column(
          children: [
            // Form section
            Container(
              height: formHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(16.0),
              child: _buildFormSectionWithoutButtons(),
            ),
            
            const SizedBox(height: 12),
            
            // Player table
            Container(
              height: tableHeight,
              child: _buildPlayerTable(),
            ),
          ],
        );
      },
    );
  }
  

  Widget _buildFullScreenButtonBar() {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _addPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Add Player', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton(
              onPressed: _clearForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Clear', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedPlayer != null ? _deletePlayer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedPlayer != null ? Colors.red[300] : Colors.grey[400],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}