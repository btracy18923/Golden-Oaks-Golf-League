import 'package:flutter/material.dart';

class ParentScreenUI extends StatelessWidget {
  final String? selectedGolfCourse;
  final List<Map<String, dynamic>> golfCourses;
  final bool isLoadingCourses;
  final double skatsAnte;
  final double closestPin;
  final double mulligans;
  final String leagueTitle;
  final String anteLabel;
  final VoidCallback onSkatsAnteEdit;
  final VoidCallback onClosestPinEdit;
  final VoidCallback onMulligansEdit;
  final Function(String?) onGolfCourseChanged;
  
  // Optional custom display values for amount fields during keypad editing
  final String? skatsAnteDisplayValue;
  final String? closestPinDisplayValue;
  final String? mulligansDisplayValue;
  final bool? isEditingAmount;
  final String? currentEditField;

  const ParentScreenUI({
    super.key,
    required this.selectedGolfCourse,
    required this.golfCourses,
    required this.isLoadingCourses,
    required this.skatsAnte,
    required this.closestPin,
    required this.mulligans,
    required this.leagueTitle,
    required this.anteLabel,
    required this.onSkatsAnteEdit,
    required this.onClosestPinEdit,
    required this.onMulligansEdit,
    required this.onGolfCourseChanged,
    this.skatsAnteDisplayValue,
    this.closestPinDisplayValue,
    this.mulligansDisplayValue,
    this.isEditingAmount,
    this.currentEditField,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Check if this is a 6.5" phone (screenWidth <= 950)
    if (screenWidth <= 950) {
      return _build6InchPhoneLandscape();
    } else {
      return _build8InchTabletLandscape();
    }
  }


  Widget _build6InchPhoneLandscape() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left Column: Settings widgets
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildCompactAnteWidget(),
                    const SizedBox(height: 8),
                    _buildCompactClosestPinWidget(),
                    const SizedBox(height: 8),
                    _buildCompactMulligansWidget(),
                    const SizedBox(height: 8),
                    _buildCompactCourseSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Column: GoldenOaks Image  
              Expanded(
                flex: 3,
                child: _buildGoldenOaksImage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build8InchTabletLandscape() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left column with title and settings
              Flexible(
                flex: 4,
                child: Column(
                  children: [
                    _buildLeagueTitleWidget(),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTabletAnteWidget(),
                          const SizedBox(height: 3),
                          _buildTabletClosestPinWidget(),
                          const SizedBox(height: 3),
                          _buildTabletMulligansWidget(),
                          const SizedBox(height: 3),
                          _buildTabletCourseSelector(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Side - Golden Oaks Image
              Flexible(
                flex: 6,
                child: _buildGoldenOaksImage(),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // League Title Widgets
  Widget _buildLeagueTitleWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green[300],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Text(
        leagueTitle,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }



  // Ante Widgets (Players Ante/Skats Ante)
  Widget _buildCompactAnteWidget() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              anteLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: GestureDetector(
                  onTap: onSkatsAnteEdit,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        skatsAnteDisplayValue ?? '\$${skatsAnte.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (isEditingAmount == true && currentEditField == 'ante') ? Colors.blue : Colors.black,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletAnteWidget() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              anteLabel,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: GestureDetector(
                  onTap: onSkatsAnteEdit,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        skatsAnteDisplayValue ?? '\$${skatsAnte.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (isEditingAmount == true && currentEditField == 'ante') ? Colors.blue : Colors.black,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  // Closest Pin Widgets
  Widget _buildCompactClosestPinWidget() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Closest Pin   ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: GestureDetector(
                  onTap: onClosestPinEdit,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        closestPinDisplayValue ?? '\$${closestPin.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (isEditingAmount == true && currentEditField == 'closestPin') ? Colors.blue : Colors.black,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletClosestPinWidget() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Closest Pin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: onClosestPinEdit,
                child: Text(
                  closestPinDisplayValue ?? '\$${closestPin.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (isEditingAmount == true && currentEditField == 'closestPin') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  // Mulligans Widgets
  Widget _buildCompactMulligansWidget() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Mulligans      ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: GestureDetector(
                  onTap: onMulligansEdit,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        mulligansDisplayValue ?? '\$${mulligans.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (isEditingAmount == true && currentEditField == 'mulligans') ? Colors.blue : Colors.black,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletMulligansWidget() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Mulligans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: onMulligansEdit,
                child: Text(
                  mulligansDisplayValue ?? '\$${mulligans.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (isEditingAmount == true && currentEditField == 'mulligans') ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  // Course Selector Widgets
  Widget _buildCompactCourseSelector() {
    return Expanded(
      flex: 4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Course',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Expanded(
              flex: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                alignment: Alignment.center,
                child: _buildCourseDropdown(fontSize: 7, hintSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletCourseSelector() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          children: [
            const Text(
              'Select Course',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Expanded(
              flex: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                alignment: Alignment.center,
                child: _buildCourseDropdown(fontSize: 8, hintSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCourseDropdown({required double fontSize, required double hintSize}) {
    return isLoadingCourses 
      ? Center(
          child: SizedBox(
            height: fontSize + 4,
            width: fontSize + 4,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : DropdownButton<String>(
          value: selectedGolfCourse,
          hint: Text(
            'Choose Course',
            style: TextStyle(
              fontSize: hintSize,
              color: Colors.black54,
            ),
          ),
          isExpanded: true,
          underline: Container(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          items: golfCourses.map<DropdownMenuItem<String>>((course) {
            return DropdownMenuItem<String>(
              value: course['name'],
              child: Text(
                course['name'],
                style: TextStyle(fontSize: fontSize * 1.5),
              ),
            );
          }).toList(),
          onChanged: onGolfCourseChanged,
        );
  }

  Widget _buildGoldenOaksImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/GoldenOaks.png',
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Center(
              child: Icon(
                Icons.park,
                size: 60,
                color: Colors.green[600],
              ),
            ),
          );
        },
      ),
    );
  }
}