import 'package:flutter/material.dart';
import '../../widgets/responsive_wrapper.dart';

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
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet10: _buildTablet10Layout(),
    );
  }
  
  Widget _buildPhoneLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Wednesday Golf Courses'),
        backgroundColor: _leagueColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(16, 24, 8),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCourseList(16, 14, 12),
            ),
            const SizedBox(height: 8),
            _buildFooterSection(12),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTablet10Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(_leagueTitle),
        backgroundColor: _leagueColor[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 64,
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
            _buildHeaderSection(24, 40, 16),
            const SizedBox(height: 24),
            Expanded(
              child: _buildCourseList(20, 16, 16),
            ),
            const SizedBox(height: 16),
            _buildFooterSection(14),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeaderSection(double fontSize, double iconSize, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _leagueColor[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _leagueColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            Icons.golf_course,
            size: iconSize,
            color: _leagueColor[700],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Wednesday League Golf Courses',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: _leagueColor[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCourseList(double titleSize, double cardPadding, double textSize) {
    return ListView.builder(
      itemCount: _wednesdayCourses.length,
      itemBuilder: (context, index) {
        final course = _wednesdayCourses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: _leagueColor[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _leagueColor[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course['name']!,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: _leagueColor[800],
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.phone, 'Phone: ${course['phone']}', textSize),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.location_on, 'Address: ${course['address']}', textSize),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.info_outline, 'Notes: ${course['notes']}', textSize),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
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
    );
  }
  
  Widget _buildDetailRow(IconData icon, String text, double fontSize) {
    return Row(
      children: [
        Icon(
          icon,
          color: _leagueColor[600],
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFooterSection(double fontSize) {
    return Container(
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
          Expanded(
            child: Text(
              'Wednesday League primarily plays at The Hideout Golf Club with rotating venues for special tournaments.',
              style: TextStyle(
                fontSize: fontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}