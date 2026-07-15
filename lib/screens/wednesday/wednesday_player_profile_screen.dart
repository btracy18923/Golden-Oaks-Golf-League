import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/UI/player_profile_service.dart';
import '../../services/UI/button_bar_UI_service.dart';
import '../../services/firebase_upload_service.dart';
import '../../config/app_config.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayPlayerProfileScreen extends StatefulWidget {
  final League? league;

  const WednesdayPlayerProfileScreen({super.key, this.league});

  @override
  State<WednesdayPlayerProfileScreen> createState() => _WednesdayPlayerProfileScreenState();
}

class _WednesdayPlayerProfileScreenState extends State<WednesdayPlayerProfileScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  League _selectedLeague = League.wednesday;
  Map<String, dynamic>? _selectedPlayer;
  List<Map<String, dynamic>> _players = [];
  bool _isTableInteracting = false;
  bool _isKeyboardVisible = false;
  bool _anyFieldHasFocus = false;

  // Form controllers - using handicap instead of skat
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _lastController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();
  final TextEditingController _cellController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Focus nodes for TAB navigation
  final FocusNode _idFocus = FocusNode();
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _lastFocus = FocusNode();
  final FocusNode _handicapFocus = FocusNode();
  final FocusNode _cellFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedLeague = widget.league ?? League.wednesday;
    _loadPlayerList();
    _setupFocusListeners();
  }

  @override
  void dispose() {
    // Upload player table to Firebase before leaving
    _uploadPlayerDataToFirebase();

    _idController.dispose();
    _firstController.dispose();
    _lastController.dispose();
    _handicapController.dispose();
    _cellController.dispose();
    _emailController.dispose();

    _idFocus.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    _handicapFocus.dispose();
    _cellFocus.dispose();
    _emailFocus.dispose();

    super.dispose();
  }

  /// Upload player table data to Firebase when leaving the screen
  void _uploadPlayerDataToFirebase() async {
    try {
      await _firebaseUploadService.uploadPlayerTableWithQueue(_selectedLeague);
      // Upload happens in background - no UI feedback needed on dispose
    } catch (e) {
      // Silently fail on dispose - don't block navigation
      debugPrint('Failed to upload player data on dispose: $e');
    }
  }

  void _setupFocusListeners() {
    _idFocus.addListener(_onFocusChange);
    _firstFocus.addListener(_onFocusChange);
    _lastFocus.addListener(_onFocusChange);
    _handicapFocus.addListener(_onFocusChange);
    _cellFocus.addListener(_onFocusChange);
    _emailFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final anyFocused = _idFocus.hasFocus ||
                      _firstFocus.hasFocus ||
                      _lastFocus.hasFocus ||
                      _handicapFocus.hasFocus ||
                      _cellFocus.hasFocus ||
                      _emailFocus.hasFocus;

    if (_anyFieldHasFocus != anyFocused) {
      setState(() {
        _anyFieldHasFocus = anyFocused;
      });
    }
  }


  Future<void> _loadPlayerList() async {
    try {
      final players = await _databaseHelper.getPlayersByLeague(_selectedLeague);
      setState(() {
        _players = players;
      });
    } catch (e) {
      _showErrorDialog('Error loading players: $e');
    }
  }

  /// Simple refresh without any dialog - just reload the player list
  Future<void> _refreshPlayerList() async {
    await _loadPlayerList();
  }


  void _clearForm() {
    _idController.clear();
    _firstController.clear();
    _lastController.clear();
    _handicapController.clear();
    _cellController.clear();
    _emailController.clear();

    // Remove focus from all form fields
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedPlayer = null;
    });
  }

  void _selectPlayer(Map<String, dynamic> player) {
    // Check if any form data exists that would be overwritten
    bool hasFormData = _idController.text.trim().isNotEmpty ||
                      _firstController.text.trim().isNotEmpty ||
                      _lastController.text.trim().isNotEmpty ||
                      _handicapController.text.trim().isNotEmpty ||
                      _cellController.text.trim().isNotEmpty ||
                      _emailController.text.trim().isNotEmpty;

    if (hasFormData && _selectedPlayer?['player_number'] != player['player_number']) {
      // Show confirmation dialog before overwriting form data
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Load Player Data?', style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.w600)),
          content: Text('This will replace the current form data with "${player['first']} ${player['last']}". Continue?', style: ResponsiveTypography.bodyTextStyle(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: ResponsiveTypography.buttonStyle(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _loadPlayerData(player);
              },
              child: Text('Load', style: ResponsiveTypography.buttonStyle(context)),
            ),
          ],
        ),
      );
    } else {
      _loadPlayerData(player);
    }
  }

  void _loadPlayerData(Map<String, dynamic> player) {
    setState(() {
      _selectedPlayer = Map<String, dynamic>.from(player);
      // Format player_number with leading zeros to ensure 4 digits
      final playerNumber = player['player_number']?.toString() ?? '';
      _idController.text = playerNumber.isEmpty ? '' : playerNumber.padLeft(4, '0');
      _firstController.text = player['first'] ?? '';
      _lastController.text = player['last'] ?? '';
      _handicapController.text = player['HC']?.toString() ?? '';
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
      _showErrorDialog('Player Number is required!');
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

    if (_handicapController.text.trim().isEmpty) {
      _showErrorDialog('HC (Handicap) is required!');
      return false;
    }

    if (_cellController.text.trim().isEmpty) {
      _showErrorDialog('Cell Phone is required!');
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Email is required!');
      return false;
    }

    return true;
  }

  bool _checkForDuplicates() {
    final playerId = int.tryParse(_idController.text.trim()) ?? 0;
    final firstName = _firstController.text.trim().toLowerCase();
    final lastName = _lastController.text.trim().toLowerCase();

    // Check for duplicate player_number
    for (var player in _players) {
      if (player['player_number'] == playerId) {
        _showErrorDialog('Player #$playerId already exists!');
        return true;
      }
    }

    // Check for duplicate name combination
    for (var player in _players) {
      final existingFirst = (player['first'] ?? '').toString().toLowerCase();
      final existingLast = (player['last'] ?? '').toString().toLowerCase();

      if (existingFirst == firstName && existingLast == lastName) {
        _showErrorDialog('Player "$firstName $lastName" already exists!');
        return true;
      }
    }

    return false;
  }

  Future<void> _addPlayer() async {
    if (!_validateForm()) return;

    // Check for duplicates
    if (_checkForDuplicates()) return;

    try {
      final leagueStr = _selectedLeague == League.monday ? 'monday' : 'wednesday';

      // Insert player to local database
      await _databaseHelper.insertPlayer({
        'player_number': int.tryParse(_idController.text) ?? 0,
        'first': _firstController.text.trim(),
        'last': _lastController.text.trim(),
        'HC': double.tryParse(_handicapController.text) ?? 0.0,
        'league': leagueStr,
        'cell': _cellController.text.trim(),
        'email': _emailController.text.trim(),
      });

      _clearForm();
      _refreshPlayerList();

      // Immediately try to upload to Firebase
      final uploadSuccess = await _firebaseUploadService.uploadPlayerTableWithQueue(_selectedLeague);

      if (uploadSuccess) {
        _showSuccessDialog('Player added and uploaded to Firebase!');
      } else {
        _showSuccessDialog('Player added locally! Firebase upload queued for when WiFi is available.');
      }
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

      await _databaseHelper.updatePlayer(_selectedPlayer!['player_number'], {
        'player_number': int.tryParse(_idController.text) ?? 0,
        'first': _firstController.text.trim(),
        'last': _lastController.text.trim(),
        'HC': double.tryParse(_handicapController.text) ?? 0.0,
        'league': leagueStr,
        'cell': _cellController.text.trim(),
        'email': _emailController.text.trim(),
      });

      _refreshPlayerList();
      _clearForm();

      // Immediately try to upload to Firebase
      final uploadSuccess = await _firebaseUploadService.uploadPlayerTableWithQueue(_selectedLeague);
      if (uploadSuccess) {
        _showSuccessDialog('Player updated and uploaded to Firebase!');
      } else {
        _showSuccessDialog('Player updated locally! Firebase upload queued for when WiFi is available.');
      }
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
        title: Text('Confirm Delete', style: TextStyle(fontSize: ResponsiveTypography.getHeading(context))),
        content: Text('Are you sure you want to delete $playerName?\n\nThis action cannot be undone.', style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear focus first
        if (mounted) {
          FocusScope.of(context).unfocus();
        }

        // Get the last name before deleting from local database
        final lastName = _selectedPlayer!['last']?.toString() ?? '';

        // Delete from local database
        await _databaseHelper.deletePlayer(_selectedPlayer!['player_number']);
        _clearForm();
        _refreshPlayerList();

        // Delete from Firebase
        final firebaseDeleteSuccess = await _firebaseUploadService.deletePlayerFromFirebaseWithQueue(_selectedLeague, lastName);

        if (mounted) {
          // Ensure absolutely no field has focus after deletion
          FocusScope.of(context).unfocus();

          // Also clear focus from all individual focus nodes
          _idFocus.unfocus();
          _firstFocus.unfocus();
          _lastFocus.unfocus();
          _handicapFocus.unfocus();
          _cellFocus.unfocus();
          _emailFocus.unfocus();

          // Show appropriate success message based on Firebase deletion result
          if (firebaseDeleteSuccess) {
            _showSuccessDialog('Player deleted from local database and Firebase!');
          } else {
            _showSuccessDialog('Player deleted from local database! Firebase deletion will occur when WiFi is available.');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Error deleting player: $e');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error', style: TextStyle(fontSize: ResponsiveTypography.getHeading(context))),
        content: Text(message, style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success', style: TextStyle(fontSize: ResponsiveTypography.getHeading(context))),
        content: Text(message, style: TextStyle(fontSize: ResponsiveTypography.getBodyText(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(fontSize: ResponsiveTypography.getButton(context))),
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
      enabled: !_isTableInteracting,
    );
  }


  Widget _buildPlayerTable() {
    return _buildWednesdayPlayerTable(
      context,
      _players,
      _selectedPlayer,
      _selectPlayer,
      _formatPhoneNumber,
      onInteractionChange: (bool isInteracting) {
        setState(() {
          _isTableInteracting = isInteracting;
        });
      },
      isKeyboardVisible: _isKeyboardVisible,
      anyFieldHasFocus: _anyFieldHasFocus,
    );
  }


  @override
  Widget build(BuildContext context) {
    // Detect keyboard visibility
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Update keyboard visibility state
    if (_isKeyboardVisible != isKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isKeyboardVisible = isKeyboardVisible;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Player Profile - ${_selectedLeague == League.monday ? 'Monday' : 'Wednesday'} League - ${AppConfig.versionDate}',
          style: TextStyle(fontSize: ResponsiveTypography.getAppBarTitle(context)),
        ),
        centerTitle: true,
        backgroundColor: FirebaseUploadService.anyAdminOverrideActive ? Colors.red[700] : (_selectedLeague == League.monday ? Colors.green[700] : Colors.orange[700]),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          phone: _buildPhoneLayout(),
          tablet10: _buildTablet10Layout(),
        ),
      ),
    );
  }


  // Phone layout (6.5" phone)
  Widget _buildPhoneLayout() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: _buildPhoneLandscapeLayout(),
          ),
        ),
        _buildFullScreenButtonBar(),
      ],
    );
  }

  // 10" tablet layout
  Widget _buildTablet10Layout() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(24.0),
            child: _buildTabletLayoutContent(),
          ),
        ),
        _buildFullScreenButtonBar(),
      ],
    );
  }

  Widget _buildTabletLayoutContent() {
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



  Widget _buildFormSectionWithoutButtons() {
    return _buildWednesdayFormSectionWithoutButtons(
      context,
      _buildCompactFormField,
      _idController,
      _firstController,
      _lastController,
      _handicapController,
      _cellController,
      _emailController,
      _idFocus,
      _firstFocus,
      _lastFocus,
      _handicapFocus,
      _cellFocus,
      _emailFocus,
    );
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



  Widget _buildFullScreenButtonBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ButtonBarUIService.buildButtonBar(
        context,
        backgroundColor: Colors.white,
        children: [
          ButtonBarUIService.buildActionButton(
            context,
            text: '<---- MainMenu',
            color: Colors.blue[300]!,
            onPressed: () => Navigator.of(context).pop(),
          ),
          ButtonBarUIService.buildActionButton(
            context,
            text: 'Clear',
            color: Colors.orange[300]!,
            onPressed: _clearForm,
          ),
          ButtonBarUIService.buildActionButton(
            context,
            text: 'Delete',
            color: _selectedPlayer != null ? Colors.red[300]! : Colors.grey[400]!,
            onPressed: _selectedPlayer != null ? _deletePlayer : null,
          ),
          ButtonBarUIService.buildActionButton(
            context,
            text: 'Add Player',
            color: Colors.green[300]!,
            onPressed: _addPlayer,
          ),
        ],
      ),
    );
  }

  // Wednesday-specific form section with HC instead of SKAT#

  Widget _buildWednesdayFormSectionWithoutButtons(
    BuildContext context,
    Widget Function(String, TextEditingController, FocusNode, FocusNode?, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) buildCompactFormField,
    TextEditingController idController,
    TextEditingController firstController,
    TextEditingController lastController,
    TextEditingController handicapController,
    TextEditingController cellController,
    TextEditingController emailController,
    FocusNode idFocus,
    FocusNode firstFocus,
    FocusNode lastFocus,
    FocusNode handicapFocus,
    FocusNode cellFocus,
    FocusNode emailFocus,
  ) {
    // Use unified device detection service for consistent classification
    final isPhone = DeviceDetectionService.is6Point5Phone(context);

    // For 6.5" phones, use compact layout with SingleChildScrollView to prevent overflow
    if (isPhone) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildCompactFormField('ID#', idController, idFocus, firstFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 0),
              buildCompactFormField('First Name', firstController, firstFocus, lastFocus),
              const SizedBox(height: 0),
              buildCompactFormField('Last Name', lastController, lastFocus, handicapFocus),
              const SizedBox(height: 0),
              buildCompactFormField('HC', handicapController, handicapFocus, cellFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 0),
              buildCompactFormField('Cell Phone', cellController, cellFocus, emailFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: false)),
              const SizedBox(height: 0),
              buildCompactFormField('Email', emailController, emailFocus, null),
            ],
          ),
        ),
      );
    }

    // For 10" tablets and other screen sizes, keep the scroll wrapper
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildCompactFormField('Player #', idController, idFocus, firstFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 8),
              buildCompactFormField('First Name', firstController, firstFocus, lastFocus),
              const SizedBox(height: 8),
              buildCompactFormField('Last Name', lastController, lastFocus, handicapFocus),
              const SizedBox(height: 8),
              buildCompactFormField('HC', handicapController, handicapFocus, cellFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 8),
              buildCompactFormField('Cell Phone', cellController, cellFocus, emailFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: false)),
              const SizedBox(height: 8),
              buildCompactFormField('Email', emailController, emailFocus, null),
            ],
          ),
        ),
      ),
    );
  }

  // Wednesday-specific player table with HC instead of SKAT#
  Widget _buildWednesdayPlayerTable(
    BuildContext context,
    List<Map<String, dynamic>> players,
    Map<String, dynamic>? selectedPlayer,
    Function(Map<String, dynamic>) onSelectPlayer,
    String Function(String?) formatPhoneNumber, {
    Function(bool)? onInteractionChange,
    bool isKeyboardVisible = false,
    bool anyFieldHasFocus = false,
  }) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = size.width;

    // Improved responsive breakpoints
    final isLargeTablet = screenWidth >= 1200;
    final isMediumTablet = screenWidth >= 800 && screenWidth < 1200;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 800;
    final isPhone = screenWidth < 600;
    final isLandscape = orientation == Orientation.landscape;
    final is6InchPhoneLandscape = isPhone && isLandscape;

    // Adaptive table width calculation
    double tableWidth;
    double rowHeight;
    // Use ResponsiveTypography for consistent font sizing
    double fontSize = ResponsiveTypography.getSmall(context) - 2;

    if (isLargeTablet) {
      tableWidth = isLandscape ? (screenWidth * 0.7) - 40 : screenWidth - 60;
      rowHeight = 48;
    } else if (isMediumTablet) {
      tableWidth = isLandscape ? (screenWidth * 0.65) - 30 : screenWidth - 50;
      rowHeight = 44;
    } else if (isSmallTablet) {
      tableWidth = isLandscape ? (screenWidth * 0.6) - 25 : screenWidth - 40;
      rowHeight = 40;
    } else if (is6InchPhoneLandscape) {
      tableWidth = (screenWidth * 0.65) - 20;
      rowHeight = 36;
    } else {
      // Phone portrait
      tableWidth = screenWidth - 32;
      rowHeight = 48;
    }

    Widget tableWidget = Container(
      width: tableWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header row
          Container(
            height: rowHeight,
            decoration: BoxDecoration(
              color: Colors.orange[300],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: SizedBox(
              width: tableWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: is6InchPhoneLandscape ? [
                    _buildHeaderCellLeftAlign('Name', tableWidth * 0.40, fontSize),
                    _buildHeaderCell('HC', tableWidth * 0.15, fontSize),
                    _buildHeaderCell('Phone', tableWidth * 0.45, fontSize),
                  ] : [
                    _buildHeaderCellLeftAlign('Name', tableWidth * 0.40, fontSize),
                    _buildHeaderCell('HC', tableWidth * 0.15, fontSize),
                    _buildHeaderCell('Phone', tableWidth * 0.45, fontSize),
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
                  child: GestureDetector(
                    onTap: () {
                      // Clear focus when tapping in the table area
                      FocusScope.of(context).unfocus();
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // Clear focus and disable form when scrolling starts
                        if (scrollInfo is ScrollStartNotification) {
                          FocusScope.of(context).unfocus();
                          onInteractionChange?.call(true);
                        } else if (scrollInfo is ScrollEndNotification) {
                          // Re-enable form when scrolling ends
                          onInteractionChange?.call(false);
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final isSelected = selectedPlayer?['player_number'] == player['player_number'];

                          return GestureDetector(
                            onTap: (isKeyboardVisible || anyFieldHasFocus) ? null : () {
                              // Clear focus before selecting player
                              FocusScope.of(context).unfocus();
                              onSelectPlayer(player);
                            },
                            child: Container(
                              height: rowHeight,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange[200] : Colors.transparent,
                                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                              ),
                              child: is6InchPhoneLandscape
                                ? _buildWednesdayMobilePlayerRow(player, tableWidth, formatPhoneNumber, fontSize)
                                : _buildWednesdayTabletPlayerRow(player, tableWidth, formatPhoneNumber, fontSize),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        tableWidget,
        // Overlay when keyboard is visible or fields have focus
        if (isKeyboardVisible || anyFieldHasFocus)
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.keyboard,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWednesdayMobilePlayerRow(Map<String, dynamic> player, double tableWidth, String Function(String?) formatPhoneNumber, double fontSize) {
    return Row(
      children: [
        _buildDataCell('${player['first'] ?? ''} ${player['last'] ?? ''}',
                      tableWidth * 0.40, fontSize, alignLeft: true),
        _buildDataCell(player['HC']?.toString() ?? '',
                      tableWidth * 0.15, fontSize),
        _buildDataCell(formatPhoneNumber(player['cell']),
                      tableWidth * 0.45, fontSize),
      ],
    );
  }

  Widget _buildWednesdayTabletPlayerRow(Map<String, dynamic> player, double tableWidth, String Function(String?) formatPhoneNumber, double fontSize) {
    return Row(
      children: [
        _buildDataCell('${player['first'] ?? ''} ${player['last'] ?? ''}', tableWidth * 0.40, fontSize, alignLeft: true),
        _buildDataCell(player['HC']?.toString() ?? '', tableWidth * 0.15, fontSize),
        _buildDataCell(formatPhoneNumber(player['cell']), tableWidth * 0.45, fontSize),
      ],
    );
  }

  Widget _buildHeaderCell(String text, double width, double fontSize) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHeaderCellLeftAlign(String text, double width, double fontSize) {
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, double fontSize, {bool alignLeft = false}) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: alignLeft
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : Center(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    );
  }
}
