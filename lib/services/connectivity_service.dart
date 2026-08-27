import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/league.dart';
import 'database_helper.dart';
import 'firebase_upload_service.dart';
import 'upload_queue_service.dart';
import 'results_email_verification_service.dart';

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
    final bool isConnected = _isConnectedToInternet(results);


    // Only process uploads when transitioning from offline to online
    if (isConnected && !_lastConnectedState) {
      _processPendingUploads();
    } else if (!isConnected && _lastConnectedState) {
    }

    _lastConnectedState = isConnected;
  }

  /// Check if connected to WiFi or mobile data
  bool _isConnectedToInternet(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile);
  }

  /// Get current connectivity status (WiFi or mobile data)
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isConnectedToInternet(results);
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

  /// Sends any results emails that were held back (offline, or the
  /// Firebase profile upload couldn't be verified) while the device was
  /// offline. Runs after queued uploads above have already been retried,
  /// so the verify inside retryPending has a real chance of finding the
  /// profile upload landed this time.
  Future<void> _sendPendingEmail() async {
    final emailVerificationService = ResultsEmailVerificationService();
    await emailVerificationService.retryPending(League.monday);
    await emailVerificationService.retryPending(League.wednesday);
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
          if (upload.playerNumbers != null && upload.playerNumbers!.isNotEmpty) {
            // Scoped retry: re-fetch just these players fresh from local DB
            // (not whatever was cached when originally queued) and push only
            // them, so this device's cache for everyone else still can't
            // clobber their correct Firebase values.
            final allPlayers = await DatabaseHelper().getPlayersByLeague(upload.league);
            final scoped = allPlayers
                .where((p) => upload.playerNumbers!.contains(p['player_number']))
                .toList();
            success = await _firebaseUploadService.uploadPlayers(upload.league, scoped);
          } else {
            success = await _firebaseUploadService.uploadPlayerTable(upload.league);
          }
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
    if (await isOnline()) {
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