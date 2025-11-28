import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/league.dart';

/// Device type enumeration for responsive design
enum MainMenuDeviceType {
  phone,       // 6.5" phones (up to 800px)
  tabletSmall, // 8" tablets (801-1000px) 
  tabletLarge, // 10" tablets (1001px+)
}

/// Responsive configuration for main menu layouts
class MainMenuResponsiveConfig {
  final MainMenuDeviceType deviceType;
  final Orientation orientation;
  final double screenWidth;
  final double screenHeight;
  final bool isLandscape;
  
  MainMenuResponsiveConfig({
    required this.deviceType,
    required this.orientation, 
    required this.screenWidth,
    required this.screenHeight,
    required this.isLandscape,
  });
  
  // Layout configuration
  bool get useCompactLayout {
    return deviceType == MainMenuDeviceType.phone && isLandscape;
  }
  
  int get adminButtonCrossAxisCount {
    // Since we only have one Firebase button now, always return 1
    return 1;
  }
  
  double get adminButtonAspectRatio {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 4.0 : 2.0; // Wider for single button
      case MainMenuDeviceType.tabletSmall:
        return isLandscape ? 4.0 : 2.5;
      case MainMenuDeviceType.tabletLarge:
        return 3.0; // More rectangular for single button
    }
  }
  
  // Font sizes
  double get titleFontSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 12 : 18;
      case MainMenuDeviceType.tabletSmall:
        return 19;
      case MainMenuDeviceType.tabletLarge:
        return 20;
    }
  }
  
  double get buttonFontSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 10 : 16;
      case MainMenuDeviceType.tabletSmall:
        return 17;
      case MainMenuDeviceType.tabletLarge:
        return 18;
    }
  }
  
  double get statusFontSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 8 : 14;
      case MainMenuDeviceType.tabletSmall:
        return 15;
      case MainMenuDeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get configLabelFontSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 8 : 14;
      case MainMenuDeviceType.tabletSmall:
        return 15;
      case MainMenuDeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get configInputFontSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 8 : 14;
      case MainMenuDeviceType.tabletSmall:
        return 15;
      case MainMenuDeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get adminButtonFontSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 8 : 10;
      case MainMenuDeviceType.tabletSmall:
        return 10;
      case MainMenuDeviceType.tabletLarge:
        return 10;
    }
  }
  
  double get adminIconSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 14 : 18;
      case MainMenuDeviceType.tabletSmall:
        return 18;
      case MainMenuDeviceType.tabletLarge:
        return 18;
    }
  }
  
  // Padding and margins
  double get containerPadding {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 4 : 12;
      case MainMenuDeviceType.tabletSmall:
        return 12;
      case MainMenuDeviceType.tabletLarge:
        return 16;
    }
  }
  
  EdgeInsets get buttonPadding {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape 
          ? const EdgeInsets.all(8)
          : const EdgeInsets.all(16);
      case MainMenuDeviceType.tabletSmall:
        return const EdgeInsets.all(20);
      case MainMenuDeviceType.tabletLarge:
        return const EdgeInsets.all(20);
    }
  }
  
  double get configInputHeight {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 24 : 40;
      case MainMenuDeviceType.tabletSmall:
        return 44;
      case MainMenuDeviceType.tabletLarge:
        return 48;
    }
  }
  
  double get borderRadius {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 6 : 12;
      case MainMenuDeviceType.tabletSmall:
        return 12;
      case MainMenuDeviceType.tabletLarge:
        return 12;
    }
  }
  
  // Spacing
  double get verticalSpacing {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 6 : 12;
      case MainMenuDeviceType.tabletSmall:
        return 14;
      case MainMenuDeviceType.tabletLarge:
        return 16;
    }
  }
  
  double get horizontalSpacing {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 8 : 12;
      case MainMenuDeviceType.tabletSmall:
        return 16;
      case MainMenuDeviceType.tabletLarge:
        return 20;
    }
  }
  
  double get adminGridSpacing {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return isLandscape ? 2 : 4;
      case MainMenuDeviceType.tabletSmall:
        return 4;
      case MainMenuDeviceType.tabletLarge:
        return 8;
    }
  }
  
  // Image configuration
  double get logoIconSize {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return 40;
      case MainMenuDeviceType.tabletSmall:
        return 80;
      case MainMenuDeviceType.tabletLarge:
        return 120;
    }
  }
  
  double get imageBorderRadius {
    switch (deviceType) {
      case MainMenuDeviceType.phone:
        return 8;
      case MainMenuDeviceType.tabletSmall:
        return 10;
      case MainMenuDeviceType.tabletLarge:
        return 12;
    }
  }
}

