import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GolfCourseUIService {
  static Widget buildFormField(
    String label, 
    TextEditingController controller, 
    FocusNode focusNode, 
    FocusNode? nextFocus, 
    BuildContext context, {
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
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildEditableDetailField(
    String label, 
    TextEditingController controller, {
    TextInputType? keyboardType
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCourseTable(
    List<Map<String, dynamic>> courses,
    Map<String, dynamic>? selectedCourse,
    Function(Map<String, dynamic>) onSelectCourse,
    Function(Map<String, dynamic>) onShowCourseDetails,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildHeaderCell('Name', 180),
                buildHeaderCell('Phone', 100),
                buildHeaderCell('Par3s', 70),
                buildHeaderCell('Tees', 80),
                buildHeaderCell('Slope', 70),
                buildHeaderCell('Travel', 80),
                buildHeaderCell('Details', 80),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final isSelected = selectedCourse?['id'] == course['id'];
                
                return GestureDetector(
                  onTap: () => onSelectCourse(course),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.lightGreen[200] : Colors.transparent,
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: buildTabletCourseRow(course, onShowCourseDetails),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTabletCourseRow(
    Map<String, dynamic> course,
    Function(Map<String, dynamic>) onShowCourseDetails,
  ) {
    return Row(
      children: [
        buildDataCell(course['name'] ?? '', 180),
        buildDataCell(course['phone'] ?? '', 100),
        buildDataCell(course['Par3s']?.toString() ?? '', 70),
        buildDataCell(course['tees'] ?? '', 80),
        buildDataCell(course['slope']?.toString() ?? '', 70),
        buildDataCell(course['travel_time'] ?? '', 80),
        buildButtonCell(course, 80, onShowCourseDetails),
      ],
    );
  }

  static Widget buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static Widget buildDataCell(String text, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  static Widget buildButtonCell(
    Map<String, dynamic> course, 
    double width,
    Function(Map<String, dynamic>) onShowCourseDetails,
  ) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.all(4),
      child: Center(
        child: ElevatedButton(
          onPressed: () => onShowCourseDetails(course),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[200],
            foregroundColor: Colors.black,
            minimumSize: const Size(70, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Details', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }

  static Widget buildActionButtons({
    required VoidCallback onAddCourse,
    required VoidCallback onUpdateCourse,
    required VoidCallback onDeleteCourse,
    required VoidCallback onClearForm,
    required VoidCallback onReturnToMainMenu,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onAddCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Add Course'),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: ElevatedButton(
                onPressed: onUpdateCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Edit Course'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onDeleteCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Delete Course'),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: ElevatedButton(
                onPressed: onClearForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Clear Form'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onReturnToMainMenu,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[300],
              foregroundColor: Colors.black,
            ),
            child: const Text('Return to Main Menu'),
          ),
        ),
      ],
    );
  }

  static Widget buildTabletLayout({
    required Widget formSection,
    required Widget courseTable,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 30,
          child: SingleChildScrollView(
            child: formSection,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 70,
          child: courseTable,
        ),
      ],
    );
  }

  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '${digits.substring(1, 4)}-${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone;
  }

  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showCourseDetailsDialog({
    required BuildContext context,
    required Map<String, dynamic> course,
    required Function(int, Map<String, dynamic>) onUpdateCourseDetails,
    required VoidCallback onRefresh,
  }) {
    final addressController = TextEditingController(text: course['address'] ?? '');
    final cityController = TextEditingController(text: course['city'] ?? '');
    final stateController = TextEditingController(text: course['state'] ?? '');
    final zipController = TextEditingController(text: course['zip'] ?? '');
    final websiteController = TextEditingController(text: course['website'] ?? '');
    
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Course Details - ${course['name']}'),
        content: SizedBox(
          width: screenWidth * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildEditableDetailField('Address:', addressController),
                buildEditableDetailField('City:', cityController),
                buildEditableDetailField('State:', stateController),
                buildEditableDetailField('ZIP Code:', zipController, keyboardType: TextInputType.number),
                buildEditableDetailField('Website:', websiteController),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await onUpdateCourseDetails(course['id'], {
                'address': addressController.text.trim(),
                'city': cityController.text.trim(),
                'state': stateController.text.trim(),
                'zip': zipController.text.trim(),
                'website': websiteController.text.trim(),
              });
              if (context.mounted) {
                Navigator.of(context).pop();
                onRefresh();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}