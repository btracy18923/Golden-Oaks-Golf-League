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
                    Expanded(
                      child: Column(
                        children: [
                          const Spacer(flex: 4), // Top spacer for centering
                          Expanded(flex: 8, child: _buildTabletAnteWidget()),
                          const SizedBox(height: 3),
                          Expanded(flex: 8, child: _buildTabletClosestPinWidget()),
                          const SizedBox(height: 3),
                          Expanded(flex: 8, child: _buildTabletMulligansWidget()),
                          const SizedBox(height: 3),
                          Expanded(flex: 8, child: _buildTabletCourseSelector()),
                          const Spacer(flex: 4), // Bottom spacer for centering
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
    return Container(
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
            SizedBox(
              width: 120, // Fixed width increased by 50% from 80px
              child: Container(
                height: 40, // Reduced from double.infinity (20% reduction from ~50px)
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
                          fontSize: 26,
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
            const Spacer(), // Add spacer to push content to the left
          ],
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
    return Container(
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
              'Closest Pin        ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120, // Same width as Players Ante
              child: Container(
                height: 40, // Reduced from double.infinity (20% reduction from ~50px)
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: (isEditingAmount == true && currentEditField == 'closestPin') ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(), // Add spacer to push content to the left
          ],
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
    return Container(
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
              'Mulligans           ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120, // Same width as Players Ante
              child: Container(
                height: 40, // Reduced from double.infinity (20% reduction from ~50px)
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: (isEditingAmount == true && currentEditField == 'mulligans') ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(), // Add spacer to push content to the left
          ],
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
    return Container(
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
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                alignment: Alignment.center,
                child: _buildCourseDropdown(fontSize: 14, hintSize: 10),
              ),
            ),
          ],
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
              fontSize: 20,
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