class MainMenuUIService {
  // Device breakpoints based on screen width
  static const double _phoneMaxWidth = 750;      // 6.5" phones
  static const double _tabletSmallMaxWidth = 830; // 8" tablets
  
  /// Determines the device type and responsive configuration
  static MainMenuResponsiveConfig getResponsiveConfig(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final width = screenSize.width;
    final height = screenSize.height;
    
    // Determine device type based on screen width
    MainMenuDeviceType deviceType;
    if (width <= _phoneMaxWidth) {
      deviceType = MainMenuDeviceType.phone;
    } else if (width <= _tabletSmallMaxWidth) {
      deviceType = MainMenuDeviceType.tabletSmall;
    } else {
      deviceType = MainMenuDeviceType.tabletLarge;
    }
    
    return MainMenuResponsiveConfig(
      deviceType: deviceType,
      orientation: orientation,
      screenWidth: width,
      screenHeight: height,
      isLandscape: orientation == Orientation.landscape,
    );
  }
  static Widget buildPhoneLandscapeLayout(
    BuildContext context, {
    required League? currentLeague,
    required Widget Function(BuildContext) buildLeagueSelectionCompact,
    required Widget Function(BuildContext) buildLeagueConfigurationCompact,
    required Widget Function(String, IconData, Color, VoidCallback) buildCompactAdminButton,
    required VoidCallback onFirebasePressed,
  }) {
    final config = getResponsiveConfig(context);
    return Column(
      children: [
        // Top area - League selection, config, and image
        Expanded(
          child: Row(
            children: [
              // Left side - League selection and configuration
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildLeagueSelectionCompact(context),
                      
                      SizedBox(height: config.verticalSpacing / 2),
                      
                      if (currentLeague != null) buildLeagueConfigurationCompact(context),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: config.horizontalSpacing),
              
              // Right side - Image only
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(config.imageBorderRadius),
                    child: Image.asset(
                      'assets/images/GoldenOaks.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(config.imageBorderRadius),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.park,
                              size: config.logoIconSize,
                              color: Colors.green[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: config.verticalSpacing),
        
        // Bottom row - Admin Functions
        Container(
          padding: EdgeInsets.all(config.containerPadding / 2),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: config.adminButtonCrossAxisCount,
            mainAxisSpacing: config.adminGridSpacing,
            crossAxisSpacing: config.adminGridSpacing,
            childAspectRatio: config.adminButtonAspectRatio,
            children: [
              buildCompactAdminButton('Firebase', Icons.cloud_upload, Colors.red[200]!, onFirebasePressed),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildTabletLayout(
    BuildContext context, {
    required bool isTablet10, // Keep for backward compatibility
    required bool isTablet8,  // Keep for backward compatibility
    required League? currentLeague,
    required Widget Function(BuildContext, bool) buildLeagueSelection,
    required Widget Function(BuildContext, bool) buildLeagueConfiguration,
    required Widget Function(BuildContext, bool, bool) buildAdminFunctionsTablet,
  }) {
    final config = getResponsiveConfig(context);
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildLeagueSelection(context, false),
                      if (currentLeague != null) ...[
                        SizedBox(height: config.verticalSpacing),
                        buildLeagueConfiguration(context, false),
                      ],
                      SizedBox(height: config.verticalSpacing + 4),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: config.horizontalSpacing),
              
              Expanded(
                flex: 7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(config.imageBorderRadius),
                  child: Image.asset(
                    'assets/images/GoldenOaks.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(config.imageBorderRadius),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.park,
                            size: config.logoIconSize,
                            color: Colors.green[600],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: config.verticalSpacing),
        
        buildAdminFunctionsTablet(context, isTablet10, isTablet8),
      ],
    );
  }

  static Widget buildLeagueSelection(
    BuildContext context, {
    required bool isPhone, // Keep for backward compatibility
    required League? currentLeague,
    required VoidCallback selectMondayLeague,
    required VoidCallback selectWednesdayLeague,
  }) {
    final config = getResponsiveConfig(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Your League:',
          style: TextStyle(
            fontSize: config.titleFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: config.verticalSpacing),
        
        config.useCompactLayout || (config.deviceType == MainMenuDeviceType.phone) 
          ? Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: selectMondayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLeague == League.monday 
                          ? Colors.green[300] 
                          : Colors.green[100],
                      foregroundColor: Colors.black,
                      padding: config.buttonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(config.borderRadius),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Monday Group',
                      style: TextStyle(
                        fontSize: config.buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectWednesdayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLeague == League.wednesday 
                          ? Colors.orange[300] 
                          : Colors.orange[100],
                      foregroundColor: Colors.black,
                      padding: config.buttonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(config.borderRadius),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Wednesday Group',
                      style: TextStyle(
                        fontSize: config.buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: selectMondayLeague,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentLeague == League.monday 
                            ? Colors.green[300] 
                            : Colors.green[100],
                        foregroundColor: Colors.black,
                        padding: config.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(config.borderRadius),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Monday Group',
                        style: TextStyle(
                          fontSize: config.buttonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: selectWednesdayLeague,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentLeague == League.wednesday 
                            ? Colors.orange[300] 
                            : Colors.orange[100],
                        foregroundColor: Colors.black,
                        padding: config.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(config.borderRadius),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Wednesday Group',
                        style: TextStyle(
                          fontSize: config.buttonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        
        SizedBox(height: config.verticalSpacing),
        
        Container(
          padding: EdgeInsets.all(config.containerPadding),
          decoration: BoxDecoration(
            color: currentLeague == League.monday 
                ? Colors.green[300] 
                : currentLeague == League.wednesday 
                    ? Colors.orange[300] 
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(config.borderRadius),
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: Text(
            currentLeague != null 
                ? 'Active League: ${currentLeague.name.toUpperCase()}'
                : 'No League Selected',
            style: TextStyle(
              fontSize: config.statusFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  static Widget buildLeagueConfiguration(
    BuildContext context, {
    required bool isPhone, // Keep for backward compatibility
    required League? currentLeague,
    required TextEditingController anteController,
    required TextEditingController closestPinController,
    required TextEditingController newFieldController,
    required TextEditingController mondayMulligansController,
    required FocusNode anteFocusNode,
    required FocusNode closestPinFocusNode,
    required FocusNode newFieldFocusNode,
    required FocusNode mondayMulligansFocusNode,
    required VoidCallback onAnteTap,
    required VoidCallback onClosestPinTap,
    required VoidCallback onNewFieldTap,
    required VoidCallback onMondayMulligansTap,
    required VoidCallback formatCurrency,
    required VoidCallback formatClosestPinCurrency,
    required VoidCallback formatNewFieldCurrency,
    required VoidCallback formatMondayMulligansCurrency,
  }) {
    final config = getResponsiveConfig(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(config.containerPadding),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Text(
                  currentLeague == League.monday ? 'Skats Ante' : 'Player\'s Ante',
                  style: TextStyle(
                    fontSize: config.configLabelFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              flex: 1,
              child: Container(
                height: config.configInputHeight,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: anteController,
                  focusNode: anteFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                  ],
                  style: TextStyle(
                    fontSize: config.configLabelFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  onTap: onAnteTap,
                  onEditingComplete: formatCurrency,
                  enabled: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: config.verticalSpacing),
        
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(config.containerPadding),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Text(
                  'Closest Pin',
                  style: TextStyle(
                    fontSize: config.configLabelFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              flex: 1,
              child: Container(
                height: config.configInputHeight,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: closestPinController,
                  focusNode: closestPinFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                  ],
                  style: TextStyle(
                    fontSize: config.configLabelFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  onTap: onClosestPinTap,
                  onEditingComplete: formatClosestPinCurrency,
                  enabled: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (currentLeague == League.monday) ...[
          SizedBox(height: config.verticalSpacing / 2),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(config.containerPadding),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Mulligans',
                    style: TextStyle(
                      fontSize: config.configLabelFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Expanded(
                flex: 1,
                child: Container(
                  height: config.configInputHeight,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: mondayMulligansController,
                    focusNode: mondayMulligansFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                    ],
                    style: TextStyle(
                      fontSize: config.configLabelFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    onTap: onMondayMulligansTap,
                    onEditingComplete: formatMondayMulligansCurrency,
                    enabled: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        
        if (currentLeague == League.wednesday) ...[
          SizedBox(height: config.verticalSpacing / 2),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(config.containerPadding),
                  decoration: BoxDecoration(
                    color: Colors.orange[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Mulligans',
                    style: TextStyle(
                      fontSize: config.configLabelFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Expanded(
                flex: 1,
                child: Container(
                  height: config.configInputHeight,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: newFieldController,
                    focusNode: newFieldFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]')),
                    ],
                    style: TextStyle(
                      fontSize: config.configLabelFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    onTap: onNewFieldTap,
                    onEditingComplete: formatNewFieldCurrency,
                    enabled: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static Widget buildAdminFunctionsTablet(
    BuildContext context, {
    required bool isTablet10, // Keep for backward compatibility
    required bool isTablet8,  // Keep for backward compatibility
    required League? currentLeague,
    required Widget Function(String, IconData, Color, VoidCallback) buildAdminButton,
    required VoidCallback onFirebasePressed,
  }) {
    final config = getResponsiveConfig(context);
    return Container(
      padding: EdgeInsets.all(config.containerPadding),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(config.borderRadius),
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: config.adminButtonCrossAxisCount,
        mainAxisSpacing: config.adminGridSpacing,
        crossAxisSpacing: config.adminGridSpacing,
        childAspectRatio: config.adminButtonAspectRatio,
        children: [
          buildAdminButton(
            'Firebase Upload',
            Icons.cloud_upload,
            Colors.red[200]!,
            onFirebasePressed,
          ),
        ],
      ),
    );
  }

  static Widget buildLeagueSelectionCompact(
    BuildContext context, {
    required League? currentLeague,
    required VoidCallback selectMondayLeague,
    required VoidCallback selectWednesdayLeague,
  }) {
    final config = getResponsiveConfig(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select League:',
          style: TextStyle(
            fontSize: config.titleFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: config.verticalSpacing / 2),
        
        // Compact league buttons - stacked for narrow space
        Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              child: ElevatedButton(
                onPressed: selectMondayLeague,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLeague == League.monday 
                      ? Colors.green[300] 
                      : Colors.green[100],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.all(config.containerPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(config.borderRadius),
                    side: const BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Monday',
                  style: TextStyle(
                    fontSize: config.buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectWednesdayLeague,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLeague == League.wednesday 
                      ? Colors.orange[300] 
                      : Colors.orange[100],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.all(config.containerPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(config.borderRadius),
                    side: const BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Wednesday',
                  style: TextStyle(
                    fontSize: config.buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: config.verticalSpacing / 2),
        
        // Compact status
        Container(
          padding: EdgeInsets.all(config.containerPadding / 2),
          decoration: BoxDecoration(
            color: currentLeague == League.monday 
                ? Colors.green[300] 
                : currentLeague == League.wednesday 
                    ? Colors.orange[300] 
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(config.borderRadius / 2),
            border: Border.all(
              color: Colors.black,
              width: 1,
            ),
          ),
          child: Text(
            currentLeague != null 
                ? currentLeague.name.toUpperCase()
                : 'No League',
            style: TextStyle(
              fontSize: config.statusFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  static Widget buildLeagueConfigurationCompact(
    BuildContext context, {
    required League? currentLeague,
    required TextEditingController anteController,
    required TextEditingController closestPinController,
    required FocusNode anteFocusNode,
    required FocusNode closestPinFocusNode,
    required VoidCallback onAnteTap,
    required VoidCallback onClosestPinTap,
    required VoidCallback formatCurrency,
    required VoidCallback formatClosestPinCurrency,
  }) {
    final config = getResponsiveConfig(context);
    return Column(
      children: [
        // Compact ante section
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(config.containerPadding / 3),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(config.borderRadius / 3),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  currentLeague == League.monday ? 'Ante' : 'Ante',
                  style: TextStyle(fontSize: config.configLabelFontSize, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: Container(
                height: config.configInputHeight / 2,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(config.borderRadius / 3),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: TextField(
                  controller: anteController,
                  focusNode: anteFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]'))],
                  style: TextStyle(fontSize: config.configLabelFontSize, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  onTap: onAnteTap,
                  onEditingComplete: formatCurrency,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: config.verticalSpacing / 3),
        
        // Compact closest pin section
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(config.containerPadding / 3),
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[200] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[200] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(config.borderRadius / 3),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  'Pin',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: Container(
                height: config.configInputHeight / 2,
                decoration: BoxDecoration(
                  color: currentLeague == League.monday 
                      ? Colors.green[100] 
                      : currentLeague == League.wednesday 
                          ? Colors.orange[100] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(config.borderRadius / 3),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: TextField(
                  controller: closestPinController,
                  focusNode: closestPinFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\$\.]'))],
                  style: TextStyle(fontSize: config.configLabelFontSize, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  onTap: onClosestPinTap,
                  onEditingComplete: formatClosestPinCurrency,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildCompactAdminButton(String title, IconData icon, Color bgColor, VoidCallback onPressed, [BuildContext? context]) {
    final config = context != null ? getResponsiveConfig(context) : null;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          vertical: config?.containerPadding ?? 4, 
          horizontal: config?.containerPadding ?? 2
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config?.borderRadius ?? 6),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: config?.adminIconSize ?? 14),
          SizedBox(height: config?.verticalSpacing ?? 1),
          Text(
            title,
            style: TextStyle(
              fontSize: config?.adminButtonFontSize ?? 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget buildAdminButton(String title, IconData icon, Color bgColor, VoidCallback onPressed, [BuildContext? context]) {
    final config = context != null ? getResponsiveConfig(context) : null;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          vertical: config?.containerPadding ?? 8, 
          horizontal: config?.containerPadding ?? 6
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config?.borderRadius ?? 8),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: config?.adminIconSize ?? 18),
          SizedBox(height: config?.verticalSpacing ?? 2),
          Text(
            title,
            style: TextStyle(
              fontSize: config?.adminButtonFontSize ?? 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}