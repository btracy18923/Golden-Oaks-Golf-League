import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshCourseList();
  }

  @override
  void dispose() {
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
        'holes': int.tryParse(_holesController.text.trim()),
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

  Future<void> _updateCourse() async {
    if (_selectedCourse == null) {
      _showErrorDialog('Please select a course to update');
      return;
    }
    
    if (!_validateForm()) return;
    
    try {
      await _databaseHelper.updateGolfCourse(_selectedCourse!['id'], {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'holes': int.tryParse(_holesController.text.trim()),
        'tees': _teesController.text.trim(),
        'slope': int.tryParse(_slopeController.text.trim()),
        'travel_time': _travelTimeController.text.trim(),
      });
      
      _clearForm();
      _refreshCourseList();
      _showSuccessDialog('Course updated successfully!');
    } catch (e) {
      _showErrorDialog('Error updating course: $e');
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
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Course Details - ${course['name']}'),
        content: SizedBox(
          width: isMobile ? screenWidth * 0.9 : screenWidth * 0.6,
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
        actions: isMobile ? [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await _updateCourseDetails(course['id'], {
                      'address': addressController.text.trim(),
                      'city': cityController.text.trim(),
                      'state': stateController.text.trim(),
                      'zip': zipController.text.trim(),
                      'website': websiteController.text.trim(),
                    });
                    if (mounted) {
                      Navigator.of(context).pop();
                      _refreshCourseList();
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ] : [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
              if (mounted) {
                Navigator.of(context).pop();
                _refreshCourseList();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ],
        ),
      );
    } else {
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
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onFieldSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              },
            ),
          ],
        ),
      );
    } else {
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
  }

  Widget _buildCourseTable() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
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
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: isMobile ? [
                  _buildHeaderCell('Name', 150),
                  _buildHeaderCell('Phone', 120),
                  _buildHeaderCell('Details', 80),
                ] : [
                  _buildHeaderCell('Name', 180),
                  _buildHeaderCell('Phone', 100),
                  _buildHeaderCell('Holes', 70),
                  _buildHeaderCell('Tees', 80),
                  _buildHeaderCell('Slope', 70),
                  _buildHeaderCell('Travel', 80),
                  _buildHeaderCell('Details', 80),
                ],
              ),
            ),
          ),
          // Data rows
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: isMobile ? 350 : 660,
                child: ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    final isSelected = _selectedCourse?['id'] == course['id'];
                    
                    return GestureDetector(
                      onTap: () => _selectCourse(course),
                      child: Container(
                        height: isMobile ? 50 : 40,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.lightGreen[200] : Colors.transparent,
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: isMobile ? _buildMobileCourseRow(course) : _buildTabletCourseRow(course),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileCourseRow(Map<String, dynamic> course) {
    return Row(
      children: [
        _buildDataCell(course['name'] ?? '', 150),
        _buildDataCell(_formatPhoneNumber(course['phone'] ?? ''), 120),
        _buildButtonCell(course, 80),
      ],
    );
  }
  
  Widget _buildTabletCourseRow(Map<String, dynamic> course) {
    return Row(
      children: [
        _buildDataCell(course['name'] ?? '', 180),
        _buildDataCell(course['phone'] ?? '', 100),
        _buildDataCell(course['holes']?.toString() ?? '', 70),
        _buildDataCell(course['tees'] ?? '', 80),
        _buildDataCell(course['slope']?.toString() ?? '', 70),
        _buildDataCell(course['travel_time'] ?? '', 80),
        _buildButtonCell(course, 80),
      ],
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

  Widget _buildHeaderCell(String text, double width) {
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

  Widget _buildDataCell(String text, double width) {
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

  Widget _buildButtonCell(Map<String, dynamic> course, double width) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.all(4),
      child: Center(
        child: ElevatedButton(
          onPressed: () => _showCourseDetails(course),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 900;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Golf Course Info'),
        backgroundColor: widget.league == League.monday ? Colors.green[700] : 
                        widget.league == League.wednesday ? Colors.orange[700] : 
                        Colors.cyan[700],
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        color: Colors.grey[100],
        padding: EdgeInsets.all(isMobile ? 10 : 20),
        child: isTablet 
          ? _buildTabletLayout()
          : _buildMobileLayout(),
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Form (30%)
        Expanded(
          flex: 30,
          child: SingleChildScrollView(
            child: _buildFormSection(),
          ),
        ),
        
        const SizedBox(width: 10),
        
        // Right side - Course list (70%)
        Expanded(
          flex: 70,
          child: _buildCourseTable(),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Form section on top
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: _buildFormSection(),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Course list below
        Expanded(
          flex: 1,
          child: _buildCourseTable(),
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
        _buildFormField('# Holes', _holesController, _holesFocus, _teesFocus, 
          keyboardType: TextInputType.number, 
          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        _buildFormField('Tees', _teesController, _teesFocus, _slopeFocus),
        _buildFormField('Slope', _slopeController, _slopeFocus, _travelTimeFocus, 
          keyboardType: TextInputType.number, 
          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        _buildFormField('Travel Time', _travelTimeController, _travelTimeFocus, null),
        
        const SizedBox(height: 20),
        
        // Action buttons
        _buildActionButtons(),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Add Course'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Edit Course'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _deleteCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Delete Course'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _clearForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Clear Form'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Return to Main Menu'),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addCourse,
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
                  onPressed: _updateCourse,
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
                  onPressed: _deleteCourse,
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
                  onPressed: _clearForm,
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
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
  }
}