import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'monday_player_selection_screen.dart';
import 'monday_player_scores_screen.dart';
import 'monday_player_profile_screen.dart';
import 'monday_golf_course_screen.dart';
import '../admin_screen.dart';
import '../../models/league.dart';
import '../../services/database_helper.dart';
import '../../services/shared/league_purse_service.dart';

class MondayParentScreen extends StatefulWidget {
  const MondayParentScreen({super.key});

  @override
  State<MondayParentScreen> createState() => _MondayParentScreenState();
}

class _MondayParentScreenState extends State<MondayParentScreen> {
  String? selectedGolfCourse;
  List<Map<String, dynamic>> golfCourses = [];
  bool isLoadingCourses = true;
  
  // Editable league settings
  double skatsAnte = 5.00;
  double closestPin = 4.00;
  double mulligans = 2.00;
  
  // Controllers for edit fields
  final TextEditingController _skatsAnteController = TextEditingController();
  final TextEditingController _closestPinController = TextEditingController();
  final TextEditingController _mulligansController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _loadGolfCourses();
    _skatsAnteController.text = skatsAnte.toStringAsFixed(2);
    _closestPinController.text = closestPin.toStringAsFixed(2);
    _mulligansController.text = mulligans.toStringAsFixed(2);
    
    // Set the initial Players Ante value in the league service
    LeaguePurseService.setPlayersAnte(skatsAnte);
  }

  void _setOrientation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lock to landscape mode for Monday League
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }
  
  @override
  void dispose() {
    _skatsAnteController.dispose();
    _closestPinController.dispose();
    _mulligansController.dispose();
    super.dispose();
  }

  Future<void> _loadGolfCourses() async {
    try {
      final courses = await DatabaseHelper().getAllGolfCourses();
      setState(() {
        golfCourses = courses;
        isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCourses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading golf courses: $e')),
        );
      }
    }
  }
  
  void navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  void _editValue(String title, TextEditingController controller, Function(double) onSave) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  border: const OutlineInputBorder(),
                  prefixText: '\$',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value >= 0) {
                  onSave(value);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monday League - Golden Oaks Golf',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          const Icon(
            Icons.storage,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 8.0),
        child: Column(
          children: [
            // League Info Section
            Expanded(
              flex: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (isLandscape) {
                    // Check if this is a 6.5" phone (screenWidth <= 950)
                    if (screenWidth <= 950) {
                      // Special layout for 6" phones - two columns without Monday League title
                      return Column(
                        children: [
                          // Two-column layout
                          Expanded(
                            child: Row(
                              children: [
                                // Left Column: Players Ante & Select Course
                                Expanded(
                                  flex: 2, // More width for 6" phone landscape
                                  child: Column(
                                    children: [
                                      // Players Ante (Skats Ante)
                                      Expanded(
                                        flex: 3, // 25% smaller than Select Course
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Players Ante',
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
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: GestureDetector(
                                                    onTap: () => _editValue('Players Ante', _skatsAnteController, (value) {
                                                      setState(() {
                                                        skatsAnte = value;
                                                        _skatsAnteController.text = value.toStringAsFixed(2);
                                                      });
                                                    }),
                                                    child: Text(
                                                      '\$${skatsAnte.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Closest Pin
                                      Expanded(
                                        flex: 3, // 25% smaller than Select Course
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Closest Pin',
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
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: GestureDetector(
                                                    onTap: () => _editValue('Closest Pin', _closestPinController, (value) {
                                                      setState(() {
                                                        closestPin = value;
                                                        _closestPinController.text = value.toStringAsFixed(2);
                                                      });
                                                    }),
                                                    child: Text(
                                                      '\$${closestPin.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Mulligans
                                      Expanded(
                                        flex: 3, // 25% smaller than Select Course
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Mulligans',
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
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: GestureDetector(
                                                    onTap: () => _editValue('Mulligans', _mulligansController, (value) {
                                                      setState(() {
                                                        mulligans = value;
                                                        _mulligansController.text = value.toStringAsFixed(2);
                                                      });
                                                    }),
                                                    child: Text(
                                                      '\$${mulligans.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Select Course
                                      Expanded(
                                        flex: 4, // Larger than other widgets
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
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
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: isLoadingCourses 
                                                    ? const Center(
                                                        child: SizedBox(
                                                          height: 12,
                                                          width: 12,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                      )
                                                    : DropdownButton<String>(
                                                        value: selectedGolfCourse,
                                                        hint: const Text(
                                                          'Choose Course',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.black54,
                                                          ),
                                                        ),
                                                        isExpanded: true,
                                                        underline: Container(),
                                                        style: const TextStyle(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                        items: golfCourses.map<DropdownMenuItem<String>>((course) {
                                                          return DropdownMenuItem<String>(
                                                            value: course['name'],
                                                            child: Text(
                                                              course['name'],
                                                              style: const TextStyle(fontSize: 10),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (String? newValue) {
                                                          setState(() {
                                                            selectedGolfCourse = newValue;
                                                          });
                                                        },
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 8),
                                
                                // Right Column: GoldenOaks Image  
                                Expanded(
                                  flex: 3, // More width for image
                                  child: ClipRRect(
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Original layout for 8" tablets (screenWidth > 950)
                      return Column(
                        children: [
                          // Compact settings row and image
                          Expanded(
                            child: Row(
                              children: [
                                // Left column with title and settings
                                Flexible(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      // League Title aligned with boxes below
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.green[300],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Text(
                                          'MONDAY LEAGUE',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 3),
                                      
                                      // Four setting boxes
                                      Expanded(
                                        child: Column(
                                    children: [
                                      // Skats Ante
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Skats Ante',
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
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: GestureDetector(
                                                  onTap: () => _editValue('Skats Ante', _skatsAnteController, (value) {
                                                    setState(() {
                                                      skatsAnte = value;
                                                      _skatsAnteController.text = value.toStringAsFixed(2);
                                                      // Update the Players Ante value in the league service
                                                      LeaguePurseService.setPlayersAnte(value);
                                                    });
                                                  }),
                                                  child: Text(
                                                    '\$${skatsAnte.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 3),
                                      
                                      // Closest Pin
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
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
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: GestureDetector(
                                                  onTap: () => _editValue('Closest Pin', _closestPinController, (value) {
                                                    setState(() {
                                                      closestPin = value;
                                                      _closestPinController.text = value.toStringAsFixed(2);
                                                    });
                                                  }),
                                                  child: Text(
                                                    '\$${closestPin.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 3),
                                      
                                      // Mulligans
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
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
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: GestureDetector(
                                                  onTap: () => _editValue('Mulligans', _mulligansController, (value) {
                                                    setState(() {
                                                      mulligans = value;
                                                      _mulligansController.text = value.toStringAsFixed(2);
                                                    });
                                                  }),
                                                  child: Text(
                                                    '\$${mulligans.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 3),
                                      
                                      // Select Course
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
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
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: isLoadingCourses 
                                                    ? const Center(
                                                        child: SizedBox(
                                                          height: 12,
                                                          width: 12,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                      )
                                                    : DropdownButton<String>(
                                                        value: selectedGolfCourse,
                                                        hint: const Text(
                                                          'Choose Course',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.black54,
                                                          ),
                                                        ),
                                                        isExpanded: true,
                                                        underline: Container(),
                                                        style: const TextStyle(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                        items: golfCourses.map<DropdownMenuItem<String>>((course) {
                                                          return DropdownMenuItem<String>(
                                                            value: course['name'],
                                                            child: Text(
                                                              course['name'],
                                                              style: const TextStyle(fontSize: 10),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (String? newValue) {
                                                          setState(() {
                                                            selectedGolfCourse = newValue;
                                                          });
                                                        },
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                        ],
                                      ),
                                    ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Right Side - Golden Oaks Image (shown for 8" tablets)
                                Flexible(
                                  flex: 6,
                                  child: ClipRRect(
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
                                              size: 80,
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
                        ],
                      );
                    }
                  } else {
                    // Check for 8" tablet portrait mode
                    final is8InchTabletPortrait = !isLandscape && 
                                                 screenWidth >= 600 && 
                                                 screenWidth <= 900;
                    
                    if (is8InchTabletPortrait) {
                      // Single vertical column layout for 8" portrait
                      return Column(
                        children: [
                          // 4 widgets at 50% screen width
                          Center(
                            child: SizedBox(
                              width: screenWidth * 0.5, // 50% of screen width
                              child: Column(
                                children: [
                              // League Title
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green[300],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: const Text(
                                  'MONDAY LEAGUE',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Skats Ante
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Skats Ante',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _editValue('Skats Ante', _skatsAnteController, (value) {
                                          setState(() {
                                            skatsAnte = value;
                                            _skatsAnteController.text = value.toStringAsFixed(2);
                                            // Update the Players Ante value in the league service
                                            LeaguePurseService.setPlayersAnte(value);
                                          });
                                        }),
                                        child: Text(
                                          '\$${skatsAnte.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Closest Pin
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _editValue('Closest Pin', _closestPinController, (value) {
                                          setState(() {
                                            closestPin = value;
                                            _closestPinController.text = value.toStringAsFixed(2);
                                          });
                                        }),
                                        child: Text(
                                          '\$${closestPin.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Mulligans
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _editValue('Mulligans', _mulligansController, (value) {
                                          setState(() {
                                            mulligans = value;
                                            _mulligansController.text = value.toStringAsFixed(2);
                                          });
                                        }),
                                        child: Text(
                                          '\$${mulligans.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Select Course
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Select Course',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: isLoadingCourses 
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : DropdownButton<String>(
                                            value: selectedGolfCourse,
                                            hint: const Text(
                                              'Choose Course',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            isExpanded: true,
                                            underline: Container(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            items: golfCourses.map<DropdownMenuItem<String>>((course) {
                                              return DropdownMenuItem<String>(
                                                value: course['name'],
                                                child: Text(
                                                  course['name'],
                                                  style: const TextStyle(fontSize: 18),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedGolfCourse = newValue;
                                              });
                                            },
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Golden Oaks Image with correct aspect ratio - full width
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/GoldenOaks.png',
                                  fit: BoxFit.contain,
                                  width: double.infinity,
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
                                          size: 80,
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
                      );
                    } else {
                      // Check for 6" phone portrait mode
                      final is6InchPhonePortrait = !isLandscape && screenWidth <= 600;
                      
                      if (is6InchPhonePortrait) {
                        // 6" phone portrait mode layout
                        return Column(
                          children: [
                            // League Title - horizontal layout for 6" phone portrait
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.green[300],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'M',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'O',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'N',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'D',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'A',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Y',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'L',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'E',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'A',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'U',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'E',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Settings in single vertical column
                            Expanded(
                              child: Column(
                                children: [
                                  // Skats Ante
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Skats Ante',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                            ),
                                            child: GestureDetector(
                                              onTap: () => _editValue('Skats Ante', _skatsAnteController, (value) {
                                                setState(() {
                                                  skatsAnte = value;
                                                  _skatsAnteController.text = value.toStringAsFixed(2);
                                                  // Update the Players Ante value in the league service
                                                  LeaguePurseService.setPlayersAnte(value);
                                                });
                                              }),
                                              child: Text(
                                                '\$${skatsAnte.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Closest Pin
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Closest Pin',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                            ),
                                            child: GestureDetector(
                                              onTap: () => _editValue('Closest Pin', _closestPinController, (value) {
                                                setState(() {
                                                  closestPin = value;
                                                  _closestPinController.text = value.toStringAsFixed(2);
                                                });
                                              }),
                                              child: Text(
                                                '\$${closestPin.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Mulligans
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Mulligans',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                            ),
                                            child: GestureDetector(
                                              onTap: () => _editValue('Mulligans', _mulligansController, (value) {
                                                setState(() {
                                                  mulligans = value;
                                                  _mulligansController.text = value.toStringAsFixed(2);
                                                });
                                              }),
                                              child: Text(
                                                '\$${mulligans.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Select Course
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Select Course',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: 1,
                                                ),
                                              ),
                                              child: isLoadingCourses 
                                                ? const Center(
                                                    child: SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  )
                                                : DropdownButton<String>(
                                                    value: selectedGolfCourse,
                                                    hint: const Text(
                                                      'Choose Course',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                    isExpanded: true,
                                                    underline: Container(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                    items: golfCourses.map<DropdownMenuItem<String>>((course) {
                                                      return DropdownMenuItem<String>(
                                                        value: course['name'],
                                                        child: Text(
                                                          course['name'],
                                                          style: const TextStyle(fontSize: 14),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (String? newValue) {
                                                      setState(() {
                                                        selectedGolfCourse = newValue;
                                                      });
                                                    },
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Original layout for larger screens
                        return Row(
                          children: [
                            // Left Side - League Info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // League Title
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.green[300],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Text(
                                      'MONDAY LEAGUE',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                
                                const SizedBox(height: 20),
                                
                                // Monday League Settings
                                Row(
                                  children: [
                                    // Skats Ante
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[200],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Skats Ante',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: 1,
                                                ),
                                              ),
                                              child: GestureDetector(
                                                onTap: () => _editValue('Skats Ante', _skatsAnteController, (value) {
                                                  setState(() {
                                                    skatsAnte = value;
                                                    _skatsAnteController.text = value.toStringAsFixed(2);
                                                    // Update the Players Ante value in the league service
                                                    LeaguePurseService.setPlayersAnte(value);
                                                  });
                                                }),
                                                child: Text(
                                                  '\$${skatsAnte.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 12),
                                    
                                    // Closest Pin
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[200],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Closest Pin',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: 1,
                                                ),
                                              ),
                                              child: GestureDetector(
                                                onTap: () => _editValue('Closest Pin', _closestPinController, (value) {
                                                  setState(() {
                                                    closestPin = value;
                                                    _closestPinController.text = value.toStringAsFixed(2);
                                                  });
                                                }),
                                                child: Text(
                                                  '\$${closestPin.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 12),
                                    
                                    // Mulligans
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[200],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Mulligans',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: 1,
                                                ),
                                              ),
                                              child: GestureDetector(
                                                onTap: () => _editValue('Mulligans', _mulligansController, (value) {
                                                  setState(() {
                                                    mulligans = value;
                                                    _mulligansController.text = value.toStringAsFixed(2);
                                                  });
                                                }),
                                                child: Text(
                                                  '\$${mulligans.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const Spacer(),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Right Side - Golden Oaks Image
                          Expanded(
                            flex: 7,
                            child: ClipRRect(
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
                                        size: 120,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                      }
                    }
                  }
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Navigation Buttons Footer
            Container(
              padding: const EdgeInsets.all(4), // Reduced by 50%
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildFooterButtons(screenWidth, isLandscape),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButtons(double screenWidth, bool isLandscape) {
    // 6" phones in landscape: width ~820px, exclude larger tablets (>850px)
    final is6InchPhoneLandscape = isLandscape && screenWidth <= 850;
    // 6" phones in portrait: width <= 600px
    final is6InchPhonePortrait = !isLandscape && screenWidth <= 600;
    // 8" tablets: width between 600-900px
    final is8InchTablet = screenWidth >= 600 && screenWidth <= 900;
    
    final baseButtons = [
      _buildNavigationButton(
        'Player Selection',
        Icons.people,
        selectedGolfCourse != null ? Colors.green[300]! : Colors.grey[400]!,
        selectedGolfCourse != null ? () => navigateToScreen(const MondayPlayerSelectionScreen()) : null,
        isCompact: is6InchPhoneLandscape || is6InchPhonePortrait,
      ),
      _buildNavigationButton(
        'Player Scores',
        Icons.score,
        Colors.green[200]!,
        () => navigateToScreen(const MondayPlayerScoresScreen()),
        isCompact: is6InchPhoneLandscape || is6InchPhonePortrait,
      ),
      _buildNavigationButton(
        'Player Profiles',
        Icons.person,
        Colors.green[300]!,
        () => navigateToScreen(const MondayPlayerProfileScreen()),
        isCompact: is6InchPhoneLandscape || is6InchPhonePortrait,
      ),
      _buildNavigationButton(
        'Golf Courses',
        Icons.golf_course,
        Colors.green[100]!,
        () => navigateToScreen(const MondayGolfCourseScreen()),
        isCompact: is6InchPhoneLandscape || is6InchPhonePortrait,
      ),
    ];
    
    // Add Administration button only if NOT 6" phone/tablet or 8" tablet
    final buttons = (is6InchPhoneLandscape || is6InchPhonePortrait || is8InchTablet)
      ? baseButtons
      : [
          ...baseButtons,
          _buildNavigationButton(
            'Administration',
            Icons.settings,
            Colors.green[100]!,
            () => navigateToScreen(AdminScreen(currentLeague: League.monday)),
            isCompact: is6InchPhoneLandscape || is6InchPhonePortrait,
          ),
        ];

    if (is6InchPhoneLandscape) {
      // Single row for phone landscape
      return Row(
        children: buttons.map((button) => Expanded(child: button)).toList(),
      );
    } else if (is6InchPhonePortrait) {
      // Two rows for 6" phone portrait
      return Column(
        children: [
          // First row: 3 buttons
          Row(
            children: [
              Expanded(child: buttons[0]), // Player Selection
              Expanded(child: buttons[1]), // Player Scores  
              Expanded(child: buttons[2]), // Player Profiles
            ],
          ),
          const SizedBox(height: 4),
          // Second row: remaining buttons centered
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons.length > 3 
              ? buttons.sublist(3).map((button) => Flexible(child: button)).toList()
              : [],
          ),
        ],
      );
    } else {
      // Default wrap layout for other screen sizes
      return Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: buttons,
      );
    }
  }

  Widget _buildNavigationButton(String title, IconData icon, Color bgColor, VoidCallback? onPressed, {bool isCompact = false}) {
    final isDisabled = onPressed == null;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 1 : 4, 
        vertical: isCompact ? 1 : 2, // Reduced by 50%
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: isDisabled ? Colors.grey[600] : Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 3 : 6, // Reduced by 50%
            horizontal: isCompact ? 4 : 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isDisabled ? Colors.grey[500]! : Colors.black, 
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: isCompact ? 14 : 18, // Reduced by ~20%
              color: isDisabled ? Colors.grey[600] : null,
            ),
            SizedBox(height: isCompact ? 0.5 : 1), // Reduced by 50%
            Text(
              title,
              style: TextStyle(
                fontSize: isCompact ? 9 : 11, // Reduced by ~15%
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.grey[600] : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}