import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_upload_service.dart';
import 'upload_queue_service.dart';
import 'backend_email_service.dart';
import 'pending_email_service.dart';

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

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
      onError: (error) {
      },
    );
    
    // Check initial connectivity state
    _checkInitialConnectivity();
  }
  
  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  /// Check initial connectivity state
  void _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
    }
  }
  
  /// Handle connectivity state changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool isConnected = _isConnectedToWiFi(results);
    

    // Only process uploads when transitioning from offline to online
    if (isConnected && !_lastConnectedState) {
      _processPendingUploads();
    } else if (!isConnected && _lastConnectedState) {
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
      return false;
    }
  }
  
  /// Process all pending uploads when connectivity is restored
  Future<void> _processPendingUploads() async {
    if (_isProcessingUploads) {
      return;
    }
    
    _isProcessingUploads = true;
    
    try {
      // Get pending uploads
      final pendingUploads = await _uploadQueueService.getPendingUploads();
      final retryableUploads = await _uploadQueueService.getRetryableUploads();
      
      final allUploads = [...pendingUploads, ...retryableUploads];
      
      if (allUploads.isEmpty) {
        return;
      }
      

      // Process each upload
      for (final upload in allUploads) {
        await _processUpload(upload);
        
        // Add small delay between uploads to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Cleanup old completed uploads
      await _uploadQueueService.cleanupOldUploads();

      await _uploadQueueService.getUploadStats();

      // Send any pending results emails that were queued while offline
      await _sendPendingEmail();

    } finally {
      _isProcessingUploads = false;
    }
  }

  /// Sends any results emails that were saved while the device was offline.
  Future<void> _sendPendingEmail() async {
    final pendingEmailService = PendingEmailService();
    final emailService = BackendEmailService();

    // Monday
    if (await pendingEmailService.hasPendingMondayEmail()) {
      final emailData = await pendingEmailService.getPendingMondayEmail();
      if (emailData != null) {
        try {
          final success = await emailService.sendMondayResultsEmail(
            subject: emailData['subject']!,
            body: emailData['body']!,
          );
          if (success) await pendingEmailService.clearPendingMondayEmail();
        } catch (e) {
          // Leave in place for next retry
        }
      }
    }

    // Wednesday
    if (await pendingEmailService.hasPendingWednesdayEmail()) {
      final emailData = await pendingEmailService.getPendingWednesdayEmail();
      if (emailData != null) {
        try {
          final success = await emailService.sendWednesdayResultsEmail(
            subject: emailData['subject']!,
            body: emailData['body']!,
          );
          if (success) await pendingEmailService.clearPendingWednesdayEmail();
        } catch (e) {
          // Leave in place for next retry
        }
      }
    }
  }
  
  /// Process a single upload
  Future<void> _processUpload(PendingUpload upload) async {
    try {

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
      await _uploadQueueService.markAsFailed(upload.id, e.toString());
    }
  }
  
  /// Manually trigger upload processing (useful for testing or manual retry)
  Future<void> processUploadsManually() async {
    if (await isWiFiConnected()) {
      await _processPendingUploads();
    } else {
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