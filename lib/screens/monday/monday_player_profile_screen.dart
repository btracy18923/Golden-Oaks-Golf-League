import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 1),
          SizedBox(
            height: 28, // Reduced height for text field
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.only(left: 6, right: 6, top: 2, bottom: 10),
              ),
              style: const TextStyle(fontSize: 11, height: 1.0),
              onFieldSubmitted: (_) {
                // If a player is selected, update the player; otherwise close keyboard
                if (_selectedPlayer != null) {
                  _updatePlayer();
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, FocusNode focusNode, FocusNode? nextFocus, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onFieldSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                } else {
                  // If this is the last field and a player is selected, update the player
                  if (_selectedPlayer != null) {
                    _updatePlayer();
                  }
                }
              },
            ),
          ],
        ),
      );
    } else {
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
                  } else {
                    // If this is the last field and a player is selected, update the player
                    if (_selectedPlayer != null) {
                      _updatePlayer();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPlayerTable() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 900;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final is6InchPhonePortrait = !isLandscape && screenWidth <= 600;
    
    // Calculate available width for table
    double tableWidth;
    if (isMobile) {
      if (is6InchPhonePortrait) {
        tableWidth = screenWidth; // Full screen width for 6" phone portrait
      } else {
        tableWidth = screenWidth - 20; // Account for padding (10px on each side)
      }
    } else if (isTablet) {
      // In tablet layout, table gets 70% of remaining width after form
      tableWidth = (screenWidth * 0.7) - 30; // Account for padding and gap
    } else {
      tableWidth = screenWidth - 40;
    }
    
    Widget tableWidget = Container(
      width: tableWidth,
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
            child: SizedBox(
              width: tableWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: isMobile ? (is6InchPhonePortrait ? [
                    _buildHeaderCellLeftAlign('Name', tableWidth * 0.47),
                    _buildHeaderCellLeftAlign('SK#', tableWidth * 0.16),
                    _buildHeaderCellLeftAlign('Phone', tableWidth * 0.37),
                  ] : [
                    _buildHeaderCell('Name', tableWidth * 0.55),
                    _buildHeaderCell('S#', tableWidth * 0.2),
                    _buildHeaderCell('Phone', tableWidth * 0.2),
                  ]) : [
                    _buildHeaderCell('Name', tableWidth * 0.5),
                    _buildHeaderCell('S#', tableWidth * 0.25),
                    _buildHeaderCell('Phone', tableWidth * 0.25),
                  ],
                ),
              ),
            ),
          ),
          // Player rows
          Expanded(
            child: SizedBox(
              width: tableWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth, // Use full available table width
                  child: ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      final isSelected = _selectedPlayer?['id'] == player['id'];
                      
                      return GestureDetector(
                        onTap: () => _selectPlayer(player),
                        child: Container(
                          height: isMobile ? 50 : 40,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.lightGreen[200] : Colors.transparent,
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                          ),
                          child: isMobile 
                            ? _buildMobilePlayerRow(player, tableWidth) 
                            : _buildTabletPlayerRow(player, tableWidth),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    
    // For 6" phone portrait, use OverflowBox to allow table to exceed parent bounds
    if (is6InchPhonePortrait) {
      return OverflowBox(
        maxWidth: screenWidth,
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: const Offset(-10, 0),
          child: tableWidget,
        ),
      );
    } else {
      return tableWidget;
    }
  }
  
  Widget _buildMobilePlayerRow(Map<String, dynamic> player, double tableWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final is6InchPhonePortrait = !isLandscape && screenWidth <= 600;
    
    return Row(
      children: [
        _buildDataCell('${player['first'] ?? ''} ${player['last'] ?? ''}', 
                      is6InchPhonePortrait ? tableWidth * 0.5 : tableWidth * 0.55, 
                      alignLeft: true),
        _buildDataCell(player['skat_number']?.toString() ?? '', 
                      is6InchPhonePortrait ? tableWidth * 0.1 : tableWidth * 0.2),
        _buildDataCell(_formatPhoneNumber(player['cell']), 
                      is6InchPhonePortrait ? tableWidth * 0.4 : tableWidth * 0.2),
      ],
    );
  }
  
  Widget _buildTabletPlayerRow(Map<String, dynamic> player, double tableWidth) {
    return Row(
      children: [
        _buildDataCell('${player['first'] ?? ''} ${player['last'] ?? ''}', tableWidth * 0.5, alignLeft: true),
        _buildDataCell(player['skat_number']?.toString() ?? '', tableWidth * 0.25),
        _buildDataCell(_formatPhoneNumber(player['cell']), tableWidth * 0.25),
      ],
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

  Widget _buildHeaderCellLeftAlign(String text, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool alignLeft = false}) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: alignLeft 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : Center(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 900;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Profile - ${_selectedLeague == League.monday ? 'Monday' : 'Wednesday'} League'),
        backgroundColor: _selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          color: Colors.grey[100],
          padding: EdgeInsets.all(isMobile ? 10 : 20),
          child: isTablet 
            ? _buildTabletLayout()
            : _buildMobileLayout(),
        ),
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Form (30%)
            Expanded(
              flex: 30,
              child: SizedBox(
                height: constraints.maxHeight,
                child: _buildFormSection(),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Right side - Player list (70%)
            Expanded(
              flex: 70,
              child: SizedBox(
                height: constraints.maxHeight,
                child: _buildPlayerTable(),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildMobileLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final is6InchPhonePortrait = !isLandscape && screenWidth <= 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (is6InchPhonePortrait) {
          // 6" phone portrait: move buttons to bottom footer
          final footerHeight = 80.0; // Height for 2-row footer
          final formHeight = constraints.maxHeight * 0.5; // Reduced from 0.55 to 0.5
          final remainingHeight = constraints.maxHeight - formHeight - footerHeight - 30;
          
          return Column(
            children: [
              // Form section on top (no buttons)
              SizedBox(
                height: formHeight,
                child: _buildFormSectionWithoutButtons(),
              ),
              
              const SizedBox(height: 10),
              
              // Player list in middle
              SizedBox(
                height: remainingHeight,
                child: _buildPlayerTable(),
              ),
              
              const SizedBox(height: 10),
              
              // Button footer at bottom
              SizedBox(
                height: footerHeight,
                child: _buildButtonFooter(),
              ),
            ],
          );
        } else {
          // Original layout for other mobile sizes
          final formHeight = constraints.maxHeight * 0.6;
          final remainingHeight = constraints.maxHeight - formHeight - 20;
          
          return Column(
            children: [
              // Form section on top
              SizedBox(
                height: formHeight,
                child: _buildFormSection(),
              ),
              
              const SizedBox(height: 20),
              
              // Player list below
              SizedBox(
                height: remainingHeight,
                child: _buildPlayerTable(),
              ),
            ],
          );
        }
      },
    );
  }
  
  Widget _buildFormSection() {
    return Column(
      children: [
        // Form fields - scrollable area that takes up available space
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildFormField('ID#', _idController, _idFocus, _firstFocus, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                _buildFormField('First Name', _firstController, _firstFocus, _lastFocus),
                _buildFormField('Last Name', _lastController, _lastFocus, _skatFocus),
                _buildFormField('SKAT#', _skatController, _skatFocus, _cellFocus, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                _buildFormField('Cell Phone', _cellController, _cellFocus, _emailFocus, 
                  keyboardType: TextInputType.numberWithOptions(decimal: false)),
                _buildFormField('Email', _emailController, _emailFocus, null),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        
        // Action buttons - fixed at bottom
        _buildActionButtons(),
      ],
    );
  }
  
  Widget _buildFormSectionWithoutButtons() {
    return Column(
      children: [
        // Form fields - static layout that fits within available space
        Expanded(
          flex: 1,
          child: _buildCompactFormField('ID#', _idController, _idFocus, _firstFocus, 
            keyboardType: TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ),
        Expanded(
          flex: 1,
          child: _buildCompactFormField('First Name', _firstController, _firstFocus, _lastFocus),
        ),
        Expanded(
          flex: 1,
          child: _buildCompactFormField('Last Name', _lastController, _lastFocus, _skatFocus),
        ),
        Expanded(
          flex: 1,
          child: _buildCompactFormField('SKAT#', _skatController, _skatFocus, _cellFocus, 
            keyboardType: TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ),
        Expanded(
          flex: 1,
          child: _buildCompactFormField('Cell Phone', _cellController, _cellFocus, _emailFocus, 
            keyboardType: TextInputType.numberWithOptions(decimal: false)),
        ),
        Expanded(
          flex: 1,
          child: _buildCompactFormField('Email', _emailController, _emailFocus, null),
        ),
      ],
    );
  }
  
  Widget _buildButtonFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // First row: 2 buttons
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _addPlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text('Add Player', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _deletePlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text('Delete Player', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Second row: 2 buttons
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _clearForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text('Clear Form', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text('Return to Main', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: _addPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text('Add Player', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: _updatePlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text('Edit Player', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: _deletePlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text('Delete Player', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: _clearForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text('Clear Form', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text('Return to Main Menu', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    child: const Text('Add Player', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updatePlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    child: const Text('Edit Player', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deletePlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    child: const Text('Delete Player', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    child: const Text('Clear Form', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 2),
              ),
              child: const Text('Return to Main Menu', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      );
    }
  }
}