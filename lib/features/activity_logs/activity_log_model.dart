import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity Log Model - Matches Firestore structure
/// Optimized for minimal writes and efficient queries
class ActivityLog {
  final String id;
  final String activityType;
  final String category;
  final String readableAction;
  final String readableDescription;
  final String userId;
  final String userName;
  final String userType; // 'admin', 'driver', 'conductor'
  final String status; // 'success', 'failure', 'warning'
  final String riskLevel; // 'low', 'medium', 'high', 'critical'
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final String? sessionId;
  final Map<String, dynamic>? metadata;
  final List<Map<String, dynamic>>? changes;
  final Map<String, dynamic>? entity;

  ActivityLog({
    required this.id,
    required this.activityType,
    required this.category,
    required this.readableAction,
    required this.readableDescription,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.status,
    required this.riskLevel,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    this.sessionId,
    this.metadata,
    this.changes,
    this.entity,
  });

  /// Create from Firestore document
  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ActivityLog(
      id: doc.id,
      activityType: data['activity_type'] ?? '',
      category: data['category'] ?? '',
      readableAction: data['readable_action'] ?? '',
      readableDescription: data['readable_description'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userType: data['user_type'] ?? '',
      status: data['status'] ?? 'success',
      riskLevel: data['risk_level'] ?? 'low',
      timestamp: _toDateTime(data['timestamp']),
      ipAddress: data['ip_address'] ?? '',
      userAgent: data['user_agent'] ?? '',
      sessionId: data['session_id'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      changes: data['changes'] != null
          ? List<Map<String, dynamic>>.from(data['changes'])
          : null,
      entity: data['entity'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'activity_type': activityType,
      'category': category,
      'readable_action': readableAction,
      'readable_description': readableDescription,
      'user_id': userId,
      'user_name': userName,
      'user_type': userType,
      'status': status,
      'risk_level': riskLevel,
      'timestamp': FieldValue.serverTimestamp(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      if (sessionId != null) 'session_id': sessionId,
      if (metadata != null) 'metadata': metadata,
      if (changes != null) 'changes': changes,
      if (entity != null) 'entity': entity,
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get risk color
  String get riskColor {
    switch (riskLevel) {
      case 'critical':
        return '#dc2626';
      case 'high':
        return '#ea580c';
      case 'medium':
        return '#f59e0b';
      case 'low':
      default:
        return '#10b981';
    }
  }

  @override
  String toString() {
    return 'ActivityLog(id: $id, action: $readableAction, user: $userName, timestamp: $timestamp)';
  }
}

/// Activity log categories
class ActivityCategory {
  static const String authentication = 'authentication';
  static const String userActions = 'user_actions';
  static const String business = 'business';
  static const String permissions = 'permissions';
  static const String errors = 'errors';
  static const String system = 'system';
}

/// Activity types
class ActivityType {
  // Authentication
  static const String login = 'login';
  static const String logout = 'logout';
  static const String sessionExpired = 'session_expired';

  // User Actions
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String view = 'view';
  static const String export = 'export';

  // Business
  static const String busAssigned = 'bus_assigned';
  static const String routeCreated = 'route_created';
  static const String accountCreated = 'account_created';

  // Permissions
  static const String permissionGranted = 'permission_granted';
  static const String permissionRevoked = 'permission_revoked';

  // Errors
  static const String error = 'error';
  static const String warning = 'warning';
}

/// Risk levels
class RiskLevel {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';
}