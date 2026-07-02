import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/UI/closest_pin_UI_service.dart' as closest_pin_ui;
import '../../services/shared/league_purse_service.dart';
import '../../services/screen_data_retention_service.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import 'monday_results_screen.dart';
import '../../services/firebase_upload_service.dart';
import '../../models/league.dart';

class MondayClosestPinScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  final double? playersAnte;

  const MondayClosestPinScreen({super.key, required this.selectedPlayers, this.playersAnte});

  @override
  State<MondayClosestPinScreen> createState() => _MondayClosestPinScreenState();
}

class _MondayClosestPinScreenState extends State<MondayClosestPinScreen> {
  late int _totalClosestPins;
  late int _remainingClosestPins;
  late double _closestPinValue;
  late double _remainingPurseAmount;
  late double _initialPurseAmount; // Store the original purse amount for Clear button
  final Map<String, double> _playerClosestPinCounts = {};
  final Map<String, double> _playerWinnings = {};
  bool _tiedMode = false; // Track if tied mode is active
  final List<String> _tiedPlayers = []; // Track players in the tie
  @override
  void initState() {
    super.initState();

    // Calculate purse directly from player count: $1.00/pin/player × 4 pins × playerCount
    double closestPinAmount = LeaguePurseService.getClosestPinAmount(league: League.monday);
    double calculatedPurse = closestPinAmount * widget.selectedPlayers.length;

    LeaguePurseService.setClosestPinPurse(calculatedPurse, isExplicit: true);

    _initialPurseAmount = calculatedPurse;

    // Number of pins = per-player amount (4 for Monday)
    _totalClosestPins = closestPinAmount.round();
    _remainingClosestPins = _totalClosestPins;

    // Value per pin, rounded to nearest dollar
    _closestPinValue = (calculatedPurse / _totalClosestPins).roundToDouble();

    // Initialize remaining purse amount to track decreases
    _remainingPurseAmount = calculatedPurse;
    
    // Initialize player closest pin counts and winnings
    for (var player in widget.selectedPlayers) {
      String lastName = player['last'] ?? 'Unknown';
      _playerClosestPinCounts[lastName] = 0.0;
      _playerWinnings[lastName] = 0.0;
    }
    
    // Lock screen to landscape mode only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use DeviceDetectionService for consistent device detection
      DeviceDetectionService.getDeviceType(context);
      DeviceDetectionService.getDeviceName(context);

      // Debug info
      DeviceDetectionService.printDebugInfo(context);

      // Lock to landscape mode for all devices
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  void _handleClear() {
    setState(() {
      // Reset to initial state values
      double closestPinAmount = LeaguePurseService.getClosestPinAmount(league: League.monday);
      _totalClosestPins = closestPinAmount.round();
      _remainingClosestPins = _totalClosestPins;
      _closestPinValue = (_initialPurseAmount / _totalClosestPins).roundToDouble();
      _remainingPurseAmount = _initialPurseAmount;

      // Sync the reset Closest Pin Purse back to LeaguePurseService
      LeaguePurseService.setClosestPinPurse(_initialPurseAmount, isExplicit: false);

      // Reset all player counts and winnings to 0
      for (var player in widget.selectedPlayers) {
        String lastName = player['last'] ?? 'Unknown';
        _playerClosestPinCounts[lastName] = 0.0;
        _playerWinnings[lastName] = 0.0;
      }

      // Reset tied mode and tied players list
      _tiedMode = false;
      _tiedPlayers.clear();
    });
  }

  void _handleSaveAndReturn() {
    // Capture data in the retention service before saving
    ScreenDataRetentionService().captureClosestPinData(
      playerClosestPinCounts: _playerClosestPinCounts,
      playerClosestPinWinnings: _playerWinnings,
      remainingClosestPinPurse: _remainingPurseAmount,
      totalClosestPins: _totalClosestPins,
      remainingClosestPins: _remainingClosestPins,
    );

    // Update the LeaguePurseService with the remaining purse amount
    LeaguePurseService.setClosestPinPurse(_remainingPurseAmount, isExplicit: false);

    // Navigate to Monday Results Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MondayResultsScreen(),
      ),
    );
  }

  void _handleTied() {
    setState(() {
      _tiedMode = !_tiedMode;
      if (!_tiedMode) {
        // Exiting tied mode - clear tied players list
        _tiedPlayers.clear();
      }
    });
  }

  void _handlePlayerTap(String lastName) {
    // In tied mode, allow selecting players regardless of remaining count (as long as tied mode is active)
    // In normal mode, check if there are remaining closest pins
    bool canSelectPlayer = (_tiedMode && _remainingClosestPins == 0) || _remainingClosestPins > 0;

    if (canSelectPlayer) {
      setState(() {
        if (_tiedMode) {
          // Add the tapped player to the tie if not already included
          if (!_tiedPlayers.contains(lastName)) {
            _tiedPlayers.add(lastName);
          }

          // Calculate split amount among all tied players so far
          double splitAmount = _closestPinValue / _tiedPlayers.length;
          double fractionalCount = 1.0 / _tiedPlayers.length;

          // Update winnings and counts for all tied players
          for (String playerName in _tiedPlayers) {
            _playerClosestPinCounts[playerName] = fractionalCount;
            _playerWinnings[playerName] = splitAmount;
          }

          // Decrement the pin counter only when the FIRST tied player is added
          if (_tiedPlayers.length == 1 && _remainingClosestPins > 0) {
            _remainingClosestPins--;
            _remainingPurseAmount -= _closestPinValue;
          }

          // Stay in tied mode â€” user taps TIE button again to finalize
        } else {
          // Normal mode - single winner gets full amount
          _playerClosestPinCounts[lastName] = _playerClosestPinCounts[lastName]! + 1.0;
          _remainingClosestPins--;
          // Increase player's winnings by the fixed closest pin value
          _playerWinnings[lastName] = _playerClosestPinCounts[lastName]! * _closestPinValue;
          // Decrease the remaining purse amount by the closest pin value
          _remainingPurseAmount -= _closestPinValue;
        }
        // Sync the Closest Pin Purse in LeaguePurseService to keep it in sync
        LeaguePurseService.setClosestPinPurse(_remainingPurseAmount, isExplicit: false);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more closest pins to process'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Gets responsive padding based on device type
  double _getResponsivePadding(BuildContext context) {
    final deviceType = DeviceDetectionService.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.phone6Point5:
        return 5.0;
      case DeviceType.tablet10Inch:
        return 16.0;
    }
  }
  // Count and $$$
  Widget _buildPlayerGridItem(Map<String, dynamic> player, int index) {
    final deviceType = DeviceDetectionService.getDeviceType(context);
    final fontSize = ResponsiveTypography.getBodyText(context);
    _getResponsivePadding(context);
    
    String lastName = player['last'] ?? 'Unknown';
    double closestPinCount = _playerClosestPinCounts[lastName] ?? 0.0;
    double winnings = _playerWinnings[lastName] ?? 0.0;
    
    // Calculate container height based on font size with minimal padding
    double containerHeight = fontSize + 2; // font size + minimal padding (1px top + 1px bottom)
    double countSize = (containerHeight - 1) * 2; // 100% wider (double the size)
    
    return GestureDetector(
      onTap: () => _handlePlayerTap(lastName),
      child: Container(
        height: containerHeight,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.fromLTRB(1, 1, 6, 1), // Extra padding on right side
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: closestPinCount > 0 ? Colors.green[300]! : Colors.grey[300]!, 
            width: closestPinCount > 0 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                lastName,
                style: TextStyle(
                  fontSize: deviceType == DeviceType.phone6Point5 ? 14 : fontSize - 3,
                  fontWeight: FontWeight.bold,
                  color: closestPinCount > 0 ? Colors.green[800] : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),
            Container(
              width: countSize * 2,
              height: countSize,
              margin: const EdgeInsets.only(right: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                border: Border.all(
                  color: closestPinCount > 0 ? Colors.green[400]! : Colors.grey[400]!,
                  width: 1,
                ),
              ),
              child: Text(
                closestPinCount % 1 == 0
                    ? '${closestPinCount.toInt()}'
                    : closestPinCount.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: deviceType == DeviceType.tablet10Inch ? fontSize + 2 : fontSize - 0,
                  fontWeight: FontWeight.bold,
                  color: closestPinCount > 0 ? Colors.green[800] : Colors.grey[600],
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                height: countSize,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: winnings > 0 ? Colors.blue[100] : Colors.grey[50],
                  border: Border.all(
                    color: winnings > 0 ? Colors.blue[300]! : Colors.grey[300]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '\$${winnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.tablet10Inch ? fontSize + 2 : fontSize,
                    fontWeight: FontWeight.w600,
                    color: winnings > 0 ? Colors.blue[800] : Colors.grey[500],
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    final deviceType = DeviceDetectionService.getDeviceType(context);
    final headerFontSize = ResponsiveTypography.getHeading(context);
    final padding = _getResponsivePadding(context);
    // For 6.5" phones, increase padding by 100% (1x)
    double paddingMultiplier;
    if (deviceType == DeviceType.phone6Point5) {
      paddingMultiplier = 1.0;
    } else {
      paddingMultiplier = 2.0;
    }
    final increasedPadding = EdgeInsets.all(padding * paddingMultiplier);
    // For 6.5" phones, double the font size (100% increase)
    final fontMultiplier = (deviceType == DeviceType.phone6Point5) ? 2.0 : 1.0;

    return Container(
      width: double.infinity,
      color: FirebaseUploadService.anyAdminOverrideActive ? Colors.red[700] : Colors.green,
      padding: increasedPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Players: ${widget.selectedPlayers.length}',
            style: TextStyle(
              fontSize: (headerFontSize - 2) * 0.75 * fontMultiplier,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Closest Pin Purse: ',
                style: TextStyle(
                  fontSize: (headerFontSize - 4) * 0.75 * fontMultiplier,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black54),
                ),
                child: Text(
                  '\$${_remainingPurseAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: (headerFontSize - 4) * 0.75 * fontMultiplier,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _remainingClosestPins > 0 ? Colors.orange[200] : Colors.green[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black54),
            ),
            child: Text(
              'Remaining: $_remainingClosestPins / $_totalClosestPins',
              style: TextStyle(
                fontSize: (headerFontSize - 2) * 0.5 * fontMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DeviceDetectionService.getDeviceType(context);
    final padding = _getResponsivePadding(context);
    final reducedPadding = EdgeInsets.all(padding / 2);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: Padding(
                padding: reducedPadding,
                child: Container(
                  color: Colors.transparent,
                  child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,   //3 rows across
                  childAspectRatio: 5.3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: widget.selectedPlayers.length,
                itemBuilder: (context, index) {
                  return _buildPlayerGridItem(widget.selectedPlayers[index], index);
                },
                  ),
                ),
              ),
            ),
          ),
          closest_pin_ui.ClosestPinUIService.buildBottomButtons(
            context,
            onClear: _handleClear,
            onSaveAndReturn: _handleSaveAndReturn,
            isEnterSkatsEnabled: _remainingClosestPins == 0,
            league: 'Monday',
            onTied: _handleTied,
            isTiedMode: _tiedMode,
          ),
        ],
      ),
    );
  }
}