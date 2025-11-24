import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/league.dart';
import '../shared/league_purse_service.dart';

/// Device type enumeration for responsive design
enum DeviceType { phone6_5, tablet8, tablet10 }

/// Service for building UI components for the enter scores screen
/// Contains reusable UI building methods extracted from new_monday_enter_scores_screen
/// Supports responsive design for 6.5" phone, 8" tablet, and 10" tablet
class EnterScoresUIService {
  
  /// Detects device type based on screen size
  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    if (isLandscape && screenWidth >= 750 && screenWidth < 900) {
      return DeviceType.phone6_5; // 6.5" phone in landscape
    } else if (screenWidth >= 900 && screenWidth < 1200) {
      return DeviceType.tablet8; // 8" tablet
    } else if (screenWidth >= 1200) {
      return DeviceType.tablet10; // 10" tablet
    } else {
      return DeviceType.phone6_5; // Default fallback
    }
  }
  
  /// Gets responsive spacing based on device type
  static EdgeInsets getResponsivePadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.phone6_5:
        return const EdgeInsets.all(4.0);
      case DeviceType.tablet8:
        return const EdgeInsets.all(8.0);
      case DeviceType.tablet10:
        return const EdgeInsets.all(12.0);
    }
  }
  
  /// Gets responsive font size based on device type
  static double getResponsiveFontSize(DeviceType deviceType, {bool isHeader = false}) {
    switch (deviceType) {
      case DeviceType.phone6_5:
        return isHeader ? 10.0 : 11.0;
      case DeviceType.tablet8:
        return isHeader ? 12.0 : 13.0;
      case DeviceType.tablet10:
        return isHeader ? 14.0 : 15.0;
    }
  }
  
  /// Gets responsive container height based on device type
  static double getResponsiveGroupHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.phone6_5:
        return 200.0; // Smaller for phone
      case DeviceType.tablet8:
        return 250.0; // Medium for 8" tablet
      case DeviceType.tablet10:
        return 300.0; // Larger for 10" tablet
    }
  }
  
  /// Gets responsive row height based on device type
  static double getResponsiveRowHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.phone6_5:
        return 32.0; // Compact for phone
      case DeviceType.tablet8:
        return 40.0; // Standard for 8" tablet
      case DeviceType.tablet10:
        return 48.0; // Larger for 10" tablet
    }
  }
  
  /// Sets orientation preferences based on device type
  /// Locks all devices to landscape mode for optimal golf scoring experience
  static void setOrientationForDevice(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phone6_5:
      case DeviceType.tablet8:
      case DeviceType.tablet10:
        // Lock all devices to landscape mode only for consistent golf scoring experience
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }
  
  /// Resets orientation to allow all orientations
  /// Call this when leaving the screen to restore normal behavior
  static void resetOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      //DeviceOrientation.portraitUp,
      //DeviceOrientation.portraitDown,
    ]);
  }
  
  /// Builds the purse header displaying league-specific purse amounts
  /// Responsive design adapts to different screen sizes
  /// Uses LeaguePurseService for dynamic purse management
  static Widget buildPurseHeader(BuildContext context, League league) {
    print("Using UI Service for ${league.name} league");
    final deviceType = getDeviceType(context);
    final fontSize = getResponsiveFontSize(deviceType, isHeader: true);
    final padding = getResponsivePadding(deviceType);
    
    // Get purse data from the league service
    final purseData = LeaguePurseService.getPurseHeaderData(league);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: padding.top / 2, 
        horizontal: padding.left
      ),
      color: Colors.green[300],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${LeaguePurseService.getPrimaryPurseLabel(league)} = ',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen[200],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      LeaguePurseService.formatPurseAmount(LeaguePurseService.getPrimaryPurse(league)),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Closest Pin Purse = ',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen[200],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      LeaguePurseService.formatPurseAmount(LeaguePurseService.closestPinPurse),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Mulligan Purse = ',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen[200],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      LeaguePurseService.formatPurseAmount(LeaguePurseService.mulliganPurse),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable groups grid containing all group rows
  /// Responsive design adapts spacing and layout to different screen sizes
  static Widget buildGroupsGrid(
    BuildContext context, 
    List<List<PlayerData>> groups, {
    Function(int groupIndex, int playerIndex, PlayerData player)? onPlayerTap,
    Function(int groupIndex, int playerIndex)? onEmptySlotTap,
    bool Function(PlayerData player)? isPlayerSelected,
    bool Function(int groupIndex, int playerIndex)? isEmptySlotSelected,
  }) {
    final deviceType = getDeviceType(context);
    final padding = getResponsivePadding(deviceType);
    final spacing = deviceType == DeviceType.phone6_5 ? 4.0 : 8.0;
    
    return Expanded(
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildGroupRow(
                context, 
                groups, 
                0, 
                1, 
                'Group 1', 
                'Group 2',
                onPlayerTap: onPlayerTap,
                onEmptySlotTap: onEmptySlotTap,
                isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected,
              ),
              SizedBox(height: spacing),
              buildGroupRow(
                context, 
                groups, 
                2, 
                3, 
                'Group 3', 
                'Group 4',
                onPlayerTap: onPlayerTap,
                onEmptySlotTap: onEmptySlotTap,
                isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected,
              ),
              SizedBox(height: spacing),
              buildGroupRow(
                context, 
                groups, 
                4, 
                5, 
                'Group 5', 
                'Group 6',
                onPlayerTap: onPlayerTap,
                onEmptySlotTap: onEmptySlotTap,
                isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected,
              ),
              SizedBox(height: spacing),
              buildGroupRow(
                context, 
                groups, 
                6, 
                7, 
                'Group 7', 
                'Group 8',
                onPlayerTap: onPlayerTap,
                onEmptySlotTap: onEmptySlotTap,
                isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected,
              ),
              SizedBox(height: spacing),
              buildGroupRow(
                context, 
                groups, 
                8, 
                9, 
                'Group 9', 
                'Group 10',
                onPlayerTap: onPlayerTap,
                onEmptySlotTap: onEmptySlotTap,
                isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a row containing two groups side by side
  /// Responsive design adapts spacing between groups
  static Widget buildGroupRow(
    BuildContext context, 
    List<List<PlayerData>> groups, 
    int leftIndex, 
    int rightIndex, 
    String leftTitle, 
    String rightTitle, {
    Function(int groupIndex, int playerIndex, PlayerData player)? onPlayerTap,
    Function(int groupIndex, int playerIndex)? onEmptySlotTap,
    bool Function(PlayerData player)? isPlayerSelected,
    bool Function(int groupIndex, int playerIndex)? isEmptySlotSelected,
  }) {
    final deviceType = getDeviceType(context);
    final spacing = deviceType == DeviceType.phone6_5 ? 4.0 : 8.0;
    
    return Row(
      children: [
        Expanded(
          child: buildGroup(
            context, 
            groups, 
            leftIndex, 
            leftTitle,
            onPlayerTap: onPlayerTap,
            onEmptySlotTap: onEmptySlotTap,
            isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: buildGroup(
            context, 
            groups, 
            rightIndex, 
            rightTitle,
            onPlayerTap: onPlayerTap,
            onEmptySlotTap: onEmptySlotTap,
            isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected,
          ),
        ),
      ],
    );
  }

  /// Builds an individual group container with header and player rows
  /// Responsive design adapts height, padding, and font sizes
  static Widget buildGroup(
    BuildContext context, 
    List<List<PlayerData>> groups, 
    int groupIndex, 
    String groupTitle, {
    Function(int groupIndex, int playerIndex, PlayerData player)? onPlayerTap,
    Function(int groupIndex, int playerIndex)? onEmptySlotTap,
    bool Function(PlayerData player)? isPlayerSelected,
    bool Function(int groupIndex, int playerIndex)? isEmptySlotSelected,
  }) {
    final deviceType = getDeviceType(context);
    final groupHeight = getResponsiveGroupHeight(deviceType);
    final fontSize = getResponsiveFontSize(deviceType, isHeader: true);
    final padding = getResponsivePadding(deviceType);
    
    return Container(
      height: groupHeight,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: padding.top / 4, 
              horizontal: padding.left
            ),
            child: Text(
              '-----$groupTitle-----',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          buildGroupHeader(context),
          Expanded(
            child: buildGroupRows(
              context, 
              groups, 
              groupIndex,
              onPlayerTap: onPlayerTap,
              onEmptySlotTap: onEmptySlotTap,
              isPlayerSelected: isPlayerSelected,
              isEmptySlotSelected: isEmptySlotSelected,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header row for a group with column titles
  /// Responsive design adapts height and styling
  static Widget buildGroupHeader(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        children: [
          buildHeaderCell(context, 'Name', flex: 2, hasLeftBorder: true),
          buildHeaderCell(context, 'SK #', flex: 1),
          buildHeaderCell(context, 'SKATS', flex: 1),
          buildHeaderCell(context, 'DIFF', flex: 1),
          buildHeaderCell(context, '\$\$\$', flex: 1),
        ],
      ),
    );
  }

  /// Builds a header cell with specified text and styling
  /// Responsive design adapts height, padding, and font size
  static Widget buildHeaderCell(BuildContext context, String text, {int flex = 1, bool hasLeftBorder = false}) {
    final deviceType = getDeviceType(context);
    final rowHeight = getResponsiveRowHeight(deviceType);
    final fontSize = getResponsiveFontSize(deviceType);
    final padding = getResponsivePadding(deviceType);
    
    return Expanded(
      flex: flex,
      child: Container(
        height: rowHeight,
        padding: EdgeInsets.all(padding.left / 2),
        decoration: BoxDecoration(
          border: Border(
            left: hasLeftBorder ? const BorderSide(color: Colors.black, width: 1) : BorderSide.none,
            right: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the rows for a specific group showing players or empty rows
  /// Responsive design adapts row generation
  static Widget buildGroupRows(
    BuildContext context, 
    List<List<PlayerData>> groups, 
    int groupIndex, {
    Function(int groupIndex, int playerIndex, PlayerData player)? onPlayerTap,
    Function(int groupIndex, int playerIndex)? onEmptySlotTap,
    bool Function(PlayerData player)? isPlayerSelected,
    bool Function(int groupIndex, int playerIndex)? isEmptySlotSelected,
  }) {
    return Column(
      children: List.generate(4, (rowIndex) {
        if (rowIndex < groups[groupIndex].length) {
          final player = groups[groupIndex][rowIndex];
          final isSelected = isPlayerSelected?.call(player) ?? false;
          
          return buildPlayerRow(
            context, 
            player,
            onPlayerTap: onPlayerTap != null 
              ? () => onPlayerTap(groupIndex, rowIndex, player)
              : null,
            isSelected: isSelected,
          );
        } else {
          final isSelected = isEmptySlotSelected?.call(groupIndex, rowIndex) ?? false;
          
          return buildEmptyRow(
            context,
            onTap: onEmptySlotTap != null 
              ? () => onEmptySlotTap(groupIndex, rowIndex)
              : null,
            isSelected: isSelected,
          );
        }
      }),
    );
  }

  /// Builds a row for a specific player with their data
  /// Responsive design adapts height and cell styling
  static Widget buildPlayerRow(BuildContext context, PlayerData player, {
    VoidCallback? onPlayerTap,
    bool isSelected = false,
  }) {
    final deviceType = getDeviceType(context);
    final rowHeight = getResponsiveRowHeight(deviceType);
    
    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        children: [
          buildClickablePlayerCell(context, player.name, flex: 2, hasLeftBorder: true, onTap: onPlayerTap, isSelected: isSelected),
          buildPlayerCell(context, player.skNumber, flex: 1),
          buildInputCell(context, player.skats, Colors.green[200], flex: 1, keyValue: '${player.name}_skats'),
          buildInputCell(context, player.diff, Colors.yellow[200], flex: 1, keyValue: '${player.name}_diff'),
          buildPlayerCell(context, player.money, flex: 1, isCurrency: true), // Format money as currency
        ],
      ),
    );
  }

  /// Builds an empty row when no player is assigned to that position
  /// Responsive design adapts height and cell styling
  static Widget buildEmptyRow(BuildContext context, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final deviceType = getDeviceType(context);
    final rowHeight = getResponsiveRowHeight(deviceType);
    
    // Selection background color
    Color? backgroundColor = isSelected ? Colors.orange[100] : null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          border: const Border(bottom: BorderSide(color: Colors.black, width: 1)),
          color: backgroundColor,
        ),
        child: Row(
          children: [
            buildPlayerCell(context, '', flex: 2, hasLeftBorder: true),
            buildPlayerCell(context, '', flex: 1),
            buildPlayerCell(context, '', flex: 1),
            buildPlayerCell(context, '', flex: 1),
            buildPlayerCell(context, '', flex: 1),
          ],
        ),
      ),
    );
  }

  /// Builds a cell for displaying player data (name, SK number, money)
  /// Responsive design adapts padding and font size, with bold formatting for data fields
  static Widget buildPlayerCell(BuildContext context, String text, {int flex = 1, bool hasLeftBorder = false, bool isCurrency = false}) {
    final deviceType = getDeviceType(context);
    final fontSize = getResponsiveFontSize(deviceType);
    final padding = getResponsivePadding(deviceType);
    
    // Format currency if this is a money field
    String displayText = text;
    if (isCurrency && text.isNotEmpty) {
      // Remove any existing currency symbols and parse as number
      final cleanText = text.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleanText.isNotEmpty) {
        final amount = double.tryParse(cleanText) ?? 0.0;
        displayText = '\$${amount.toStringAsFixed(2)}';
      }
    }
    
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.all(padding.left / 2),
        decoration: BoxDecoration(
          border: Border(
            left: hasLeftBorder ? const BorderSide(color: Colors.black, width: 1) : BorderSide.none,
            right: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Text(
          displayText,
          textAlign: flex == 2 ? TextAlign.left : TextAlign.center, // Left align for Name column (flex: 2), center for others
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold, // Make all data fields bold
          ),
        ),
      ),
    );
  }

  /// Builds a clickable cell for displaying player data (name, SK number, money)
  /// Responsive design adapts padding and font size, with bold formatting for data fields
  static Widget buildClickablePlayerCell(BuildContext context, String text, {int flex = 1, bool hasLeftBorder = false, bool isCurrency = false, VoidCallback? onTap, bool isSelected = false}) {
    final deviceType = getDeviceType(context);
    final fontSize = getResponsiveFontSize(deviceType);
    final padding = getResponsivePadding(deviceType);
    
    // Format currency if this is a money field
    String displayText = text;
    if (isCurrency && text.isNotEmpty) {
      // Remove any existing currency symbols and parse as number
      final cleanText = text.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleanText.isNotEmpty) {
        final amount = double.tryParse(cleanText) ?? 0.0;
        displayText = '\$${amount.toStringAsFixed(2)}';
      }
    }
    
    // Selection background color for the cell
    Color? backgroundColor = isSelected ? Colors.blue[100] : null;
    
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(padding.left / 2),
          decoration: BoxDecoration(
            border: Border(
              left: hasLeftBorder ? const BorderSide(color: Colors.black, width: 1) : BorderSide.none,
              right: const BorderSide(color: Colors.black, width: 1),
            ),
            color: backgroundColor,
          ),
          child: Text(
            displayText,
            textAlign: flex == 2 ? TextAlign.left : TextAlign.center, // Left align for Name column (flex: 2), center for others
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold, // Make all data fields bold
              color: onTap != null ? Colors.blue[700] : Colors.black, // Blue color for clickable text
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an input cell for editable data (skats, diff)
  /// Responsive design adapts padding and font size, with bold formatting for data fields
  static Widget buildInputCell(BuildContext context, String value, Color? backgroundColor, {int flex = 1, String? keyValue}) {
    final deviceType = getDeviceType(context);
    final fontSize = getResponsiveFontSize(deviceType);
    final padding = getResponsivePadding(deviceType);
    
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: const Border(right: BorderSide(color: Colors.black, width: 1)),
          color: backgroundColor,
        ),
        child: Center(
          child: TextFormField(
            key: keyValue != null ? Key('${keyValue}_$value') : null,
            initialValue: value,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold, // Make input fields bold
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ),
    );
  }

  /// Builds the bottom buttons row with navigation and action buttons
  /// Responsive design adapts padding and button sizing
  static Widget buildBottomButtons(BuildContext context, {
    VoidCallback? onReturn,
    VoidCallback? onClosestPin,
    VoidCallback? onAutoFill,
    VoidCallback? onSwapPlayers,
  }) {
    final deviceType = getDeviceType(context);
    final padding = getResponsivePadding(deviceType);
    
    return Container(
      color: Colors.grey[300],
      padding: EdgeInsets.all(padding.left / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildBottomButton(context, 'Return', Colors.blue[200]!, onReturn ?? () => Navigator.pop(context)),
          buildBottomButton(context, 'Closest Pin', Colors.green[200]!, onClosestPin ?? () {}),
          buildBottomButton(context, 'Auto Fill', Colors.orange[200]!, onAutoFill ?? () {}),
          buildBottomButton(context, 'SWAP Players', Colors.grey[400]!, onSwapPlayers ?? () {}),
        ],
      ),
    );
  }

  /// Builds an individual bottom button with specified styling
  /// Responsive design adapts padding, font size, and button height
  static Widget buildBottomButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    final deviceType = getDeviceType(context);
    final fontSize = getResponsiveFontSize(deviceType, isHeader: true);
    final padding = getResponsivePadding(deviceType);
    
    // Adjust button text for smaller screens
    String displayText = text;
    if (deviceType == DeviceType.phone6_5) {
      if (text == 'Closest Pin') displayText = 'ClosePin';
      if (text == 'SWAP Players') displayText = 'SWAP';
    }
    
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding.left / 2),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(vertical: padding.top / 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class representing a player in a group
class PlayerData {
  String name;
  String skNumber;
  String skats;
  String diff;
  String money;

  PlayerData({
    required this.name,
    required this.skNumber,
    this.skats = '',
    this.diff = '',
    this.money = '',
  });
}