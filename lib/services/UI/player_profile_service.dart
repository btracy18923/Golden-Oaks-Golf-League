import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/league.dart';

class PlayerProfileService {
  static Widget buildCompactFormField(
    BuildContext context,
    String label, 
    TextEditingController controller, 
    FocusNode focusNode, 
    FocusNode? nextFocus,
    VoidCallback? onUpdatePlayer, {
    TextInputType? keyboardType, 
    List<TextInputFormatter>? inputFormatters
  }) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = size.width;
    
    // Improved responsive breakpoints
    final isLargeTablet = screenWidth >= 1200;
    final isMediumTablet = screenWidth >= 800 && screenWidth < 1200;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 800;
    final isPhone = screenWidth < 600;
    final isTablet = isLargeTablet || isMediumTablet || isSmallTablet;
    final isLandscape = orientation == Orientation.landscape;
    final is6InchPhoneLandscape = isPhone && isLandscape;
    
    // Convert long labels to short labels for compact layouts
    String displayLabel = label;
    if (is6InchPhoneLandscape || (isTablet && isLandscape)) {
      if (label == 'First Name') displayLabel = 'First';
      else if (label == 'Last Name') displayLabel = 'Last';
      else if (label == 'Cell Phone') displayLabel = 'Phone';
      else if (label == 'SKAT#') displayLabel = 'SKAT#';
    }
    
