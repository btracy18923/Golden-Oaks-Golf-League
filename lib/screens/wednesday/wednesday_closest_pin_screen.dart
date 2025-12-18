import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/UI/closest_pin_UI_service.dart' as ClosestPinUI;
import '../../services/shared/league_purse_service.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import '../../models/league.dart';
import 'wednesday_parent_screen.dart';
import 'wednesday_results_screen.dart';
import '../../services/screen_data_retention_service.dart';

class WednesdayClosestPinScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  final List<List<Map<String, dynamic>?>>? groups;
  final double? groupPurseAmount;
  final double? groupPayoutAmount;
  final double? adjustedMulliganPurse;
  final List<Map<String, dynamic>>? individualWinners;
  final double? playersAnte;
  final double? closestPinAmount;
  final double? mulliganAmount;

  const WednesdayClosestPinScreen({
    Key? key,
    required this.selectedPlayers,
    this.groups,
    this.groupPurseAmount,
    this.groupPayoutAmount,
    this.adjustedMulliganPurse,
    this.individualWinners,
    this.playersAnte,
    this.closestPinAmount,
    this.mulliganAmount,
  }) : super(key: key);

  @override
  _WednesdayClosestPinScreenState createState() => _WednesdayClosestPinScreenState();
}

class _WednesdayClosestPinScreenState extends State<WednesdayClosestPinScreen> {
  late int _totalClosestPins;
  late int _remainingClosestPins;
  late double _closestPinValue;
  late double _remainingPurseAmount;
  late double _initialPurseAmount; // Store the original purse amount for Clear button
  Map<String, int> _playerClosestPinCounts = {};
  Map<String, double> _playerWinnings = {};
  @override
  void initState() {
    super.initState();

    // Calculate Closest Pin Purse based on number of selected players
    // Wednesday league has only 1 closest pin (not 4 like Monday)
    // Each player contributes $1.00 to the single closest pin purse
    double closestPinAmount = LeaguePurseService.getClosestPinAmount(league: League.wednesday);
    double calculatedPurse = closestPinAmount * widget.selectedPlayers.length;

    // Set the purse explicitly
    LeaguePurseService.setClosestPinPurse(calculatedPurse, isExplicit: false);

    // Store the initial purse amount for Clear button resets
    _initialPurseAmount = calculatedPurse;

    // Wednesday has only 1 closest pin to award (not 4 like Monday)
    _totalClosestPins = 1;
    _remainingClosestPins = _totalClosestPins;

    // Calculate the value per closest pin (entire purse goes to the single winner)
    _closestPinValue = _initialPurseAmount;

    // Initialize remaining purse amount to track decreases
    _remainingPurseAmount = _initialPurseAmount;

    // Initialize player closest pin counts and winnings
    for (var player in widget.selectedPlayers) {
      String lastName = player['last'] ?? 'Unknown';
      _playerClosestPinCounts[lastName] = 0;
      _playerWinnings[lastName] = 0.0;
    }

    // Lock screen to landscape mode only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use DeviceDetectionService for consistent device detection
      final deviceType = DeviceDetectionService.getDeviceType(context);
      final deviceName = DeviceDetectionService.getDeviceName(context);

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
      // Wednesday has only 1 closest pin to award
      _totalClosestPins = 1;
      _remainingClosestPins = _totalClosestPins;
      _closestPinValue = _initialPurseAmount;
      _remainingPurseAmount = _initialPurseAmount;

      // Reset all player counts and winnings to 0
      for (var player in widget.selectedPlayers) {
        String lastName = player['last'] ?? 'Unknown';
        _playerClosestPinCounts[lastName] = 0;
        _playerWinnings[lastName] = 0.0;
      }
    });
  }

  void _handleSaveAndReturn() {
    // Save closest pin data to retention service
    final retentionService = ScreenDataRetentionService();
    retentionService.captureClosestPinData(
      playerClosestPinCounts: _playerClosestPinCounts,
      playerClosestPinWinnings: _playerWinnings,
      remainingClosestPinPurse: _remainingPurseAmount,
      totalClosestPins: _totalClosestPins,
      remainingClosestPins: _remainingClosestPins,
    );

    // Check if we have groups data (came from enter scores screen)
    if (widget.groups != null &&
        widget.groupPurseAmount != null &&
        widget.groupPayoutAmount != null &&
        widget.adjustedMulliganPurse != null) {
      // Navigate to Wednesday Results Screen with group data and individual winners
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WednesdayResultsScreen(
            groupPurseAmount: widget.groupPurseAmount!,
            groupPayoutAmount: widget.groupPayoutAmount!,
            adjustedMulliganPurse: widget.adjustedMulliganPurse!,
            groups: widget.groups!,
            individualWinners: widget.individualWinners ?? [],
            playersAnte: widget.playersAnte ?? 0.0,
            closestPinAmount: widget.closestPinAmount ?? 0.0,
            mulliganAmount: widget.mulliganAmount ?? 0.0,
          ),
        ),
      );
    } else {
      // No groups data - came from player selection screen, return to parent
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const WednesdayParentScreen(),
        ),
        (route) => false,
      );
    }
  }

  void _handlePlayerTap(String lastName) {
    if (_remainingClosestPins > 0) {
      setState(() {
        _playerClosestPinCounts[lastName] = _playerClosestPinCounts[lastName]! + 1;
        _remainingClosestPins--;
        // Increase player's winnings by the fixed closest pin value
        _playerWinnings[lastName] = _playerClosestPinCounts[lastName]! * _closestPinValue;
        // Decrease the remaining purse amount by the closest pin value
        _remainingPurseAmount -= _closestPinValue;
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
      case DeviceType.tablet8Inch:
        return 12.0;
      case DeviceType.tablet10Inch:
        return 16.0;
    }
  }

  Widget _buildPlayerGridItem(Map<String, dynamic> player, int index) {
    final deviceType = DeviceDetectionService.getDeviceType(context);
    final fontSize = ResponsiveTypography.getBodyText(context);
    final padding = _getResponsivePadding(context);

    String lastName = player['last'] ?? 'Unknown';
    int closestPinCount = _playerClosestPinCounts[lastName] ?? 0;
    double winnings = _playerWinnings[lastName] ?? 0.0;

    // Calculate container height based on font size with minimal padding
    double containerHeight = fontSize + 2; // font size + minimal padding (1px top + 1px bottom)
    double countSize = (containerHeight - 1) * 2; // 100% wider (double the size)

    return GestureDetector(
      onTap: () => _handlePlayerTap(lastName),
      child: Container(
        height: containerHeight,
        margin: EdgeInsets.all(2),
        padding: EdgeInsets.fromLTRB(1, 1, 6, 1), // Extra padding on right side
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: closestPinCount > 0 ? Colors.orange[300]! : Colors.grey[300]!,
            width: closestPinCount > 0 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
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
                  fontSize: deviceType == DeviceType.phone6Point5 ? 18 : fontSize + 3,
                  fontWeight: FontWeight.bold,
                  color: closestPinCount > 0 ? Colors.blue[300] : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),
            Container(
              width: countSize,
              height: countSize,
              margin: EdgeInsets.only(right: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: closestPinCount > 0 ? Colors.orange[300] : Colors.grey[100],
                border: Border.all(
                  color: closestPinCount > 0 ? Colors.blue[700]! : Colors.grey[400]!,
                  width: 1,
                ),
              ),
              child: Text(
                '$closestPinCount',
                style: TextStyle(
                  fontSize: deviceType == DeviceType.tablet10Inch ? fontSize + 2 : fontSize - 0,
                  fontWeight: FontWeight.bold,
                  color: closestPinCount > 0 ? Colors.blue[700] : Colors.grey[600],
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
                margin: EdgeInsets.only(right: 4),
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
    // For 6.5" phones, increase padding by 200% (2x) to increase height by 100%
    // For 8" tablets, increase padding by 150% (1.5x) to increase height
    double paddingMultiplier;
    if (deviceType == DeviceType.phone6Point5) {
      paddingMultiplier = 2.0;
    } else if (deviceType == DeviceType.tablet8Inch) {
      paddingMultiplier = 1.5;
    } else {
      paddingMultiplier = 0.5;
    }
    final increasedPadding = EdgeInsets.all(padding * paddingMultiplier);
    // For 6.5" phones and 8" tablets, double the font size (100% increase)
    final fontMultiplier = (deviceType == DeviceType.phone6Point5 || deviceType == DeviceType.tablet8Inch) ? 2.0 : 1.0;

    return Container(
      width: double.infinity,
      color: Colors.orange[300],
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _remainingClosestPins > 0 ? Colors.orange[200] : Colors.orange[200],
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
    final deviceType = DeviceDetectionService.getDeviceType(context);
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
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
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
          ClosestPinUI.ClosestPinUIService.buildBottomButtons(
            context,
            onClear: _handleClear,
            onSaveAndReturn: _handleSaveAndReturn,
            isEnterSkatsEnabled: _remainingPurseAmount == 0.0,
            league: 'Wednesday',
          ),
        ],
      ),
    );
  }
}
