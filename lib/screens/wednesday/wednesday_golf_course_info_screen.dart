import 'package:flutter/material.dart';

class WednesdayGolfCourseInfoScreen extends StatefulWidget {
  const WednesdayGolfCourseInfoScreen({super.key});

  @override
  State<WednesdayGolfCourseInfoScreen> createState() => _WednesdayGolfCourseInfoScreenState();
}

class _WednesdayGolfCourseInfoScreenState extends State<WednesdayGolfCourseInfoScreen> {
  
  // Hard-coded Wednesday league values and courses
  static const MaterialColor _leagueColor = Colors.orange;
  static const String _leagueTitle = 'Wednesday League Golf Course Information';
  
  final List<Map<String, String>> _wednesdayCourses = [
    {
      'name': 'The Hideout Golf Club',
      'phone': '(555) 987-6543',
      'address': '987 Hideout Drive',
      'notes': 'Primary venue for Wednesday league'
    },
    {
      'name': 'Sunset Hills Golf Course',
      'phone': '(555) 876-5432', 
      'address': '321 Sunset Hills Boulevard',
      'notes': 'Backup course for Wednesday matches'
    },
    {
      'name': 'Meadowbrook Golf Club',
      'phone': '(555) 765-4321',
      'address': '654 Meadowbrook Way', 
      'notes': 'Special events venue for Wednesday league'
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
                      'Wednesday League Golf Courses',
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
                itemCount: _wednesdayCourses.length,
                itemBuilder: (context, index) {
                  final course = _wednesdayCourses[index];
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
                      'Wednesday League primarily plays at The Hideout Golf Club with rotating venues for special tournaments.',
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