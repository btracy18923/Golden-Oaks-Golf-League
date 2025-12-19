import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/league.dart';
import '../shared/league_purse_service.dart';
import '../responsive_typography.dart';
import '../device_detection_service.dart';
import 'button_bar_UI_service.dart';

/// Device type enumeration for responsive design
enum DeviceType { phone6_5, tablet8, tablet10 }

/// League-specific UI configuration for Enter Scores screens
class LeagueUIConfig {
  final Color headerColor;
  final Color headerValueBackground;
  final Color inputCellColor;
  final Color selectedColor;
  final Color buttonBarColor;

  const LeagueUIConfig({
    required this.headerColor,
    required this.headerValueBackground,
    required this.inputCellColor,
    required this.selectedColor,
    required this.buttonBarColor,
  });

  /// Monday league green color scheme
  static const monday = LeagueUIConfig(
    headerColor: Color(0xFF81C784), // Colors.green[300]
    headerValueBackground: Color(0xFFFFFFFF), // Colors.white
    inputCellColor: Color(0xFFFFF59D), // Colors.yellow[200]
    selectedColor: Color(0xFFBBDEFB), // Colors.blue[100]
    buttonBarColor: Color(0xFFE0E0E0), // Colors.grey[300]
  );

  /// Wednesday league orange color scheme
  static const wednesday = LeagueUIConfig(
    headerColor: Color(0xFFFFCC80), // Colors.orange[200]
    headerValueBackground: Color(0xFFFFFFFF), // Colors.white
    inputCellColor: Color(0xFFFFD700), // Gold
    selectedColor: Color(0xFFFFFF00), // Yellow
    buttonBarColor: Color(0xFFFFE0B2), // Colors.orange[100]
  );

