import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/responsive_typography.dart';
import '../../config/app_config.dart';
import '../../services/device_detection_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../services/firebase_upload_service.dart';
import '../../services/handicap_calculation_service.dart';
import '../../services/error_log_service.dart';

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
  bool _showAddScoreRow = false;
  DateTime? _insertDate;
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
      _insertDate = null;
      _grossScoreController.clear();
      _unlockedScoreIds.clear();
    });
    _loadPlayerScores(playerLast);
  }

  void _startInsertScore() {
    setState(() {
      _showAddScoreRow = true;
      _insertDate = DateTime.now();
      _grossScoreController.clear();
    });
  }

  void _cancelInsertScore() {
    setState(() {
      _showAddScoreRow = false;
      _insertDate = null;
      _grossScoreController.clear();
    });
  }

  Future<void> _pickInsertDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _insertDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _insertDate = picked;
      });
    }
  }

  /// Inserts a manually-entered score for the currently selected player.
  /// Reuses the same insert path (and duplicate-date handling) as a normal
  /// Save Results, then recalculates this player's handicap so New HC / Pad#
  /// populate immediately instead of staying blank until a manual recalc.
  Future<void> _insertManualScore() async {
    if (_selectedPlayer == null) return;

    final grossText = _grossScoreController.text.trim();
    if (grossText.isEmpty) {
      _showErrorDialog('Please enter a Match Gross score.');
      return;
    }
    final grossScore = int.tryParse(grossText);
    if (grossScore == null) {
      _showErrorDialog('Match Gross score must be a number.');
      return;
    }

    final dbPlayer = _players.firstWhere(
      (p) => p['last'] == _selectedPlayer,
      orElse: () => <String, dynamic>{},
    );
    if (dbPlayer.isEmpty) {
      _showErrorDialog('Could not find player record.');
      return;
    }

    final date = _insertDate ?? DateTime.now();
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final playerId = dbPlayer['player_number'] as int;
    final playerName = _selectedPlayer!;

    try {
      final scoreData = <String, dynamic>{
        'player_id': playerId,
        'name': playerName,
        'date_played': dateStr,
        'golf_course': 'The Hideout',
        'handicap': (dbPlayer['HC'] as num?)?.toDouble() ?? 0.0,
        'gross_score': grossScore,
        'close_pin_winnings': 0.0,
        'single_winnings': 0.0,
        'group_winnings': 0.0,
      };

      final insertResult = await _databaseHelper.insertScoreLeague(scoreData, League.wednesday);
      final deletedScores = insertResult['deletedScores'] as List<Map<String, dynamic>>;

      await _recalculateHandicapForPlayer(playerId, playerName);

      await _firebaseUploadService.uploadPlayerScoresTableWithQueue(League.wednesday);
      // Scoped to just this one player — a full-roster push would also
      // re-upload every other Wednesday player from this device's local
      // cache, which may be stale for players this device didn't touch.
      final updatedPlayer = await _databaseHelper.getPlayer(playerId);
      if (updatedPlayer != null) {
        await _firebaseUploadService.uploadPlayersWithQueue(League.wednesday, [updatedPlayer]);
      }
      if (deletedScores.isNotEmpty) {
        await _firebaseUploadService.deletePlayerScoresFromFirebase(deletedScores, League.wednesday);
      }

      if (!mounted) return;
      setState(() {
        _showAddScoreRow = false;
        _insertDate = null;
        _grossScoreController.clear();
      });

      await _loadPlayerScores(playerName);
      await _loadPlayers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score inserted successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      await ErrorLogService().logError('Wednesday Manual Score Insert ($playerName)', e);
      if (mounted) _showErrorDialog('Error inserting score: $e');
    }
  }

  /// Recalculates a single player's handicap from their recent score history
  /// (same algorithm as "Recalculate All Handicaps") and writes New HC /
  /// Pad# onto their most recent score record.
  Future<void> _recalculateHandicapForPlayer(int playerId, String playerName) async {
    try {
      final scores = await _databaseHelper.getPlayerRecentScores(playerId, League.wednesday, limit: 6);
      final grossScores = scores
          .where((s) => s['gross_score'] != null)
          .map((s) => (s['gross_score'] as num).toInt())
          .toList();
      if (grossScores.isEmpty) return;

      final padCount = 6 - grossScores.length.clamp(0, 6);
      final handicapService = HandicapCalculationService();
      final newHandicap = handicapService.calculateWednesdayHandicap(grossScores: grossScores);

      await _databaseHelper.updatePlayerHandicap(playerId, newHandicap, League.wednesday);

      final mostRecentScoreId = scores.first['id'] as int?;
      if (mostRecentScoreId != null) {
        await _databaseHelper.updateScoreField(mostRecentScoreId, 'new_hc', newHandicap, League.wednesday);
        await _databaseHelper.updateScoreField(mostRecentScoreId, 'pad_count', padCount, League.wednesday);
      }
    } catch (e) {
      debugPrint('Error recalculating handicap for $playerName: $e');
      await ErrorLogService().logError('Wednesday Manual Score Insert - HC Recalc ($playerName)', e);
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
        _buildFlexDataCellWithIcon(score['name'] ?? '', isUnlocked, 16, isCompact: isCompact),
        _buildFlexDataCell(_formatDateToMMDDYY(score['date_played']), 12, isCompact: isCompact),
        _buildFlexDataCell('${score['pad_count'] ?? ''}', 10, isCompact: isCompact),
        _buildFlexDataCell('${score['handicap'] ?? ''}', 12, isCompact: isCompact),
        _buildFlexDataCell('${score['gross_score'] ?? ''}', 12, isCompact: isCompact),
        _buildFlexDataCell('${score['new_hc'] ?? ''}', 15, isCompact: isCompact),
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
        _buildFlexDataCell(_selectedPlayer ?? '', 16, isCompact: isCompact),
        _buildInsertDateCell(isCompact: isCompact),
        _buildFlexDataCell('', 10, isCompact: isCompact), // Pad# â€” calculated on save
        _buildFlexDataCell('', 12, isCompact: isCompact), // Start HC â€” taken from player's current HC on save
        _buildFlexEditableCellWithBorder(_grossScoreController, _grossScoreFocus, 12, TextInputType.number, isCompact: isCompact),
        _buildFlexDataCell('', 15, isCompact: isCompact), // New HC â€” calculated on save
      ],
    );
  }

  /// Tappable Date cell for the manual-insert row — opens a date picker
  /// instead of free-text entry to keep the stored date format valid.
  Widget _buildInsertDateCell({bool isCompact = false}) {
    final dateText = _insertDate != null
        ? _formatDateToMMDDYY(_insertDate!.toIso8601String())
        : _getCurrentDateMMDDYY();

    return Expanded(
      flex: 12,
      child: GestureDetector(
        onTap: _pickInsertDate,
        child: Container(
          height: isCompact ? 35 : 30,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 0.5),
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: ResponsiveTypography.getSmall(context) - 3,
                decoration: TextDecoration.underline,
                color: Colors.blue[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaders({bool isCompact = false, bool isMedium = false}) {
    final isPhone = DeviceDetectionService.is6Point5Phone(context);

    return Column(
      children: [
        Row(
          children: [
            _buildFlexHeaderCell('Name', 16, isCompact: isCompact),
            _buildFlexHeaderCell('Date', 12, isCompact: isCompact),
            _buildFlexHeaderCell('Pad#', 10, isCompact: isCompact),
            _buildFlexHeaderCell('Start\nHC', 12, isCompact: isCompact),
            _buildFlexHeaderCell('Match\nGross', 12, isCompact: isCompact),
            _buildFlexHeaderCell('New\nHC', 15, isCompact: isCompact),
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
        title: Text('Player Scores - ${_getLeagueDisplayName()} League- ${AppConfig.versionDate}',
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
        title: Text('Player Scores - ${_getLeagueDisplayName()} League- ${AppConfig.versionDate}',
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
    final canInsert = _selectedPlayer != null && !_showAddScoreRow;

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.white,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: '<---- MainMenu',
          color: Colors.blue[300]!,
          onPressed: _showAddScoreRow ? null : () => Navigator.of(context).pop(),
          flex: 5, // 25% of screen width (5 out of 20 total flex units) - matches player_profile_screen
        ),
        if (_showAddScoreRow) ...[
          ButtonBarUIService.buildActionButton(
            context,
            text: 'Save New Score',
            color: Colors.green[400]!,
            onPressed: _insertManualScore,
            flex: 10,
          ),
          ButtonBarUIService.buildActionButton(
            context,
            text: 'Cancel',
            color: Colors.grey[400]!,
            onPressed: _cancelInsertScore,
            flex: 5,
          ),
        ] else ...[
          ButtonBarUIService.buildActionButton(
            context,
            text: 'Insert Score',
            color: canInsert ? Colors.orange[300]! : Colors.grey[400]!,
            onPressed: canInsert ? _startInsertScore : null,
            flex: 5, // Spacer with flex: 5
          ),
          const Expanded(flex: 5, child: SizedBox()), // Spacer with flex: 5
          const Expanded(flex: 5, child: SizedBox()), // Spacer with flex: 5
        ],
      ],
    );
  }
}
