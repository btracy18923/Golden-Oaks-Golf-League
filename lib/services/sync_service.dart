import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';
import 'firebase_service.dart';
import '../models/league.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  
  SyncStatus _currentStatus = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  
  // Stream controllers for status updates
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Getters
  SyncStatus get currentStatus => _currentStatus;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  // Streams
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Initialize the sync service
  Future<void> initialize() async {
    // Load last sync time from database
    String? lastSyncStr = await _dbHelper.getSetting('last_sync_time');
    if (lastSyncStr != null) {
      try {
        _lastSyncTime = DateTime.parse(lastSyncStr);
      } catch (e) {
        print('Error parsing last sync time: $e');
      }
    }

    // Start auto-sync if enabled
    bool syncEnabled = await _firebaseService.isSyncEnabled();
    if (syncEnabled) {
      startAutoSync();
    }
  }

  /// Check internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Perform a full sync (bidirectional)
  Future<bool> performFullSync() async {
    return await _performSync(SyncDirection.bidirectional);
  }

  /// Sync local data to Firebase
  Future<bool> syncToFirebase() async {
    return await _performSync(SyncDirection.toFirebase);
  }

  /// Sync Firebase data to local
  Future<bool> syncFromFirebase() async {
    return await _performSync(SyncDirection.fromFirebase);
  }

  /// Internal sync method
  Future<bool> _performSync(SyncDirection direction) async {
    if (_currentStatus == SyncStatus.syncing) {
      print('Sync already in progress');
      return false;
    }

    _updateStatus(SyncStatus.syncing);
    _lastError = null;

    try {
      // Check if sync is enabled
      bool syncEnabled = await _firebaseService.isSyncEnabled();
      if (!syncEnabled) {
        _updateStatus(SyncStatus.idle);
        return false;
      }

      // Check internet connectivity
      bool hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        _updateStatus(SyncStatus.offline);
        _setError('No internet connection available');
        return false;
      }

      bool success = false;
      
      switch (direction) {
        case SyncDirection.toFirebase:
          success = await _firebaseService.syncToFirebase();
          break;
        case SyncDirection.fromFirebase:
          success = await _firebaseService.syncFromFirebase();
          break;
        case SyncDirection.bidirectional:
          // First sync from Firebase, then to Firebase
          bool fromSuccess = await _firebaseService.syncFromFirebase();
          bool toSuccess = await _firebaseService.syncToFirebase();
          success = fromSuccess && toSuccess;
          break;
      }

      if (success) {
        _lastSyncTime = DateTime.now();
        await _dbHelper.setSetting('last_sync_time', _lastSyncTime!.toIso8601String());
        _updateStatus(SyncStatus.success);
        
        // Return to idle after a brief success indication
        Timer(const Duration(seconds: 2), () {
          if (_currentStatus == SyncStatus.success) {
            _updateStatus(SyncStatus.idle);
          }
        });
      } else {
        _updateStatus(SyncStatus.error);
        _setError('Sync operation failed');
      }

      return success;
    } catch (e) {
      _updateStatus(SyncStatus.error);
      _setError('Sync error: $e');
      print('Sync error: $e');
      return false;
    }
  }

  /// Start automatic synchronization
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    stopAutoSync(); // Stop any existing timer
    
    _autoSyncTimer = Timer.periodic(interval, (timer) async {
      bool hasInternet = await hasInternetConnection();
      bool syncEnabled = await _firebaseService.isSyncEnabled();
      
      if (hasInternet && syncEnabled && _currentStatus != SyncStatus.syncing) {
        await performFullSync();
      }
    });
  }

  /// Stop automatic synchronization
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Sync specific player data
  Future<bool> syncPlayer(int playerId) async {
    try {
      if (!await _firebaseService.isSyncEnabled()) return false;
      if (!await hasInternetConnection()) return false;

      Map<String, dynamic>? player = await _dbHelper.getPlayer(playerId);
      if (player == null) return false;

      // For now, just trigger a full sync
      // In a more advanced implementation, we'd sync just this player
      return await syncToFirebase();
    } catch (e) {
      print('Error syncing player: $e');
      return false;
    }
  }

  /// Sync specific game results
  Future<bool> syncGameResults(int gameId, List<Map<String, dynamic>> playerResults) async {
    try {
      if (!await _firebaseService.isSyncEnabled()) return false;
      if (!await hasInternetConnection()) return false;

      return await _firebaseService.uploadGameResults(gameId, playerResults);
    } catch (e) {
      print('Error syncing game results: $e');
      return false;
    }
  }

  /// Force sync now (manual sync)
  Future<bool> forceSyncNow() async {
    return await performFullSync();
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    Map<String, int> dataCounts = await _dbHelper.getDataCounts();
    Map<String, dynamic> firebaseStatus = await _firebaseService.getSyncStatus();
    
    return {
      'local_data': dataCounts,
      'firebase_status': firebaseStatus,
      'last_sync': _lastSyncTime?.toIso8601String(),
      'current_status': _currentStatus.toString(),
      'last_error': _lastError,
      'auto_sync_active': _autoSyncTimer != null,
    };
  }

  /// Enable/disable Firebase sync
  Future<void> setSyncEnabled(bool enabled) async {
    await _firebaseService.setSyncEnabled(enabled);
    
    if (enabled) {
      startAutoSync();
    } else {
      stopAutoSync();
      _updateStatus(SyncStatus.idle);
    }
  }

  /// Check for conflicts and resolve them
  Future<void> resolveConflicts() async {
    await _firebaseService.resolveConflicts();
  }

  /// Update status and notify listeners
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Set error and notify listeners
  void _setError(String error) {
    _lastError = error;
    _errorController.add(error);
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _statusController.close();
    _errorController.close();
  }
}

enum SyncDirection {
  toFirebase,
  fromFirebase,
  bidirectional,
}