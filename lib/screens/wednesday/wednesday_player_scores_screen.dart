import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/responsive_typography.dart';
import '../../services/device_detection_service.dart';
import '../../services/UI/button_bar_UI_service.dart';

class WednesdayPlayerScoresScreen extends StatefulWidget {
  final League? league;

  const WednesdayPlayerScoresScreen({super.key, this.league});

  @override
  State<WednesdayPlayerScoresScreen> createState() => _WednesdayPlayerScoresScreenState();
}

class _WednesdayPlayerScoresScreenState extends State<WednesdayPlayerScoresScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  League _selectedLeague = League.wednesday;
  String? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _scores = [];
  int? _selectedScoreIndex;
  bool _showAddScoreRow = false;
  final Set<int> _unlockedScoreIds = {};

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



  void _selectPlayer(String playerLast) {
    setState(() {
      _selectedPlayer = playerLast;
      _selectedScoreIndex = null;
      _showAddScoreRow = false;
      _unlockedScoreIds.clear();
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
    final isPhone = DeviceDetectionService.is6Point5Phone(context);

    double tableWidth;
    if (isPhone) {
      tableWidth = 550;
    } else {
      tableWidth = 870;
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
            _buildFlexHeaderCell(isPhone ? 'Close Pin\n\$\$\$' : 'Close Pin', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
            _buildFlexHeaderCell('IND\n\$\$\$', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
            _buildFlexHeaderCell('Group\n\$\$\$', isCompact ? 16 : isMedium ? 15 : 15, isCompact: isCompact),
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
            style: TextStyle(fontSize: ResponsiveTypography.getSmall(context) - 4, fontWeight: FontWeight.bold, height: 1.0),
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
    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.white,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: '◄---- MainMenu',
          color: Colors.blue[300]!,
          onPressed: () => Navigator.of(context).pop(),
          flex: 5, // 25% of screen width (5 out of 20 total flex units) - matches player_profile_screen
        ),
        const Expanded(flex: 5, child: SizedBox()), // Spacer with flex: 5
        const Expanded(flex: 5, child: SizedBox()), // Spacer with flex: 5
        const Expanded(flex: 5, child: SizedBox()), // Spacer with flex: 5
      ],
    );
  }
}
