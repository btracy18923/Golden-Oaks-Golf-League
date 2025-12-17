import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DeviceType {
  phone6_5,
  tablet8,
  tablet10,
}

class ClosestPinUIService {
  
  /// Determines device type based on screen size
  static DeviceType getDeviceType(Size screenSize) {
    // Use shortest side for consistent device detection (matches DeviceDetectionService)
    final shortestSide = screenSize.shortestSide;

    // Device breakpoints using shortest side
    // 6.5" phone: shortestSide < 450
    // 8" tablet: 450 <= shortestSide < 650
    // 10" tablet: shortestSide >= 650
    if (shortestSide < 450) {
      return DeviceType.phone6_5;
    } else if (shortestSide < 650) {
      return DeviceType.tablet8;
    } else {
      return DeviceType.tablet10;
    }
  }

  /// Sets orientation preferences based on device type
  static void setOrientationForDevice(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = getDeviceType(screenSize);
    
    if (deviceType == DeviceType.phone6_5) {
      // Force landscape for 6" phones
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Allow all orientations for tablets
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Gets responsive padding based on device type
  static EdgeInsets getResponsivePadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.phone6_5:
        return const EdgeInsets.all(8.0);
      case DeviceType.tablet8:
        return const EdgeInsets.all(12.0);
      case DeviceType.tablet10:
        return const EdgeInsets.all(16.0);
    }
  }

  /// Gets responsive font size based on device type
  static double getResponsiveFontSize(DeviceType deviceType, {bool isHeader = false}) {
    if (isHeader) {
      switch (deviceType) {
        case DeviceType.phone6_5:
          return 18.0;
        case DeviceType.tablet8:
          return 22.0;
        case DeviceType.tablet10:
          return 26.0;
      }
    } else {
      switch (deviceType) {
        case DeviceType.phone6_5:
          return 14.0;
        case DeviceType.tablet8:
          return 16.0;
        case DeviceType.tablet10:
          return 18.0;
      }
    }
  }

  /// Gets cross axis count for grid based on device type and orientation
  static int getCrossAxisCount(DeviceType deviceType, Size screenSize) {
    final isLandscape = screenSize.width > screenSize.height;
    
    switch (deviceType) {
      case DeviceType.phone6_5:
        return isLandscape ? 2 : 1;
      case DeviceType.tablet8:
        return isLandscape ? 3 : 2;
      case DeviceType.tablet10:
        return isLandscape ? 4 : 2;
    }
  }

  /// Builds the header section with title and player count
  static Widget buildHeader(BuildContext context, int playerCount) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = getDeviceType(screenSize);
    final headerFontSize = getResponsiveFontSize(deviceType, isHeader: true);
    final padding = getResponsivePadding(deviceType);
    
    return Container(
      width: double.infinity,
      color: Colors.green[100],
      padding: padding,
      child: Column(
        children: [
          Text(
            'Closest Pin Contest',
            style: TextStyle(
              fontSize: headerFontSize + 4,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Selected Players: $playerCount',
            style: TextStyle(
              fontSize: headerFontSize - 2,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds a player card widget
  static Widget buildPlayerCard(Map<String, dynamic> player, DeviceType deviceType) {
    final fontSize = getResponsiveFontSize(deviceType);
    final padding = getResponsivePadding(deviceType);
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.all(4),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${player['first'] ?? ''} ${player['last'] ?? ''}',
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'SK#',
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${player['skat_number'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Handicap',
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${player['handicap']?.toStringAsFixed(1) ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!, width: 1),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  'Closest Pin Entry',
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the players grid
  static Widget buildPlayersGrid(
    BuildContext context,
    List<Map<String, dynamic>> selectedPlayers,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = getDeviceType(screenSize);
    final crossAxisCount = getCrossAxisCount(deviceType, screenSize);
    final padding = getResponsivePadding(deviceType);
    
    return Expanded(
      child: Padding(
        padding: padding,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: deviceType == DeviceType.phone6_5 ? 1.8 : 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: selectedPlayers.length,
          itemBuilder: (context, index) {
            return buildPlayerCard(selectedPlayers[index], deviceType);
          },
        ),
      ),
    );
  }

  /// Builds the bottom buttons section
  static Widget buildBottomButtons(
    BuildContext context, {
    required VoidCallback onClear,
    required VoidCallback onSaveAndReturn,
    bool isEnterSkatsEnabled = true,
    String league = 'Monday', // Add league parameter with default value
  }) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = getDeviceType(screenSize);
    final fontSize = getResponsiveFontSize(deviceType, isHeader: true);
    final padding = getResponsivePadding(deviceType);

    // Increase button bar and button height by 50% for 10" tablets
    final containerPaddingMultiplier = deviceType == DeviceType.tablet10 ? 0.6 : 0.4;
    final buttonPaddingMultiplier = deviceType == DeviceType.tablet10 ? 0.6 : 0.4;

    // Determine button text based on league
    final buttonText = league == 'Monday' ? 'Enter SKATS ---➤' : 'Enter Gross ---➤';

    // Determine button color based on league
    final buttonColor = league == 'Monday' ? Colors.green[200]! : Colors.orange[300]!;

    return Container(
      color: Colors.grey[300],
      padding: EdgeInsets.all(padding.left * containerPaddingMultiplier),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding.left / 2),
            child: SizedBox(
              width: screenSize.width * 0.25, // Same width as Enter button
              child: ElevatedButton(
                onPressed: onClear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[200]!,
                  padding: EdgeInsets.symmetric(vertical: padding.top * buttonPaddingMultiplier),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding.left / 2),
            child: SizedBox(
              width: screenSize.width * 0.25, // 50% smaller than half width
              child: ElevatedButton(
                onPressed: isEnterSkatsEnabled ? onSaveAndReturn : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnterSkatsEnabled ? buttonColor : Colors.grey[300]!,
                  padding: EdgeInsets.symmetric(vertical: padding.top * buttonPaddingMultiplier),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                    color: isEnterSkatsEnabled ? Colors.black : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles return navigation with proper orientation management
  static void handleReturn(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Navigator.pop(context);
  }

  /// Handles save results action
  static void handleSaveResults(BuildContext context) {
    // TODO: Implement save functionality for closest pin results
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Closest pin results saved!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}