import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/upload_queue_service.dart';

class UploadStatusWidget extends StatefulWidget {
  final bool showWhenNoPendingUploads;
  
  const UploadStatusWidget({
    super.key,
    this.showWhenNoPendingUploads = false,
  });

  @override
  State<UploadStatusWidget> createState() => _UploadStatusWidgetState();
}

class _UploadStatusWidgetState extends State<UploadStatusWidget> {
  final ConnectivityService _connectivityService = ConnectivityService();
  Map<String, int> _uploadStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUploadStats();
  }

  Future<void> _loadUploadStats() async {
    try {
      final stats = await _connectivityService.getUploadStats();
      setState(() {
        _uploadStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading upload stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _retryUploads() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _connectivityService.processUploadsManually();
      await _loadUploadStats();
    } catch (e) {
      print('Error retrying uploads: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final pendingCount = _uploadStats['pending'] ?? 0;
    final failedCount = _uploadStats['failed'] ?? 0;
    final totalPending = pendingCount + failedCount;

    if (totalPending == 0 && !widget.showWhenNoPendingUploads) {
      return const SizedBox.shrink();
    }

    Color statusColor = Colors.green;
    IconData statusIcon = Icons.cloud_done;
    String statusText = 'All synced';

    if (failedCount > 0) {
      statusColor = Colors.red;
      statusIcon = Icons.cloud_off;
      statusText = 'Upload failed ($failedCount)';
    } else if (pendingCount > 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.cloud_queue;
      statusText = 'Pending ($pendingCount)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (totalPending > 0) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _retryUploads,
              child: Icon(
                Icons.refresh,
                size: 14,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UploadStatusDialog extends StatefulWidget {
  const UploadStatusDialog({super.key});

  @override
  State<UploadStatusDialog> createState() => _UploadStatusDialogState();
}

class _UploadStatusDialogState extends State<UploadStatusDialog> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final UploadQueueService _uploadQueueService = UploadQueueService();
  
  Map<String, int> _uploadStats = {};
  List<PendingUpload> _pendingUploads = [];
  bool _isLoading = true;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await _connectivityService.getUploadStats();
      final pending = await _uploadQueueService.getPendingUploads();
      final retryable = await _uploadQueueService.getRetryableUploads();
      
      setState(() {
        _uploadStats = stats;
        _pendingUploads = [...pending, ...retryable];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading upload data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _retryUploads() async {
    setState(() {
      _isRetrying = true;
    });
    
    try {
      await _connectivityService.processUploadsManually();
      await _loadData();
    } catch (e) {
      print('Error retrying uploads: $e');
    } finally {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_upload, size: 24),
          SizedBox(width: 8),
          Text('Upload Status'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats summary
                _buildStatsRow(),
                const SizedBox(height: 16),
                
                // Pending uploads list
                if (_pendingUploads.isNotEmpty) ...[
                  const Text(
                    'Pending Uploads:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _pendingUploads.length,
                      itemBuilder: (context, index) {
                        final upload = _pendingUploads[index];
                        return _buildUploadItem(upload);
                      },
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Text(
                      'No pending uploads',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      ),
      actions: [
        if (_pendingUploads.isNotEmpty)
          TextButton(
            onPressed: _isRetrying ? null : _retryUploads,
            child: _isRetrying 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Retry Now'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final pending = _uploadStats['pending'] ?? 0;
    final failed = _uploadStats['failed'] ?? 0;
    final completed = _uploadStats['completed'] ?? 0;

    return Row(
      children: [
        _buildStatChip('Pending', pending, Colors.orange),
        const SizedBox(width: 8),
        _buildStatChip('Failed', failed, Colors.red),
        const SizedBox(width: 8),
        _buildStatChip('Completed', completed, Colors.green),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Chip(
      label: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildUploadItem(PendingUpload upload) {
    IconData typeIcon;
    switch (upload.uploadType) {
      case UploadType.players:
        typeIcon = Icons.people;
        break;
      case UploadType.golfCourses:
        typeIcon = Icons.golf_course;
        break;
      case UploadType.scores:
        typeIcon = Icons.scoreboard;
        break;
    }

    Color statusColor = upload.status == 'failed' ? Colors.red : Colors.orange;

    return ListTile(
      dense: true,
      leading: Icon(typeIcon, color: statusColor, size: 20),
      title: Text(
        '${upload.uploadType.name} - ${upload.league.name}',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: ${upload.status}',
            style: TextStyle(fontSize: 12, color: statusColor),
          ),
          if (upload.retryCount > 0)
            Text(
              'Retries: ${upload.retryCount}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          if (upload.errorMessage?.isNotEmpty == true)
            Text(
              'Error: ${upload.errorMessage}',
              style: const TextStyle(fontSize: 10, color: Colors.red),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Icon(
        upload.status == 'failed' ? Icons.error : Icons.schedule,
        color: statusColor,
        size: 16,
      ),
    );
  }
}

/// Show the upload status dialog
Future<void> showUploadStatusDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const UploadStatusDialog(),
  );
}