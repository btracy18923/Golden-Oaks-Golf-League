import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/league.dart';

class PlayerScoresUIService {
  static Widget buildPlayerList({
    required List<Map<String, dynamic>> players,
    required String? selectedPlayer,
    required Function(String) onSelectPlayer,
    required League selectedLeague,
    bool isCompact = false,
    bool hideHeader = false,
  }) {
    double listWidth = isCompact ? double.infinity : 200;
    double headerFontSize = isCompact ? 12 : 16;
    double itemFontSize = isCompact ? 11 : 14;
    double itemPadding = isCompact ? 2 : 4;
    
    Widget playerListView = ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final playerName = '${player['first']} ${player['last']}';
        final isSelected = selectedPlayer == player['last'];
        
        return GestureDetector(
          onTap: () => onSelectPlayer(player['last']),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8, vertical: itemPadding),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (selectedLeague == League.monday ? Colors.green[200] : Colors.amber[200])
                  : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              playerName,
              style: TextStyle(
                fontSize: itemFontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );

    if (hideHeader) {
      return playerListView;
    }

    return Container(
      width: isCompact ? null : listWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 4 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Text(
              'Players',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
            ),
          ),
          Expanded(
            child: playerListView,
          ),
        ],
      ),
    );
  }

  static Widget buildScoresTable({
    required BuildContext context,
    required League selectedLeague,
    required String? selectedPlayer,
    required List<Map<String, dynamic>> scores,
    required bool showAddScoreRow,
    required int? selectedScoreIndex,
    required Set<int> unlockedScoreIds,
    required Function(int) onScoreSelect,
    required Widget Function({required bool isCompact}) buildAddScoreRow,
    required Widget Function(Map<String, dynamic>, bool, {required bool isCompact}) buildScoreRow,
    required Widget Function({required bool isCompact}) buildHeaders,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    double tableWidth;
    if (is6InchPhoneLandscape) {
      tableWidth = selectedLeague == League.monday ? 510 : 550;
    } else {
      tableWidth = selectedLeague == League.monday ? 810 : 870;
    }
    
    final isCompact = is6InchPhoneLandscape;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final finalTableWidth = availableWidth > tableWidth ? availableWidth : tableWidth;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: finalTableWidth,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.grey[200],
                  ),
                  child: buildHeaders(isCompact: isCompact),
                ),
                
                if (selectedPlayer != null && showAddScoreRow) 
                  buildAddScoreRow(isCompact: isCompact),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, index) {
                      final score = scores[index];
                      final isSelected = selectedScoreIndex == index;
                      final scoreId = score['id'] as int;
                      final isUnlocked = unlockedScoreIds.contains(scoreId);
                      
                      return GestureDetector(
                        key: ValueKey(index),
                        onTap: () => onScoreSelect(isSelected ? -1 : index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isUnlocked ? Colors.orange : Colors.black, 
                              width: isUnlocked ? 1.5 : 0.5
                            ),
                            color: isSelected 
                                ? (selectedLeague == League.monday ? Colors.green[200] : Colors.amber[200])
                                : isUnlocked 
                                  ? Colors.orange[50]
                                  : Colors.grey[50],
                          ),
                          child: buildScoreRow(score, isUnlocked, isCompact: isCompact),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildScoreRow({
    required Map<String, dynamic> score,
    required bool isUnlocked,
    required League selectedLeague,
    bool isCompact = false,
  }) {
    final screenWidth = MediaQuery.of(MediaQueryData.fromView(WidgetsBinding.instance.window).size.width).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    if (selectedLeague == League.monday) {
      return Row(
        children: [
          buildFlexDataCellWithIcon(score['name'] ?? '', isUnlocked, isCompact ? 22 : 24, isCompact: isCompact),
          buildFlexDataCell(_formatDateToMMDDYY(score['date_played']), isCompact ? 14 : 14, isCompact: isCompact),
          buildFlexDataCell(score['golf_course'] ?? '', isCompact ? 20 : 18, isCompact: isCompact),
          buildFlexDataCell(is6InchPhoneLandscape ? _formatWinningsWithCents(score['close_pin_winnings']) : _formatWinningsSimple(score['close_pin_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
          buildFlexDataCell('${score['skats_score'] ?? ''}', isCompact ? 10 : 9, isCompact: isCompact),
          buildFlexDataCell(is6InchPhoneLandscape ? _formatWinningsWithCents(score['skat_winnings']) : _formatWinningsSimple(score['skat_winnings']), isCompact ? 18 : 20, isCompact: isCompact),
        ],
      );
    } else {
      return Row(
        children: [
          buildFlexDataCellWithIcon(score['name'] ?? '', isUnlocked, isCompact ? 12 : 12, isCompact: isCompact),
          buildFlexDataCell(_formatDateToMMDDYY(score['date_played']), isCompact ? 14 : 14, isCompact: isCompact),
          buildFlexDataCell(score['golf_course'] ?? '', isCompact ? 18 : 18, isCompact: isCompact),
          buildFlexDataCell('${score['handicap'] ?? 0}', isCompact ? 12 : 12, isCompact: isCompact),
          buildFlexDataCell('${score['gross_score'] ?? ''}', isCompact ? 10 : 9, isCompact: isCompact),
          buildFlexDataCell(_formatWinningsSimple(score['close_pin_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
          buildFlexDataCell(_formatWinningsSimple(score['single_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
          buildFlexDataCell(_formatWinningsSimple(score['group_winnings']), isCompact ? 16 : 15, isCompact: isCompact),
        ],
      );
    }
  }

  static Widget buildAddScoreRow({
    required League selectedLeague,
    required String? selectedPlayer,
    required String selectedGolfCourse,
    required List<String> golfCourses,
    required TextEditingController grossScoreController,
    required TextEditingController skatsController,
    required TextEditingController winningsController,
    required TextEditingController handicapController,
    required TextEditingController closePinController,
    required FocusNode grossScoreFocus,
    required FocusNode skatsFocus,
    required FocusNode winningsFocus,
    required FocusNode handicapFocus,
    required FocusNode closePinFocus,
    required Function(String) onGolfCourseChanged,
    bool isCompact = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: selectedLeague == League.monday ? Colors.green[100] : Colors.amber[100],
      ),
      child: _buildAddScoreRowContent(
        selectedLeague: selectedLeague,
        selectedPlayer: selectedPlayer,
        selectedGolfCourse: selectedGolfCourse,
        golfCourses: golfCourses,
        grossScoreController: grossScoreController,
        skatsController: skatsController,
        winningsController: winningsController,
        handicapController: handicapController,
        closePinController: closePinController,
        grossScoreFocus: grossScoreFocus,
        skatsFocus: skatsFocus,
        winningsFocus: winningsFocus,
        handicapFocus: handicapFocus,
        closePinFocus: closePinFocus,
        onGolfCourseChanged: onGolfCourseChanged,
        isCompact: isCompact,
      ),
    );
  }

  static Widget _buildAddScoreRowContent({
    required League selectedLeague,
    required String? selectedPlayer,
    required String selectedGolfCourse,
    required List<String> golfCourses,
    required TextEditingController grossScoreController,
    required TextEditingController skatsController,
    required TextEditingController winningsController,
    required TextEditingController handicapController,
    required TextEditingController closePinController,
    required FocusNode grossScoreFocus,
    required FocusNode skatsFocus,
    required FocusNode winningsFocus,
    required FocusNode handicapFocus,
    required FocusNode closePinFocus,
    required Function(String) onGolfCourseChanged,
    bool isCompact = false,
  }) {
    final screenWidth = MediaQuery.of(MediaQueryData.fromView(WidgetsBinding.instance.window).size.width).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    if (selectedLeague == League.monday) {
      return Row(
        children: [
          buildFlexDataCell(selectedPlayer ?? '', isCompact ? 22 : 24, isCompact: isCompact),
          buildFlexDataCell(_getCurrentDateMMDDYY(), isCompact ? 14 : 14, isCompact: isCompact),
          buildFlexGolfCourseDropdown(
            selectedGolfCourse: selectedGolfCourse,
            golfCourses: golfCourses,
            onChanged: onGolfCourseChanged,
            flex: isCompact ? 20 : 18,
            isCompact: isCompact,
          ),
          is6InchPhoneLandscape 
            ? buildFlexEditableCellWithBorder(closePinController, closePinFocus, isCompact ? 16 : 15, TextInputType.number, isCompact: isCompact)
            : buildFlexDataCell('\$0.00', isCompact ? 16 : 15, isCompact: isCompact),
          buildFlexEditableCellWithBorder(skatsController, skatsFocus, isCompact ? 10 : 9, TextInputType.number, isCompact: isCompact),
          buildFlexEditableCellWithBorder(winningsController, winningsFocus, isCompact ? 18 : 20, TextInputType.number, isCompact: isCompact),
        ],
      );
    } else {
      return Row(
        children: [
          buildFlexDataCell(selectedPlayer ?? '', isCompact ? 12 : 12, isCompact: isCompact),
          buildFlexDataCell(_getCurrentDateMMDDYY(), isCompact ? 14 : 14, isCompact: isCompact),
          buildFlexDataCell('The Hideout', isCompact ? 18 : 18, isCompact: isCompact),
          buildFlexEditableCellWithBorder(handicapController, handicapFocus, isCompact ? 12 : 12, TextInputType.number, isCompact: isCompact),
          buildFlexEditableCellWithBorder(grossScoreController, grossScoreFocus, isCompact ? 10 : 9, TextInputType.number, isCompact: isCompact),
          buildFlexDataCell('\$0.00', isCompact ? 16 : 15, isCompact: isCompact),
          buildFlexEditableCellWithBorder(winningsController, winningsFocus, isCompact ? 16 : 15, TextInputType.number, isCompact: isCompact),
          buildFlexDataCell('\$0.00', isCompact ? 16 : 15, isCompact: isCompact),
        ],
      );
    }
  }

  static Widget buildHeaders({
    required League selectedLeague,
    bool isCompact = false,
  }) {
    final screenWidth = MediaQuery.of(MediaQueryData.fromView(WidgetsBinding.instance.window).size.width).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    if (selectedLeague == League.monday) {
      return Column(
        children: [
          Row(
            children: [
              buildFlexHeaderCell('Name', isCompact ? 22 : 24, isCompact: isCompact),
              buildFlexHeaderCell('Date', isCompact ? 14 : 14, isCompact: isCompact),
              buildFlexHeaderCell('Golf Course', isCompact ? 20 : 18, isCompact: isCompact),
              buildFlexHeaderCell(is6InchPhoneLandscape ? 'Close Pin\nWinnings' : 'Close Pin', isCompact ? 16 : 15, isCompact: isCompact),
              buildFlexHeaderCell('SKATS', isCompact ? 10 : 9, isCompact: isCompact),
              buildFlexHeaderCell('SKAT\nWinnings', isCompact ? 18 : 20, isCompact: isCompact),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              buildFlexHeaderCell('Name', isCompact ? 12 : 12, isCompact: isCompact),
              buildFlexHeaderCell('Date', isCompact ? 14 : 14, isCompact: isCompact),
              buildFlexHeaderCell('Golf Course', isCompact ? 18 : 18, isCompact: isCompact),
              buildFlexHeaderCell('HC', isCompact ? 12 : 12, isCompact: isCompact),
              buildFlexHeaderCell('Gross', isCompact ? 10 : 9, isCompact: isCompact),
              buildFlexHeaderCell(is6InchPhoneLandscape ? 'Close Pin\nWinnings' : 'Close Pin', isCompact ? 16 : 15, isCompact: isCompact),
              buildFlexHeaderCell('Single\nWinnings', isCompact ? 16 : 15, isCompact: isCompact),
              buildFlexHeaderCell('Group\nWinnings', isCompact ? 16 : 15, isCompact: isCompact),
            ],
          ),
        ],
      );
    }
  }

  static Widget buildFlexHeaderCell(String text, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 40 : 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: isCompact ? 10 : 12,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  static Widget buildFlexDataCell(String text, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontSize: isCompact ? 10 : 12),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  static Widget buildFlexDataCellWithIcon(String text, bool isUnlocked, int flex, {bool isCompact = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: isCompact ? 15 : 20,
              child: Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                size: isCompact ? 10 : 12,
                color: isUnlocked ? Colors.orange : Colors.grey[600],
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: isCompact ? 10 : 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildFlexGolfCourseDropdown({
    required String selectedGolfCourse,
    required List<String> golfCourses,
    required Function(String) onChanged,
    required int flex,
    bool isCompact = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: DropdownButtonFormField<String>(
          value: selectedGolfCourse,
          isExpanded: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            isDense: true,
          ),
          style: TextStyle(fontSize: isCompact ? 10 : 12, color: Colors.black),
          items: golfCourses.map((course) {
            return DropdownMenuItem(
              value: course,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  course, 
                  style: TextStyle(fontSize: isCompact ? 10 : 12),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => onChanged(value!),
        ),
      ),
    );
  }

  static Widget buildFlexEditableCellWithBorder(
    TextEditingController controller, 
    FocusNode focusNode, 
    int flex, 
    TextInputType inputType, 
    {bool isCompact = false}
  ) {
    List<TextInputFormatter>? formatters;
    String? prefixText;
    final screenWidth = MediaQuery.of(MediaQueryData.fromView(WidgetsBinding.instance.window).size.width).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    if (inputType == TextInputType.number) {
      // Determine formatters based on controller usage pattern
      if (controller.text.isEmpty || controller.text.contains('.')) {
        // Likely handicap or decimal field
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          LengthLimitingTextInputFormatter(5),
        ];
      } else {
        // Likely score or whole number field
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ];
      }
      
      // Add currency formatting for winnings fields
      if (controller.hashCode % 2 == 0) { // Simple way to identify winnings fields
        if (is6InchPhoneLandscape) {
          formatters = [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            LengthLimitingTextInputFormatter(6),
          ];
        }
        prefixText = '\$';
      }
    }
    
    return Expanded(
      flex: flex,
      child: Container(
        height: isCompact ? 25 : 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Center(
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: inputType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              prefixText: prefixText,
              prefixStyle: TextStyle(fontSize: isCompact ? 10 : 12),
            ),
            style: TextStyle(fontSize: isCompact ? 10 : 12),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
          ),
        ),
      ),
    );
  }

  static Widget buildActionButtons({
    required BuildContext context,
    required VoidCallback onAddScore,
    required VoidCallback? onEditScore,
    required VoidCallback? onDeleteScore,
    required VoidCallback onClearSelection,
    required VoidCallback onClearAllData,
    required VoidCallback onReturn,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final is6InchPhoneLandscape = screenWidth <= 900;
    
    if (is6InchPhoneLandscape) {
      return _buildCompactActionButtons(
        onAddScore: onAddScore,
        onEditScore: onEditScore,
        onDeleteScore: onDeleteScore,
        onClearSelection: onClearSelection,
        onClearAllData: onClearAllData,
        onReturn: onReturn,
      );
    } else {
      return _buildStandardActionButtons(
        onAddScore: onAddScore,
        onEditScore: onEditScore,
        onDeleteScore: onDeleteScore,
        onClearSelection: onClearSelection,
        onClearAllData: onClearAllData,
        onReturn: onReturn,
      );
    }
  }

  static Widget _buildStandardActionButtons({
    required VoidCallback onAddScore,
    required VoidCallback? onEditScore,
    required VoidCallback? onDeleteScore,
    required VoidCallback onClearSelection,
    required VoidCallback onClearAllData,
    required VoidCallback onReturn,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onAddScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Add Score'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onEditScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Edit Score'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onDeleteScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Delete Score'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onClearSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Clear'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onClearAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All Data'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onReturn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[300],
              foregroundColor: Colors.black,
            ),
            child: const Text('Return to Main Menu'),
          ),
        ],
      ),
    );
  }

  static Widget _buildCompactActionButtons({
    required VoidCallback onAddScore,
    required VoidCallback? onEditScore,
    required VoidCallback? onDeleteScore,
    required VoidCallback onClearSelection,
    required VoidCallback onClearAllData,
    required VoidCallback onReturn,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: onAddScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: onEditScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: onDeleteScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Delete', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: onClearSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Clear', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: onClearAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Clear All', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: onReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      child: const Text('Return', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildButtonFooterLandscape({
    required VoidCallback onAddScore,
    required VoidCallback? onDeleteScore,
    required VoidCallback onClearSelection,
    required VoidCallback onClearAllData,
    required VoidCallback onReturn,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: onAddScore,
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
                onPressed: onDeleteScore,
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
                onPressed: onClearSelection,
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
                onPressed: onClearAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Clear All', style: TextStyle(fontSize: 9)),
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

  static Widget buildTabletStyleLayout({
    required BuildContext context,
    required Widget playerList,
    required Widget scoresTable,
    required Widget buttonFooter,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const footerHeight = 40.0;
        final mainContentHeight = constraints.maxHeight - footerHeight - 5;
        
        return Column(
          children: [
            SizedBox(
              height: mainContentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 20,
                    child: Container(
                      height: mainContentHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: const Border(bottom: BorderSide(color: Colors.grey)),
                            ),
                            child: const Text(
                              'Players',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(child: playerList),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 80,
                    child: Container(
                      height: mainContentHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: scoresTable,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(height: footerHeight, child: buttonFooter),
          ],
        );
      },
    );
  }

  static Widget buildDesktopLayout({
    required Widget playerList,
    required Widget scoresTable,
    required Widget actionButtons,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Player Scores',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              playerList,
              const SizedBox(width: 20),
              scoresTable,
            ],
          ),
        ),
        actionButtons,
      ],
    );
  }

  // Helper functions
  static String _formatWinningsSimple(dynamic winnings) {
    if (winnings == null || winnings == 0) {
      return '\$0';
    }
    int amount = winnings is int ? winnings : (winnings as double).round();
    return '\$$amount';
  }

  static String _formatWinningsWithCents(dynamic winnings) {
    if (winnings == null || winnings == 0) {
      return '\$0.00';
    }
    double amount = winnings is int ? winnings.toDouble() : (winnings as double);
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String _formatDateToMMDDYY(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      DateTime date = DateTime.parse(dateString);
      String month = date.month.toString().padLeft(2, '0');
      String day = date.day.toString().padLeft(2, '0');
      String year = (date.year % 100).toString().padLeft(2, '0');
      return '$month/$day/$year';
    } catch (e) {
      return dateString;
    }
  }

  static String _getCurrentDateMMDDYY() {
    DateTime now = DateTime.now();
    String month = now.month.toString().padLeft(2, '0');
    String day = now.day.toString().padLeft(2, '0');
    String year = (now.year % 100).toString().padLeft(2, '0');
    return '$month/$day/$year';
  }
}