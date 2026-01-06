import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/league.dart';

enum UploadType { players, golfCourses, scores }

class PendingUpload {
  final int id;
  final UploadType uploadType;
  final League league;
  final DateTime timestamp;
  final String status; // 'pending', 'uploading', 'failed', 'completed'
  final int retryCount;
  final String? errorMessage;

  PendingUpload({
    required this.id,
    required this.uploadType,
    required this.league,
    required this.timestamp,
    required this.status,
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'upload_type': uploadType.name,
      'league': league == League.monday ? 'monday' : 'wednesday',
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  factory PendingUpload.fromMap(Map<String, dynamic> map) {
    return PendingUpload(
      id: map['id'] as int,
      uploadType: UploadType.values.byName(map['upload_type'] as String),
      league: map['league'] == 'monday' ? League.monday : League.wednesday,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: map['status'] as String,
      retryCount: map['retry_count'] as int? ?? 0,
      errorMessage: map['error_message'] as String?,
    );
  }
}

class UploadQueueService {
  static final UploadQueueService _instance = UploadQueueService._internal();
  static Database? _database;
  
  factory UploadQueueService() => _instance;
  UploadQueueService._internal();
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'upload_queue.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_uploads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            upload_type TEXT NOT NULL,
            league TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER DEFAULT 0,
            error_message TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        // Create index for faster queries
        await db.execute('''
          CREATE INDEX idx_pending_uploads_status_type 
          ON pending_uploads (status, upload_type, league)
        ''');
      },
    );
  }

  /// Add an upload to the queue
  Future<int> queueUpload({
    required UploadType uploadType,
    required League league,
  }) async {
    final db = await database;
    
    // Check if there's already a pending upload of this type for this league
    final existing = await db.query(
      'pending_uploads',
      where: 'upload_type = ? AND league = ? AND status IN (?, ?)',
      whereArgs: [
        uploadType.name, 
        league == League.monday ? 'monday' : 'wednesday',
        'pending',
        'uploading'
      ],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // Update timestamp of existing upload
      final existingId = existing.first['id'] as int;
      await db.update(
        'pending_uploads',
        {
          'timestamp': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    }
    
    // Insert new upload
    final uploadData = {
      'upload_type': uploadType.name,
      'league': league == League.monday ? 'monday' : 'wednesday',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
    };
    
    final id = await db.insert('pending_uploads', uploadData);
    return id;
  }

  /// Get all pending uploads
  Future<List<PendingUpload>> getPendingUploads() async {
    final db = await database;
    
    final maps = await db.query(
      'pending_uploads',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
    );
    
    return maps.map((map) => PendingUpload.fromMap(map)).toList();
  }

  /// Get failed uploads that can be retried
  Future<List<PendingUpload>> getRetryableUploads() async {
    final db = await database;
    
    final maps = await db.query(
      'pending_uploads',
      where: 'status = ? AND retry_count < ?',
      whereArgs: ['failed', 3], // Max 3 retries
      orderBy: 'timestamp ASC',
    );
    
    return maps.map((map) => PendingUpload.fromMap(map)).toList();
  }

  /// Mark upload as uploading
  Future<void> markAsUploading(int uploadId) async {
    final db = await database;
    
    await db.update(
      'pending_uploads',
      {
        'status': 'uploading',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [uploadId],
    );
  }

  /// Mark upload as completed
  Future<void> markAsCompleted(int uploadId) async {
    final db = await database;
    
    await db.update(
      'pending_uploads',
      {
        'status': 'completed',
        'error_message': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [uploadId],
    );
    
  }

  /// Mark upload as failed
  Future<void> markAsFailed(int uploadId, String errorMessage) async {
    final db = await database;
    
    // Get current retry count
    final upload = await db.query(
      'pending_uploads',
      where: 'id = ?',
      whereArgs: [uploadId],
      limit: 1,
    );
    
    if (upload.isNotEmpty) {
      final currentRetries = upload.first['retry_count'] as int? ?? 0;
      
      await db.update(
        'pending_uploads',
        {
          'status': 'failed',
          'retry_count': currentRetries + 1,
          'error_message': errorMessage,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [uploadId],
      );
      
    }
  }

  /// Reset failed upload to pending for retry
  Future<void> resetForRetry(int uploadId) async {
    final db = await database;
    
    await db.update(
      'pending_uploads',
      {
        'status': 'pending',
        'error_message': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [uploadId],
    );
    
  }

  /// Remove completed uploads older than specified days
  Future<void> cleanupOldUploads({int daysOld = 7}) async {
    final db = await database;
    
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    await db.delete(
      'pending_uploads',
      where: 'status = ? AND updated_at < ?',
      whereArgs: ['completed', cutoffDate.toIso8601String()],
    );
    
  }

  /// Get upload statistics
  Future<Map<String, int>> getUploadStats() async {
    final db = await database;
    
    final pendingCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM pending_uploads WHERE status = ?',
      ['pending'],
    )) ?? 0;
    
    final failedCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM pending_uploads WHERE status = ?',
      ['failed'],
    )) ?? 0;
    
    final completedCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM pending_uploads WHERE status = ?',
      ['completed'],
    )) ?? 0;
    
    return {
      'pending': pendingCount,
      'failed': failedCount,
      'completed': completedCount,
    };
  }

  /// Check if there are any pending uploads
  Future<bool> hasPendingUploads() async {
    final db = await database;
    
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM pending_uploads WHERE status IN (?, ?)',
      ['pending', 'failed'],
    )) ?? 0;
    
    return count > 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}