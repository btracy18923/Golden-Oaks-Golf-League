import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_upload_service.dart';
import 'upload_queue_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  final UploadQueueService _uploadQueueService = UploadQueueService();
  final FirebaseUploadService _firebaseUploadService = FirebaseUploadService();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessingUploads = false;
  bool _lastConnectedState = false;
  
  /// Start monitoring connectivity changes
  void startMonitoring() {
    print('ConnectivityService: Starting connectivity monitoring');
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
      onError: (error) {
        print('ConnectivityService: Error monitoring connectivity - $error');
      },
    );
    
    // Check initial connectivity state
    _checkInitialConnectivity();
  }
  
  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    print('ConnectivityService: Stopping connectivity monitoring');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  /// Check initial connectivity state
  void _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      print('ConnectivityService: Error checking initial connectivity - $e');
    }
  }
  
  /// Handle connectivity state changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool isConnected = _isConnectedToWiFi(results);
    
    print('ConnectivityService: Connectivity changed - WiFi: $isConnected');
    print('ConnectivityService: Connection types: ${results.map((r) => r.name).join(', ')}');
    
    // Only process uploads when transitioning from offline to online
    if (isConnected && !_lastConnectedState) {
      print('ConnectivityService: WiFi connection established, processing pending uploads');
      _processPendingUploads();
    } else if (!isConnected && _lastConnectedState) {
      print('ConnectivityService: WiFi connection lost');
    }
    
    _lastConnectedState = isConnected;
  }
  
  /// Check if connected to WiFi
  bool _isConnectedToWiFi(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi);
  }
  
  /// Get current connectivity status
  Future<bool> isWiFiConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isConnectedToWiFi(results);
    } catch (e) {
      print('ConnectivityService: Error checking WiFi status - $e');
      return false;
    }
  }
  
  /// Process all pending uploads when connectivity is restored
  Future<void> _processPendingUploads() async {
    if (_isProcessingUploads) {
      print('ConnectivityService: Upload processing already in progress, skipping');
      return;
    }
    
    _isProcessingUploads = true;
    
    try {
      // Get pending uploads
      final pendingUploads = await _uploadQueueService.getPendingUploads();
      final retryableUploads = await _uploadQueueService.getRetryableUploads();
      
      final allUploads = [...pendingUploads, ...retryableUploads];
      
      if (allUploads.isEmpty) {
        print('ConnectivityService: No pending uploads to process');
        return;
      }
      
      print('ConnectivityService: Processing ${allUploads.length} uploads');
      
      // Process each upload
      for (final upload in allUploads) {
        await _processUpload(upload);
        
        // Add small delay between uploads to avoid overwhelming the system
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // Cleanup old completed uploads
      await _uploadQueueService.cleanupOldUploads();
      
      final stats = await _uploadQueueService.getUploadStats();
      print('ConnectivityService: Upload processing complete. Stats: $stats');
      
    } catch (e) {
      print('ConnectivityService: Error processing pending uploads - $e');
    } finally {
      _isProcessingUploads = false;
    }
  }
  
  /// Process a single upload
  Future<void> _processUpload(PendingUpload upload) async {
    try {
      print('ConnectivityService: Processing upload ${upload.id} - ${upload.uploadType.name} for ${upload.league.name}');
      
      // Mark as uploading
      await _uploadQueueService.markAsUploading(upload.id);
      
      bool success = false;
      
      // Execute the appropriate upload based on type
      switch (upload.uploadType) {
        case UploadType.players:
          success = await _firebaseUploadService.uploadPlayerTable(upload.league);
          break;
        case UploadType.golfCourses:
          success = await _firebaseUploadService.uploadGolfCourseTable(upload.league);
          break;
        case UploadType.scores:
          success = await _firebaseUploadService.uploadPlayerScoresTable(upload.league);
          break;
      }
      
      if (success) {
        await _uploadQueueService.markAsCompleted(upload.id);
      } else {
        await _uploadQueueService.markAsFailed(upload.id, 'Upload failed without specific error');
      }
      
    } catch (e) {
      print('ConnectivityService: Upload ${upload.id} failed - $e');
      await _uploadQueueService.markAsFailed(upload.id, e.toString());
    }
  }
  
  /// Manually trigger upload processing (useful for testing or manual retry)
  Future<void> processUploadsManually() async {
    if (await isWiFiConnected()) {
      print('ConnectivityService: Manual upload processing triggered');
      await _processPendingUploads();
    } else {
      print('ConnectivityService: Manual upload processing skipped - no WiFi connection');
    }
  }
  
  /// Get upload queue statistics
  Future<Map<String, int>> getUploadStats() async {
    return await _uploadQueueService.getUploadStats();
  }
  
  /// Check if there are pending uploads
  Future<bool> hasPendingUploads() async {
    return await _uploadQueueService.hasPendingUploads();
  }
}