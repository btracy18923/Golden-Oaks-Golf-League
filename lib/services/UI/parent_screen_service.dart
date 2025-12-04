import 'package:flutter/material.dart';
import '../responsive_typography.dart';
import '../device_detection_service.dart';

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
    // Use unified device detection service for consistent classification
    if (DeviceDetectionService.is6Point5Phone(context)) {
      return _build6InchPhoneLandscape(context);
    } else if (DeviceDetectionService.is8Tablet(context)) {
      return _build8InchTabletLandscape(context);
    } else {
      return _build10InchTabletLandscape(context);
    }
  }


  Widget _build6InchPhoneLandscape(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left Column: Settings widgets
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactAnteWidget(context),
                    const SizedBox(height: 4),
                    _buildCompactClosestPinWidget(context),
                    const SizedBox(height: 4),
                    _buildCompactMulligansWidget(context),
                    const SizedBox(height: 4),
                    _buildCompactCourseSelector(context),
                  ],
                ),
              ),
              const SizedBox(width: 4),
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

  Widget _build8InchTabletLandscape(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left column with title and settings
              Flexible(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabletAnteWidget(context),
                    const SizedBox(height: 8),
                    _buildTabletClosestPinWidget(context),
                    const SizedBox(height: 8),
                    _buildTabletMulligansWidget(context),
                    const SizedBox(height: 8),
                    _buildTabletCourseSelector(context),
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

  Widget _build10InchTabletLandscape(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left column with title and settings
              Flexible(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTablet10AnteWidget(context),
                      const SizedBox(height: 12),
                      _buildTablet10ClosestPinWidget(context),
                      const SizedBox(height: 12),
                      _buildTablet10MulligansWidget(context),
                      const SizedBox(height: 12),
                      _buildTablet10CourseSelector(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
  Widget _buildCompactAnteWidget(BuildContext context) {
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
              style: ResponsiveTypography.labelStyle(context,
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
                        style: ResponsiveTypography.displayStyle(context,
                          fontWeight: FontWeight.bold,
                          color: (isEditingAmount == true && currentEditField == 'ante') ? Colors.blue : Colors.black,
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

  Widget _buildTabletAnteWidget(BuildContext context) {
    return Container(
        height: 60,
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
              style: ResponsiveTypography.labelStyle(context,
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
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: onSkatsAnteEdit,
                  child: Text(
                    skatsAnteDisplayValue ?? '\$${skatsAnte.toStringAsFixed(2)}',
                    style: ResponsiveTypography.displayStyle(context,
                      fontWeight: FontWeight.bold,
                      color: (isEditingAmount == true && currentEditField == 'ante') ? Colors.blue : Colors.black,
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
  Widget _buildCompactClosestPinWidget(BuildContext context) {
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
              'Closest Pin   ',
              style: ResponsiveTypography.labelStyle(context,
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
                        style: ResponsiveTypography.displayStyle(context,
                          fontWeight: FontWeight.bold,
                          color: (isEditingAmount == true && currentEditField == 'closestPin') ? Colors.blue : Colors.black,
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

  Widget _buildTabletClosestPinWidget(BuildContext context) {
    return Container(
        height: 60,
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
              'Closest Pin        ',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120, // Same width as Players Ante
              child: Container(
                height: 40, // Reduced from double.infinity (20% reduction from ~50px)
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
                    style: ResponsiveTypography.displayStyle(context,
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
  Widget _buildCompactMulligansWidget(BuildContext context) {
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
              'Mulligans      ',
              style: ResponsiveTypography.labelStyle(context,
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
                        style: ResponsiveTypography.displayStyle(context,
                          fontWeight: FontWeight.bold,
                          color: (isEditingAmount == true && currentEditField == 'mulligans') ? Colors.blue : Colors.black,
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

  Widget _buildTabletMulligansWidget(BuildContext context) {
    return Container(
        height: 60,
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
              'Mulligans           ',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120, // Same width as Players Ante
              child: Container(
                height: 40, // Reduced from double.infinity (20% reduction from ~50px)
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
                    style: ResponsiveTypography.displayStyle(context,
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
  Widget _buildCompactCourseSelector(BuildContext context) {
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
            Text(
              'Select Course',
              style: ResponsiveTypography.smallStyle(context,
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
                child: _buildCourseDropdown(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletCourseSelector(BuildContext context) {
    return Container(
        height: 90,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Course',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                alignment: Alignment.center,
                child: _buildCourseDropdown(context),
              ),
            ),
          ],
        ),
      );
  }



  Widget _buildCourseDropdown(BuildContext context) {
    return isLoadingCourses 
      ? Center(
          child: SizedBox(
            height: ResponsiveTypography.getBodyText(context) + 4,
            width: ResponsiveTypography.getBodyText(context) + 4,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : DropdownButton<String>(
          value: selectedGolfCourse,
          hint: Center(
            child: Text(
              'Choose Course',
              style: ResponsiveTypography.bodyTextStyle(context,
                color: Colors.black54,
              ),
            ),
          ),
          isExpanded: true,
          underline: Container(),
          style: ResponsiveTypography.bodyTextStyle(context,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          items: golfCourses.map<DropdownMenuItem<String>>((course) {
            return DropdownMenuItem<String>(
              value: course['name'],
              child: Text(
                course['name'],
                style: ResponsiveTypography.bodyTextStyle(context),
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

  // 10" Tablet Widget Methods
  Widget _buildTablet10AnteWidget(BuildContext context) {
    return Container(
        height: 70,
        padding: const EdgeInsets.all(8),
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
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: onSkatsAnteEdit,
                  child: Text(
                    skatsAnteDisplayValue ?? '\$${skatsAnte.toStringAsFixed(2)}',
                    style: ResponsiveTypography.displayStyle(context,
                      fontWeight: FontWeight.bold,
                      color: (isEditingAmount == true && currentEditField == 'ante') ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
  }

  Widget _buildTablet10ClosestPinWidget(BuildContext context) {
    return Container(
        height: 70,
        padding: const EdgeInsets.all(8),
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
              'Closest Pin        ',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: Container(
                height: 45,
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
                    style: ResponsiveTypography.displayStyle(context,
                      fontWeight: FontWeight.bold,
                      color: (isEditingAmount == true && currentEditField == 'closestPin') ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
  }

  Widget _buildTablet10MulligansWidget(BuildContext context) {
    return Container(
        height: 70,
        padding: const EdgeInsets.all(8),
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
              'Mulligans           ',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: Container(
                height: 45,
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
                    style: ResponsiveTypography.displayStyle(context,
                      fontWeight: FontWeight.bold,
                      color: (isEditingAmount == true && currentEditField == 'mulligans') ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
  }

  Widget _buildTablet10CourseSelector(BuildContext context) {
    return Container(
        height: 120,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Course',
              style: ResponsiveTypography.labelStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                alignment: Alignment.center,
                child: _buildCourseDropdown(context),
              ),
            ),
          ],
        ),
      );
  }
}