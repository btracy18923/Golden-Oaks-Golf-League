import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/responsive_typography.dart';
import '../../services/device_detection_service.dart';
import '../../services/UI/button_bar_UI_service.dart';

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
  bool _showAddScoreRow = false; // Track whether to show the add score row
  final Set<int> _unlockedScoreIds = {}; // Track which score rows are unlocked for editing
  
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
    // Only force landscape for phones (6.5" and smaller)
    // Let tablets use natural orientation
    if (DeviceDetectionService.is6Point5Phone(context)) {
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
      final playerNumber = _players.firstWhere((p) => p['last'] == playerLast)['player_number'];
      final scores = await _databaseHelper.getPlayerScoresSimple(
        playerNumber,
        _selectedLeague
      );

      // Limit to 20 scores - if more than 20, delete the oldest ones
      if (scores.length > 20) {
        // Get the scores to delete (everything after the first 20)
        final scoresToDelete = scores.sublist(20);

        // Delete each excess score from the database
        for (var score in scoresToDelete) {
          await _databaseHelper.deleteScore(score['id']);
        }

        // Keep only the first 20 scores
        setState(() {
          _scores = scores.sublist(0, 20);
          _selectedScoreIndex = null; // Clear selection when loading new player scores
        });
      } else {
        setState(() {
          _scores = scores;
          _selectedScoreIndex = null; // Clear selection when loading new player scores
        });
      }
    } catch (e) {
      _showErrorDialog('Error loading scores: $e');
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
              color: isSelected 
                  ? (_selectedLeague == League.monday ? Colors.green[200] : Colors.amber[200])
                  : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              playerName,
              style: TextStyle(fontSize: ResponsiveTypography.getSmall(context) - 3,
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
              border: const Border(bottom: BorderSide(color: Colors.grey)),
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
    // Define device categories using DeviceDetectionService
    final isPhone = DeviceDetectionService.is6Point5Phone(context);  // 6.5" phones
    DeviceDetectionService.is10Tablet(context);  // 10" tablets

    // Adjust table width based on screen size and orientation
    double tableWidth;
    if (isPhone) {
      // Phone: Compact layout
      tableWidth = _selectedLeague == League.monday ? 510 : 550;
    } else {
      // 10" tablet: Full layout
      tableWidth = _selectedLeague == League.monday ? 810 : 870;
    }

    final isCompact = isPhone;
    const isMedium = false;
    
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
    final isPhone = DeviceDetectionService.is6Point5Phone(context);
    
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, SKATS, Close Pin, SKAT Winnings
      return Row(
        children: [
          _buildFlexDataCellWithIcon(score['name'] ?? '', isUnlocked, isCompact ? 22 : 24, isCompact: isCompact),
          _buildFlexDataCell(_formatDateToMMDDYY(score['date_played']), isCompact ? 14 : 14, isCompact: isCompact),
          _buildFlexDataCellLeftAligned(score['golf_course'] ?? '', isCompact ? 20 : 18, isCompact: isCompact),
          _buildFlexDataCell('${score['skats_score'] ?? ''}', isCompact ? 10 : isMedium ? 10 : 9, isCompact: isCompact),
          _buildFlexDataCell(isPhone ? _formatWinningsWithCents(score['close_pin_winnings']) : _formatWinningsSimple(score['close_pin_winnings']), isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
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
    final isPhone = DeviceDetectionService.is6Point5Phone(context);
    
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, SKATS, Close Pin, SKAT Winnings
      return Row(
        children: [
          _buildFlexDataCell(_selectedPlayer ?? '', isCompact ? 22 : isMedium ? 22 : 24, isCompact: isCompact),
          _buildFlexDataCell(_getCurrentDateMMDDYY(), isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
          _buildFlexGolfCourseCell(isCompact: isCompact), // Golf Course - editable dropdown for Monday
          _buildFlexEditableCellWithBorder(_skatsController, _skatsFocus, isCompact ? 10 : isMedium ? 10 : 9, TextInputType.number, isCompact: isCompact),
          isPhone 
            ? _buildFlexEditableCellWithBorder(_closePinController, _closePinFocus, isCompact ? 16 : 15, TextInputType.number, isCompact: isCompact) // Close Pin - editable for phones
            : _buildFlexDataCell('\$0.00', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact), // Close pin winnings - static for tablets
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


  Widget _buildHeaders({bool isCompact = false, bool isMedium = false}) {
    final isPhone = DeviceDetectionService.is6Point5Phone(context);
    
    if (_selectedLeague == League.monday) {
      // Monday League: Name, Date, Golf Course, SKATS, Close Pin, SKAT Winnings
      return Column(
        children: [
          // First header line
          Row(
            children: [
              _buildFlexHeaderCell('Name', isCompact ? 22 : isMedium ? 22 : 24, isCompact: isCompact),
              _buildFlexHeaderCell('Date', isCompact ? 14 : isMedium ? 14 : 14, isCompact: isCompact),
              _buildFlexHeaderCell('Golf Course', isCompact ? 20 : isMedium ? 18 : 18, isCompact: isCompact),
              _buildFlexHeaderCell('SKAT#', isCompact ? 10 : isMedium ? 10 : 9, isCompact: isCompact),
              _buildFlexHeaderCell(isPhone ? 'Close Pin\n\$\$\$' : 'Close Pin', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
              _buildFlexHeaderCell('SKAT\n\$\$\$', isCompact ? 18 : isMedium ? 18 : 20, isCompact: isCompact),
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
  // Data Table Header
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
            style: TextStyle(fontSize: ResponsiveTypography.getSmall(context) - 4, fontWeight: FontWeight.bold, height: 1.0),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow text to wrap to 2 lines
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  // Table Data: Date, SKAT #, Close Pin $$$, SKAT $$$
  Widget _buildFlexDataCell(String text, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 35 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(fontSize: ResponsiveTypography.getSmall(context) - 3),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
  //Table Data: Golf Course
  Widget _buildFlexDataCellLeftAligned(String text, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 35 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(fontSize: ResponsiveTypography.getSmall(context) - 3),
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // Lock Icon and Name
  Widget _buildFlexDataCellWithIcon(String text, bool isUnlocked, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 35 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
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
                  style: TextStyle(fontSize: ResponsiveTypography.getSmall(context) - 3),
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
          initialValue: _selectedGolfCourse,
          isExpanded: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            isDense: true,
          ),
          style: ResponsiveTypography.smallStyle(context).copyWith(color: Colors.black),
          items: _golfCourses.map((course) {
            return DropdownMenuItem(
              value: course,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  course, 
                  style: ResponsiveTypography.smallStyle(context),
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
    final is6InchPhoneLandscape = DeviceDetectionService.is6Point5Phone(context);
    
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
          onFieldSubmitted: (_) {
            // Handle field submission focus changes if needed
          },
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
    return '\$$amount';
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


  @override
  Widget build(BuildContext context) {
    if (DeviceDetectionService.is6Point5Phone(context)) {
      return _buildPhoneLayout();
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
        backgroundColor: _selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700],
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

  Widget _buildTablet10Layout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Scores - ${_getLeagueDisplayName()} League- ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.appBarTitleStyle(context, color: Colors.white)),
        centerTitle: true,
        backgroundColor: _selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700],
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
        final mainContentHeight = constraints.maxHeight; // Use full height since we have no footer
        
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
                              border: const Border(bottom: BorderSide(color: Colors.grey)),
                            ),
                            child: Text(
                              'Players',
                              style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
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
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Title
        Container(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Player Scores',
            style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.bold),
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
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.white,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: '◄---- Back',
          color: Colors.blue[300]!,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ButtonBarUIService.buildSpacer(),
        ButtonBarUIService.buildSpacer(),
        ButtonBarUIService.buildSpacer(),
      ],
    );
  }

}