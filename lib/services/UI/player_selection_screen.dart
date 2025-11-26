import 'package:flutter/material.dart';

/// Device type enumeration for responsive design
enum DeviceType {
  phone,       // 6.5" phones (up to 800px)
  tabletSmall, // 8" tablets (801-1000px) 
  tabletLarge, // 10" tablets (1001px+)
}

/// Responsive configuration class that provides device-specific values
class ResponsiveConfig {
  final DeviceType deviceType;
  final Orientation orientation;
  final double screenWidth;
  final double screenHeight;
  final bool isLandscape;
  
  ResponsiveConfig({
    required this.deviceType,
    required this.orientation, 
    required this.screenWidth,
    required this.screenHeight,
    required this.isLandscape,
  });
  
  // Grid layout configuration
  int get gridColumnCount {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 6 : 3; // More columns in landscape for phones
      case DeviceType.tabletSmall:
        return isLandscape ? 5 : 4;  // Balanced for 8" tablets
      case DeviceType.tabletLarge:
        return isLandscape ? 6 : 4;  // Maximum for 10" tablets
    }
  }
  
  // Container spacing
  double get containerMargin {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 2 : 8;
      case DeviceType.tabletSmall:
        return isLandscape ? 8 : 12;
      case DeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get containerPadding {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 4 : 8;
      case DeviceType.tabletSmall:
        return isLandscape ? 8 : 12;
      case DeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get borderRadius {
    switch (deviceType) {
      case DeviceType.phone:
        return 4;
      case DeviceType.tabletSmall:
        return 6;
      case DeviceType.tabletLarge:
        return 8;
    }
  }
  
  // Header configuration
  bool get showPlayerCount {
    return !(deviceType == DeviceType.phone && isLandscape);
  }
  
  double get headerFontSize {
    switch (deviceType) {
      case DeviceType.phone:
        return 14;
      case DeviceType.tabletSmall:
        return 15;
      case DeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get headerVerticalPadding {
    switch (deviceType) {
      case DeviceType.phone:
        return 4;
      case DeviceType.tabletSmall:
        return 6;
      case DeviceType.tabletLarge:
        return 8;
    }
  }
  
  double get headerSpacing {
    switch (deviceType) {
      case DeviceType.phone:
        return 4;
      case DeviceType.tabletSmall:
        return 7;
      case DeviceType.tabletLarge:
        return 10;
    }
  }
  
  // Empty state configuration
  double get emptyStateIconSize {
    switch (deviceType) {
      case DeviceType.phone:
        return 50;
      case DeviceType.tabletSmall:
        return 65;
      case DeviceType.tabletLarge:
        return 80;
    }
  }
  
  double get emptyStateFontSize {
    switch (deviceType) {
      case DeviceType.phone:
        return 12;
      case DeviceType.tabletSmall:
        return 15;
      case DeviceType.tabletLarge:
        return 18;
    }
  }
  
  double get emptyStateSpacing {
    switch (deviceType) {
      case DeviceType.phone:
        return 6;
      case DeviceType.tabletSmall:
        return 10;
      case DeviceType.tabletLarge:
        return 16;
    }
  }
  
  // Scrolling behavior
  bool get needsScrolling {
    return deviceType == DeviceType.phone && isLandscape;
  }
  
  // Button configuration 
  bool get showCheckAllButton {
    return !(deviceType == DeviceType.phone && isLandscape);
  }
  
  double get buttonFontSize {
    switch (deviceType) {
      case DeviceType.phone:
        return 14;
      case DeviceType.tabletSmall:
        return 15;
      case DeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get buttonPaddingHorizontal {
    switch (deviceType) {
      case DeviceType.phone:
        return 20;
      case DeviceType.tabletSmall:
        return 30;
      case DeviceType.tabletLarge:
        return 40;
    }
  }
  
  double get buttonPaddingVertical {
    switch (deviceType) {
      case DeviceType.phone:
        return 8;
      case DeviceType.tabletSmall:
        return 10;
      case DeviceType.tabletLarge:
        return 12;
    }
  }
  
  double get buttonSpacing {
    switch (deviceType) {
      case DeviceType.phone:
        return 10;
      case DeviceType.tabletSmall:
        return 15;
      case DeviceType.tabletLarge:
        return 20;
    }
  }
  
  // Footer configuration
  bool get useCompactFooter {
    return deviceType == DeviceType.phone && isLandscape;
  }
  
  double get footerPadding {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 6 : 12;
      case DeviceType.tabletSmall:
        return 14;
      case DeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get footerButtonFontSize {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 10 : 12;
      case DeviceType.tabletSmall:
        return 13;
      case DeviceType.tabletLarge:
        return 14;
    }
  }
  
  double get footerButtonPaddingHorizontal {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 8 : 16;
      case DeviceType.tabletSmall:
        return 18;
      case DeviceType.tabletLarge:
        return 20;
    }
  }
  
  double get footerButtonPaddingVertical {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 6 : 10;
      case DeviceType.tabletSmall:
        return 11;
      case DeviceType.tabletLarge:
        return 12;
    }
  }
  
  // Player item configuration
  bool get useShortPlayerNames {
    return deviceType == DeviceType.phone && isLandscape;
  }
  
  double get playerItemVerticalMargin {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 0.3 : 0.5;
      case DeviceType.tabletSmall:
        return 0.7;
      case DeviceType.tabletLarge:
        return 1.0;
    }
  }
  
  double get playerItemHorizontalMargin {
    return 2;
  }
  
  double get playerItemVerticalPadding {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 1 : 2;
      case DeviceType.tabletSmall:
        return 3;
      case DeviceType.tabletLarge:
        return 4;
    }
  }
  
  double get playerItemHorizontalPadding {
    return 4;
  }
  
  double get checkboxSize {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 20 : 24;
      case DeviceType.tabletSmall:
        return 28;
      case DeviceType.tabletLarge:
        return 32;
    }
  }
  
  double get checkboxFontSize {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 12 : 14;
      case DeviceType.tabletSmall:
        return 16;
      case DeviceType.tabletLarge:
        return 18;
    }
  }
  
  double get playerNameSpacing {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 4 : 6;
      case DeviceType.tabletSmall:
        return 7;
      case DeviceType.tabletLarge:
        return 8;
    }
  }
  
  double get playerNameFontSize {
    switch (deviceType) {
      case DeviceType.phone:
        return isLandscape ? 10 : 12;
      case DeviceType.tabletSmall:
        return 13;
      case DeviceType.tabletLarge:
        return 14;
    }
  }
  
  int get playerNameMaxLines {
    return (deviceType == DeviceType.phone && isLandscape) ? 1 : 2;
  }
}