    // Special two-row layout for Email field for all screen sizes
    if (label == 'Email') {
      double labelFontSize = 10;
      double fieldHeight = 28;
      double inputFontSize = 9;
      
      if (!is6InchPhoneLandscape && isTablet) {
        labelFontSize = 11;
        fieldHeight = 32;
        inputFontSize = 11;
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: labelFontSize),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: fieldHeight,
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.only(left: 6, right: 6, top: 2, bottom: 10),
                ),
                style: TextStyle(fontSize: inputFontSize, height: 1.0),
                onFieldSubmitted: (_) {
                  if (onUpdatePlayer != null) {
                    onUpdatePlayer();
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
    
    if (is6InchPhoneLandscape) {
        // Horizontal layout for other fields in landscape mode
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 60, // Fixed width for label
                child: Text(
                  displayLabel == 'SKAT#' ? displayLabel : '$displayLabel:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.only(left: 6, right: 6, top: 2, bottom: 10),
                    ),
                    style: const TextStyle(fontSize: 11, height: 1.0),
                    onFieldSubmitted: (_) {
                      if (onUpdatePlayer != null) {
                        onUpdatePlayer();
                      } else {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
    } else {
      // Adaptive layout for tablets and larger screens
      double labelWidth = 80;
      double fontSize = 11;
      double fieldHeight = 32;
      
      if (isLargeTablet) {
        labelWidth = 100;
        fontSize = 12;
        fieldHeight = 36;
      } else if (isMediumTablet) {
        labelWidth = 90;
        fontSize = 11;
        fieldHeight = 32;
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                '$displayLabel:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: fieldHeight,
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  style: TextStyle(fontSize: fontSize, height: 1.2),
                  onFieldSubmitted: (_) {
                    if (nextFocus != null) {
                      FocusScope.of(context).requestFocus(nextFocus);
                    } else if (onUpdatePlayer != null) {
                      onUpdatePlayer();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  static Widget buildFormField(
    BuildContext context,
    String label, 
    TextEditingController controller, 
    FocusNode focusNode, 
    FocusNode? nextFocus,
    VoidCallback? onUpdatePlayer, {
    TextInputType? keyboardType, 
    List<TextInputFormatter>? inputFormatters
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onFieldSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                } else {
                  if (onUpdatePlayer != null) {
                    onUpdatePlayer();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPlayerTable(
    BuildContext context,
    List<Map<String, dynamic>> players,
    Map<String, dynamic>? selectedPlayer,
    Function(Map<String, dynamic>) onSelectPlayer,
    String Function(String?) formatPhoneNumber,
  ) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = size.width;
    final screenHeight = size.height;
    
    // Improved responsive breakpoints
    final isLargeTablet = screenWidth >= 1200;
    final isMediumTablet = screenWidth >= 800 && screenWidth < 1200;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 800;
    final isPhone = screenWidth < 600;
    final isTablet = isLargeTablet || isMediumTablet || isSmallTablet;
    final isLandscape = orientation == Orientation.landscape;
    final is6InchPhoneLandscape = isPhone && isLandscape;
    
    // Adaptive table width calculation
    double tableWidth;
    double rowHeight;
    double fontSize;
    
    if (isLargeTablet) {
      tableWidth = isLandscape ? (screenWidth * 0.7) - 40 : screenWidth - 60;
      rowHeight = 48;
      fontSize = 14;
    } else if (isMediumTablet) {
      tableWidth = isLandscape ? (screenWidth * 0.65) - 30 : screenWidth - 50;
      rowHeight = 44;
      fontSize = 13;
    } else if (isSmallTablet) {
      tableWidth = isLandscape ? (screenWidth * 0.6) - 25 : screenWidth - 40;
      rowHeight = 40;
      fontSize = 12;
    } else if (is6InchPhoneLandscape) {
      tableWidth = (screenWidth * 0.65) - 20;
      rowHeight = 36;
      fontSize = 11;
    } else {
      // Phone portrait
      tableWidth = screenWidth - 32;
      rowHeight = 48;
      fontSize = 13;
    }
    
    Widget tableWidget = Container(
      width: tableWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            height: rowHeight,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: SizedBox(
              width: tableWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: is6InchPhoneLandscape ? [
                    _buildHeaderCellLeftAlign('Name', tableWidth * 0.40, fontSize),
                    _buildHeaderCellLeftAlign('Skat #', tableWidth * 0.15, fontSize),
                    _buildHeaderCellLeftAlign('Phone', tableWidth * 0.45, fontSize),
                  ] : [
                    _buildHeaderCellLeftAlign('Name', tableWidth * 0.45, fontSize),
                    _buildHeaderCell('Skat #', tableWidth * 0.20, fontSize),
                    _buildHeaderCell('Phone', tableWidth * 0.35, fontSize),
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
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final isSelected = selectedPlayer?['id'] == player['id'];
                      
                      return GestureDetector(
                        onTap: () => onSelectPlayer(player),
                        child: Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.lightGreen[200] : Colors.transparent,
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                          ),
                          child: is6InchPhoneLandscape
                            ? _buildMobilePlayerRow(player, tableWidth, formatPhoneNumber, fontSize) 
                            : _buildTabletPlayerRow(player, tableWidth, formatPhoneNumber, fontSize),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    
    return tableWidget;
  }
  
  static Widget _buildMobilePlayerRow(Map<String, dynamic> player, double tableWidth, String Function(String?) formatPhoneNumber, double fontSize) {
    final is6InchPhoneLandscape = tableWidth <= 540; // Infer from table width instead of screen width
    
    return Row(
      children: [
        _buildDataCell('${player['first'] ?? ''} ${player['last'] ?? ''}', 
                      tableWidth * 0.40, fontSize, alignLeft: true),
        _buildDataCell(player['skat_number']?.toString() ?? '', 
                      tableWidth * 0.15, fontSize),
        _buildDataCell(formatPhoneNumber(player['cell']), 
                      tableWidth * 0.45, fontSize),
      ],
    );
  }
  
  static Widget _buildTabletPlayerRow(Map<String, dynamic> player, double tableWidth, String Function(String?) formatPhoneNumber, double fontSize) {
    return Row(
      children: [
        _buildDataCell('${player['first'] ?? ''} ${player['last'] ?? ''}', tableWidth * 0.45, fontSize, alignLeft: true),
        _buildDataCell(player['skat_number']?.toString() ?? '', tableWidth * 0.20, fontSize),
        _buildDataCell(formatPhoneNumber(player['cell']), tableWidth * 0.35, fontSize),
      ],
    );
  }

  static Widget _buildHeaderCell(String text, double width, double fontSize) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static Widget _buildHeaderCellLeftAlign(String text, double width, double fontSize) {
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

  static Widget _buildDataCell(String text, double width, double fontSize, {bool alignLeft = false}) {
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

  static Widget buildTabletLayout(
    BuildContext context,
    BoxConstraints constraints,
    Widget formSection,
    Widget playerTable,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Form (30%)
        Expanded(
          flex: 30,
          child: SizedBox(
            height: constraints.maxHeight,
            child: formSection,
          ),
        ),
        
        const SizedBox(width: 10),
        
        // Right side - Player list (70%)
        Expanded(
          flex: 70,
          child: SizedBox(
            height: constraints.maxHeight,
            child: playerTable,
          ),
        ),
      ],
    );
  }
  
  static Widget buildMobileLayout(
    BuildContext context,
    BoxConstraints constraints,
    Widget formSection,
    Widget playerTable,
    Widget buttonFooter,
  ) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = size.width;
    
    final isPhone = screenWidth < 600;
    final isLandscape = orientation == Orientation.landscape;
    final is6InchPhoneLandscape = isPhone && isLandscape;
    
    if (is6InchPhoneLandscape) {
      // 6" phone landscape: 2-column layout with form on left, table on right
      final footerHeight = 40.0; // Single row footer height
      final mainContentHeight = constraints.maxHeight - footerHeight - 5; // Content height minus footer and reduced spacing
      
      return Column(
        children: [
          // Main content area - 2 columns
          SizedBox(
            height: mainContentHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Form (40% of width)
                Expanded(
                  flex: 40,
                  child: Container(
                    height: mainContentHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: formSection,
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // Right column - Player Table (60% of width)
                Expanded(
                  flex: 60,
                  child: Container(
                    height: mainContentHeight,
                    child: playerTable,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 2),
          
          // Button footer at bottom
          SizedBox(
            height: footerHeight,
            child: buttonFooter,
          ),
        ],
      );
    } else {
      // Original layout for other mobile sizes
      final formHeight = constraints.maxHeight * 0.6;
      final remainingHeight = constraints.maxHeight - formHeight - 20;
      
      return Column(
        children: [
          // Form section on top
          SizedBox(
            height: formHeight,
            child: formSection,
          ),
          
          const SizedBox(height: 20),
          
          // Player list below
          SizedBox(
            height: remainingHeight,
            child: playerTable,
          ),
        ],
      );
    }
  }

  static Widget buildFormSection(
    BuildContext context,
    Widget Function(String, TextEditingController, FocusNode, FocusNode?, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) buildFormField,
    TextEditingController idController,
    TextEditingController firstController,
    TextEditingController lastController,
    TextEditingController skatController,
    TextEditingController cellController,
    TextEditingController emailController,
    FocusNode idFocus,
    FocusNode firstFocus,
    FocusNode lastFocus,
    FocusNode skatFocus,
    FocusNode cellFocus,
    FocusNode emailFocus,
    Widget actionButtons,
  ) {
    return Column(
      children: [
        // Form fields - scrollable area that takes up available space
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                buildFormField('ID#', idController, idFocus, firstFocus, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                buildFormField('First Name', firstController, firstFocus, lastFocus),
                buildFormField('Last Name', lastController, lastFocus, skatFocus),
                buildFormField('SKAT#', skatController, skatFocus, cellFocus, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                buildFormField('Cell Phone', cellController, cellFocus, emailFocus, 
                  keyboardType: TextInputType.numberWithOptions(decimal: false)),
                buildFormField('Email', emailController, emailFocus, null),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        
        // Action buttons - fixed at bottom
        actionButtons,
      ],
    );
  }
  
  static Widget buildFormSectionWithoutButtons(
    BuildContext context,
    Widget Function(String, TextEditingController, FocusNode, FocusNode?, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) buildCompactFormField,
    TextEditingController idController,
    TextEditingController firstController,
    TextEditingController lastController,
    TextEditingController skatController,
    TextEditingController cellController,
    TextEditingController emailController,
    FocusNode idFocus,
    FocusNode firstFocus,
    FocusNode lastFocus,
    FocusNode skatFocus,
    FocusNode cellFocus,
    FocusNode emailFocus,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 900;
    final is6InchPhoneLandscape = screenWidth <= 900 && !isTablet;
    
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: buildCompactFormField('ID#', idController, idFocus, firstFocus, 
            keyboardType: TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ),
        Expanded(
          flex: 1,
          child: buildCompactFormField('First Name', firstController, firstFocus, lastFocus),
        ),
        Expanded(
          flex: 1,
          child: buildCompactFormField('Last Name', lastController, lastFocus, skatFocus),
        ),
        Expanded(
          flex: 1,
          child: buildCompactFormField('SKAT#', skatController, skatFocus, cellFocus, 
            keyboardType: TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ),
        Expanded(
          flex: 1,
          child: buildCompactFormField('Cell Phone', cellController, cellFocus, emailFocus, 
            keyboardType: TextInputType.numberWithOptions(decimal: false)),
        ),
        Expanded(
          flex: is6InchPhoneLandscape ? 2 : 1,
          child: buildCompactFormField('Email', emailController, emailFocus, null),
        ),
      ],
    );
  }
  
  static Widget buildButtonFooterLandscape(
    VoidCallback onAddPlayer,
    VoidCallback onDeletePlayer,
    VoidCallback onClearForm,
    VoidCallback onReturn,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: onAddPlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: onDeletePlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: onClearForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: onReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Return', style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static Widget buildActionButtons(
    VoidCallback onAddPlayer,
    VoidCallback onUpdatePlayer,
    VoidCallback onDeletePlayer,
    VoidCallback onClearForm,
    VoidCallback onReturnToMainMenu,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAddPlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  child: const Text('Add Player', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpdatePlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  child: const Text('Edit Player', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onDeletePlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  child: const Text('Delete Player', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: ElevatedButton(
                  onPressed: onClearForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  child: const Text('Clear Form', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 30,
          child: ElevatedButton(
            onPressed: onReturnToMainMenu,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[300],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 2),
            ),
            child: const Text('Return to Main Menu', style: TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
  }
}