import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/firebase_upload_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/device_detection_service.dart';

class WednesdayPlayerScoresScreen extends StatefulWidget {
  final League? league;

  const WednesdayPlayerScoresScreen({super.key, this.league});

  @override
  State<WednesdayPlayerScoresScreen> createState() => _WednesdayPlayerScoresScreenState();
}

class _WednesdayPlayerScoresScreenState extends State<WednesdayPlayerScoresScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  League _selectedLeague = League.wednesday;
  String? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _scores = [];
  int? _selectedScoreIndex;
  bool _isEditing = false;
  bool _showAddScoreRow = false;
  Set<int> _unlockedScoreIds = {};

  // Controllers for adding new scores
  final TextEditingController _grossScoreController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();
  final TextEditingController _indWinningsController = TextEditingController();
  final TextEditingController _groupWinningsController = TextEditingController();
  final TextEditingController _closePinController = TextEditingController();
  final FocusNode _grossScoreFocus = FocusNode();
  final FocusNode _handicapFocus = FocusNode();
  final FocusNode _indWinningsFocus = FocusNode();
  final FocusNode _groupWinningsFocus = FocusNode();
  final FocusNode _closePinFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedLeague = widget.league ?? League.wednesday;
    _loadPlayers();

    // Force landscape orientation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOrientation();
    });
  }

  void _setOrientation() {
    if (DeviceDetectionService.is6Point5Phone(context)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
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
    _grossScoreController.dispose();
    _handicapController.dispose();
    _indWinningsController.dispose();
    _groupWinningsController.dispose();
    _closePinController.dispose();
    _grossScoreFocus.dispose();
    _handicapFocus.dispose();
    _indWinningsFocus.dispose();
    _groupWinningsFocus.dispose();
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
        _players.firstWhere((p) => p['last'] == playerLast)['player_number'],
        _selectedLeague
      );
      setState(() {
        _scores = scores;
        _selectedScoreIndex = null;
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

    if (!_showAddScoreRow) {
      final player = _players.firstWhere((p) => p['last'] == _selectedPlayer);
      final is6InchPhoneLandscape = DeviceDetectionService.is6Point5Phone(context);

      setState(() {
        _showAddScoreRow = true;
        _handicapController.text = (player['handicap'] ?? 0.0).toString();
        _indWinningsController.text = is6InchPhoneLandscape ? '0.00' : '0';
        _groupWinningsController.text = is6InchPhoneLandscape ? '0.00' : '0';
        _closePinController.text = is6InchPhoneLandscape ? '0.00' : '0';
      });
      return;
    }

    // Validate required fields
    List<String> missingFields = [];

    if (_grossScoreController.text.trim().isEmpty) {
      missingFields.add('Gross Score');
    }

    if (_indWinningsController.text.trim().isEmpty) {
      missingFields.add('IND Winnings');
    }

    if (missingFields.isNotEmpty) {
      String errorMessage = 'Please enter: ${missingFields.join(', ')}';
      _showErrorDialog(errorMessage);
      return;
    }

    // Check for duplicate date
    final playerId = _players.firstWhere((p) => p['last'] == _selectedPlayer)['player_number'];
    final currentDate = DateTime.now().toIso8601String().split('T')[0];

    try {
      final existingScoreForDate = await _databaseHelper.getPlayerScoreByDate(playerId, currentDate, _selectedLeague);
      if (existingScoreForDate != null) {
        final formattedDate = _formatDateToMMDDYY(currentDate);
        _showErrorDialog('A score for $_selectedPlayer on $formattedDate already exists.\\n\\nOnly one score per player per day is allowed.');
        return;
      }
    } catch (e) {
      _showErrorDialog('Error checking for duplicate date: $e');
      return;
    }

    // Validate gross score
    final grossScore = int.tryParse(_grossScoreController.text.trim());
    if (grossScore == null || grossScore < 10 || grossScore > 99) {
      _showErrorDialog('Gross score must be between 10 and 99');
      return;
    }

    double indWinningsAmount = 0.0;
    if (_indWinningsController.text.trim().isNotEmpty) {
      indWinningsAmount = double.tryParse(_indWinningsController.text.trim()) ?? 0.0;
    }

    double groupWinningsAmount = 0.0;
    if (_groupWinningsController.text.trim().isNotEmpty) {
      groupWinningsAmount = double.tryParse(_groupWinningsController.text.trim()) ?? 0.0;
    }

    double handicap = 0.0;
    if (_handicapController.text.trim().isNotEmpty) {
      handicap = double.tryParse(_handicapController.text.trim()) ?? 0.0;
    }

    double closePinWinnings = 0.0;
    if (_closePinController.text.trim().isNotEmpty) {
      closePinWinnings = double.tryParse(_closePinController.text.trim()) ?? 0.0;
    }

    try {
      final player = _players.firstWhere((p) => p['last'] == _selectedPlayer);
      final playerName = '${player['first']} ${player['last']}';

      Map<String, dynamic> scoreData = {
        'player_id': playerId,
        'name': player['last'],
        'date_played': DateTime.now().toIso8601String().split('T')[0],
        'golf_course': 'The Hideout',
        'handicap': handicap,
        'gross_score': grossScore,
        'close_pin_winnings': closePinWinnings,
        'single_winnings': indWinningsAmount,
        'group_winnings': groupWinningsAmount,
      };

      int scoreId = await _databaseHelper.insertScoreLeague(scoreData, _selectedLeague);

      // Clear input fields and hide add score row
      _grossScoreController.clear();
      _handicapController.clear();
      _indWinningsController.clear();
      _groupWinningsController.clear();
      _closePinController.clear();

      setState(() {
        _unlockedScoreIds.remove(scoreId);
        _showAddScoreRow = false;
      });

      _loadPlayerScores(_selectedPlayer!);
      _showSuccessDialog('Score added successfully!');
    } catch (e) {
      _showErrorDialog('Error adding score: $e');
    }
  }

  Future<void> _deleteScore(Map<String, dynamic> score) async {
    final scoreId = score['id'] as int;

    setState(() {
      _unlockedScoreIds.add(scoreId);
    });

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the score ${score['gross_score']} for $_selectedPlayer on ${score['date_played']}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
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
        final db = await _databaseHelper.database;
        await db.delete(
          'wednesday_scores',
          where: 'id = ?',
          whereArgs: [scoreId],
        );

        setState(() {
          _selectedScoreIndex = null;
          _unlockedScoreIds.remove(scoreId);
        });
        _loadPlayerScores(_selectedPlayer!);
        _showSuccessDialog('Score deleted successfully!');
      } catch (e) {
        setState(() {
          _unlockedScoreIds.remove(scoreId);
        });
        _showErrorDialog('Error deleting score: $e');
      }
    } else {
      setState(() {
        _unlockedScoreIds.remove(scoreId);
      });
    }
  }

  void _selectPlayer(String playerLast) {
    setState(() {
      _selectedPlayer = playerLast;
      _selectedScoreIndex = null;
      _showAddScoreRow = false;
      _unlockedScoreIds.clear();
    });
    _loadPlayerScores(playerLast);
  }

  void _clearSelection() {
    setState(() {
      _selectedPlayer = null;
      _selectedScoreIndex = null;
      _scores = [];
      _showAddScoreRow = false;
      _unlockedScoreIds.clear();
      _grossScoreController.clear();
      _handicapController.clear();
      _indWinningsController.clear();
      _groupWinningsController.clear();
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

    setState(() {
      _unlockedScoreIds.add(scoreId);
    });

    showDialog(
      context: context,
      builder: (context) {
        final grossController = TextEditingController(text: selectedScore['gross_score']?.toString() ?? '');
        final indWinningsController = TextEditingController(text: selectedScore['single_winnings']?.toString() ?? '0');
        final groupWinningsController = TextEditingController(text: selectedScore['group_winnings']?.toString() ?? '0');

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
              TextField(
                controller: indWinningsController,
                decoration: const InputDecoration(labelText: 'IND Winnings'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              TextField(
                controller: groupWinningsController,
                decoration: const InputDecoration(labelText: 'Group Winnings'),
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
                  if (grossScore == null || grossScore < 10 || grossScore > 99) {
                    Navigator.of(context).pop();
                    setState(() {
                      _unlockedScoreIds.remove(scoreId);
                    });
                    _showErrorDialog('Gross score must be between 10 and 99');
                    return;
                  }

                  final indWinnings = double.tryParse(indWinningsController.text) ?? 0.0;
                  final groupWinnings = double.tryParse(groupWinningsController.text) ?? 0.0;

                  Map<String, dynamic> updateData = {
                    'gross_score': grossScore,
                    'single_winnings': indWinnings,
                    'group_winnings': groupWinnings,
                  };

                  final db = await _databaseHelper.database;
                  await db.update(
                    'wednesday_scores',
                    updateData,
                    where: 'id = ?',
                    whereArgs: [scoreId],
                  );

                  Navigator.of(context).pop();
                  setState(() {
                    _selectedScoreIndex = null;
                    _unlockedScoreIds.remove(scoreId);
                  });
                  _loadPlayerScores(_selectedPlayer!);
                  _showSuccessDialog('Score updated successfully!');
                } catch (e) {
                  Navigator.of(context).pop();
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

  Widget _buildPlayerList({bool isCompact = false, bool hideHeader = false}) {
    double listWidth = isCompact ? double.infinity : 200;
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
              color: isSelected ? Colors.orange[200] : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              playerName,
              style: ResponsiveTypography.smallStyle(context,
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
              style: ResponsiveTypography.labelStyle(context, fontWeight: FontWeight.bold),
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
    final isPhone = DeviceDetectionService.is6Point5Phone(context);
    final isSmallTablet = DeviceDetectionService.is8Tablet(context);
    final isLargeTablet = DeviceDetectionService.is10Tablet(context);

    double tableWidth;
    if (isPhone) {
      tableWidth = 550;
    } else if (isSmallTablet) {
      tableWidth = 700;
    } else {
      tableWidth = 870;
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
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.grey[200],
                  ),
                  child: _buildHeaders(isCompact: isCompact, isMedium: isMedium),
                ),

                if (_selectedPlayer != null && _showAddScoreRow) _buildAddScoreRow(isCompact: isCompact, isMedium: isMedium),

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
                                ? Colors.orange[200]
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
    final isPhone = DeviceDetectionService.is6Point5Phone(context);

    return Row(
      children: [
        _buildFlexDataCellWithIcon(score['name'] ?? '', isUnlocked, isCompact ? 12 : 12, isCompact: isCompact),
        _buildFlexDataCell(_formatDateToMMDDYY(score['date_played']), isCompact ? 14 : 14, isCompact: isCompact),
        _buildFlexDataCell('${score['handicap'] ?? 0}', isCompact ? 12 : 12, isCompact: isCompact),
        _buildFlexDataCell('${score['gross_score'] ?? ''}', isCompact ? 10 : 9, isCompact: isCompact),
        _buildFlexDataCell(_formatWinningsSimple(score['close_pin_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
        _buildFlexDataCell(_formatWinningsSimple(score['single_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
        _buildFlexDataCell(_formatWinningsSimple(score['group_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
      ],
    );
  }

  Widget _buildAddScoreRow({bool isCompact = false, bool isMedium = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: Colors.orange[100],
      ),
      child: _buildAddScoreRowContent(isCompact: isCompact, isMedium: isMedium),
    );
  }

  Widget _buildAddScoreRowContent({bool isCompact = false, bool isMedium = false}) {
    final isPhone = DeviceDetectionService.is6Point5Phone(context);

    return Row(
      children: [
        _buildFlexDataCell(_selectedPlayer ?? '', isCompact ? 12 : isMedium ? 12 : 12, isCompact: isCompact),
        _buildFlexDataCell(_getCurrentDateMMDDYY(), isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
        _buildFlexEditableCellWithBorder(_handicapController, _handicapFocus, isCompact ? 12 : isMedium ? 12 : 12, TextInputType.number, isCompact: isCompact),
        _buildFlexEditableCellWithBorder(_grossScoreController, _grossScoreFocus, isCompact ? 10 : isMedium ? 10 : 9, TextInputType.number, isCompact: isCompact),
        _buildFlexDataCell('\$0.00', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
        _buildFlexEditableCellWithBorder(_indWinningsController, _indWinningsFocus, isCompact ? 16 : isMedium ? 15 : 15, TextInputType.number, isCompact: isCompact),
        _buildFlexDataCell('\$0.00', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
      ],
    );
  }

  Widget _buildHeaders({bool isCompact = false, bool isMedium = false}) {
    final isPhone = DeviceDetectionService.is6Point5Phone(context);

    return Column(
      children: [
        Row(
          children: [
            _buildFlexHeaderCell('Name', isCompact ? 12 : isMedium ? 12 : 12, isCompact: isCompact),
            _buildFlexHeaderCell('Date', isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
            _buildFlexHeaderCell('HC', isCompact ? 12 : isMedium ? 12 : 12, isCompact: isCompact),
            _buildFlexHeaderCell('Gross', isCompact ? 10 : isMedium ? 10 : 9, isCompact: isCompact),
            _buildFlexHeaderCell(isPhone ? 'Close Pin\nWinnings' : 'Close Pin', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
            _buildFlexHeaderCell('IND\nWinnings', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
            _buildFlexHeaderCell('Group\nWinnings', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
          ],
        ),
      ],
    );
  }

  Widget _buildFlexHeaderCell(String text, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 40 : 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: ResponsiveTypography.smallStyle(context,
              fontWeight: FontWeight.bold,
            ).copyWith(height: 1.0),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
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
        child: Align(
          alignment: Alignment.center,
          child: Text(
            text,
            style: ResponsiveTypography.smallStyle(context),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
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
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: ResponsiveTypography.smallStyle(context),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlexEditableCellWithBorder(TextEditingController controller, FocusNode focusNode, int flex, TextInputType inputType, {bool isCompact = false}) {
    List<TextInputFormatter>? formatters;
    String? prefixText;
    final is6InchPhoneLandscape = DeviceDetectionService.is6Point5Phone(context);

    if (inputType == TextInputType.number) {
      if (controller == _grossScoreController) {
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ];
      } else if (controller == _handicapController) {
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'^\\d*\\.?\\d*')),
          LengthLimitingTextInputFormatter(5),
        ];
      } else if (controller == _indWinningsController || controller == _groupWinningsController || controller == _closePinController) {
        if (is6InchPhoneLandscape) {
          formatters = [
            FilteringTextInputFormatter.allow(RegExp(r'^\\d*\\.?\\d{0,2}')),
            LengthLimitingTextInputFormatter(6),
          ];
        } else {
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
            prefixStyle: ResponsiveTypography.smallStyle(context),
          ),
          style: ResponsiveTypography.smallStyle(context),
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          onFieldSubmitted: (_) {},
        ),
      ),
    );
  }

  String _formatWinningsSimple(dynamic winnings) {
    if (winnings == null || winnings == 0) {
      return '\$0';
    }
    int amount = winnings is int ? winnings : (winnings as double).round();
    return '\$$amount';
  }

  String _formatDateToMMDDYY(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      DateTime date = DateTime.parse(dateString);
      String month = date.month.toString().padLeft(2, '0');
      String day = date.day.toString().padLeft(2, '0');
      String year = (date.year % 100).toString().padLeft(2, '0');
      return '$month/$day/$year';
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    if (DeviceDetectionService.is6Point5Phone(context)) {
      return _buildPhoneLayout();
    } else if (DeviceDetectionService.is8Tablet(context)) {
      return _buildTablet8Layout();
    } else {
      return _buildTablet10Layout();
    }
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Scores - ${_getLeagueDisplayName()} League- ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.appBarTitleStyle(context, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(10),
              child: SafeArea(
                child: _buildTabletStyleLayout(),
              ),
            ),
          ),
          _buildPhoneButtonBar(),
        ],
      ),
    );
  }

  Widget _buildTablet8Layout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Scores - ${_getLeagueDisplayName()} League- ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.appBarTitleStyle(context, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: false,
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(15),
        child: SafeArea(
          child: _buildTabletStyleLayoutMedium(),
        ),
      ),
    );
  }

  Widget _buildTablet10Layout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Scores - ${_getLeagueDisplayName()} League- ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.appBarTitleStyle(context, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: _buildDesktopLayout(),
              ),
            ),
          ),
          _buildPhoneButtonBar(),
        ],
      ),
    );
  }

  Widget _buildTabletStyleLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mainContentHeight = constraints.maxHeight;

        return Column(
          children: [
            SizedBox(
              height: mainContentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: const Border(bottom: BorderSide(color: Colors.grey)),
                            ),
                            child: Text(
                              'Players',
                              style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: _buildPlayerList(isCompact: true, hideHeader: true),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

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
          ],
        );
      },
    );
  }

  Widget _buildTabletStyleLayoutMedium() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mainContentHeight = constraints.maxHeight;

        return Column(
          children: [
            SizedBox(
              height: mainContentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: const Border(bottom: BorderSide(color: Colors.grey)),
                            ),
                            child: Text(
                              'Players',
                              style: ResponsiveTypography.labelStyle(context, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: _buildPlayerList(isCompact: false, hideHeader: true),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

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
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Player Scores',
            style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerList(),

              const SizedBox(width: 20),

              Expanded(
                child: _buildScoresTable(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneButtonBar() {
    return Container(
      width: double.infinity,
      height: 60.0,
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
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.center,
              ),
              child: Text('◄---- Back', style: TextStyle(fontSize: ResponsiveTypography.getButton(context), fontWeight: FontWeight.bold)),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
