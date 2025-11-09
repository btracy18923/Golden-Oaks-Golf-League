import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../models/league.dart';

class PlayerScoresScreen extends StatefulWidget {
  final League? league;
  
  const PlayerScoresScreen({super.key, this.league});

  @override
  State<PlayerScoresScreen> createState() => _PlayerScoresScreenState();
}

class _PlayerScoresScreenState extends State<PlayerScoresScreen> {
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
  final TextEditingController _skatNumberController = TextEditingController();
  final FocusNode _grossScoreFocus = FocusNode();
  final FocusNode _skatsFocus = FocusNode();
  final FocusNode _winningsFocus = FocusNode();
  final FocusNode _handicapFocus = FocusNode();
  final FocusNode _skatNumberFocus = FocusNode();
  
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
  }

  @override
  void dispose() {
    _grossScoreController.dispose();
    _skatsController.dispose();
    _winningsController.dispose();
    _handicapController.dispose();
    _skatNumberController.dispose();
    _grossScoreFocus.dispose();
    _skatsFocus.dispose();
    _winningsFocus.dispose();
    _handicapFocus.dispose();
    _skatNumberFocus.dispose();
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
      setState(() {
        _showAddScoreRow = true;
        // Pre-populate fields with player data
        _handicapController.text = (player['handicap'] ?? 0.0).toString();
        _skatNumberController.text = (player['skat_number'] ?? 0).toString();
        _winningsController.text = '0'; // Prefill winnings field with $0
      });
      return;
    }
    
    // Check for required fields
    List<String> missingFields = [];
    
    // Check gross score
    if (_grossScoreController.text.trim().isEmpty) {
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
    
    final grossScore = int.tryParse(_grossScoreController.text.trim());
    if (grossScore == null || grossScore < 10 || grossScore > 99) {
      _showErrorDialog('Gross score must be between 10 and 99');
      return;
    }
    
    double winningsAmount = 0.0;
    if (_winningsController.text.trim().isNotEmpty) {
      winningsAmount = double.tryParse(_winningsController.text.trim()) ?? 0.0;
    }
    
    // Get handicap from editable field
    double handicap = 0.0;
    if (_handicapController.text.trim().isNotEmpty) {
      handicap = double.tryParse(_handicapController.text.trim()) ?? 0.0;
    }
    
    // Get SKAT number from editable field (for Monday league)
    int skatNumber = 0;
    if (_selectedLeague == League.monday && _skatNumberController.text.trim().isNotEmpty) {
      skatNumber = int.tryParse(_skatNumberController.text.trim()) ?? 0;
    }
    
    try {
      final playerId = _players.firstWhere((p) => p['last'] == _selectedPlayer)['id'];
      final player = _players.firstWhere((p) => p['last'] == _selectedPlayer);
      final playerName = '${player['first']} ${player['last']}';
      
      Map<String, dynamic> scoreData = {
        'player_id': playerId,
        'name': player['last'], // Use only Last Name
        'date_played': DateTime.now().toIso8601String().split('T')[0],
        'handicap': handicap, // Use value from editable field
        'gross_score': grossScore,
        'close_pin_winnings': 0.0, // Always $0 for now
      };
      
      if (_selectedLeague == League.monday) {
        // Monday League: Name, Date, Golf Course, HC, SKAT#, Gross, SKATS, Close Pin, SKAT Winnings
        scoreData['golf_course'] = _selectedGolfCourse; // Use selected golf course
        scoreData['skat_number'] = skatNumber; // Use value from editable field
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
      _skatNumberController.clear();
      
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
      _skatNumberController.clear();
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
                  final grossScore = int.tryParse(grossController.text);
                  final winnings = double.tryParse(winningsController.text) ?? 0.0;
                  
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
                  
                  // Prepare update data based on league
                  Map<String, dynamic> updateData = {
                    'gross_score': grossScore,
                  };
                  
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
      _skatNumberController.clear();
    });
    _loadPlayers();
  }

  Widget _buildPlayerList() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: const Text(
              'Players',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                final playerName = '${player['first']} ${player['last']}';
                final isSelected = _selectedPlayer == player['last'];
                
                return GestureDetector(
                  onTap: () => _selectPlayer(player['last']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (_selectedLeague == League.monday ? Colors.green[200] : Colors.amber[200])
                          : Colors.transparent,
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Text(
                      playerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresTable() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _selectedLeague == League.monday ? 990 : 870, // Adjust width based on league columns
          child: Column(
            children: [
              // Two-line header
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.grey[200],
                ),
                child: _buildHeaders(),
              ),
              
              // Add new score row (if player selected and add score button clicked)
              if (_selectedPlayer != null && _showAddScoreRow) _buildAddScoreRow(),
              
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
                        child: _buildScoreRow(score, isUnlocked),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(Map<String, dynamic> score, bool isUnlocked) {
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, HC, SKAT#, Gross, SKATS, Close Pin, SKAT Winnings
      return Row(
        children: [
          _buildDataCellWithIcon(score['name'] ?? '', isUnlocked, 80),
          _buildDataCell(_formatDateToMMDDYY(score['date_played']), 90),
          _buildDataCell(score['golf_course'] ?? '', 120),
          _buildDataCell('${score['handicap'] ?? 0}', 80),
          _buildDataCell('${score['skat_number'] ?? ''}', 100),
          _buildDataCell('${score['gross_score'] ?? ''}', 60),
          _buildDataCell('${score['skats_score'] ?? ''}', 60),
          _buildDataCell(_formatWinningsSimple(score['close_pin_winnings']), 100),
          _buildDataCell(_formatWinningsSimple(score['skat_winnings']), 110),
        ],
      );
    } else {
      // Wednesday League: Name, Date, Golf Course, HC, Gross, Close Pin, Single Winnings, Group Winnings
      return Row(
        children: [
          _buildDataCellWithIcon(score['name'] ?? '', isUnlocked, 80),
          _buildDataCell(_formatDateToMMDDYY(score['date_played']), 90),
          _buildDataCell(score['golf_course'] ?? '', 120),
          _buildDataCell('${score['handicap'] ?? 0}', 80),
          _buildDataCell('${score['gross_score'] ?? ''}', 60),
          _buildDataCell(_formatWinningsSimple(score['close_pin_winnings']), 100),
          _buildDataCell(_formatWinningsSimple(score['single_winnings']), 100),
          _buildDataCell(_formatWinningsSimple(score['group_winnings']), 100),
        ],
      );
    }
  }

  Widget _buildAddScoreRow() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: _selectedLeague == League.monday ? Colors.green[100] : Colors.amber[100],
      ),
      child: _buildAddScoreRowContent(),
    );
  }

  Widget _buildAddScoreRowContent() {
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, HC, SKAT#, Gross, SKATS, Close Pin, SKAT Winnings
      return Row(
        children: [
          _buildDataCell(_selectedPlayer ?? '', 80),
          _buildDataCell(_getCurrentDateMMDDYY(), 90),
          _buildGolfCourseCell(), // Golf Course - editable dropdown for Monday
          _buildEditableCellWithBorder(_handicapController, _handicapFocus, 80, TextInputType.number), // HC editable
          _buildEditableCellWithBorder(_skatNumberController, _skatNumberFocus, 100, TextInputType.number), // SKAT# editable
          _buildEditableCellWithBorder(_grossScoreController, _grossScoreFocus, 60, TextInputType.number),
          _buildEditableCellWithBorder(_skatsController, _skatsFocus, 60, TextInputType.number),
          _buildDataCell('\$0.00', 100), // Close pin winnings - always $0
          _buildEditableCellWithBorder(_winningsController, _winningsFocus, 110, TextInputType.number), // SKAT Winnings
        ],
      );
    } else {
      // Wednesday League: Name, Date, Golf Course, HC, Gross, Close Pin, Single Winnings, Group Winnings
      return Row(
        children: [
          _buildDataCell(_selectedPlayer ?? '', 80),
          _buildDataCell(_getCurrentDateMMDDYY(), 90),
          _buildDataCell('The Hideout', 120), // Golf Course - always The Hideout for Wednesday
          _buildEditableCellWithBorder(_handicapController, _handicapFocus, 80, TextInputType.number), // HC editable
          _buildEditableCellWithBorder(_grossScoreController, _grossScoreFocus, 60, TextInputType.number),
          _buildDataCell('\$0.00', 100), // Close pin winnings - always $0
          _buildEditableCellWithBorder(_winningsController, _winningsFocus, 100, TextInputType.number), // Single Winnings
          _buildDataCell('\$0.00', 100), // Group winnings - always $0
        ],
      );
    }
  }

  Widget _buildGolfCourseCell() {
    // Wednesday League always uses "The Hideout", Monday League has dropdown
    if (_selectedLeague == League.wednesday) {
      return _buildDataCell('The Hideout', 120);
    } else {
      return _buildGolfCourseDropdown();
    }
  }

  Widget _buildGolfCourseDropdown() {
    return Container(
      width: 120,
      height: 30,
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
        style: const TextStyle(fontSize: 12, color: Colors.black),
        items: _golfCourses.map((course) {
          return DropdownMenuItem(
            value: course,
            child: Container(
              width: 100,
              alignment: Alignment.center,
              child: Text(
                course, 
                style: const TextStyle(fontSize: 12),
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
          if (focusNode == _grossScoreFocus && controller.text.length == 2) {
            FocusScope.of(context).requestFocus(_skatsFocus);
          }
        },
      ),
    );
  }

  Widget _buildEditableCellWithBorder(TextEditingController controller, FocusNode focusNode, double width, TextInputType inputType) {
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
      height: 30,
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
            prefixStyle: const TextStyle(fontSize: 12),
          ),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          onFieldSubmitted: (_) {
            if (focusNode == _grossScoreFocus && controller.text.length == 2) {
              FocusScope.of(context).requestFocus(_skatsFocus);
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeaders() {
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, HC, SKAT#, Gross, SKATS, Close Pin, SKAT Winnings
      return Column(
        children: [
          // First header line
          Row(
            children: [
              _buildHeaderCell('Name', 80),
              _buildHeaderCell('Date', 90),
              _buildHeaderCell('Golf Course', 120),
              _buildHeaderCell('HC', 80),
              _buildHeaderCell('SKAT#', 100),
              _buildHeaderCell('Gross', 60),
              _buildHeaderCell('SKATS', 60),
              _buildHeaderCell('Close Pin', 100),
              _buildHeaderCell('SKAT\nWinnings', 110),
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
              _buildHeaderCell('Name', 80),
              _buildHeaderCell('Date', 90),
              _buildHeaderCell('Golf Course', 120),
              _buildHeaderCell('HC', 80),
              _buildHeaderCell('Gross', 60),
              _buildHeaderCell('Close Pin', 100),
              _buildHeaderCell('Single\nWinnings', 100),
              _buildHeaderCell('Group\nWinnings', 100),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: 50, // Increased height to accommodate multi-word titles
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
          maxLines: 2, // Allow text to wrap to 2 lines
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return Container(
      width: width,
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataCellWithIcon(String text, bool isUnlocked, double width) {
    return Container(
      width: width,
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            child: Icon(
              isUnlocked ? Icons.lock_open : Icons.lock,
              size: 12,
              color: isUnlocked ? Colors.orange : Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Scores - ${_getLeagueDisplayName()} League'),
        backgroundColor: _selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
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
        ),
      ),
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