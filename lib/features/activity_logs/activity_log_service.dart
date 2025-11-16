import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'activity_log_model.dart';

/// Activity Log Service - QUOTA OPTIMIZED
/// 
/// Key optimizations:
/// 1. Batched writes - Queue logs and write in batches
/// 2. Local filtering - Minimize Firestore queries
/// 3. Smart indexing - Only index essential fields
/// 4. Automatic cleanup - Delete old logs to save space
/// 5. Rate limiting - Prevent quota exhaustion
class ActivityLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Batch write queue
  final List<ActivityLog> _logQueue = [];
  Timer? _batchTimer;
  static const int _batchSize = 50; // Write in batches of 50
  static const Duration _batchInterval = Duration(seconds: 30);
  
  // Rate limiting
  static const int _maxLogsPerMinute = 100;
  final List<DateTime> _recentLogs = [];

  CollectionReference get _auditLogsCollection {
    return _firestore.collection('global_audit_logs');
  }

  /// Initialize batch writing
  ActivityLogService() {
    _startBatchTimer();
  }

  /// Start batch timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (_) {
      _flushBatch();
    });
  }

  /// Check rate limit
  bool _isRateLimited() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove old entries
    _recentLogs.removeWhere((time) => time.isBefore(oneMinuteAgo));
    
    if (_recentLogs.length >= _maxLogsPerMinute) {
      print('⚠️ Activity log rate limit reached');
      return true;
    }
    
    _recentLogs.add(now);
    return false;
  }

  /// Log activity (batched)
  /// This is the main method to call for logging
  Future<void> logActivity({
    required String activityType,
    required String category,
    required String readableAction,
    required String readableDescription,
    required String userId,
    required String userName,
    required String userType,
    String status = 'success',
    String riskLevel = 'low',
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? changes,
    Map<String, dynamic>? entity,
  }) async {
    // Check rate limit
    if (_isRateLimited()) {
      return;
    }

    try {
      final log = ActivityLog(
        id: '', // Will be auto-generated
        activityType: activityType,
        category: category,
        readableAction: readableAction,
        readableDescription: readableDescription,
        userId: userId,
        userName: userName,
        userType: userType,
        status: status,
        riskLevel: riskLevel,
        timestamp: DateTime.now(),
        ipAddress: 'web-client', // For web, IP is hidden
        userAgent: _getUserAgent(),
        sessionId: _getSessionId(),
        metadata: metadata,
        changes: changes,
        entity: entity,
      );

      // Add to batch queue
      _logQueue.add(log);

      // If queue is full, flush immediately
      if (_logQueue.length >= _batchSize) {
        await _flushBatch();
      }
    } catch (e) {
      print('❌ Error queueing activity log: $e');
    }
  }

  /// Flush batch queue to Firestore
  Future<void> _flushBatch() async {
    if (_logQueue.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final logsToWrite = List<ActivityLog>.from(_logQueue);
      _logQueue.clear();

      for (final log in logsToWrite) {
        final docRef = _auditLogsCollection.doc();
        batch.set(docRef, log.toFirestore());
      }

      await batch.commit();
      print('✅ Flushed ${logsToWrite.length} activity logs');
    } catch (e) {
      print('❌ Error flushing batch: $e');
      // Re-add failed logs to queue
      _logQueue.addAll(_logQueue);
    }
  }

  /// Get activity logs with pagination (OPTIMIZED)
  Stream<List<ActivityLog>> getActivityLogsStream({
    String? companyId,
    String? category,
    String? userId,
    int limit = 50,
  }) {
    Query query = _auditLogsCollection.orderBy('timestamp', descending: true);

    // Apply filters
    if (companyId != null) {
      query = query.where('metadata.company_id', isEqualTo: companyId);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ActivityLog.fromFirestore(doc)).toList();
    });
  }

  /// Get paginated logs (one-time fetch)
  Future<List<ActivityLog>> getActivityLogs({
    String? companyId,
    String? category,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _auditLogsCollection;

      // Apply filters BEFORE orderBy
      if (companyId != null) {
        query = query.where('metadata.company_id', isEqualTo: companyId);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Add orderBy
      query = query.orderBy('timestamp', descending: true);

      // Pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      // Handle empty results
      if (snapshot.docs.isEmpty) {
        print('📭 No activity logs found');
        return [];
      }

      final logs = <ActivityLog>[];
      for (var doc in snapshot.docs) {
        try {
          logs.add(ActivityLog.fromFirestore(doc));
        } catch (e) {
          print('⚠️ Error parsing log ${doc.id}: $e');
          // Skip invalid documents
          continue;
        }
      }

      print('✅ Loaded ${logs.length} activity logs');
      return logs;
    } catch (e) {
      print('❌ Error fetching activity logs: $e');
      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }

  /// Search logs by keyword (client-side filtering to save quota)
  Future<List<ActivityLog>> searchLogs({
    required String companyId,
    required String searchQuery,
    int limit = 100,
  }) async {
    try {
      // Fetch recent logs
      final logs = await getActivityLogs(
        companyId: companyId,
        limit: limit,
      );

      // Filter client-side
      final query = searchQuery.toLowerCase();
      return logs.where((log) {
        return log.readableAction.toLowerCase().contains(query) ||
            log.readableDescription.toLowerCase().contains(query) ||
            log.userName.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      print('❌ Error searching logs: $e');
      return [];
    }
  }

  /// Get activity statistics
  Future<Map<String, int>> getActivityStats(String companyId) async {
    try {
      final logs = await getActivityLogs(
        companyId: companyId,
        limit: 500, // Last 500 logs
      );

      return {
        'total': logs.length,
        'authentication': logs.where((l) => l.category == ActivityCategory.authentication).length,
        'user_actions': logs.where((l) => l.category == ActivityCategory.userActions).length,
        'business': logs.where((l) => l.category == ActivityCategory.business).length,
        'errors': logs.where((l) => l.category == ActivityCategory.errors).length,
        'critical': logs.where((l) => l.riskLevel == RiskLevel.critical).length,
        'high_risk': logs.where((l) => l.riskLevel == RiskLevel.high).length,
      };
    } catch (e) {
      print('❌ Error getting activity stats: $e');
      return {};
    }
  }

  /// Auto-cleanup old logs (call periodically)
  /// This saves storage space and reduces quota usage
  Future<void> cleanupOldLogs({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final snapshot = await _auditLogsCollection
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // Delete in batches
          .get();

      if (snapshot.docs.isEmpty) {
        print('✅ No old logs to delete');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Deleted ${snapshot.docs.length} old logs');
    } catch (e) {
      print('❌ Error cleaning up old logs: $e');
    }
  }

  /// Helper: Get user agent
  String _getUserAgent() {
    // For web, you can use dart:html to get navigator.userAgent
    // For now, return a generic identifier
    return 'BukTrack-Web-Admin';
  }

  /// Helper: Get session ID
  String? _getSessionId() {
    // You can implement session tracking here
    // For now, return null
    return null;
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _flushBatch(); // Flush remaining logs
  }
}

/// Helper class for common logging operations
class ActivityLogger {
  final ActivityLogService _service;
  final String userId;
  final String userName;
  final String companyId;

  ActivityLogger({
    required ActivityLogService service,
    required this.userId,
    required this.userName,
    required this.companyId,
  }) : _service = service;

  /// Log authentication events
  Future<void> logLogin() async {
    await _service.logActivity(
      activityType: ActivityType.login,
      category: ActivityCategory.authentication,
      readableAction: 'User Login',
      readableDescription: '$userName logged in successfully',
      userId: userId,
      userName: userName,
      userType: 'admin',
      status: 'success',
      riskLevel: RiskLevel.low,
      metadata: {'company_id': companyId},
    );
  }

  Future<void> logLogout() async {
    await _service.logActivity(
      activityType: ActivityType.logout,
      category: ActivityCategory.authentication,
      readableAction: 'User Logout',
      readableDescription: '$userName logged out',
      userId: userId,
      userName: userName,
      userType: 'admin',
      status: 'success',
      riskLevel: RiskLevel.low,
      metadata: {'company_id': companyId},
    );
  }

  /// Log business operations
  Future<void> logBusCreated(String busPlate) async {
    await _service.logActivity(
      activityType: ActivityType.create,
      category: ActivityCategory.business,
      readableAction: 'Bus Created',
      readableDescription: '$userName created bus $busPlate',
      userId: userId,
      userName: userName,
      userType: 'admin',
      status: 'success',
      riskLevel: RiskLevel.medium,
      metadata: {
        'company_id': companyId,
        'bus_plate': busPlate,
        'operation': 'create_bus',
      },
      entity: {
        'type': 'bus',
        'name': busPlate,
      },
    );
  }

  Future<void> logBusDeleted(String busPlate) async {
    await _service.logActivity(
      activityType: ActivityType.delete,
      category: ActivityCategory.business,
      readableAction: 'Bus Deleted',
      readableDescription: '$userName deleted bus $busPlate',
      userId: userId,
      userName: userName,
      userType: 'admin',
      status: 'success',
      riskLevel: RiskLevel.high,
      metadata: {
        'company_id': companyId,
        'bus_plate': busPlate,
        'operation': 'delete_bus',
      },
      entity: {
        'type': 'bus',
        'name': busPlate,
      },
    );
  }

  Future<void> logAccountCreated(String accountName, String role) async {
    await _service.logActivity(
      activityType: ActivityType.accountCreated,
      category: ActivityCategory.business,
      readableAction: 'Account Created',
      readableDescription: '$userName created $role account: $accountName',
      userId: userId,
      userName: userName,
      userType: 'admin',
      status: 'success',
      riskLevel: RiskLevel.medium,
      metadata: {
        'company_id': companyId,
        'account_name': accountName,
        'account_role': role,
        'operation': 'create_account',
      },
      entity: {
        'type': 'account',
        'name': accountName,
      },
    );
  }

  /// Log errors
  Future<void> logError(String operation, String errorMessage) async {
    await _service.logActivity(
      activityType: ActivityType.error,
      category: ActivityCategory.errors,
      readableAction: 'Error Occurred',
      readableDescription: 'Error in $operation: $errorMessage',
      userId: userId,
      userName: userName,
      userType: 'admin',
      status: 'failure',
      riskLevel: RiskLevel.high,
      metadata: {
        'company_id': companyId,
        'operation': operation,
        'error_message': errorMessage,
      },
    );
  }
}