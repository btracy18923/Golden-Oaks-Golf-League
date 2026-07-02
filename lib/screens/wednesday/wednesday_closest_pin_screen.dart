import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/UI/closest_pin_UI_service.dart' as closest_pin_ui;
import '../../services/shared/league_purse_service.dart';
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';
import '../../models/league.dart';
import 'wednesday_parent_screen.dart';
import 'wednesday_results_screen.dart';
import '../../services/firebase_upload_service.dart';
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
    super.key,
    required this.selectedPlayers,
    this.groups,
    this.groupPurseAmount,
    this.groupPayoutAmount,
    this.adjustedMulliganPurse,
    this.individualWinners,
    this.playersAnte,
    this.closestPinAmount,
    this.mulliganAmount,
  });

  @override
  _WednesdayClosestPinScreenState createState() => _WednesdayClosestPinScreenState();
}

class _WednesdayClosestPinScreenState extends State<WednesdayClosestPinScreen> {
  late int _totalClosestPins;
  late int _remainingClosestPins;
  late double _closestPinValue;
  late double _remainingPurseAmount;
  late double _initialPurseAmount; // Store the original purse amount for Clear button
  final Map<String, double> _playerClosestPinCounts = {}; // Changed to double to support fractional counts
  final Map<String, double> _playerWinnings = {};
  bool _tiedMode = false; // Track if tied mode is active
  final List<String> _tiedPlayers = []; // Track players in the tie
  bool _tiedIsRedo = false; // True when rebuilding a tie over an already-used pin
  @override
  void initState() {
    super.initState();

    // Calculate Closest Pin Purse based on number of selected players
    // Wednesday league has 2 closest pins; each player contributes $1.00
    double closestPinAmount = LeaguePurseService.getClosestPinAmount(league: League.wednesday);
    double totalPurse = closestPinAmount * widget.selectedPlayers.length;

    // Round down to even so the purse splits equally between 2 winners.
    // Any remainder (odd player count) rolls into the mulligan purse.
    double effectivePurse = (totalPurse / 2).floorToDouble() * 2;
    double overage = totalPurse - effectivePurse;
    if (overage > 0) {
      LeaguePurseService.setMulliganPurse(
        LeaguePurseService.mulliganPurse + overage,
        isExplicit: true,
      );
    }

    // Set the purse explicitly
    LeaguePurseService.setClosestPinPurse(effectivePurse, isExplicit: false);

    // Store the effective purse for Clear button resets
    _initialPurseAmount = effectivePurse;

    // Wednesday has 2 closest pins to award
    _totalClosestPins = 2;
    _remainingClosestPins = _totalClosestPins;

    // Each winner receives half the effective purse
    _closestPinValue = effectivePurse / 2;

    // Initialize remaining purse amount to track decreases
    _remainingPurseAmount = effectivePurse;

    // Initialize player closest pin counts and winnings
    for (var player in widget.selectedPlayers) {
      String lastName = player['last'] ?? 'Unknown';
      _playerClosestPinCounts[lastName] = 0.0;
      _playerWinnings[lastName] = 0.0;
    }

    // Lock screen to landscape mode only
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      // Wednesday has 2 closest pins to award
      _totalClosestPins = 2;
      _remainingClosestPins = _totalClosestPins;
      _closestPinValue = _initialPurseAmount / 2;
      _remainingPurseAmount = _initialPurseAmount;

      // Reset all player counts and winnings to 0
      for (var player in widget.selectedPlayers) {
        String lastName = player['last'] ?? 'Unknown';
        _playerClosestPinCounts[lastName] = 0.0;
        _playerWinnings[lastName] = 0.0;
      }

      // Reset tied mode and tied players list
      _tiedMode = false;
      _tiedIsRedo = false;
      _tiedPlayers.clear();
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

  void _handleTied() {
    setState(() {
      if (_tiedMode) {
        // Second press of Tied = confirm/resolve the tie
        if (_tiedPlayers.isNotEmpty && !_tiedIsRedo) {
          // Fresh tie: consume one pin slot now
          _remainingClosestPins--;
          _remainingPurseAmount -= _closestPinValue;
        }
        _tiedMode = false;
        _tiedIsRedo = false;
        _tiedPlayers.clear();
      } else {
        // First press of Tied = enter tied mode
        // Rebuild list from any player already assigned a pin (redo scenario)
        for (var entry in _playerClosestPinCounts.entries) {
          if (entry.value > 0 && entry.value <= 1.0) {
            _tiedPlayers.add(entry.key);
          }
        }
        _tiedIsRedo = _tiedPlayers.isNotEmpty;
        _tiedMode = true;
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
          // Add player to tied list (toggle off if already there)
          if (_tiedPlayers.contains(lastName)) {
            _tiedPlayers.remove(lastName);
          } else {
            _tiedPlayers.add(lastName);
          }

          // Show live split across all tied players (no pin consumed yet)
          if (_tiedPlayers.isNotEmpty) {
            double splitAmount = _closestPinValue / _tiedPlayers.length;
            double fractionalCount = 1.0 / _tiedPlayers.length;
            for (String playerName in _tiedPlayers) {
              _playerClosestPinCounts[playerName] = fractionalCount;
              _playerWinnings[playerName] = splitAmount;
            }
          }
          // Pin is consumed when Tied button is pressed again to confirm
        } else {
          // Normal mode - single winner gets full amount
          _playerClosestPinCounts[lastName] = _playerClosestPinCounts[lastName]! + 1.0;
          _remainingClosestPins--;
          // Increase player's winnings by the fixed closest pin value
          _playerWinnings[lastName] = _playerClosestPinCounts[lastName]! * _closestPinValue;
          // Decrease the remaining purse amount by the closest pin value
          _remainingPurseAmount -= _closestPinValue;
        }
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

  Widget _buildPlayerGridItem(Map<String, dynamic> player, int index) {
    final deviceType = DeviceDetectionService.getDeviceType(context);
    final fontSize = ResponsiveTypography.getBodyText(context);

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
            color: closestPinCount > 0 ? Colors.orange[300]! : Colors.grey[300]!,
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
                  color: closestPinCount > 0 ? Colors.blue[300] : Colors.black,
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
                color: closestPinCount > 0 ? Colors.blue[100] : Colors.grey[100],
                border: Border.all(
                  color: closestPinCount > 0 ? Colors.blue[700]! : Colors.grey[400]!,
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
      color: FirebaseUploadService.anyAdminOverrideActive ? Colors.red[700] : Colors.orange[300],
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              color: Colors.orange[200],
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
                  crossAxisCount: 3,
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
            isEnterSkatsEnabled: _remainingPurseAmount == 0.0,
            league: 'Wednesday',
            onTied: _handleTied,
            isTiedMode: _tiedMode,
          ),
        ],
      ),
    );
  }
}
