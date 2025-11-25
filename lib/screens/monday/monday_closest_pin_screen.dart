import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/UI/closest_pin_UI_service.dart';
import '../../services/shared/league_purse_service.dart';

class MondayClosestPinScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  
  const MondayClosestPinScreen({Key? key, required this.selectedPlayers}) : super(key: key);

  @override
  _MondayClosestPinScreenState createState() => _MondayClosestPinScreenState();
}

class _MondayClosestPinScreenState extends State<MondayClosestPinScreen> {
  late int _totalClosestPins;
  late int _remainingClosestPins;
  late double _closestPinValue;
  late double _remainingPurseAmount;
  Map<String, int> _playerClosestPinCounts = {};
  Map<String, double> _playerWinnings = {};
  @override
  void initState() {
    super.initState();
    
    // Calculate total closest pins to process (closestPinAmount / $1.00)
    double closestPinAmount = LeaguePurseService.closestPinAmount;
    _totalClosestPins = (closestPinAmount / 1.0).round();
    _remainingClosestPins = _totalClosestPins;
    
    // Calculate the value per closest pin (Closest Pin Purse / initial remaining amount)
    _closestPinValue = LeaguePurseService.closestPinPurse / _totalClosestPins;
    
    // Initialize remaining purse amount to track decreases
    _remainingPurseAmount = LeaguePurseService.closestPinPurse;
    
    // Initialize player closest pin counts and winnings
    for (var player in widget.selectedPlayers) {
      String lastName = player['last'] ?? 'Unknown';
      _playerClosestPinCounts[lastName] = 0;
      _playerWinnings[lastName] = 0.0;
    }
    
    // Lock screen to landscape mode only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  void _handleReturn() {
    ClosestPinUIService.handleReturn(context);
  }

  void _handleSaveResults() {
    ClosestPinUIService.handleSaveResults(context);
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

  Widget _buildPlayerGridItem(Map<String, dynamic> player, int index) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = ClosestPinUIService.getDeviceType(screenSize);
    final fontSize = ClosestPinUIService.getResponsiveFontSize(deviceType);
    final padding = ClosestPinUIService.getResponsivePadding(deviceType);
    
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
            color: closestPinCount > 0 ? Colors.green[300]! : Colors.grey[300]!, 
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
                  fontSize: fontSize - 2,
                  fontWeight: FontWeight.bold,
                  color: closestPinCount > 0 ? Colors.green[800] : Colors.black,
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
              decoration: BoxDecoration(
                color: closestPinCount > 0 ? Colors.green[200] : Colors.grey[100],
                border: Border.all(
                  color: closestPinCount > 0 ? Colors.green[400]! : Colors.grey[400]!,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$closestPinCount',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.bold,
                    color: closestPinCount > 0 ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.only(right: 4),
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: winnings > 0 ? Colors.blue[100] : Colors.grey[50],
                  border: Border.all(
                    color: winnings > 0 ? Colors.blue[300]! : Colors.grey[300]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  winnings > 0 ? '\$${winnings.round()}' : '\$0',
                  style: TextStyle(
                    fontSize: fontSize - 3,
                    fontWeight: FontWeight.w600,
                    color: winnings > 0 ? Colors.blue[800] : Colors.grey[500],
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
    final screenSize = MediaQuery.of(context).size;
    final deviceType = ClosestPinUIService.getDeviceType(screenSize);
    final headerFontSize = ClosestPinUIService.getResponsiveFontSize(deviceType, isHeader: true);
    final padding = ClosestPinUIService.getResponsivePadding(deviceType);
    final increasedPadding = EdgeInsets.all(padding.left * 0.5); // 100% increase from current
    
    return Container(
      width: double.infinity,
      color: Colors.green,
      padding: increasedPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Players: ${widget.selectedPlayers.length}',
            style: TextStyle(
              fontSize: (headerFontSize - 2) * 0.75,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'Closest Pin Purse: \$${_remainingPurseAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: (headerFontSize - 4) * 0.75,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _remainingClosestPins > 0 ? Colors.orange[200] : Colors.green[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black54),
            ),
            child: Text(
              'Remaining: $_remainingClosestPins / $_totalClosestPins',
              style: TextStyle(
                fontSize: (headerFontSize - 2) * 0.5,
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
    final screenSize = MediaQuery.of(context).size;
    final deviceType = ClosestPinUIService.getDeviceType(screenSize);
    final padding = ClosestPinUIService.getResponsivePadding(deviceType);
    final reducedPadding = EdgeInsets.all(padding.left / 2);
    
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
          ClosestPinUIService.buildBottomButtons(
            context,
            onReturn: _handleReturn,
            onSaveResults: _handleSaveResults,
          ),
        ],
      ),
    );
  }
}