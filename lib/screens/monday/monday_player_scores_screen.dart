import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';

class MondayPlayerScoresScreen extends StatefulWidget {
  final League? league;
  
  const MondayPlayerScoresScreen({super.key, this.league});

  @override
  State<MondayPlayerScoresScreen> createState() => _MondayPlayerScoresScreenState();
}

class _MondayPlayerScoresScreenState extends State<MondayPlayerScoresScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  League _selectedLeague = League.monday;
  String? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _scores = [];
  int? _selectedScoreIndex;
  bool _isEditing = false;
  bool _showAddScoreRow = false; // Track whether to show the add score row
  Set<int> _unlockedScoreIds = {}; // Track which score rows are unlocked for editing
  
  // Controllers for adding new scores
  final TextEditingController _grossScoreController = TextEditingController();
  final TextEditingController _skatsController = TextEditingController();
  final TextEditingController _winningsController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();
  final TextEditingController _closePinController = TextEditingController();
  final FocusNode _grossScoreFocus = FocusNode();
  final FocusNode _skatsFocus = FocusNode();
  final FocusNode _winningsFocus = FocusNode();
  final FocusNode _handicapFocus = FocusNode();
  final FocusNode _closePinFocus = FocusNode();
  
  // Golf course selection
  String _selectedGolfCourse = 'TBD';
  final List<String> _golfCourses = [
    'TBD',
    'The Hideout',
    'Golden Oaks',
    'Pine Valley',
    'Oak Creek',
    'Sunset Hills'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLeague = widget.league ?? League.monday;
    // Set default golf course based on league
    _selectedGolfCourse = _selectedLeague == League.monday ? 'TBD' : 'The Hideout';
    _loadPlayers();
    
    // Force landscape orientation for 6" phones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOrientation();
    });
  }

  void _setOrientation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Only force landscape for phones (6.5" and smaller)
    // Let tablets use natural orientation
    if (screenWidth <= 900 || screenHeight <= 600) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Allow both orientations for tablets
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    // Keep landscape mode locked for Monday screens
    
    _grossScoreController.dispose();
    _skatsController.dispose();
    _winningsController.dispose();
    _handicapController.dispose();
    _closePinController.dispose();
    _grossScoreFocus.dispose();
    _skatsFocus.dispose();
    _winningsFocus.dispose();
    _handicapFocus.dispose();
    _closePinFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    try {
      final players = await _databaseHelper.getPlayersByLeague(_selectedLeague);
      setState(() {
        _players = players;
      });
    } catch (e) {
      _showErrorDialog('Error loading players: $e');
    }
  }

  Future<void> _loadPlayerScores(String playerLast) async {
    try {
      final scores = await _databaseHelper.getPlayerScoresSimple(
        _players.firstWhere((p) => p['last'] == playerLast)['id'],
        _selectedLeague
      );
      setState(() {
        _scores = scores;
        _selectedScoreIndex = null; // Clear selection when loading new player scores
      });
    } catch (e) {
      _showErrorDialog('Error loading scores: $e');
    }
  }

  Future<void> _addScore() async {
    if (_selectedPlayer == null) {
      _showErrorDialog('Please select a player first');
      return;
    }
    
    // If the add score row is not showing, show it and populate fields
    if (!_showAddScoreRow) {
      final player = _players.firstWhere((p) => p['last'] == _selectedPlayer);
      final screenWidth = MediaQuery.of(context).size.width;
      final is6InchPhoneLandscape = screenWidth <= 900;
      
      setState(() {
        _showAddScoreRow = true;
        // Pre-populate fields with player data
        if (_selectedLeague == League.wednesday) {
          _handicapController.text = (player['handicap'] ?? 0.0).toString();
        }
        _winningsController.text = is6InchPhoneLandscape ? '0.00' : '0'; // Prefill winnings field with appropriate format
        _closePinController.text = is6InchPhoneLandscape ? '0.00' : '0'; // Prefill close pin field with appropriate format
      });
      return;
    }
    
    // Check for required fields
    List<String> missingFields = [];
    
    // Check gross score for Wednesday league only
    if (_selectedLeague == League.wednesday && _grossScoreController.text.trim().isEmpty) {
      missingFields.add('Gross Score');
    }
    
    // Check SKATS field for Monday league only
    if (_selectedLeague == League.monday && _skatsController.text.trim().isEmpty) {
      missingFields.add('SKATS Score');
    }
    
    // Check winnings field 
    if (_winningsController.text.trim().isEmpty) {
      missingFields.add('Winnings Amount');
    }
    
    // Show error if any fields are missing
    if (missingFields.isNotEmpty) {
      String errorMessage = 'Please enter: ${missingFields.join(', ')}';
      _showErrorDialog(errorMessage);
      return;
    }
    
    // Validate gross score for Wednesday league
    if (_selectedLeague == League.wednesday) {
      final grossScore = int.tryParse(_grossScoreController.text.trim());
      if (grossScore == null || grossScore < 10 || grossScore > 99) {
        _showErrorDialog('Gross score must be between 10 and 99');
        return;
      }
    }
    
    double winningsAmount = 0.0;
    if (_winningsController.text.trim().isNotEmpty) {
      winningsAmount = double.tryParse(_winningsController.text.trim()) ?? 0.0;
    }
    
    // Get handicap from editable field (for Wednesday league)
    double handicap = 0.0;
    if (_selectedLeague == League.wednesday && _handicapController.text.trim().isNotEmpty) {
      handicap = double.tryParse(_handicapController.text.trim()) ?? 0.0;
    }
    
    // Get gross score (for Wednesday league)
    int grossScore = 0;
    if (_selectedLeague == League.wednesday && _grossScoreController.text.trim().isNotEmpty) {
      grossScore = int.tryParse(_grossScoreController.text.trim()) ?? 0;
    }
    
    // Get close pin winnings
    double closePinWinnings = 0.0;
    if (_closePinController.text.trim().isNotEmpty) {
      closePinWinnings = double.tryParse(_closePinController.text.trim()) ?? 0.0;
    }
    
    // SKAT number no longer used - removed from Monday league
    
    try {
      final playerId = _players.firstWhere((p) => p['last'] == _selectedPlayer)['id'];
      final player = _players.firstWhere((p) => p['last'] == _selectedPlayer);
      final playerName = '${player['first']} ${player['last']}';
      
      Map<String, dynamic> scoreData = {
        'player_id': playerId,
        'name': player['last'], // Use only Last Name
        'date_played': DateTime.now().toIso8601String().split('T')[0],
        'close_pin_winnings': closePinWinnings, // From Close Pin field
      };
      
      // Add handicap and gross score for Wednesday league only
      if (_selectedLeague == League.wednesday) {
        scoreData['handicap'] = handicap;
        scoreData['gross_score'] = grossScore;
      }
      
      if (_selectedLeague == League.monday) {
        // Monday League: Name, Date, Golf Course, Close Pin, SKATS, SKAT Winnings
        scoreData['golf_course'] = _selectedGolfCourse; // Use selected golf course
        scoreData['skats_score'] = int.tryParse(_skatsController.text.trim()) ?? 0; // From Enter Scores
        scoreData['skat_winnings'] = winningsAmount; // From Enter Scores
      } else {
        // Wednesday League: Name, Date, Golf Course, HC, Gross, Close Pin, Single Winnings, Group Winnings
        scoreData['golf_course'] = 'The Hideout'; // Always The Hideout
        scoreData['single_winnings'] = winningsAmount; // From Enter Scores
        scoreData['group_winnings'] = 0.0; // Always $0 for now
      }
      
      int scoreId = await _databaseHelper.insertScoreLeague(scoreData, _selectedLeague);
      
      // Clear input fields and hide add score row
      _grossScoreController.clear();
      _skatsController.clear();
      _winningsController.clear();
      _handicapController.clear();
      _closePinController.clear();
      
      // Lock the newly created row immediately and hide add score row
      setState(() {
        _unlockedScoreIds.remove(scoreId); // Ensure it's locked
        _showAddScoreRow = false; // Hide the add score row
      });
      
      _loadPlayerScores(_selectedPlayer!);
      _showSuccessDialog('Score added and locked successfully!');
    } catch (e) {
      _showErrorDialog('Error adding score: $e');
    }
  }

  Future<void> _deleteScore(Map<String, dynamic> score) async {
    final scoreId = score['id'] as int;
    
    // Always unlock the row first for deletion
    setState(() {
      _unlockedScoreIds.add(scoreId);
    });
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the score ${score['gross_score']} for ${_selectedPlayer} on ${score['date_played']}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              // Re-lock the row if user cancels
              setState(() {
                _selectedScoreIndex = null;
                _unlockedScoreIds.remove(scoreId);
              });
            },
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
        // Determine which table to delete from based on league
        String tableName = _selectedLeague == League.monday ? 'monday_scores' : 'wednesday_scores';
        final db = await _databaseHelper.database;
        
        // Delete from the appropriate league table
        await db.delete(
          tableName,
          where: 'id = ?',
          whereArgs: [scoreId],
        );
        
        setState(() {
          _selectedScoreIndex = null;
          // Remove from unlocked set since the row is now deleted
          _unlockedScoreIds.remove(scoreId);
        });
        _loadPlayerScores(_selectedPlayer!);
        _showSuccessDialog('Score deleted successfully!');
      } catch (e) {
        // Re-lock the row if deletion failed
        setState(() {
          _unlockedScoreIds.remove(scoreId);
        });
        _showErrorDialog('Error deleting score: $e');
      }
    } else {
      // If confirmation dialog was dismissed without choosing, re-lock the row
      setState(() {
        _unlockedScoreIds.remove(scoreId);
      });
    }
  }

  void _selectPlayer(String playerLast) {
    setState(() {
      _selectedPlayer = playerLast;
      _selectedScoreIndex = null;
      _showAddScoreRow = false; // Hide add score row when selecting new player
      _unlockedScoreIds.clear(); // Lock all rows when selecting a new player
    });
    _loadPlayerScores(playerLast);
  }

  void _clearSelection() {
    setState(() {
      _selectedPlayer = null;
      _selectedScoreIndex = null;
      _scores = [];
      _showAddScoreRow = false; // Hide add score row when clearing selection
      _unlockedScoreIds.clear(); // Lock all rows when clearing selection
      // Clear input fields
      _grossScoreController.clear();
      _skatsController.clear();
      _winningsController.clear();
      _handicapController.clear();
      _closePinController.clear();
    });
  }

  void _editScore() {
    if (_selectedScoreIndex == null) {
      _showErrorDialog('Please select a score to edit');
      return;
    }
    
    final selectedScore = _scores[_selectedScoreIndex!];
    final scoreId = selectedScore['id'] as int;
    
    // Always unlock the selected row for editing
    setState(() {
      _unlockedScoreIds.add(scoreId);
    });
    
    // Show edit dialog with appropriate fields based on league
    showDialog(
      context: context,
      builder: (context) {
        final grossController = TextEditingController(text: selectedScore['gross_score']?.toString() ?? '');
        final skatsController = TextEditingController(text: selectedScore['skats_score']?.toString() ?? '');
        final winningsController = TextEditingController(
          text: _selectedLeague == League.monday 
            ? selectedScore['skat_winnings']?.toString() ?? '0'
            : selectedScore['single_winnings']?.toString() ?? '0'
        );
        
        return AlertDialog(
          title: const Text('Edit Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedLeague == League.wednesday)
                TextField(
                  controller: grossController,
                  decoration: const InputDecoration(labelText: 'Gross Score'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
              if (_selectedLeague == League.monday)
                TextField(
                  controller: skatsController,
                  decoration: const InputDecoration(labelText: 'SKATS Score'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              TextField(
                controller: winningsController,
                decoration: InputDecoration(
                  labelText: _selectedLeague == League.monday ? 'SKAT Winnings' : 'Single Winnings'
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Re-lock the row if user cancels
                setState(() {
                  _unlockedScoreIds.remove(scoreId);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final winnings = double.tryParse(winningsController.text) ?? 0.0;
                  
                  // Validate gross score for Wednesday league
                  if (_selectedLeague == League.wednesday) {
                    final grossScore = int.tryParse(grossController.text);
                    if (grossScore == null || grossScore < 10 || grossScore > 99) {
                      // Close the edit dialog first, then show error
                      Navigator.of(context).pop();
                      // Re-lock the row since edit failed
                      setState(() {
                        _unlockedScoreIds.remove(scoreId);
                      });
                      _showErrorDialog('Gross score must be between 10 and 99');
                      return;
                    }
                  }
                  
                  // Prepare update data based on league
                  Map<String, dynamic> updateData = {};
                  
                  if (_selectedLeague == League.wednesday) {
                    final grossScore = int.tryParse(grossController.text);
                    updateData['gross_score'] = grossScore;
                  }
                  
                  if (_selectedLeague == League.monday) {
                    final skatsScore = skatsController.text.trim();
                    updateData['skats_score'] = skatsScore.isEmpty ? null : int.tryParse(skatsScore);
                    updateData['skat_winnings'] = winnings;
                  } else {
                    updateData['single_winnings'] = winnings;
                  }
                  
                  // Update in the appropriate league table
                  String tableName = _selectedLeague == League.monday ? 'monday_scores' : 'wednesday_scores';
                  final db = await _databaseHelper.database;
                  
                  await db.update(
                    tableName,
                    updateData,
                    where: 'id = ?',
                    whereArgs: [scoreId],
                  );
                  
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedScoreIndex = null;
                    // Re-lock the row after successful edit
                    _unlockedScoreIds.remove(scoreId);
                  });
                  _loadPlayerScores(_selectedPlayer!);
                  _showSuccessDialog('Score updated successfully!');
                } catch (e) {
                  // Close the edit dialog first, then show error
                  Navigator.of(context).pop();
                  // Re-lock the row since edit failed
                  setState(() {
                    _unlockedScoreIds.remove(scoreId);
                  });
                  _showErrorDialog('Error updating score: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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

  String _getLeagueDisplayName() {
    return _selectedLeague == League.monday ? 'Monday' : 'Wednesday';
  }

  void setLeague(League league) {
    setState(() {
      _selectedLeague = league;
      _selectedPlayer = null;
      _selectedScoreIndex = null;
      _scores = [];
      _showAddScoreRow = false; // Hide add score row when league changes
      _unlockedScoreIds.clear(); // Lock all rows when league changes
      // Clear input fields when league changes
      _grossScoreController.clear();
      _skatsController.clear();
      _winningsController.clear();
      _handicapController.clear();
    });
    _loadPlayers();
  }

  Widget _buildPlayerList({bool isCompact = false, bool hideHeader = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    double listWidth = isCompact ? double.infinity : 200;
    double headerFontSize = isCompact ? 12 : 16;
    double itemFontSize = isCompact ? 11 : 14;
    double itemPadding = isCompact ? 2 : 4;
    
    Widget playerListView = ListView.builder(
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        final playerName = '${player['first']} ${player['last']}';
        final isSelected = _selectedPlayer == player['last'];
        
        return GestureDetector(
          onTap: () => _selectPlayer(player['last']),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8, vertical: itemPadding),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (_selectedLeague == League.monday ? Colors.green[200] : Colors.amber[200])
                  : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              playerName,
              style: TextStyle(
                fontSize: itemFontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );

    if (hideHeader) {
      return playerListView;
    }

    return Container(
      width: isCompact ? null : listWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 4 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Text(
              'Players',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
            ),
          ),
          Expanded(
            child: playerListView,
          ),
        ],
      ),
    );
  }

  Widget _buildScoresTable() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Define device categories
    final isPhone = screenWidth <= 900;  // 6.5" phones
    final isSmallTablet = screenWidth > 900 && screenWidth <= 1200;  // 8" tablets
    final isLargeTablet = screenWidth > 1200;  // 10" tablets
    
    // Adjust table width based on screen size and orientation
    double tableWidth;
    if (isPhone) {
      // Phone: Compact layout
      tableWidth = _selectedLeague == League.monday ? 510 : 550;
    } else if (isSmallTablet) {
      // 8" tablet: Medium layout
      tableWidth = _selectedLeague == League.monday ? 650 : 700;
    } else {
      // 10" tablet: Full layout
      tableWidth = _selectedLeague == League.monday ? 810 : 870;
    }
    
    final isCompact = isPhone;
    final isMedium = isSmallTablet;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final finalTableWidth = availableWidth > tableWidth ? availableWidth : tableWidth;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: finalTableWidth,
            child: Column(
              children: [
            // Two-line header
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.grey[200],
              ),
              child: _buildHeaders(isCompact: isCompact, isMedium: isMedium),
            ),
            
            // Add new score row (if player selected and add score button clicked)
            if (_selectedPlayer != null && _showAddScoreRow) _buildAddScoreRow(isCompact: isCompact, isMedium: isMedium),
            
            // Scores list
            Expanded(
              child: ListView.builder(
                itemCount: _scores.length,
                itemBuilder: (context, index) {
                  final score = _scores[index];
                  final isSelected = _selectedScoreIndex == index;
                  final scoreId = score['id'] as int;
                  final isUnlocked = _unlockedScoreIds.contains(scoreId);
                  
                  return GestureDetector(
                    key: ValueKey(index),
                    onTap: () {
                      setState(() {
                        _selectedScoreIndex = isSelected ? null : index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isUnlocked ? Colors.orange : Colors.black, 
                          width: isUnlocked ? 1.5 : 0.5
                        ),
                        color: isSelected 
                            ? (_selectedLeague == League.monday ? Colors.green[200] : Colors.amber[200])
                            : isUnlocked 
                              ? Colors.orange[50]
                              : Colors.grey[50],
                      ),
                      child: _buildScoreRow(score, isUnlocked, isCompact: isCompact, isMedium: isMedium),
                    ),
                  );
                },
              ),
            ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreRow(Map<String, dynamic> score, bool isUnlocked, {bool isCompact = false, bool isMedium = false}) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isPhone = screenWidth <= 900;
    
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, Close Pin, SKATS, SKAT Winnings
      return Row(
        children: [
          _buildFlexDataCellWithIcon(score['name'] ?? '', isUnlocked, isCompact ? 22 : 24, isCompact: isCompact),
          _buildFlexDataCell(_formatDateToMMDDYY(score['date_played']), isCompact ? 14 : 14, isCompact: isCompact),
          _buildFlexDataCell(score['golf_course'] ?? '', isCompact ? 20 : 18, isCompact: isCompact),
          _buildFlexDataCell(isPhone ? _formatWinningsWithCents(score['close_pin_winnings']) : _formatWinningsSimple(score['close_pin_winnings']), isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
          _buildFlexDataCell('${score['skats_score'] ?? ''}', isCompact ? 10 : isMedium ? 10 : 9, isCompact: isCompact),
          _buildFlexDataCell(isPhone ? _formatWinningsWithCents(score['skat_winnings']) : _formatWinningsSimple(score['skat_winnings']), isCompact ? 18 : isMedium ? 18 : 20, isCompact: isCompact),
        ],
      );
    } else {
      // Wednesday League: Name, Date, Golf Course, HC, Gross, Close Pin, Single Winnings, Group Winnings
      return Row(
        children: [
          _buildFlexDataCellWithIcon(score['name'] ?? '', isUnlocked, isCompact ? 12 : 12, isCompact: isCompact),
          _buildFlexDataCell(_formatDateToMMDDYY(score['date_played']), isCompact ? 14 : 14, isCompact: isCompact),
          _buildFlexDataCell(score['golf_course'] ?? '', isCompact ? 18 : 18, isCompact: isCompact),
          _buildFlexDataCell('${score['handicap'] ?? 0}', isCompact ? 12 : 12, isCompact: isCompact),
          _buildFlexDataCell('${score['gross_score'] ?? ''}', isCompact ? 10 : 9, isCompact: isCompact),
          _buildFlexDataCell(_formatWinningsSimple(score['close_pin_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
          _buildFlexDataCell(_formatWinningsSimple(score['single_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
          _buildFlexDataCell(_formatWinningsSimple(score['group_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
        ],
      );
    }
  }

  Widget _buildAddScoreRow({bool isCompact = false, bool isMedium = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: _selectedLeague == League.monday ? Colors.green[100] : Colors.amber[100],
      ),
      child: _buildAddScoreRowContent(isCompact: isCompact, isMedium: isMedium),
    );
  }

  Widget _buildAddScoreRowContent({bool isCompact = false, bool isMedium = false}) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isPhone = screenWidth <= 900;
    
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, Close Pin, SKATS, SKAT Winnings
      return Row(
        children: [
          _buildFlexDataCell(_selectedPlayer ?? '', isCompact ? 22 : isMedium ? 22 : 24, isCompact: isCompact),
          _buildFlexDataCell(_getCurrentDateMMDDYY(), isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
          _buildFlexGolfCourseCell(isCompact: isCompact), // Golf Course - editable dropdown for Monday
          isPhone 
            ? _buildFlexEditableCellWithBorder(_closePinController, _closePinFocus, isCompact ? 16 : 15, TextInputType.number, isCompact: isCompact) // Close Pin - editable for phones
            : _buildFlexDataCell('\$0.00', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact), // Close pin winnings - static for tablets
          _buildFlexEditableCellWithBorder(_skatsController, _skatsFocus, isCompact ? 10 : isMedium ? 10 : 9, TextInputType.number, isCompact: isCompact),
          _buildFlexEditableCellWithBorder(_winningsController, _winningsFocus, isCompact ? 18 : isMedium ? 18 : 20, TextInputType.number, isCompact: isCompact), // SKAT Winnings
        ],
      );
    } else {
      // Wednesday League: Name, Date, Golf Course, HC, Gross, Close Pin, Single Winnings, Group Winnings
      return Row(
        children: [
          _buildFlexDataCell(_selectedPlayer ?? '', isCompact ? 12 : isMedium ? 12 : 12, isCompact: isCompact),
          _buildFlexDataCell(_getCurrentDateMMDDYY(), isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
          _buildFlexDataCell('The Hideout', isCompact ? 18 : isMedium ? 18 : 18, isCompact: isCompact), // Golf Course - always The Hideout for Wednesday
          _buildFlexEditableCellWithBorder(_handicapController, _handicapFocus, isCompact ? 12 : isMedium ? 12 : 12, TextInputType.number, isCompact: isCompact), // HC editable
          _buildFlexEditableCellWithBorder(_grossScoreController, _grossScoreFocus, isCompact ? 10 : isMedium ? 10 : 9, TextInputType.number, isCompact: isCompact), // Gross editable
          _buildFlexDataCell('\$0.00', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact), // Close pin winnings - always $0
          _buildFlexEditableCellWithBorder(_winningsController, _winningsFocus, isCompact ? 16 : isMedium ? 15 : 15, TextInputType.number, isCompact: isCompact), // Single Winnings
          _buildFlexDataCell('\$0.00', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact), // Group winnings - always $0
        ],
      );
    }
  }

  Widget _buildGolfCourseCell({bool isCompact = false}) {
    // Wednesday League always uses "The Hideout", Monday League has dropdown
    if (_selectedLeague == League.wednesday) {
      return _buildDataCell('The Hideout', isCompact ? 100 : 120, isCompact: isCompact);
    } else {
      return _buildGolfCourseDropdown(isCompact: isCompact);
    }
  }

  Widget _buildGolfCourseDropdown({bool isCompact = false}) {
    return Container(
      width: isCompact ? 100 : 120,
      height: isCompact ? 25 : 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGolfCourse,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          isDense: true,
        ),
        style: TextStyle(fontSize: isCompact ? 10 : 12, color: Colors.black),
        items: _golfCourses.map((course) {
          return DropdownMenuItem(
            value: course,
            child: Container(
              width: isCompact ? 80 : 100,
              alignment: Alignment.center,
              child: Text(
                course, 
                style: TextStyle(fontSize: isCompact ? 10 : 12),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGolfCourse = value!;
          });
        },
      ),
    );
  }

  Widget _buildEditableCell(TextEditingController controller, FocusNode focusNode, double width, TextInputType inputType) {
    return SizedBox(
      width: width,
      height: 30,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: inputType,
        inputFormatters: inputType == TextInputType.number ? [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ] : null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
        onFieldSubmitted: (_) {
          // Handle field submission focus changes if needed
        },
      ),
    );
  }

  Widget _buildEditableCellWithBorder(TextEditingController controller, FocusNode focusNode, double width, TextInputType inputType, {bool isCompact = false}) {
    List<TextInputFormatter>? formatters;
    String? prefixText;
    
    if (inputType == TextInputType.number) {
      if (controller == _grossScoreController || controller == _skatsController) {
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ];
      } else if (controller == _handicapController) {
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          LengthLimitingTextInputFormatter(5), // Allow decimal handicaps like 12.5
        ];
      } else if (controller == _winningsController) {
        // Currency formatting for winnings field
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
        ];
        prefixText = '\$';
      } else {
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
        ];
      }
    }
    
    return Container(
      width: width,
      height: isCompact ? 25 : 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Center(
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: inputType,
          inputFormatters: formatters,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            prefixText: prefixText,
            prefixStyle: TextStyle(fontSize: isCompact ? 10 : 12),
          ),
          style: TextStyle(fontSize: isCompact ? 10 : 12),
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          onFieldSubmitted: (_) {
            // Handle field submission focus changes if needed
          },
        ),
      ),
    );
  }

  Widget _buildHeaders({bool isCompact = false, bool isMedium = false}) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isPhone = screenWidth <= 900;
    
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, Close Pin, SKATS, SKAT Winnings
      return Column(
        children: [
          // First header line
          Row(
            children: [
              _buildFlexHeaderCell('Name', isCompact ? 22 : isMedium ? 22 : 24, isCompact: isCompact),
              _buildFlexHeaderCell('Date', isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
              _buildFlexHeaderCell('Golf Course', isCompact ? 20 : isMedium ? 18 : 18, isCompact: isCompact),
              _buildFlexHeaderCell(isPhone ? 'Close Pin\nWinnings' : 'Close Pin', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
              _buildFlexHeaderCell('SKATS', isCompact ? 10 : isMedium ? 10 : 9, isCompact: isCompact),
              _buildFlexHeaderCell('SKAT\nWinnings', isCompact ? 18 : isMedium ? 18 : 20, isCompact: isCompact),
            ],
          ),
        ],
      );
    } else {
      // Wednesday League: Name, Date, Golf Course, HC, Gross, Close Pin, Single Winnings, Group Winnings
      return Column(
        children: [
          // First header line
          Row(
            children: [
              _buildFlexHeaderCell('Name', isCompact ? 12 : isMedium ? 12 : 12, isCompact: isCompact),
              _buildFlexHeaderCell('Date', isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
              _buildFlexHeaderCell('Golf Course', isCompact ? 18 : isMedium ? 18 : 18, isCompact: isCompact),
              _buildFlexHeaderCell('HC', isCompact ? 12 : isMedium ? 12 : 12, isCompact: isCompact),
              _buildFlexHeaderCell('Gross', isCompact ? 10 : isMedium ? 10 : 9, isCompact: isCompact),
              _buildFlexHeaderCell(isPhone ? 'Close Pin\nWinnings' : 'Close Pin', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
              _buildFlexHeaderCell('Single\nWinnings', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
              _buildFlexHeaderCell('Group\nWinnings', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildFlexHeaderCell(String text, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 40 : 50, // Reduced height for compact mode
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: isCompact ? 10 : 12,
              height: 1.0, // Reduce line height to tighten spacing
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow text to wrap to 2 lines
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, {bool isCompact = false}) {
    return Container(
      width: width,
      height: isCompact ? 40 : 50, // Reduced height for compact mode
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isCompact ? 10 : 12),
          textAlign: TextAlign.center,
          maxLines: 2, // Allow text to wrap to 2 lines
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  Widget _buildFlexDataCell(String text, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontSize: isCompact ? 10 : 12),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool isCompact = false}) {
    return Container(
      width: width,
      height: isCompact ? 25 : 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: isCompact ? 10 : 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFlexDataCellWithIcon(String text, bool isUnlocked, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: isCompact ? 15 : 20,
              child: Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                size: isCompact ? 10 : 12,
                color: isUnlocked ? Colors.orange : Colors.grey[600],
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: isCompact ? 10 : 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCellWithIcon(String text, bool isUnlocked, double width, {bool isCompact = false}) {
    return Container(
      width: width,
      height: isCompact ? 25 : 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 15 : 20,
            child: Icon(
              isUnlocked ? Icons.lock_open : Icons.lock,
              size: isCompact ? 10 : 12,
              color: isUnlocked ? Colors.orange : Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: isCompact ? 10 : 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexGolfCourseCell({bool isCompact = false}) {
    // Wednesday League always uses "The Hideout", Monday League has dropdown
    if (_selectedLeague == League.wednesday) {
      return _buildFlexDataCell('The Hideout', isCompact ? 18 : 18, isCompact: isCompact);
    } else {
      return _buildFlexGolfCourseDropdown(isCompact: isCompact);
    }
  }

  Widget _buildFlexGolfCourseDropdown({bool isCompact = false}) {
    return Expanded(
      flex: isCompact ? 20 : 18,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedGolfCourse,
          isExpanded: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            isDense: true,
          ),
          style: TextStyle(fontSize: isCompact ? 10 : 12, color: Colors.black),
          items: _golfCourses.map((course) {
            return DropdownMenuItem(
              value: course,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  course, 
                  style: TextStyle(fontSize: isCompact ? 10 : 12),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGolfCourse = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFlexEditableCellWithBorder(TextEditingController controller, FocusNode focusNode, int flex, TextInputType inputType, {bool isCompact = false}) {
    List<TextInputFormatter>? formatters;
    String? prefixText;
    final screenWidth = MediaQuery.of(context).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    if (inputType == TextInputType.number) {
      if (controller == _grossScoreController || controller == _skatsController) {
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ];
      } else if (controller == _handicapController) {
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          LengthLimitingTextInputFormatter(5), // Allow decimal handicaps like 12.5
        ];
      } else if (controller == _winningsController || controller == _closePinController) {
        // Currency formatting for winnings fields
        if (is6InchPhoneLandscape) {
          // Allow decimal input for 6" landscape mode (e.g., 5.00, 10.50)
          formatters = [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            LengthLimitingTextInputFormatter(6), // Allow up to 999.99
          ];
        } else {
          // Digits only for other screen sizes
          formatters = [
            FilteringTextInputFormatter.digitsOnly,
          ];
        }
        prefixText = '\$';
      } else {
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
        ];
      }
    }
    
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: inputType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              prefixText: prefixText,
              prefixStyle: TextStyle(fontSize: isCompact ? 10 : 12),
            ),
            style: TextStyle(fontSize: isCompact ? 10 : 12),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            onFieldSubmitted: (_) {
              // Handle field submission focus changes if needed
            },
          ),
        ),
      ),
    );
  }

  String _formatWinningsSimple(dynamic winnings) {
    // Simple formatting like Gross Score - just display the value as-is
    // No conditional logic - just show what's in the database
    if (winnings == null || winnings == 0) {
      return '\$0';
    }
    
    // Convert to whole dollar amount (no cents)
    int amount = winnings is int ? winnings : (winnings as double).round();
    return '\$${amount}';
  }

  String _formatWinningsWithCents(dynamic winnings) {
    // Format with cents for 6" phone landscape mode
    if (winnings == null || winnings == 0) {
      return '\$0.00';
    }
    
    // Convert to dollar amount with cents
    double amount = winnings is int ? winnings.toDouble() : (winnings as double);
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatDateToMMDDYY(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      // Parse the date string (expecting YYYY-MM-DD format)
      DateTime date = DateTime.parse(dateString);
      
      // Format as MM/DD/YY
      String month = date.month.toString().padLeft(2, '0');
      String day = date.day.toString().padLeft(2, '0');
      String year = (date.year % 100).toString().padLeft(2, '0');
      
      return '$month/$day/$year';
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }

  String _getCurrentDateMMDDYY() {
    DateTime now = DateTime.now();
    String month = now.month.toString().padLeft(2, '0');
    String day = now.day.toString().padLeft(2, '0');
    String year = (now.year % 100).toString().padLeft(2, '0');
    
    return '$month/$day/$year';
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    if (is6InchPhoneLandscape) {
      return _buildCompactActionButtons();
    } else {
      return _buildStandardActionButtons();
    }
  }

  Widget _buildStandardActionButtons() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Add Score'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _selectedScoreIndex != null ? _editScore : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Edit Score'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _selectedScoreIndex != null ? () => _deleteScore(_scores[_selectedScoreIndex!]) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Delete Score'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _clearSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Clear'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _clearAllScoreData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All Data'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Return button
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[300],
              foregroundColor: Colors.black,
            ),
            child: const Text('Return to Main Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // First row: 3 buttons
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _addScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _selectedScoreIndex != null ? _editScore : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _selectedScoreIndex != null ? () => _deleteScore(_scores[_selectedScoreIndex!]) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Delete', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 3),
          
          // Second row: 3 buttons
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _clearSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Clear', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: _clearAllScoreData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Clear All', style: TextStyle(fontSize: 9)),
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
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Return', style: TextStyle(fontSize: 9)),
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Define device categories
    final isPhone = screenWidth <= 900;  // 6.5" phones
    final isSmallTablet = screenWidth > 900 && screenWidth <= 1200;  // 8" tablets
    final isLargeTablet = screenWidth > 1200;  // 10" tablets
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Scores - ${_getLeagueDisplayName()} League'),
        backgroundColor: _selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          color: Colors.grey[100],
          padding: EdgeInsets.all(isPhone ? 10 : isSmallTablet ? 15 : 20),
          child: isPhone
            ? _buildPhoneLayout()
            : isSmallTablet
              ? _buildTabletLayout()
              : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    // Phone landscape - use 2-column compact layout
    return _buildTabletStyleLayout();
  }

  Widget _buildTabletLayout() {
    // 8" tablet - use enhanced tablet layout with better spacing
    return _buildTabletStyleLayoutMedium();
  }

  Widget _buildTabletStyleLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final footerHeight = 40.0; // Single row footer height
        final mainContentHeight = constraints.maxHeight - footerHeight - 5; // Content height minus footer and spacing
        
        return Column(
          children: [
            // Main content area - 2 columns
            SizedBox(
              height: mainContentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Player list (20% of width)
                  Expanded(
                    flex: 20,
                    child: Container(
                      height: mainContentHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // Player list header
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border(bottom: BorderSide(color: Colors.grey)),
                            ),
                            child: const Text(
                              'Players',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          // Player list content
                          Expanded(
                            child: _buildPlayerList(isCompact: true, hideHeader: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // Right column - Scores Table (80% of width)
                  Expanded(
                    flex: 80,
                    child: Container(
                      height: mainContentHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildScoresTable(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 2),
            
            // Button footer at bottom
            SizedBox(
              height: footerHeight,
              child: _buildButtonFooterLandscape(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabletStyleLayoutMedium() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final footerHeight = 45.0; // Slightly larger footer for 8" tablets
        final mainContentHeight = constraints.maxHeight - footerHeight - 8; // More spacing
        
        return Column(
          children: [
            // Main content area - 2 columns
            SizedBox(
              height: mainContentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Player list (18% of width for better balance)
                  Expanded(
                    flex: 18,
                    child: Container(
                      height: mainContentHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          // Player list header
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border(bottom: BorderSide(color: Colors.grey)),
                            ),
                            child: const Text(
                              'Players',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          // Player list content
                          Expanded(
                            child: _buildPlayerList(isCompact: false, hideHeader: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Right column - Scores Table (82% of width)
                  Expanded(
                    flex: 82,
                    child: Container(
                      height: mainContentHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _buildScoresTable(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 5),
            
            // Button footer at bottom
            SizedBox(
              height: footerHeight,
              child: _buildButtonFooterTablet(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonFooterLandscape() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: _addScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: _selectedScoreIndex != null ? () => _deleteScore(_scores[_selectedScoreIndex!]) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: _clearSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: _clearAllScoreData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Clear All', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Return', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonFooterTablet() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: _addScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Add Score', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: _selectedScoreIndex != null ? _editScore : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: _selectedScoreIndex != null ? () => _deleteScore(_scores[_selectedScoreIndex!]) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: _clearSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: _clearAllScoreData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Clear All', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Return', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCompactButton('Add', Colors.lightGreen, _addScore),
            const SizedBox(width: 4),
            _buildCompactButton('Edit', Colors.lightBlue, _selectedScoreIndex != null ? _editScore : null),
            const SizedBox(width: 4),
            _buildCompactButton('Delete', Colors.red[300]!, _selectedScoreIndex != null ? () => _deleteScore(_scores[_selectedScoreIndex!]) : null),
            const SizedBox(width: 4),
            _buildCompactButton('Clear', Colors.amber[300]!, _clearSelection),
            const SizedBox(width: 4),
            _buildCompactButton('Clear All', Colors.red[600]!, _clearAllScoreData),
            const SizedBox(width: 4),
            _buildCompactButton('Return', Colors.red[300]!, () => Navigator.of(context).popUntil((route) => route.isFirst)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactButton(String text, Color color, VoidCallback? onPressed) {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: text == 'Clear All' ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Text(text, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Title
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Player Scores',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Main content
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left sidebar - Player list (15%)
              _buildPlayerList(),
              
              const SizedBox(width: 20),
              
              // Right side - Scores table (85%)
              _buildScoresTable(),
            ],
          ),
        ),
        
        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleHeight = 30.0;
        final playerListHeight = constraints.maxHeight * 0.22; // Reduced from 0.25
        final buttonHeight = 75.0; // Reduced from 80.0
        final spacing = 25.0; // Total spacing (3 gaps of ~8px each)
        final remainingHeight = constraints.maxHeight - titleHeight - playerListHeight - buttonHeight - spacing;
        
        return Column(
          children: [
            // Compact title
            SizedBox(
              height: titleHeight,
              child: const Center(
                child: Text(
                  'Player Scores',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Reduced font size
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Player list - compact at top
            SizedBox(
              height: playerListHeight,
              child: _buildPlayerList(isCompact: true),
            ),
            
            const SizedBox(height: 8),
            
            // Scores table - main content (using Expanded to take remaining space)
            Expanded(
              child: _buildScoresTable(),
            ),
            
            const SizedBox(height: 8),
            
            // Compact action buttons at bottom
            SizedBox(
              height: buttonHeight,
              child: _buildActionButtons(),
            ),
          ],
        );
      },
    );
  }

  void _clearAllScoreData() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Score Data'),
        content: const Text('This will permanently delete ALL scores, games, and winnings data for ALL players. This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseHelper.clearAllScoreData();
        setState(() {
          _scores = [];
          _selectedScoreIndex = null;
          _selectedPlayer = null;
        });
        _showSuccessDialog('All score data has been cleared from the database');
      } catch (e) {
        _showErrorDialog('Error clearing data: $e');
      }
    }
  }

}