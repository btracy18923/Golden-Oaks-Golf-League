import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/database_helper.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _status = 'Ready to test Firebase upload';
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Upload Test'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Firebase Database Upload Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Status display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            
            // Database stats
            FutureBuilder<Map<String, int>>(
              future: _dbHelper.getDataCounts(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final counts = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Local Database Contents:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Players: ${counts['players']}'),
                          Text('Games: ${counts['games']}'),
                          Text('Scores: ${counts['scores']}'),
                        ],
                      ),
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 20),
            
            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Uploading...'),
                        ],
                      )
                    : const Text('Upload Damaged Database to Firebase',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Test connection button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _testConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Test Firebase Connection',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Test Anonymous Authentication
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _testAnonymousAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Test Anonymous Authentication',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Download from Firebase
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _downloadFromFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Download & Restore from Firebase',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Download from Damaged Tablet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _downloadDamagedTabletData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Download from Damaged Tablet Backup',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Auto-Sync Test
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _testAutoSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Start Auto-Sync (1-min intervals)',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Create Backup
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _createBackup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Firebase Backup',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Bypass authentication upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadWithoutAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Upload Without Authentication (Bypass)',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Troubleshooting:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('1. Check internet connection'),
                    Text('2. Enable Anonymous Authentication in Firebase Console'),
                    Text('3. Check Firebase Security Rules'),
                    Text('4. Verify Firebase configuration files'),
                    SizedBox(height: 8),
                    Text('Known Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('• Dynamic Links deprecation (handled automatically)'),
                    Text('• Windows platform configuration'),
                    Text('• Network firewall restrictions'),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _status = 'Testing Firebase connection...';
    });

    try {
      bool canConnect = await _firebaseService.testFirebaseConnection();
      if (canConnect) {
        setState(() {
          _status = 'SUCCESS: Firebase connection works!';
        });
      } else {
        setState(() {
          _status = 'FAILED: Cannot connect to Firebase. Check internet and configuration.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'ERROR: $e';
      });
    }
  }

  Future<void> _uploadDatabase() async {
    setState(() {
      _isUploading = true;
      _status = 'Starting upload of damaged tablet database...';
    });

    try {
      bool success = await _firebaseService.uploadDamagedDatabaseToFirebase();
      
      setState(() {
        _isUploading = false;
        if (success) {
          _status = 'SUCCESS: Database uploaded to Firebase successfully!';
        } else {
          _status = 'FAILED: Upload failed. Check logs for details.';
        }
      });

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Upload Successful' : 'Upload Failed'),
            content: Text(success 
                ? 'Your damaged tablet database has been successfully uploaded to Firebase!'
                : 'Upload failed. Please check the Firebase configuration and try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _status = 'ERROR: $e';
      });
    }
  }

  Future<void> _testAnonymousAuth() async {
    setState(() {
      _isUploading = true;
      _status = 'Testing Anonymous Authentication...\nChecking Firebase configuration...';
    });

    try {
      // First check if Firebase is initialized
      setState(() {
        _status = 'Testing Anonymous Authentication...\nInitializing Firebase...';
      });
      
      var user = await _firebaseService.signInAnonymously();
      
      setState(() {
        _isUploading = false;
        if (user != null) {
          _status = 'SUCCESS: Anonymous Auth works!\nUser ID: ${user.uid}\nAnonymous: ${user.isAnonymous}\nCreated: ${user.metadata.creationTime}';
        } else {
          _status = 'FAILED: Anonymous authentication returned null.\n\nPossible causes:\n1. Anonymous Auth not enabled in Firebase Console\n2. Invalid Firebase configuration\n3. Network connection issues\n4. Firebase project misconfiguration\n\nCheck the console output for detailed error messages.';
        }
      });

      // Show result dialog with detailed info
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(user != null ? 'Authentication Success' : 'Authentication Failed'),
            content: user != null 
                ? Text('Anonymous authentication successful!\n\nUser ID: ${user.uid}\nAnonymous: ${user.isAnonymous}\nCreated: ${user.metadata.creationTime}')
                : const Text('Anonymous authentication failed.\n\nCheck:\n1. Firebase Console → Authentication → Sign-in method → Anonymous (enabled?)\n2. Internet connection\n3. Firebase project configuration\n\nSee console output for detailed error messages.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _status = 'CRITICAL ERROR: $e\n\nError type: ${e.runtimeType}\n\nTroubleshooting:\n1. Check internet connection\n2. Verify Firebase project ID: golf-league-b0bb2\n3. Confirm Anonymous Auth is enabled\n4. Check API key configuration';
      });
    }
  }

  Future<void> _downloadFromFirebase() async {
    setState(() {
      _isUploading = true;
      _status = 'Downloading and restoring data from Firebase...';
    });

    try {
      bool success = await _firebaseService.downloadAndRestoreDatabase();
      
      setState(() {
        _isUploading = false;
        if (success) {
          _status = 'SUCCESS: Database restored from Firebase!';
        } else {
          _status = 'FAILED: Download/restore failed. Check connection and authentication.';
        }
      });

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Download Successful' : 'Download Failed'),
            content: Text(success 
                ? 'Data has been successfully downloaded and restored from Firebase!'
                : 'Download failed. Check Firebase connection and authentication.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _status = 'ERROR: $e';
      });
    }
  }

  Future<void> _testAutoSync() async {
    setState(() {
      _status = 'Starting Auto-Sync with 1-minute intervals...';
    });

    try {
      await _firebaseService.setSyncEnabled(true);
      await _firebaseService.startAutoSync(interval: const Duration(minutes: 1));
      
      setState(() {
        _status = 'SUCCESS: Auto-Sync started! Will sync every 1 minute.\nWatch console output for sync activity.';
      });

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Auto-Sync Started'),
            content: const Text('Auto-sync is now running every 1 minute.\n\nThis will automatically:\n• Upload local changes to Firebase\n• Download updates from Firebase\n\nWatch the console output for sync activity.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'ERROR: Auto-sync failed to start: $e';
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isUploading = true;
      _status = 'Creating Firebase backup...';
    });

    try {
      String backupName = 'test_backup_${DateTime.now().millisecondsSinceEpoch}';
      bool success = await _firebaseService.createFirebaseBackup(backupName: backupName);
      
      setState(() {
        _isUploading = false;
        if (success) {
          _status = 'SUCCESS: Backup created!\nBackup name: $backupName';
        } else {
          _status = 'FAILED: Backup creation failed. Check Firebase connection.';
        }
      });

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Backup Created' : 'Backup Failed'),
            content: Text(success 
                ? 'Backup successfully created in Firebase!\n\nBackup name: $backupName'
                : 'Backup creation failed. Check Firebase connection and permissions.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _status = 'ERROR: Backup failed: $e';
      });
    }
  }

  Future<void> _uploadWithoutAuth() async {
    setState(() {
      _isUploading = true;
      _status = 'Uploading without authentication (bypass mode)...';
    });

    try {
      bool success = await _firebaseService.uploadWithoutAuth();
      
      setState(() {
        _isUploading = false;
        if (success) {
          _status = 'SUCCESS: Database uploaded to Firebase backup collections!';
        } else {
          _status = 'FAILED: Bypass upload failed. Check logs for details.';
        }
      });

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Bypass Upload Successful' : 'Bypass Upload Failed'),
            content: Text(success 
                ? 'Your data has been uploaded to Firebase backup collections without authentication!'
                : 'Bypass upload failed. Your Firebase security rules may be too restrictive.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _status = 'ERROR: $e';
      });
    }
  }

  Future<void> _downloadDamagedTabletData() async {
    setState(() {
      _isUploading = true;
      _status = 'Downloading data from damaged tablet backup collections...';
    });

    try {
      bool success = await _firebaseService.restoreDamagedTabletData();
      
      setState(() {
        _isUploading = false;
        if (success) {
          _status = 'SUCCESS: Damaged tablet data restored!';
        } else {
          _status = 'FAILED: Could not download damaged tablet data.';
        }
      });

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Download Successful' : 'Download Failed'),
            content: Text(success 
                ? 'Damaged tablet data has been successfully downloaded and restored!'
                : 'Failed to download data. The damaged tablet backup may not exist.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _status = 'ERROR: $e';
      });
    }
  }
}