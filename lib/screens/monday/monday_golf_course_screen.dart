import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/database_helper.dart';
import '../../models/league.dart';
import '../../services/firebase_upload_service.dart';
import '../../services/responsive_typography.dart';
import '../../services/device_detection_service.dart';

class MondayGolfCourseScreen extends StatefulWidget {
  final League? league;
  
  const MondayGolfCourseScreen({super.key, this.league});

  @override
  State<MondayGolfCourseScreen> createState() => _MondayGolfCourseScreenState();
}

class _MondayGolfCourseScreenState extends State<MondayGolfCourseScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  Map<String, dynamic>? _selectedCourse;
  List<Map<String, dynamic>> _courses = [];
  bool _isKeyboardVisible = false;
  bool _anyFieldHasFocus = false;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _holesController = TextEditingController();
  final TextEditingController _teesController = TextEditingController();
  final TextEditingController _travelTimeController = TextEditingController();
  
  // Focus nodes for TAB navigation
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _holesFocus = FocusNode();
  final FocusNode _teesFocus = FocusNode();
  final FocusNode _travelTimeFocus = FocusNode();
  
  
  // Auto-save timer
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _refreshCourseList();
    _setupAutoSaveListeners();
    _setupFocusListeners();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force landscape only for all devices
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    
    // Upload golf course table to Firebase before leaving
    _uploadGolfCourseDataToFirebase();
    
    _nameController.dispose();
    _phoneController.dispose();
    _holesController.dispose();
    _teesController.dispose();
    _travelTimeController.dispose();
    
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _holesFocus.dispose();
    _teesFocus.dispose();
    _travelTimeFocus.dispose();
    
    super.dispose();
  }

  /// Upload golf course table data to Firebase when leaving the screen
  void _uploadGolfCourseDataToFirebase() async {
    try {
      final league = widget.league ?? League.monday;
      final success = await _firebaseUploadService.uploadGolfCourseTableWithQueue(league);
      if (success) {
      } else {
      }
    } catch (e) {
    }
  }

  void _setupAutoSaveListeners() {
    // Auto-save listeners removed - fields now save only on Enter key press
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
    _holesFocus.addListener(_onFocusChange);
    _teesFocus.addListener(_onFocusChange);
    _travelTimeFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final anyFocused = _nameFocus.hasFocus || 
                      _phoneFocus.hasFocus || 
                      _holesFocus.hasFocus || 
                      _teesFocus.hasFocus || 
                      _travelTimeFocus.hasFocus;
    
    if (_anyFieldHasFocus != anyFocused) {
      setState(() {
        _anyFieldHasFocus = anyFocused;
      });
    }
  }

  Future<void> _saveCurrentField(TextEditingController controller) async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No course selected - cannot save field'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // For now, just update the in-memory data without database save
    // This will help us isolate if the issue is database-specific
    
    String fieldName = '';
    String newValue = '';
    
    if (controller == _nameController) {
      fieldName = 'name';
      newValue = controller.text.trim();
    } else if (controller == _phoneController) {
      fieldName = 'phone'; 
      newValue = controller.text.trim();
    } else if (controller == _holesController) {
      fieldName = 'Par3s';
      newValue = controller.text.trim();
    } else if (controller == _teesController) {
      fieldName = 'tees';
      newValue = controller.text.trim();
    } else if (controller == _travelTimeController) {
      fieldName = 'travel_time';
      newValue = controller.text.trim();
    }
    
    // Now actually save to database
    try {
      Map<String, dynamic> updateData = {};
      
      if (fieldName == 'Par3s') {
        updateData[fieldName] = int.tryParse(newValue);
      } else {
        updateData[fieldName] = newValue;
      }
      
      // Save to database using the course ID
      await _databaseHelper.updateGolfCourse(_selectedCourse!['id'], updateData);
      
      // Refresh course list and re-select current course
      await _refreshCourseList();
      
      // Find the updated course by ID
      final updatedCourse = _courses.firstWhere(
        (course) => course['id'] == _selectedCourse!['id'],
        orElse: () => _selectedCourse!,
      );
      
      // Convert to mutable map and update _selectedCourse
      _selectedCourse = Map<String, dynamic>.from(updatedCourse);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fieldName saved successfully'),
          duration: const Duration(seconds: 1),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving $fieldName: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _refreshCourseList() async {
    try {
      final courses = await _databaseHelper.getAllGolfCourses();
      setState(() {
        _courses = courses;
      });
    } catch (e) {
      _showErrorDialog('Error loading courses: $e');
    }
  }



  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _holesController.clear();
    _teesController.clear();
    _travelTimeController.clear();
    setState(() {
      _selectedCourse = null;
    });
    // Unfocus after setState to prevent layout shifts
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _selectCourse(Map<String, dynamic> course) {
    // If clicking on the same course that's already selected, just proceed
    if (_selectedCourse?['id'] == course['id']) {
      _loadCourseData(course);
      return;
    }
    
    // Check if any form data exists that would be overwritten when selecting a DIFFERENT course
    bool hasFormData = _nameController.text.trim().isNotEmpty ||
                      _phoneController.text.trim().isNotEmpty ||
                      _holesController.text.trim().isNotEmpty ||
                      _teesController.text.trim().isNotEmpty ||
                      _travelTimeController.text.trim().isNotEmpty;
    
    // Only show dialog when switching to a different course while form has data
    if (hasFormData && _selectedCourse != null) {
      // Show confirmation dialog before overwriting form data
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Load Course Data?', style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.w600)),
          content: Text('This will replace the current form data with "${course['name']}". Continue?', style: ResponsiveTypography.bodyTextStyle(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: ResponsiveTypography.buttonStyle(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _loadCourseData(course);
              },
              child: Text('Load', style: ResponsiveTypography.buttonStyle(context)),
            ),
          ],
        ),
      );
    } else {
      _loadCourseData(course);
    }
  }
  
  void _loadCourseData(Map<String, dynamic> course) {
    setState(() {
      _selectedCourse = Map<String, dynamic>.from(course);
      _nameController.text = course['name'] ?? '';
      _phoneController.text = course['phone'] ?? '';
      _holesController.text = course['Par3s']?.toString() ?? '';
      _teesController.text = course['tees'] ?? '';
      _travelTimeController.text = course['travel_time'] ?? '';
    });
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Course Name is required!');
      return false;
    }
    return true;
  }

  Future<void> _addCourse() async {
    // Remove focus from form fields immediately
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_validateForm()) return;

    try {
      await _databaseHelper.insertGolfCourse({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'Par3s': 4,
        'tees': _teesController.text.trim(),
        'travel_time': _travelTimeController.text.trim(),
      });
      
      _clearForm();
      _refreshCourseList();
      _showSuccessDialog('Course added successfully!');
    } catch (e) {
      _showErrorDialog('Error adding course: $e');
    }
  }


  Future<void> _deleteCourse() async {
    // Remove focus from form fields immediately
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedCourse == null) {
      _showErrorDialog('Please select a course to delete');
      return;
    }
    
    final courseName = _selectedCourse!['name'];
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete course "$courseName"?\n\nThis action cannot be undone.', style: ResponsiveTypography.bodyTextStyle(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: ResponsiveTypography.buttonStyle(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: ResponsiveTypography.buttonStyle(context)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _databaseHelper.deleteGolfCourse(_selectedCourse!['id']);
        _clearForm();
        _refreshCourseList();
        _showSuccessDialog('Course deleted successfully!');
      } catch (e) {
        _showErrorDialog('Error deleting course: $e');
      }
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error', style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.w600)),
        content: Text(message, style: ResponsiveTypography.bodyTextStyle(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: ResponsiveTypography.buttonStyle(context)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success', style: ResponsiveTypography.headingStyle(context, fontWeight: FontWeight.w600)),
        content: Text(message, style: ResponsiveTypography.bodyTextStyle(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: ResponsiveTypography.buttonStyle(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, FocusNode focusNode, FocusNode? nextFocus, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    final isPhone = DeviceDetectionService.is6Point5Phone(context);
    final labelWidth = isPhone ? 75.0 : 90.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () {
          // Force focus to this field and prevent event propagation
          FocusScope.of(context).requestFocus(focusNode);
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                '$label:',
                style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: ResponsiveTypography.smallStyle(context),
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 6 : 8,
                  vertical: isPhone ? 3 : 4,
                ),
              ),
              onFieldSubmitted: (_) {
                _saveCurrentField(controller);
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCourseTable() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[50],
          ),
          child: Column(
        children: [
          // Header row
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 31, child: _buildHeaderCellExpanded('Name', leftAlign: true)),
                Expanded(flex: 27, child: _buildHeaderCellExpanded('Phone')),
                Expanded(flex: 14, child: _buildHeaderCellExpanded('Par3s')),
                Expanded(flex: 16, child: _buildHeaderCellExpanded('Tees')),
                Expanded(flex: 12, child: _buildHeaderCellExpanded('Travel')),
              ],
            ),
          ),
          // Data rows
          Expanded(
            child: ListView.builder(
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final isSelected = _selectedCourse?['id'] == course['id'];
                
                return GestureDetector(
                  onTap: (_isKeyboardVisible || _anyFieldHasFocus) ? null : () => _selectCourse(course),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.lightGreen[200] : Colors.transparent,
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: _buildTabletCourseRowExpanded(course),
                  ),
                );
              },
            ),
          ),
        ],
          ),
        ),
        // Overlay when keyboard is visible to prevent touch-through
        if (_isKeyboardVisible)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: Icon(
                Icons.keyboard,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
  
  
  Widget _buildTabletCourseRowExpanded(Map<String, dynamic> course) {
    return Row(
      children: [
        Expanded(flex: 31, child: _buildDataCellExpanded(course['name'] ?? '', leftAlign: true)),
        Expanded(flex: 27, child: _buildDataCellExpanded(_formatPhoneNumber(course['phone'] ?? ''))),
        Expanded(flex: 14, child: _buildDataCellExpanded(course['Par3s']?.toString() ?? '')),
        Expanded(flex: 16, child: _buildDataCellExpanded(course['tees'] ?? '')),
        Expanded(flex: 12, child: _buildDataCellExpanded(course['travel_time'] ?? '')),
      ],
    );
  }

  Widget _buildTabletCourseRow(Map<String, dynamic> course, double nameWidth, double phoneWidth, double par3Width, double teesWidth, double travelWidth) {
    return Row(
      children: [
        _buildDataCell(course['name'] ?? '', nameWidth, leftAlign: true),
        _buildDataCell(_formatPhoneNumber(course['phone'] ?? ''), phoneWidth),
        _buildDataCell(course['Par3s']?.toString() ?? '', par3Width),
        _buildDataCell(course['tees'] ?? '', teesWidth),
        _buildDataCell(course['travel_time'] ?? '', travelWidth),
      ],
    );
  }
  
  Widget _buildPhoneCourseList() {
    return ListView.builder(
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        final isSelected = _selectedCourse?['id'] == course['id'];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          color: isSelected ? Colors.lightGreen[200] : Colors.white,
          child: ListTile(
            title: Text(
              course['name'] ?? '',
              style: ResponsiveTypography.bodyTextStyle(context, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((course['phone'] ?? '').isNotEmpty)
                  Text('Phone: ${_formatPhoneNumber(course['phone'])}', style: ResponsiveTypography.smallStyle(context)),
                Row(
                  children: [
                    if ((course['Par3s']?.toString() ?? '').isNotEmpty)
                      Text('Par3s: ${course['Par3s']}', style: ResponsiveTypography.smallStyle(context)),
                    const SizedBox(width: 16),
                  ],
                ),
                Row(
                  children: [
                    if ((course['tees'] ?? '').isNotEmpty)
                      Text('Tees: ${course['tees']}', style: ResponsiveTypography.smallStyle(context)),
                    const SizedBox(width: 16),
                    if ((course['travel_time'] ?? '').isNotEmpty)
                      Text('Travel: ${course['travel_time']}', style: ResponsiveTypography.smallStyle(context)),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _selectCourse(course),
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.green : Colors.grey,
              ),
              tooltip: 'Select Course',
            ),
            onTap: () => _selectCourse(course),
          ),
        );
      },
    );
  }
  
  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '${digits.substring(1, 4)}-${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone;
  }

  Widget _buildHeaderCell(String text, double width, {bool leftAlign = false}) {
    
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
            ),
          )
        : Center(
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
    );
  }

  Widget _buildHeaderCellExpanded(String text, {bool leftAlign = false}) {
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          )
        : Center(
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    );
  }

  Widget _buildDataCellExpanded(String text, {bool leftAlign = false}) {
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context),
              overflow: TextOverflow.ellipsis,
            ),
          )
        : Center(
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool leftAlign = false}) {
    
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context),
              overflow: TextOverflow.ellipsis,
            ),
          )
        : Center(
            child: Text(
              text,
              style: ResponsiveTypography.smallStyle(context),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    );
  }



  @override
  Widget build(BuildContext context) {
    // Use keyboard visibility directly from MediaQuery without setState
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (DeviceDetectionService.is6Point5Phone(context)) {
      return _buildPhoneLayout();
    } else if (DeviceDetectionService.is8Tablet(context)) {
      return _buildTablet8Layout();
    } else {
      return _buildTablet10Layout();
    }
  }
  
  Widget _buildTablet8Layout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Golf Course Info - Monday League- ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.appBarTitleStyle(context),
        ),
        centerTitle: true,
        backgroundColor: widget.league == League.monday ? Colors.green[700] : 
                        widget.league == League.wednesday ? Colors.orange[700] : 
                        Colors.cyan[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 35,
                      child: _buildFormSection(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 65,
                      child: _buildCourseTable(),
                    ),
                  ],
                ),
              ),
            ),
            _buildFullScreenButtonBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet10Layout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Golf Course Info - Monday League - ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.appBarTitleStyle(context),
        ),
        centerTitle: true,
        backgroundColor: widget.league == League.monday ? Colors.green[700] :
                        widget.league == League.wednesday ? Colors.orange[700] :
                        Colors.cyan[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 30,
                      child: _buildFormSection(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 70,
                      child: _buildCourseTable(),
                    ),
                  ],
                ),
              ),
            ),
            _buildFullScreenButtonBar(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhoneLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Golf Courses - Monday League - ${DeviceDetectionService.getDeviceName(context)}',
          style: ResponsiveTypography.appBarTitleStyle(context),
        ),
        centerTitle: true,
        backgroundColor: widget.league == League.monday ? Colors.green[700] :
                        widget.league == League.wednesday ? Colors.orange[700] :
                        Colors.cyan[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Form (non-scrollable) - 35%
                    Expanded(
                      flex: 35,
                      child: _buildFormSection(),
                    ),
                    const SizedBox(width: 8),
                    // Right side: Course table - 65%
                    Expanded(
                      flex: 65,
                      child: _buildCourseTable(),
                    ),
                  ],
                ),
              ),
            ),
            _buildFullScreenButtonBar(),
          ],
        ),
      ),
    );
  }
  
  
  
  
  
  
  Widget _buildFormSection() {
    return GestureDetector(
      onTap: () {
        // Absorb taps on form area to prevent bleeding to table
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
        _buildFormField('Name', _nameController, _nameFocus, _phoneFocus),
        _buildFormField('Phone', _phoneController, _phoneFocus, _holesFocus, 
          keyboardType: TextInputType.phone),
        _buildFormField('Par3s', _holesController, _holesFocus, _teesFocus,
          keyboardType: TextInputType.number, 
          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        _buildFormField('Tees', _teesController, _teesFocus, _travelTimeFocus),
        _buildFormField('Travel', _travelTimeController, _travelTimeFocus, null),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenButtonBar() {
    final isPhone = DeviceDetectionService.is6Point5Phone(context);
    const double phoneHeight = 60.0;
    const double tabletHeight = 90.0;
    final buttonBarHeight = isPhone ? phoneHeight : tabletHeight;

    return SizedBox(
      height: buttonBarHeight,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
                ),
                child: Text('◄---- Back', style: ResponsiveTypography.buttonStyle(context, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: _clearForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
                ),
                child: Text('Clear', style: ResponsiveTypography.buttonStyle(context, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedCourse != null ? _deleteCourse : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCourse != null ? Colors.red[300] : Colors.grey[400],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
                ),
                child: Text('Delete', style: ResponsiveTypography.buttonStyle(context, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: _addCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
                ),
                child: Text('Add Course', style: ResponsiveTypography.buttonStyle(context, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}