class PlayerSelectionUIService {
  // Device breakpoints based on screen width
  static const double _phoneMaxWidth = 800;      // 6.5" phones
  static const double _tabletSmallMaxWidth = 1000; // 8" tablets
  
  /// Determines the device type and responsive configuration
  static ResponsiveConfig getResponsiveConfig(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final width = screenSize.width;
    final height = screenSize.height;
    
    // Determine device type based on screen width
    DeviceType deviceType;
    if (width <= _phoneMaxWidth) {
      deviceType = DeviceType.phone;
    } else if (width <= _tabletSmallMaxWidth) {
      deviceType = DeviceType.tabletSmall;
    } else {
      deviceType = DeviceType.tabletLarge;
    }
    
    return ResponsiveConfig(
      deviceType: deviceType,
      orientation: orientation,
      screenWidth: width,
      screenHeight: height,
      isLandscape: orientation == Orientation.landscape,
    );
  }
  static Widget buildMainContent({
    required BuildContext context,
    required bool is6Point5Phone, // Keep for backward compatibility
    required List<Map<String, dynamic>> players,
    required Set<int> selectedPlayerIds,
    required bool isLoading,
    required Widget Function() buildPlayerGrid,
    required VoidCallback selectAllPlayers,
    required Color leagueColor,
  }) {
    final config = getResponsiveConfig(context);
    return Container(
      margin: EdgeInsets.all(config.containerMargin),
      padding: EdgeInsets.all(config.containerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(config.borderRadius),
      ),
      child: Column(
        children: [
          // Selected count info (hide for phones in landscape to save space)
          if (config.showPlayerCount) 
            Container(
              padding: EdgeInsets.symmetric(vertical: config.headerVerticalPadding),
              child: Text(
                'Selected Players: ${selectedPlayerIds.length}/${players.length}',
                style: TextStyle(
                  fontSize: config.headerFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          if (config.showPlayerCount) SizedBox(height: config.headerSpacing),
      
          // 4-column player grid
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: config.emptyStateIconSize,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: config.emptyStateSpacing),
                        Text(
                          'No players found\nTry importing players first',
                          style: TextStyle(fontSize: config.emptyStateFontSize),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : config.needsScrolling
                    ? Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: buildPlayerGrid(),
                        ),
                      )
                    : buildPlayerGrid(),
          ),
          
          // Check All button (hidden for phones in landscape mode)
          if (config.showCheckAllButton)
            Column(
              children: [
                SizedBox(height: config.buttonSpacing),
                ElevatedButton(
                  onPressed: selectAllPlayers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: leagueColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: config.buttonPaddingHorizontal, 
                      vertical: config.buttonPaddingVertical
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Text(
                    selectedPlayerIds.length == players.length 
                        ? 'Uncheck All' 
                        : 'Check All',
                    style: TextStyle(
                      fontSize: config.buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Widget buildFooterButtons({
    required BuildContext context,
    required bool is6Point5Phone, // Keep for backward compatibility
    required Set<int> selectedPlayerIds,
    required List<Map<String, dynamic>> players,
    required Color leagueColor,
    required VoidCallback onReturn,
    required VoidCallback selectAllPlayers,
    required VoidCallback? onEnterScores,
    required String enterScoresButtonText,
    required String returnButtonText,
  }) {
    final config = getResponsiveConfig(context);
    return Container(
      padding: EdgeInsets.all(config.footerPadding),
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: config.useCompactFooter
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Return button
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: onReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: leagueColor,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: config.footerButtonPaddingHorizontal, 
                          vertical: config.footerButtonPaddingVertical
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Text(
                        'Return',
                        style: TextStyle(
                          fontSize: config.footerButtonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Check All button
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: selectAllPlayers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: leagueColor,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: config.footerButtonPaddingHorizontal, 
                          vertical: config.footerButtonPaddingVertical
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Text(
                        selectedPlayerIds.length == players.length 
                            ? 'Uncheck All' 
                            : 'Check All',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Enter Scores button
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: selectedPlayerIds.isEmpty ? null : onEnterScores,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: leagueColor,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: leagueColor,
                        disabledForegroundColor: Colors.black.withOpacity(0.6),
                        padding: EdgeInsets.symmetric(
                          horizontal: config.footerButtonPaddingHorizontal, 
                          vertical: config.footerButtonPaddingVertical
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Text(
                        enterScoresButtonText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: leagueColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: config.footerButtonPaddingHorizontal, 
                      vertical: config.footerButtonPaddingVertical
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Text(
                    returnButtonText,
                    style: TextStyle(
                      fontSize: config.footerButtonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedPlayerIds.isEmpty ? null : onEnterScores,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: leagueColor,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: leagueColor.withOpacity(0.6),
                    disabledForegroundColor: Colors.black.withOpacity(0.6),
                    padding: EdgeInsets.symmetric(
                      horizontal: config.footerButtonPaddingHorizontal, 
                      vertical: config.footerButtonPaddingVertical
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Text(
                    enterScoresButtonText,
                    style: TextStyle(
                      fontSize: config.footerButtonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static Widget buildPlayerGrid({
    required BuildContext context,
    required List<Map<String, dynamic>> players,
    required Widget Function(Map<String, dynamic>) buildPlayerCheckbox,
  }) {
    final config = getResponsiveConfig(context);
    final columnCount = config.gridColumnCount;
    
    // Organize players into columns based on responsive column count
    List<List<Map<String, dynamic>>> columns = List.generate(columnCount, (_) => []);
    for (int i = 0; i < players.length; i++) {
      columns[i % columnCount].add(players[i]);
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int colIndex = 0; colIndex < columnCount; colIndex++)
          Expanded(
            child: Column(
              children: [
                for (var player in columns[colIndex])
                  buildPlayerCheckbox(player),
              ],
            ),
          ),
      ],
    );
  }

  static Widget buildPlayerCheckbox({
    required BuildContext context,
    required Map<String, dynamic> player,
    required Set<int> selectedPlayerIds,
    required Color leagueColor,
    required VoidCallback Function(int) togglePlayerSelection,
    bool is6Point5Phone = false, // Keep for backward compatibility
  }) {
    final int playerId = player['id'] as int;
    final bool isSelected = selectedPlayerIds.contains(playerId);
    final config = getResponsiveConfig(context);
        
    // Choose player name format based on device type
    final String playerName = config.useShortPlayerNames 
        ? '${player['last']}'  // Only last name for compact devices
        : '${player['last']}, ${player['first']}';  // Full name for larger devices
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: config.playerItemVerticalMargin, 
        horizontal: config.playerItemHorizontalMargin
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => togglePlayerSelection(playerId),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: config.playerItemVerticalPadding, 
              horizontal: config.playerItemHorizontalPadding
            ),
            child: Row(
              children: [
                Container(
                  width: config.checkboxSize,
                  height: config.checkboxSize,
                  decoration: BoxDecoration(
                    color: isSelected ? leagueColor : Colors.grey[300],
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? Center(
                          child: Text(
                            'X',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: config.checkboxFontSize,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: config.playerNameSpacing),
                Expanded(
                  child: Text(
                    playerName,
                    style: TextStyle(
                      fontSize: config.playerNameFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: config.playerNameMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildScaffold({
    required BuildContext context,
    required String title,
    required Color appBarColor,
    required Widget body,
    required bool isLoading,
  }) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text(title),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : body,
    );
  }

  static Widget buildMainLayout({
    required BuildContext context,
    required Widget mainContent,
    required Widget footerButtons,
  }) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     kToolbarHeight,
        ),
        child: Column(
          children: [
            // Main content area with white background
            mainContent,
            
            // Footer buttons
            footerButtons,
          ],
        ),
      ),
    );
  }

  static bool isCompactMode(BuildContext context) {
    final config = getResponsiveConfig(context);
    return config.deviceType == DeviceType.phone && config.isLandscape;
  }
}