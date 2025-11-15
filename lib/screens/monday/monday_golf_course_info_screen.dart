import 'package:flutter/material.dart';

class MondayGolfCourseInfoScreen extends StatefulWidget {
  const MondayGolfCourseInfoScreen({super.key});

  @override
  State<MondayGolfCourseInfoScreen> createState() => _MondayGolfCourseInfoScreenState();
}

class _MondayGolfCourseInfoScreenState extends State<MondayGolfCourseInfoScreen> {
  
  // Hard-coded Monday league values and courses
  static const Color _leagueColor = Colors.green;
  static const String _leagueTitle = 'Monday League Golf Course Information';
  
  final List<Map<String, String>> _mondayCourses = [
    {
      'name': 'Golden Oaks Golf Club',
      'phone': '(555) 123-4567',
      'address': '123 Golf Course Drive',
      'notes': 'Home course for Monday league'
    },
    {
      'name': 'Pine Valley Golf Course',
      'phone': '(555) 234-5678', 
      'address': '456 Pine Valley Road',
      'notes': 'Alternate course for Monday matches'
    },
    {
      'name': 'Oak Creek Golf Club',
      'phone': '(555) 345-6789',
      'address': '789 Oak Creek Lane', 
      'notes': 'Tournament course for Monday league'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(_leagueTitle),
        backgroundColor: _leagueColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _leagueColor[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _leagueColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.golf_course,
                    size: 40,
                    color: _leagueColor[700],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Monday League Golf Courses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _leagueColor[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Course Information Cards
            Expanded(
              child: ListView.builder(
                itemCount: _mondayCourses.length,
                itemBuilder: (context, index) {
                  final course = _mondayCourses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _leagueColor[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _leagueColor[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course Name
                        Text(
                          course['name']!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _leagueColor[800],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Course Details
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: _leagueColor[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Phone: ${course['phone']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: _leagueColor[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Address: ${course['address']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: _leagueColor[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Notes: ${course['notes']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Action Button
                        ElevatedButton.icon(
                          onPressed: () {
                            // Could implement phone dialing or map opening
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Contact ${course['name']} at ${course['phone']}'),
                                backgroundColor: _leagueColor[600],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _leagueColor[400],
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Contact Course'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Footer Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _leagueColor[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: _leagueColor[700],
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Monday League plays primarily at Golden Oaks Golf Club with occasional tournaments at other courses.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}