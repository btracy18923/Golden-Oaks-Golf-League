import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/database_helper.dart';
import '../../models/league.dart';

class MondayGolfCourseScreen extends StatefulWidget {
  final League? league;
  
  const MondayGolfCourseScreen({super.key, this.league});

  @override
  State<MondayGolfCourseScreen> createState() => _MondayGolfCourseScreenState();
}

class _MondayGolfCourseScreenState extends State<MondayGolfCourseScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, dynamic>? _selectedCourse;
  List<Map<String, dynamic>> _courses = [];
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _holesController = TextEditingController();
  final TextEditingController _teesController = TextEditingController();
  final TextEditingController _slopeController = TextEditingController();
  final TextEditingController _travelTimeController = TextEditingController();
  
  // Focus nodes for TAB navigation
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _holesFocus = FocusNode();
  final FocusNode _teesFocus = FocusNode();
  final FocusNode _slopeFocus = FocusNode();
  final FocusNode _travelTimeFocus = FocusNode();
  
  
  // Auto-save timer
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _refreshCourseList();
    _setupAutoSaveListeners();
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      
      // Allow both orientations for phones, prefer landscape for tablets
      if (screenWidth < 600) {
        // Phone - allow both orientations
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        // Tablet - prefer landscape
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    
    _nameController.dispose();
    _phoneController.dispose();
    _holesController.dispose();
    _teesController.dispose();
    _slopeController.dispose();
    _travelTimeController.dispose();
    
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _holesFocus.dispose();
    _teesFocus.dispose();
    _slopeFocus.dispose();
    _travelTimeFocus.dispose();
    
    super.dispose();
  }

  void _setupAutoSaveListeners() {
    _nameController.addListener(_onFormFieldChanged);
    _phoneController.addListener(_onFormFieldChanged);
    _holesController.addListener(_onFormFieldChanged);
    _teesController.addListener(_onFormFieldChanged);
    _slopeController.addListener(_onFormFieldChanged);
    _travelTimeController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() {
    if (_selectedCourse == null) return;
    
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      _autoSaveCourse();
    });
  }

  Future<void> _autoSaveCourse() async {
    if (_selectedCourse == null || !_validateForm()) return;
    
    try {
      await _databaseHelper.updateGolfCourse(_selectedCourse!['id'], {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'holes': int.tryParse(_holesController.text.trim()),
        'tees': _teesController.text.trim(),
        'slope': int.tryParse(_slopeController.text.trim()),
        'travel_time': _travelTimeController.text.trim(),
      });
      
      _refreshCourseList();
    } catch (e) {
      // Silently handle auto-save errors to avoid interrupting user experience
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
    FocusScope.of(context).unfocus();
    _nameController.clear();
    _phoneController.clear();
    _holesController.clear();
    _teesController.clear();
    _slopeController.clear();
    _travelTimeController.clear();
    setState(() {
      _selectedCourse = null;
    });
  }

  void _selectCourse(Map<String, dynamic> course) {
    setState(() {
      _selectedCourse = course;
      _nameController.text = course['name'] ?? '';
      _phoneController.text = course['phone'] ?? '';
      _holesController.text = course['holes']?.toString() ?? '';
      _teesController.text = course['tees'] ?? '';
      _slopeController.text = course['slope']?.toString() ?? '';
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
    if (!_validateForm()) return;
    
    try {
      await _databaseHelper.insertGolfCourse({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'holes': 4,
        'tees': _teesController.text.trim(),
        'slope': int.tryParse(_slopeController.text.trim()),
        'travel_time': _travelTimeController.text.trim(),
        'address': '',
        'city': '',
        'state': '',
        'zip': '',
        'website': '',
      });
      
      _clearForm();
      _refreshCourseList();
      _showSuccessDialog('Course added successfully!');
    } catch (e) {
      _showErrorDialog('Error adding course: $e');
    }
  }


  Future<void> _deleteCourse() async {
    if (_selectedCourse == null) {
      _showErrorDialog('Please select a course to delete');
      return;
    }
    
    final courseName = _selectedCourse!['name'];
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete course "$courseName"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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

  void _showCourseDetails(Map<String, dynamic> course) {
    final addressController = TextEditingController(text: course['address'] ?? '');
    final cityController = TextEditingController(text: course['city'] ?? '');
    final stateController = TextEditingController(text: course['state'] ?? '');
    final zipController = TextEditingController(text: course['zip'] ?? '');
    final websiteController = TextEditingController(text: course['website'] ?? '');
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPhone = screenWidth < 600;
    final dialogWidth = isPhone ? screenWidth * 0.9 : screenWidth * 0.6;
    final maxHeight = screenHeight * 0.8;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Course Details - ${course['name']}',
          style: TextStyle(fontSize: isPhone ? 16 : 18),
        ),
        content: SizedBox(
          width: dialogWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditableDetailField('Address:', addressController),
                  _buildEditableDetailField('City:', cityController),
                  _buildEditableDetailField('State:', stateController),
                  _buildEditableDetailField('ZIP Code:', zipController, keyboardType: TextInputType.number),
                  _buildEditableDetailField('Website:', websiteController),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isPhone ? 14 : 16),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _updateCourseDetails(course['id'], {
                'address': addressController.text.trim(),
                'city': cityController.text.trim(),
                'state': stateController.text.trim(),
                'zip': zipController.text.trim(),
                'website': websiteController.text.trim(),
              });
              Navigator.of(context).pop();
              _refreshCourseList();
            },
            child: Text(
              'Save',
              style: TextStyle(fontSize: isPhone ? 14 : 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final labelWidth = isPhone ? 80.0 : 100.0;
    final fontSize = isPhone ? 12.0 : 14.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isPhone ? 6 : 8),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: fontSize),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 6 : 8,
                  vertical: isPhone ? 10 : 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCourseDetails(int courseId, Map<String, dynamic> details) async {
    try {
      await _databaseHelper.updateGolfCourse(courseId, details);
      _showSuccessDialog('Course details updated successfully!');
    } catch (e) {
      _showErrorDialog('Error updating course details: $e');
    }
  }


  void _showErrorDialog(String message) {
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

  void _showSuccessDialog(String message) {
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

  Widget _buildFormField(String label, TextEditingController controller, FocusNode focusNode, FocusNode? nextFocus, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final labelWidth = isPhone ? 75.0 : 90.0;
    final fontSize = isPhone ? 12.0 : 14.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize - 2,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: TextStyle(fontSize: fontSize * 0.8),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 6 : 8,
                  vertical: isPhone ? 3 : 4,
                ),
              ),
              onFieldSubmitted: (_) {
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
    );
  }

  Widget _buildCourseTable() {
    return Container(
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
                  onTap: () => _selectCourse(course),
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
    );
  }
  
  
  Widget _buildTabletCourseRowExpanded(Map<String, dynamic> course) {
    return Row(
      children: [
        Expanded(flex: 31, child: _buildDataCellExpanded(course['name'] ?? '', leftAlign: true)),
        Expanded(flex: 27, child: _buildDataCellExpanded(_formatPhoneNumber(course['phone'] ?? ''))),
        Expanded(flex: 14, child: _buildDataCellExpanded(course['holes']?.toString() ?? '')),
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
        _buildDataCell(course['holes']?.toString() ?? '', par3Width),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((course['phone'] ?? '').isNotEmpty)
                  Text('Phone: ${_formatPhoneNumber(course['phone'])}', style: const TextStyle(fontSize: 12)),
                Row(
                  children: [
                    if ((course['holes']?.toString() ?? '').isNotEmpty)
                      Text('Par3s: ${course['holes']}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    if ((course['slope']?.toString() ?? '').isNotEmpty)
                      Text('Slope: ${course['slope']}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    if ((course['tees'] ?? '').isNotEmpty)
                      Text('Tees: ${course['tees']}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    if ((course['travel_time'] ?? '').isNotEmpty)
                      Text('Travel: ${course['travel_time']}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _selectCourse(course),
                  icon: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  tooltip: 'Select Course',
                ),
                IconButton(
                  onPressed: () => _showCourseDetails(course),
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  tooltip: 'Details',
                ),
              ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 900;
    final fontSize = isSmallTablet ? 10.0 : 12.0;
    
    return Container(
      width: width,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: isSmallTablet ? 4 : 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
          )
        : Center(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              textAlign: TextAlign.center,
            ),
          ),
    );
  }

  Widget _buildHeaderCellExpanded(String text, {bool leftAlign = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 900;
    final fontSize = isSmallTablet ? 10.0 : 12.0;
    
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: isSmallTablet ? 4 : 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          )
        : Center(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    );
  }

  Widget _buildDataCellExpanded(String text, {bool leftAlign = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 900;
    final fontSize = isSmallTablet ? 10.0 : 12.0;
    
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: isSmallTablet ? 4 : 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
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

  Widget _buildDataCell(String text, double width, {bool leftAlign = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 900;
    final fontSize = isSmallTablet ? 10.0 : 12.0;
    
    return Container(
      width: width,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: isSmallTablet ? 4 : 8),
      child: leftAlign 
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
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



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPhone ? 'Golf Courses' : 'Golf Course Info',
          style: TextStyle(fontSize: isPhone ? 18 : 20),
        ),
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
                padding: EdgeInsets.all(isPhone ? 12 : 20),
                child: isPhone ? _buildPhoneLayout() : _buildTabletLayout(),
              ),
            ),
            _buildFullScreenButtonBar(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 900;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Form (adjust ratio based on screen size)
        Expanded(
          flex: isSmallTablet ? 35 : 30,
          child: _buildFormSection(),
        ),
        
        SizedBox(width: isSmallTablet ? 8 : 10),
        
        // Right side - Course list
        Expanded(
          flex: isSmallTablet ? 65 : 70,
          child: _buildCourseTable(),
        ),
      ],
    );
  }
  
  Widget _buildPhoneLayout() {
    return Column(
      children: [
        // Form section (collapsed by default on phones)
        ExpansionTile(
          title: const Text(
            'Course Form',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          initiallyExpanded: _selectedCourse != null,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: _buildFormSection(),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Course list takes remaining space
        Expanded(
          child: Column(
            children: [
              const Text(
                'Golf Courses',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildPhoneCourseList()),
            ],
          ),
        ),
      ],
    );
  }
  
  
  
  
  
  
  Widget _buildFormSection() {
    return Column(
      children: [
        _buildFormField('Name', _nameController, _nameFocus, _phoneFocus),
        _buildFormField('Phone', _phoneController, _phoneFocus, _holesFocus, 
          keyboardType: TextInputType.phone),
        _buildFormField('# Par3s', _holesController, _holesFocus, _teesFocus, 
          keyboardType: TextInputType.number, 
          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        _buildFormField('Tees', _teesController, _teesFocus, _travelTimeFocus),
        _buildFormField('Travel', _travelTimeController, _travelTimeFocus, null),
      ],
    );
  }

  Widget _buildFullScreenButtonBar() {
    return Container(
      width: double.infinity,
      height: 45,
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
      padding: const EdgeInsets.all(6.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Add Course', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                padding: EdgeInsets.zero,
              ),
              child: const Text('Clear', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                padding: EdgeInsets.zero,
              ),
              child: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}