import 'package:flutter/material.dart';
import '../services/csv_import_service.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({Key? key}) : super(key: key);

  @override
  _CsvImportScreenState createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  bool _isImporting = false;
  String _statusMessage = '';

  Future<void> _importPlayers() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Importing players...';
    });

    try {
      await CsvImportService.importPlayersFromCsv('players.csv');
      setState(() {
        _statusMessage = 'Players imported successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error importing players: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _importGolfCourses() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Importing golf courses...';
    });

    try {
      await CsvImportService.importGolfCoursesFromCsv('golf_courses.csv');
      setState(() {
        _statusMessage = 'Golf courses imported successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error importing golf courses: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _importAll() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Importing all data...';
    });

    try {
      await CsvImportService.importAllCsvData();
      setState(() {
        _statusMessage = 'All data imported successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error importing data: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Import'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSV Data Import',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This will import data from players.csv and golf_courses.csv files located in the app directory.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            
            // Import Players Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importPlayers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Import Players Only',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Import Golf Courses Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importGolfCourses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Import Golf Courses Only',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Import All Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Import All Data',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Status Display
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error') 
                    ? Colors.red[100] 
                    : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('Error') 
                      ? Colors.red 
                      : Colors.green,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: _statusMessage.contains('Error') 
                      ? Colors.red[800] 
                      : Colors.green[800],
                  ),
                ),
              ),
            
            // Loading Indicator
            if (_isImporting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              
            const Spacer(),
            
            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Place players.csv and golf_courses.csv files in the app directory'),
                    Text('2. Click the appropriate import button'),
                    Text('3. Existing records will be updated, new records will be created'),
                    Text('4. Check the status message for results'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}