  /// Get config for a specific league
  static LeagueUIConfig forLeague(League league) {
    switch (league) {
      case League.monday:
        return monday;
      case League.wednesday:
        return wednesday;
    }
  }
}

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
        return isHeader ? 8.0 : 11.0;
      case DeviceType.tablet8:
        return isHeader ? 12.0 : 13.0;
      case DeviceType.tablet10:
        return isHeader ? 14.0 : 15.0;
    }
  }

  /// Gets purse header label font size based on device type
  /// Uses base label size from ResponsiveTypography with a multiplier for fine-tuning
  static double getPurseHeaderFontSize(BuildContext context) {
    return ResponsiveTypography.getLabel(context) * .85;
  }

  /// Gets table header font size based on device type (Name, SK #, SKATS, DIFF, $$$)
  /// Uses base table header size from ResponsiveTypography with a multiplier for fine-tuning
  static double getTableHeaderFontSize(BuildContext context) {
    return ResponsiveTypography.getTableHeader(context) * .85;
  }

  /// Gets group header font size based on device type (-----Group 1-----)
  /// Uses base heading size from ResponsiveTypography with a multiplier for fine-tuning
  static double getGroupHeaderFontSize(BuildContext context) {
    return ResponsiveTypography.getHeading(context) * .85;
  }

  /// Gets table data row font size based on device type (player names, SK numbers, SKATS, DIFF, money)
  /// Uses base small text size from ResponsiveTypography with a multiplier for fine-tuning
  static double getTableDataFontSize(BuildContext context) {
    return ResponsiveTypography.getSmall(context) * .85;
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
  /// [onReturn] - Optional callback for left arrow return functionality
  /// [onAutoFill] - Optional callback for storage icon auto-fill functionality
  static Widget buildPurseHeader(BuildContext context, League league, {VoidCallback? onReturn, VoidCallback? onAutoFill}) {
    //print("Using UI Service for ${league.name} league");
    final deviceType = getDeviceType(context);
    final fontSize = getResponsiveFontSize(deviceType, isHeader: true);
    final headerFontSize = getPurseHeaderFontSize(context);
    final padding = getResponsivePadding(deviceType);
    
    // Get purse data from the league service
    LeaguePurseService.getPurseHeaderData(league);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: padding.top / 2, 
        horizontal: padding.left
      ),
      color: Colors.green[300],
      child: Row(
        children: [

          // Purse information section
          Expanded(
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
                  Flexible(
                    child: Text(
                      '${LeaguePurseService.getPrimaryPurseLabel(league)} = ',
                      style: TextStyle(
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        LeaguePurseService.formatPurseAmount(LeaguePurseService.getPrimaryPurse(league)),
                        style: TextStyle(
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ClosePin Purse = ',
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    LeaguePurseService.formatPurseAmount(LeaguePurseService.closestPinPurse),
                    style: TextStyle(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '    Mulligan Purse = ',
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    LeaguePurseService.formatPurseAmount(LeaguePurseService.mulliganPurse),
                    style: TextStyle(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
              ],
            ),
          ),
          // Storage icon button for Auto Fill
          if (onAutoFill != null)
            GestureDetector(
              onTap: onAutoFill,
            child: Container(
              width: fontSize * 3.0,
              height: fontSize * 2.0,
              margin: EdgeInsets.only(left: padding.left / 2),
              decoration: const BoxDecoration(
                //border: Border.all(color: Colors.black, width: 1),
                //borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.black,
                  size: fontSize * 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable groups grid containing all group rows
  /// Responsive design adapts spacing and layout to different screen sizes
  /// 10" tablets show 3 columns, other devices show 2 columns
  static Widget buildGroupsGrid(
    BuildContext context,
    List<List<PlayerData>> groups, {
    Function(int groupIndex, int playerIndex, PlayerData player)? onPlayerTap,
    Function(int groupIndex, int playerIndex)? onEmptySlotTap,
    bool Function(PlayerData player)? isPlayerSelected,
    bool Function(int groupIndex, int playerIndex)? isEmptySlotSelected,
    Function(PlayerData, String)? onSkatsChanged,
    List<List<FocusNode?>>? skatsFocusNodes,
    bool Function(PlayerData player)? isPlayerFocused,
  }) {
    final deviceType = getDeviceType(context);
    final padding = getResponsivePadding(deviceType);
    final spacing = deviceType == DeviceType.phone6_5 ? 4.0 : 8.0;

    // Use 3-column layout for 10" tablets, 2-column for other devices
    if (deviceType == DeviceType.tablet10) {
      return Expanded(
        child: Padding(
          padding: padding,
          child: SingleChildScrollView(
            child: Column(
              children: [
                buildGroupRowThreeColumn(
                  context,
                  groups,
                  0,
                  1,
                  2,
                  'Group 1',
                  'Group 2',
                  'Group 3',
                  onPlayerTap: onPlayerTap,
                  onEmptySlotTap: onEmptySlotTap,
                  isPlayerSelected: isPlayerSelected,
                  isEmptySlotSelected: isEmptySlotSelected,
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
                ),
                SizedBox(height: spacing),
                buildGroupRowThreeColumn(
                  context,
                  groups,
                  3,
                  4,
                  5,
                  'Group 4',
                  'Group 5',
                  'Group 6',
                  onPlayerTap: onPlayerTap,
                  onEmptySlotTap: onEmptySlotTap,
                  isPlayerSelected: isPlayerSelected,
                  isEmptySlotSelected: isEmptySlotSelected,
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
                ),
                SizedBox(height: spacing),
                buildGroupRowThreeColumn(
                  context,
                  groups,
                  6,
                  7,
                  8,
                  'Group 7',
                  'Group 8',
                  'Group 9',
                  onPlayerTap: onPlayerTap,
                  onEmptySlotTap: onEmptySlotTap,
                  isPlayerSelected: isPlayerSelected,
                  isEmptySlotSelected: isEmptySlotSelected,
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
                ),
                SizedBox(height: spacing),
                buildGroupRow(
                  context,
                  groups,
                  9,
                  -1, // Use -1 to indicate no second group
                  'Group 10',
                  '',
                  onPlayerTap: onPlayerTap,
                  onEmptySlotTap: onEmptySlotTap,
                  isPlayerSelected: isPlayerSelected,
                  isEmptySlotSelected: isEmptySlotSelected,
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // 2-column layout for other devices
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
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
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
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
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
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
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
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
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
                  onSkatsChanged: onSkatsChanged,
                  skatsFocusNodes: skatsFocusNodes,
                  isPlayerFocused: isPlayerFocused,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// Builds a row containing two groups side by side
  /// Responsive design adapts spacing between groups
  /// If rightIndex is -1, only displays the left group
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
    Function(PlayerData, String)? onSkatsChanged,
    List<List<FocusNode?>>? skatsFocusNodes,
    bool Function(PlayerData player)? isPlayerFocused,
  }) {
    final deviceType = getDeviceType(context);
    final spacing = deviceType == DeviceType.phone6_5 ? 4.0 : 8.0;

    // If rightIndex is -1, only show left group
    if (rightIndex == -1) {
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
              onSkatsChanged: onSkatsChanged,
              skatsFocusNodes: skatsFocusNodes,
              isPlayerFocused: isPlayerFocused,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(child: Container()), // Empty space to maintain layout
        ],
      );
    }

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
            onSkatsChanged: onSkatsChanged,
            skatsFocusNodes: skatsFocusNodes,
            isPlayerFocused: isPlayerFocused,
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
            onSkatsChanged: onSkatsChanged,
            skatsFocusNodes: skatsFocusNodes,
            isPlayerFocused: isPlayerFocused,
          ),
        ),
      ],
    );
  }

  /// Builds a row containing three groups side by side (for 10" tablets)
  /// Responsive design adapts spacing between groups
  static Widget buildGroupRowThreeColumn(
    BuildContext context,
    List<List<PlayerData>> groups,
    int firstIndex,
    int secondIndex,
    int thirdIndex,
    String firstTitle,
    String secondTitle,
    String thirdTitle, {
    Function(int groupIndex, int playerIndex, PlayerData player)? onPlayerTap,
    Function(int groupIndex, int playerIndex)? onEmptySlotTap,
    bool Function(PlayerData player)? isPlayerSelected,
    bool Function(int groupIndex, int playerIndex)? isEmptySlotSelected,
    Function(PlayerData, String)? onSkatsChanged,
    List<List<FocusNode?>>? skatsFocusNodes,
    bool Function(PlayerData player)? isPlayerFocused,
  }) {
    final deviceType = getDeviceType(context);
    final spacing = deviceType == DeviceType.phone6_5 ? 4.0 : 8.0;

    return Row(
      children: [
        Expanded(
          child: buildGroup(
            context,
            groups,
            firstIndex,
            firstTitle,
            onPlayerTap: onPlayerTap,
            onEmptySlotTap: onEmptySlotTap,
            isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected,
            onSkatsChanged: onSkatsChanged,
            skatsFocusNodes: skatsFocusNodes,
            isPlayerFocused: isPlayerFocused,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: buildGroup(
            context,
            groups,
            secondIndex,
            secondTitle,
            onPlayerTap: onPlayerTap,
            onEmptySlotTap: onEmptySlotTap,
            isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected,
            onSkatsChanged: onSkatsChanged,
            skatsFocusNodes: skatsFocusNodes,
            isPlayerFocused: isPlayerFocused,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: buildGroup(
            context,
            groups,
            thirdIndex,
            thirdTitle,
            onPlayerTap: onPlayerTap,
            onEmptySlotTap: onEmptySlotTap,
            isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected,
            onSkatsChanged: onSkatsChanged,
            skatsFocusNodes: skatsFocusNodes,
            isPlayerFocused: isPlayerFocused,
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
    Function(PlayerData, String)? onSkatsChanged,
    List<List<FocusNode?>>? skatsFocusNodes,
    bool Function(PlayerData player)? isPlayerFocused,
  }) {
    final deviceType = getDeviceType(context);
    final groupHeight = getResponsiveGroupHeight(deviceType);
    final groupHeaderFontSize = getGroupHeaderFontSize(context);
    final padding = getResponsivePadding(deviceType);

    return SizedBox(
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
                fontSize: groupHeaderFontSize,
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
              onSkatsChanged: onSkatsChanged,
              skatsFocusNodes: skatsFocusNodes,
              isPlayerFocused: isPlayerFocused,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header row for a group with column titles
  /// Responsive design adapts height and styling
  static Widget buildGroupHeader(BuildContext context) {
    getDeviceType(context);
    
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
    final tableHeaderFontSize = getTableHeaderFontSize(context);
    final padding = getResponsivePadding(deviceType);

    return Expanded(
      flex: flex,
      child: Container(
        height: rowHeight,
        padding: EdgeInsets.only(
          left: padding.left / 2,
          right: padding.left / 2,
          top: padding.top,
          bottom: padding.bottom,
        ),
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
              fontSize: tableHeaderFontSize,
              fontWeight: FontWeight.bold,
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
    Function(PlayerData, String)? onSkatsChanged,
    List<List<FocusNode?>>? skatsFocusNodes,
    bool Function(PlayerData player)? isPlayerFocused,
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
            onSkatsChanged: onSkatsChanged,
            skatsFocusNode: skatsFocusNodes?[groupIndex]?[rowIndex],
            showSkatsFocus: isPlayerFocused?.call(player) ?? false,
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
    Function(PlayerData, String)? onSkatsChanged,
    FocusNode? skatsFocusNode,
    bool showSkatsFocus = false,
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
          buildInputCell(
            context, 
            player.skats, 
            Colors.yellow[200], 
            flex: 1, 
            keyValue: '${player.name}_skats',
            onChanged: onSkatsChanged != null ? (value) => onSkatsChanged(player, value) : null,
            focusNode: skatsFocusNode,
            showFocus: showSkatsFocus,
          ),
          buildInputCell(
            context, 
            player.diff, 
            getDiffBackgroundColor(player.diff), 
            flex: 1, 
            keyValue: '${player.name}_diff'
          ),
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
    final tableDataFontSize = getTableDataFontSize(context);
    final padding = getResponsivePadding(deviceType);

    // Format currency if this is a money field
    String displayText = text;
    if (isCurrency && text.isNotEmpty) {
      // Remove any existing currency symbols and parse as number
      final cleanText = text.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleanText.isNotEmpty) {
        final amount = double.tryParse(cleanText) ?? 0.0;
        displayText = '\$${amount.round()}';
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
            fontSize: tableDataFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Builds a clickable cell for displaying player data (name, SK number, money)
  /// Responsive design adapts padding and font size, with bold formatting for data fields
  static Widget buildClickablePlayerCell(BuildContext context, String text, {int flex = 1, bool hasLeftBorder = false, bool isCurrency = false, VoidCallback? onTap, bool isSelected = false}) {
    final deviceType = getDeviceType(context);
    final tableDataFontSize = getTableDataFontSize(context);
    final padding = getResponsivePadding(deviceType);

    // Format currency if this is a money field
    String displayText = text;
    if (isCurrency && text.isNotEmpty) {
      // Remove any existing currency symbols and parse as number
      final cleanText = text.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleanText.isNotEmpty) {
        final amount = double.tryParse(cleanText) ?? 0.0;
        displayText = '\$${amount.round()}';
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
              fontSize: tableDataFontSize,
              fontWeight: FontWeight.bold,
              color: onTap != null ? Colors.blue[700] : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  /// Gets the background color for DIFF field based on the difference value
  /// Returns light green for positive, light red for negative and zero, white for empty
  static Color getDiffBackgroundColor(String diffValue) {
    if (diffValue.isEmpty) {
      return Colors.white; // Default white for empty
    }
    
    // Remove the sign and parse the number
    String cleanValue = diffValue.replaceAll('+', '').replaceAll('-', '');
    if (cleanValue == '0') {
      return Colors.red[200]!; // Light red for zero
    }
    
    // Check if it's positive or negative
    if (diffValue.startsWith('+')) {
      return Colors.lightGreen[200]!; // Light green for positive
    } else if (diffValue.startsWith('-')) {
      return Colors.red[200]!; // Light red for negative
    } else {
      return Colors.white; // Default white
    }
  }

  /// Builds an input cell for editable data (skats, diff)
  /// Responsive design adapts padding and font size, with bold formatting for data fields
  static Widget buildInputCell(BuildContext context, String value, Color? backgroundColor, {
    int flex = 1,
    String? keyValue,
    Function(String)? onChanged,
    FocusNode? focusNode,
    bool showFocus = false,
  }) {
    final tableDataFontSize = getTableDataFontSize(context);

    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: showFocus ? const BorderSide(color: Colors.blue, width: 3) : const BorderSide(color: Colors.black, width: 1),
            top: showFocus ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
            bottom: showFocus ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
            left: showFocus ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
          ),
          color: backgroundColor,
        ),
        child: Center(
          child: TextFormField(
            key: keyValue != null ? Key('${keyValue}_$value') : null,
            initialValue: value,
            focusNode: focusNode,
            readOnly: true, // Disable system keyboard
            enableInteractiveSelection: false, // Disable text selection
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: tableDataFontSize,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  /// Builds the bottom buttons row with navigation and action buttons
  /// Now uses standardized ButtonBarUIService for consistent styling
  static Widget buildBottomButtons(BuildContext context, {
    VoidCallback? onReturn,
    VoidCallback? onClosestPin,
    VoidCallback? onAutoFill,
    VoidCallback? onSwapPlayers,
  }) {
    final deviceType = getDeviceType(context);

    // Adjust button text for smaller screens
    String closestPinText = 'Closest Pin';
    String swapText = 'SWAP Players';
    if (deviceType == DeviceType.phone6_5) {
      closestPinText = 'ClosePin';
      swapText = 'SWAP';
    }

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: Colors.grey[300]!,
      children: [
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Return',
          color: Colors.blue[200]!,
          onPressed: onReturn ?? () => Navigator.pop(context),
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: closestPinText,
          color: Colors.green[200]!,
          onPressed: onClosestPin ?? () {},
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: 'Auto Fill',
          color: Colors.orange[200]!,
          onPressed: onAutoFill ?? () {},
        ),
        ButtonBarUIService.buildActionButton(
          context,
          text: swapText,
          color: Colors.grey[400]!,
          onPressed: onSwapPlayers ?? () {},
        ),
      ],
    );
  }

  // ============== WEDNESDAY-SPECIFIC METHODS ==============

  /// Builds the purse header for Wednesday league with configurable purse display
  /// Uses orange color scheme and supports groupsProcessed state
  static Widget buildWednesdayPurseHeader(
    BuildContext context, {
    required double playersPurse,
    required double closestPinPurse, required double mulliganPurse,
    required bool groupsProcessed,
    bool individualsProcessingComplete = false,
    VoidCallback? onReturn,
    VoidCallback? onAutoFill,
  }) {
    final isPhone = DeviceDetectionService.isPhone(context);
    final headerFontSize = ResponsiveTypography.getLabel(context);
    final spacing = isPhone ? 10.0 : 30.0;
    const config = LeagueUIConfig.wednesday;

    // Determine the labels based on processing state
    String firstPurseLabel;
    String secondPurseLabel;
    if (groupsProcessed) {
      firstPurseLabel = "Group Purse";
      secondPurseLabel = "Group Payout";
    } else {
      firstPurseLabel = "Ind Purse";
      // Default to "Payout" for initial state and after individuals processing
      secondPurseLabel = "Payout";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      color: config.headerColor,
      child: Row(
        children: [
          // Return button
          /*if (onReturn != null)
            GestureDetector(
              onTap: onReturn,
              child: Container(
                width: isPhone ? 36 : 48,
                height: isPhone ? 28 : 36,
                margin: EdgeInsets.only(right: isPhone ? 8 : 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.white,
                ),
                child: Center(
                  child: Icon(Icons.arrow_back, color: Colors.black, size: isPhone ? 18 : 24),
                ),
              ),
            ),*/
          // Purse information
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    "$firstPurseLabel = ",
                    style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: config.headerValueBackground,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '\$${playersPurse.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Text(
                    "$secondPurseLabel = ",
                    style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: config.headerValueBackground,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '\$${closestPinPurse.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Text(
                    "Mulligan Purse = ",
                    style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: config.headerValueBackground,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '\$${mulliganPurse.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Auto fill button
          if (onAutoFill != null)
            GestureDetector(
              onTap: onAutoFill,
              child: Container(
                width: isPhone ? 36 : 48,
                height: isPhone ? 28 : 36,
                margin: EdgeInsets.only(left: isPhone ? 8 : 16),
                decoration: BoxDecoration(
                  //border: Border.all(color: Colors.black, width: 1),
                  //borderRadius: BorderRadius.circular(4.0),
                  color: Colors.orange[200],
                ),
                child: Center(
                  child: Icon(Icons.arrow_downward, color: Colors.black, size: isPhone ? 18 : 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Gets responsive group height for Wednesday layout
  static double getWednesdayGroupHeight(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    return isPhone ? 180.0 : 220.0;
  }

  /// Gets responsive row height for Wednesday layout
  static double getWednesdayRowHeight(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    return isPhone ? 32.0 : 40.0;
  }

  /// Builds the scrollable groups grid for Wednesday league
  /// Supports both pre-processed and post-processed column structures
  /// Always uses 2-column layout for consistency
  static Widget buildWednesdayGroupsGrid(
    BuildContext context,
    List<List<Map<String, dynamic>?>> groups, {
    required bool groupsProcessed,
    Function(int groupIndex, int playerIndex, Map<String, dynamic> player)? onPlayerTap,
    Function(int groupIndex, int playerIndex)? onEmptySlotTap,
    bool Function(String playerName)? isPlayerSelected,
    bool Function(int groupIndex, int playerIndex)? isEmptySlotSelected,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    List<List<FocusNode?>>? grossFocusNodes,
    bool Function(Map<String, dynamic> player)? isPlayerFocused,
  }) {
    final isPhone = DeviceDetectionService.isPhone(context);
    final padding = EdgeInsets.all(isPhone ? 4.0 : 8.0);
    final spacing = isPhone ? 4.0 : 8.0;

    // Always use 2-column layout
    return _buildWednesdayTwoColumnLayout(context, groups, groupsProcessed, spacing, padding,
      onPlayerTap: onPlayerTap,
      onEmptySlotTap: onEmptySlotTap,
      isPlayerSelected: isPlayerSelected,
      isEmptySlotSelected: isEmptySlotSelected,
      onGrossScoreChanged: onGrossScoreChanged,
      grossFocusNodes: grossFocusNodes,
      isPlayerFocused: isPlayerFocused,
      useThreeColumns: false,
    );
  }

  static Widget _buildWednesdayTwoColumnLayout(
    BuildContext context,
    List<List<Map<String, dynamic>?>> groups,
    bool groupsProcessed,
    double spacing,
    EdgeInsets padding, {
    Function(int, int, Map<String, dynamic>)? onPlayerTap,
    Function(int, int)? onEmptySlotTap,
    bool Function(String)? isPlayerSelected,
    bool Function(int, int)? isEmptySlotSelected,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    List<List<FocusNode?>>? grossFocusNodes,
    bool Function(Map<String, dynamic>)? isPlayerFocused,
    required bool useThreeColumns,
  }) {
    return Expanded(
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWednesdayGroupRow(context, groups, 0, 1, 'Group 1', 'Group 2', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
              SizedBox(height: spacing),
              _buildWednesdayGroupRow(context, groups, 2, 3, 'Group 3', 'Group 4', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
              SizedBox(height: spacing),
              _buildWednesdayGroupRow(context, groups, 4, 5, 'Group 5', 'Group 6', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
              SizedBox(height: spacing),
              _buildWednesdayGroupRow(context, groups, 6, 7, 'Group 7', 'Group 8', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
              SizedBox(height: spacing),
              _buildWednesdayGroupRow(context, groups, 8, 9, 'Group 9', 'Group 10', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildWednesdayThreeColumnLayout(
    BuildContext context,
    List<List<Map<String, dynamic>?>> groups,
    bool groupsProcessed,
    double spacing,
    EdgeInsets padding, {
    Function(int, int, Map<String, dynamic>)? onPlayerTap,
    Function(int, int)? onEmptySlotTap,
    bool Function(String)? isPlayerSelected,
    bool Function(int, int)? isEmptySlotSelected,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    List<List<FocusNode?>>? grossFocusNodes,
    bool Function(Map<String, dynamic>)? isPlayerFocused,
    required bool useThreeColumns,
  }) {
    return Expanded(
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWednesdayGroupRowThree(context, groups, 0, 1, 2, 'Group 1', 'Group 2', 'Group 3', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
              SizedBox(height: spacing),
              _buildWednesdayGroupRowThree(context, groups, 3, 4, 5, 'Group 4', 'Group 5', 'Group 6', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
              SizedBox(height: spacing),
              _buildWednesdayGroupRowThree(context, groups, 6, 7, 8, 'Group 7', 'Group 8', 'Group 9', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
              SizedBox(height: spacing),
              _buildWednesdayGroupRow(context, groups, 9, -1, 'Group 10', '', groupsProcessed, spacing,
                onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
                isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
                grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildWednesdayGroupRow(
    BuildContext context,
    List<List<Map<String, dynamic>?>> groups,
    int leftIndex,
    int rightIndex,
    String leftTitle,
    String rightTitle,
    bool groupsProcessed,
    double spacing, {
    Function(int, int, Map<String, dynamic>)? onPlayerTap,
    Function(int, int)? onEmptySlotTap,
    bool Function(String)? isPlayerSelected,
    bool Function(int, int)? isEmptySlotSelected,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    List<List<FocusNode?>>? grossFocusNodes,
    bool Function(Map<String, dynamic>)? isPlayerFocused,
    required bool useThreeColumns,
  }) {
    if (rightIndex == -1) {
      return Row(
        children: [
          Expanded(
            child: _buildWednesdayGroup(context, groups, leftIndex, leftTitle, groupsProcessed,
              onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
              isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
              grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
          ),
          SizedBox(width: spacing),
          Expanded(child: Container()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildWednesdayGroup(context, groups, leftIndex, leftTitle, groupsProcessed,
            onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
            grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildWednesdayGroup(context, groups, rightIndex, rightTitle, groupsProcessed,
            onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
            grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
        ),
      ],
    );
  }

  static Widget _buildWednesdayGroupRowThree(
    BuildContext context,
    List<List<Map<String, dynamic>?>> groups,
    int firstIndex,
    int secondIndex,
    int thirdIndex,
    String firstTitle,
    String secondTitle,
    String thirdTitle,
    bool groupsProcessed,
    double spacing, {
    Function(int, int, Map<String, dynamic>)? onPlayerTap,
    Function(int, int)? onEmptySlotTap,
    bool Function(String)? isPlayerSelected,
    bool Function(int, int)? isEmptySlotSelected,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    List<List<FocusNode?>>? grossFocusNodes,
    bool Function(Map<String, dynamic>)? isPlayerFocused,
    required bool useThreeColumns,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildWednesdayGroup(context, groups, firstIndex, firstTitle, groupsProcessed,
            onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
            grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildWednesdayGroup(context, groups, secondIndex, secondTitle, groupsProcessed,
            onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
            grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildWednesdayGroup(context, groups, thirdIndex, thirdTitle, groupsProcessed,
            onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
            isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
            grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
        ),
      ],
    );
  }

  static Widget _buildWednesdayGroup(
    BuildContext context,
    List<List<Map<String, dynamic>?>> groups,
    int groupIndex,
    String groupTitle,
    bool groupsProcessed, {
    Function(int, int, Map<String, dynamic>)? onPlayerTap,
    Function(int, int)? onEmptySlotTap,
    bool Function(String)? isPlayerSelected,
    bool Function(int, int)? isEmptySlotSelected,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    List<List<FocusNode?>>? grossFocusNodes,
    bool Function(Map<String, dynamic>)? isPlayerFocused,
    required bool useThreeColumns,
  }) {
    final groupHeight = getWednesdayGroupHeight(context);

    // Check if group index is valid
    if (groupIndex >= groups.length) {
      return Container(height: groupHeight);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Text(
            '-----$groupTitle-----',
            textAlign: TextAlign.center,
            style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.bold),
          ),
        ),
        // Column headers
        _buildWednesdayGroupHeader(context, groupsProcessed, useThreeColumns),
        // Player rows
        _buildWednesdayGroupRows(context, groups, groupIndex, groupsProcessed,
          onPlayerTap: onPlayerTap, onEmptySlotTap: onEmptySlotTap, isPlayerSelected: isPlayerSelected,
          isEmptySlotSelected: isEmptySlotSelected, onGrossScoreChanged: onGrossScoreChanged,
          grossFocusNodes: grossFocusNodes, isPlayerFocused: isPlayerFocused, useThreeColumns: useThreeColumns),
      ],
    );
  }

  static Widget _buildWednesdayGroupHeader(BuildContext context, bool groupsProcessed, bool useThreeColumns) {
    final rowHeight = getWednesdayRowHeight(context);

    // Adjust flex values for three-column layout to prevent compression
    int nameFlex = useThreeColumns ? 25 : 30;
    int hcFlex = useThreeColumns ? 8 : 10;
    int grossFlex = useThreeColumns ? 9 : 11;
    int netFlex = useThreeColumns ? 8 : 10;
    int grpFlex = useThreeColumns ? 8 : 10;
    int avgFlex = useThreeColumns ? 8 : 10;
    int posFlex = useThreeColumns ? 8 : 10;
    int moneyFlex = useThreeColumns ? 15 : 20;

    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildWednesdayHeaderCell(context, 'Name', flex: nameFlex, hasLeftBorder: true),
          if (!groupsProcessed) _buildWednesdayHeaderCell(context, 'HC', flex: hcFlex),
          if (!groupsProcessed) _buildWednesdayHeaderCell(context, 'Gross', flex: grossFlex, reducedPadding: true),
          if (groupsProcessed) _buildWednesdayHeaderCell(context, 'Grp#', flex: grpFlex),
          _buildWednesdayHeaderCell(context, 'Net', flex: netFlex),
          if (groupsProcessed) _buildWednesdayHeaderCell(context, 'AVG', flex: avgFlex),
          _buildWednesdayHeaderCell(context, 'Pos', flex: posFlex),
          _buildWednesdayHeaderCell(context, '\$\$\$', flex: moneyFlex),
        ],
      ),
    );
  }

  static Widget _buildWednesdayHeaderCell(BuildContext context, String text, {int flex = 1, bool reducedPadding = false, bool hasLeftBorder = false}) {
    final isPhone = DeviceDetectionService.isPhone(context);
    final padding = isPhone ? 4.0 : 8.0;

    // Use reduced padding for columns that need to fit more text
    final leftRightPadding = reducedPadding ? 1.0 : padding / 2;

    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.only(
          left: leftRightPadding,
          right: leftRightPadding,
          top: padding,
          bottom: padding,
        ),
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
            style: ResponsiveTypography.tableHeaderStyle(context, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  static Widget _buildWednesdayGroupRows(
    BuildContext context,
    List<List<Map<String, dynamic>?>> groups,
    int groupIndex,
    bool groupsProcessed, {
    Function(int, int, Map<String, dynamic>)? onPlayerTap,
    Function(int, int)? onEmptySlotTap,
    bool Function(String)? isPlayerSelected,
    bool Function(int, int)? isEmptySlotSelected,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    List<List<FocusNode?>>? grossFocusNodes,
    bool Function(Map<String, dynamic>)? isPlayerFocused,
    required bool useThreeColumns,
  }) {
    return Column(
      children: List.generate(4, (rowIndex) {
        final player = (groupIndex < groups.length && rowIndex < groups[groupIndex].length)
            ? groups[groupIndex][rowIndex]
            : null;

        if (player != null) {
          final isSelected = isPlayerSelected?.call(player['last'] ?? '') ?? false;
          return _buildWednesdayPlayerRow(context, player, groupIndex, rowIndex, groupsProcessed,
            onPlayerTap: onPlayerTap != null ? () => onPlayerTap(groupIndex, rowIndex, player) : null,
            isSelected: isSelected,
            onGrossScoreChanged: onGrossScoreChanged,
            grossFocusNode: grossFocusNodes?[groupIndex][rowIndex],
            showFocus: isPlayerFocused?.call(player) ?? false,
            useThreeColumns: useThreeColumns,
          );
        } else {
          final isSelected = isEmptySlotSelected?.call(groupIndex, rowIndex) ?? false;
          return _buildWednesdayEmptyRow(context, groupsProcessed,
            onTap: onEmptySlotTap != null ? () => onEmptySlotTap(groupIndex, rowIndex) : null,
            isSelected: isSelected,
            useThreeColumns: useThreeColumns,
          );
        }
      }),
    );
  }

  static Widget _buildWednesdayPlayerRow(
    BuildContext context,
    Map<String, dynamic> player,
    int groupIndex,
    int rowIndex,
    bool groupsProcessed, {
    VoidCallback? onPlayerTap,
    bool isSelected = false,
    Function(Map<String, dynamic>, String)? onGrossScoreChanged,
    FocusNode? grossFocusNode,
    bool showFocus = false,
    required bool useThreeColumns,
  }) {
    final rowHeight = getWednesdayRowHeight(context);
    const config = LeagueUIConfig.wednesday;

    // Extract player data
    String name = player['last'] ?? '';
    double handicap = (player['handicap'] ?? 0.0).toDouble();
    int? netScore = player['net_score'] as int?;
    String position = player['pos'] ?? '';
    String prizeMoney = player['prize_money'] ?? '';
    int? manualGroup = player['manual_group'] as int?;
    String avgNet = player['avg_net'] ?? '';
    bool isWildCard = player['is_wild_card'] == true;

    // Adjust flex values for three-column layout to match header
    int nameFlex = useThreeColumns ? 25 : 30;
    int hcFlex = useThreeColumns ? 8 : 10;
    int grossFlex = useThreeColumns ? 9 : 11;
    int netFlex = useThreeColumns ? 8 : 10;
    int grpFlex = useThreeColumns ? 8 : 10;
    int avgFlex = useThreeColumns ? 8 : 10;
    int posFlex = useThreeColumns ? 8 : 10;
    int moneyFlex = useThreeColumns ? 15 : 20;

    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        children: [
          // Name cell (clickable)
          _buildWednesdayClickableNameCell(context, name, isWildCard, flex: nameFlex, onTap: onPlayerTap, isSelected: isSelected),
          // Handicap (only when not processed)
          if (!groupsProcessed)
            _buildWednesdayDataCell(context, handicap.toStringAsFixed(1), flex: hcFlex),
          // Gross score input (only when not processed)
          if (!groupsProcessed)
            _buildWednesdayGrossInputCell(context, player, flex: grossFlex,
              onChanged: onGrossScoreChanged,
              focusNode: grossFocusNode,
              showFocus: showFocus),
          // Group number (only when processed)
          if (groupsProcessed)
            _buildWednesdayDataCell(context, manualGroup?.toString() ?? '', flex: grpFlex,
              backgroundColor: config.inputCellColor),
          // Net score
          _buildWednesdayDataCell(context, netScore?.toString() ?? '', flex: netFlex),
          // AVG (only when processed) - shows average net score for the group
          if (groupsProcessed)
            _buildWednesdayDataCell(context, avgNet, flex: avgFlex),
          // Position
          _buildWednesdayDataCell(context, position, flex: posFlex),
          // Prize money
          _buildWednesdayDataCell(context, prizeMoney, flex: moneyFlex),
        ],
      ),
    );
  }

  static Widget _buildWednesdayEmptyRow(
    BuildContext context,
    bool groupsProcessed, {
    VoidCallback? onTap,
    bool isSelected = false,
    required bool useThreeColumns,
  }) {
    final rowHeight = getWednesdayRowHeight(context);
    const config = LeagueUIConfig.wednesday;

    // Adjust flex values for three-column layout to match header
    int nameFlex = useThreeColumns ? 25 : 30;
    int hcFlex = useThreeColumns ? 8 : 10;
    int grossFlex = useThreeColumns ? 9 : 11;
    int netFlex = useThreeColumns ? 8 : 10;
    int grpFlex = useThreeColumns ? 8 : 10;
    int avgFlex = useThreeColumns ? 8 : 10;
    int posFlex = useThreeColumns ? 8 : 10;
    int moneyFlex = useThreeColumns ? 15 : 20;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          border: const Border(bottom: BorderSide(color: Colors.black, width: 1)),
          color: isSelected ? config.selectedColor : null,
        ),
        child: Row(
          children: [
            _buildWednesdayDataCell(context, '', flex: nameFlex, hasLeftBorder: true),
            if (!groupsProcessed) _buildWednesdayDataCell(context, '', flex: hcFlex),
            if (!groupsProcessed) _buildWednesdayDataCell(context, '', flex: grossFlex),
            if (groupsProcessed) _buildWednesdayDataCell(context, '', flex: grpFlex),
            _buildWednesdayDataCell(context, '', flex: netFlex),
            if (groupsProcessed) _buildWednesdayDataCell(context, '', flex: avgFlex),
            _buildWednesdayDataCell(context, '', flex: posFlex),
            _buildWednesdayDataCell(context, '', flex: moneyFlex),
          ],
        ),
      ),
    );
  }

  static Widget _buildWednesdayClickableNameCell(
    BuildContext context,
    String name,
    bool isWildCard, {
    int flex = 1,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final isPhone = DeviceDetectionService.isPhone(context);
    const config = LeagueUIConfig.wednesday;

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: const Border(
              left: BorderSide(color: Colors.black, width: 1),
              right: BorderSide(color: Colors.black, width: 1),
            ),
            color: isSelected ? config.selectedColor : Colors.white,
          ),
          padding: EdgeInsets.symmetric(horizontal: isPhone ? 2 : 4),
          child: Row(
            children: [
              if (isWildCard) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.black, width: 0.5),
                  ),
                  child: Text(
                    'WC',
                    style: TextStyle(fontSize: isPhone ? 8 : 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: isPhone ? 2 : 4),
              ],
              Expanded(
                child: Text(
                  name,
                  style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildWednesdayDataCell(
    BuildContext context,
    String text, {
    int flex = 1,
    Color? backgroundColor,
    bool hasLeftBorder = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: hasLeftBorder ? const BorderSide(color: Colors.black, width: 1) : BorderSide.none,
            right: const BorderSide(color: Colors.black, width: 1),
          ),
          color: backgroundColor,
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  static Widget _buildWednesdayGrossInputCell(
    BuildContext context,
    Map<String, dynamic> player, {
    int flex = 1,
    Function(Map<String, dynamic>, String)? onChanged,
    FocusNode? focusNode,
    bool showFocus = false,
  }) {
    const config = LeagueUIConfig.wednesday;
    int? grossScore = player['gross_score'] as int?;
    String playerName = player['last'] ?? '';

    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: showFocus ? Colors.blue : Colors.black, width: showFocus ? 3 : 1),
            top: showFocus ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
            bottom: showFocus ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
            left: showFocus ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
          ),
          color: config.inputCellColor,
        ),
        child: Center(
          child: TextFormField(
            key: ValueKey('${playerName}_gross_${grossScore ?? 0}'), // Force rebuild when gross score changes
            initialValue: grossScore?.toString() ?? '',
            focusNode: focusNode,
            readOnly: true,
            enableInteractiveSelection: false,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
            decoration:  const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: onChanged != null ? (value) => onChanged(player, value) : null,
          ),
        ),
      ),
    );
  }

  /// Builds bottom action buttons for Wednesday league
  /// Now uses standardized ButtonBarUIService for consistent styling
  static Widget buildWednesdayBottomButtons(
    BuildContext context, {
    required String swapButtonText,
    required Color swapButtonColor,
    required bool individualsComplete,
    bool groupsProcessed = false,
    VoidCallback? onAutoFill,
    VoidCallback? onMainMenu,
    VoidCallback? onShuffle,
    Color? shuffleButtonColor,
    Color? backButtonColor,
    VoidCallback? onIndividuals,
    VoidCallback? onProcessGroups,
    VoidCallback? onClosestPin,
    VoidCallback? onSwap,
  }) {
    const config = LeagueUIConfig.wednesday;

    // Determine button text and callback based on groups processing state
    String processButtonText = groupsProcessed ? 'Close Pin Winner ---➤' : 'Process Groups ---➤';
    VoidCallback? processButtonCallback = groupsProcessed
        ? onClosestPin
        : (individualsComplete ? onProcessGroups : null);
    Color processButtonColor = groupsProcessed
        ? Colors.green[300]!
        : (individualsComplete ? Colors.green[300]! : Colors.grey[400]!);

    // Disable Back button when groups are processed
    VoidCallback? backButtonCallback = groupsProcessed ? null : onMainMenu;
    Color finalBackButtonColor = backButtonColor ?? Colors.lightBlue[100]!;

    // Build button list based on processing state
    List<Widget> buttons = [];

    if (!groupsProcessed) {
      // Show all buttons when not processed
      if (onAutoFill != null) {
        buttons.add(ButtonBarUIService.buildActionButton(
          context,
          text: 'Auto Fill',
          color: Colors.orange[200]!,
          onPressed: onAutoFill,
        ));
      }
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: '◄---- Back     ',
        color: finalBackButtonColor,
        onPressed: backButtonCallback,
      ));
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: 'Shuffle',
        color: shuffleButtonColor ?? Colors.purple[200]!,
        onPressed: onShuffle,
      ));
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: swapButtonText,
        color: swapButtonColor,
        onPressed: onSwap,
      ));
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: processButtonText,
        color: processButtonColor,
        onPressed: processButtonCallback,
      ));
    } else {
      // Only show Close Pin Winner button when processed
      buttons.add(ButtonBarUIService.buildActionButton(
        context,
        text: processButtonText,
        color: processButtonColor,
        onPressed: processButtonCallback,
      ));
    }

    return ButtonBarUIService.buildButtonBar(
      context,
      backgroundColor: config.buttonBarColor,
      children: buttons,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      useMinHeight: true, // Allow expansion for longer text
    );
  }
}

/// Data model for representing player data in golf league scoring
class PlayerData {
  final String name;
  final String skNumber;
  final String skats;
  final String diff;
  final String money;

  const PlayerData({
    required this.name,
    required this.skNumber,
    this.skats = '',
    this.diff = '',
    this.money = '',
  });

  @override
  String toString() {
    return 'PlayerData(name: $name, skNumber: $skNumber, skats: $skats, diff: $diff, money: $money)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerData &&
        other.name == name &&
        other.skNumber == skNumber &&
        other.skats == skats &&
        other.diff == diff &&
        other.money == money;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        skNumber.hashCode ^
        skats.hashCode ^
        diff.hashCode ^
        money.hashCode;
  }

  /// Creates a copy of this PlayerData with updated values
  PlayerData copyWith({
    String? name,
    String? skNumber,
    String? skats,
    String? diff,
    String? money,
  }) {
    return PlayerData(
      name: name ?? this.name,
      skNumber: skNumber ?? this.skNumber,
      skats: skats ?? this.skats,
      diff: diff ?? this.diff,
      money: money ?? this.money,
    );
  }

  /// Creates a PlayerData instance from a map (useful for database operations)
  factory PlayerData.fromMap(Map<String, dynamic> map) {
    return PlayerData(
      name: map['name'] ?? '',
      skNumber: map['skNumber'] ?? '',
      skats: map['skats'] ?? '',
      diff: map['diff'] ?? '',
      money: map['money'] ?? '',
    );
  }

  /// Converts this PlayerData to a map (useful for database operations)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'skNumber': skNumber,
      'skats': skats,
      'diff': diff,
      'money': money,
    };
  }
}

