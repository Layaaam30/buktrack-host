import 'package:cloud_firestore/cloud_firestore.dart';

/// Route Model
/// Matches Firestore structure for bus routes
class RouteModel {
  final String id;
  final String routeCode;
  final String routeName;
  final String originName;
  final String destinationName;
  final List<String> waypoints;
  final int estimatedTravelTime; // in minutes
  final bool isActive;
  final String companyId;

  // Assignment and scheduling
  final List<String> assignedBuses;
  final List<Map<String, dynamic>> schedules;

  // Audit fields
  final String createdByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignmentChangedBy;
  final String? statusChangedBy;
  final DateTime? statusChangedAt;
  final String? updatedByAdmin;

  RouteModel({
    required this.id,
    required this.routeCode,
    required this.routeName,
    required this.originName,
    required this.destinationName,
    this.waypoints = const [],
    required this.estimatedTravelTime,
    this.isActive = true,
    required this.companyId,
    this.assignedBuses = const [],
    this.schedules = const [],
    required this.createdByAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.assignmentChangedBy,
    this.statusChangedBy,
    this.statusChangedAt,
    this.updatedByAdmin,
  });

  /// Create RouteModel from Firestore document
  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        print('⚠️ Document ${doc.id} has null data');
        throw Exception('Document data is null');
      }

      print('   Parsing route fields:');
      print('     - route_code: ${data['route_code']}');
      print('     - route_name: ${data['route_name']}');
      print('     - company_ID: ${data['company_ID']}');

      return RouteModel(
        id: doc.id,
        routeCode: data['route_code']?.toString() ?? '',
        routeName: data['route_name']?.toString() ?? '',
        originName: data['origin_name']?.toString() ?? '',
        destinationName: data['destination_name']?.toString() ?? '',
        waypoints: _parseWaypoints(data['waypoints']),
        estimatedTravelTime: _parseInt(data['estimated_travel_time']) ?? 0,
        isActive: data['is_active'] ?? true,
        companyId: data['company_ID']?.toString() ?? '',
        assignedBuses: _parseStringList(data['assigned_buses']),
        schedules: _parseSchedules(data['schedules']),
        createdByAdmin: data['created_by_admin']?.toString() ?? '',
        createdAt: _toDateTime(data['created_at']) ?? DateTime.now(),
        updatedAt: _toDateTime(data['updated_at']) ?? DateTime.now(),
        assignmentChangedBy: data['assignment_changed_by']?.toString(),
        statusChangedBy: data['status_changed_by']?.toString(),
        statusChangedAt: _toDateTime(data['status_changed_at']),
        updatedByAdmin: data['updated_by_admin']?.toString(),
      );
    } catch (e, stackTrace) {
      print('❌❌❌ Error parsing route document ${doc.id}:');
      print('   Error: $e');
      print('   Stack: $stackTrace');
      print('   Data: ${doc.data()}');
      rethrow;
    }
  }

  /// Helper: Parse waypoints from various formats
  static List<String> _parseWaypoints(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Helper: Parse string list
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Helper: Parse schedules
  static List<Map<String, dynamic>> _parseSchedules(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map(
            (e) =>
                e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
          )
          .toList();
    }
    return [];
  }

  /// Helper: Parse integer
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper: Safely convert to DateTime
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convert RouteModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'route_code': routeCode,
      'route_name': routeName,
      'origin_name': originName,
      'destination_name': destinationName,
      'waypoints': waypoints,
      'estimated_travel_time': estimatedTravelTime,
      'is_active': isActive,
      'company_ID': companyId,
      'assigned_buses': assignedBuses,
      'schedules': schedules,
      'created_by_admin': createdByAdmin,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'assignment_changed_by': assignmentChangedBy,
      'status_changed_by': statusChangedBy,
      'status_changed_at': statusChangedAt != null
          ? Timestamp.fromDate(statusChangedAt!)
          : null,
      'updated_by_admin': updatedByAdmin,
    };
  }

  /// Create a copy with updated fields
  RouteModel copyWith({
    String? id,
    String? routeCode,
    String? routeName,
    String? originName,
    String? destinationName,
    List<String>? waypoints,
    int? estimatedTravelTime,
    bool? isActive,
    String? companyId,
    List<String>? assignedBuses,
    List<Map<String, dynamic>>? schedules,
    String? createdByAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignmentChangedBy,
    String? statusChangedBy,
    DateTime? statusChangedAt,
    String? updatedByAdmin,
  }) {
    return RouteModel(
      id: id ?? this.id,
      routeCode: routeCode ?? this.routeCode,
      routeName: routeName ?? this.routeName,
      originName: originName ?? this.originName,
      destinationName: destinationName ?? this.destinationName,
      waypoints: waypoints ?? this.waypoints,
      estimatedTravelTime: estimatedTravelTime ?? this.estimatedTravelTime,
      isActive: isActive ?? this.isActive,
      companyId: companyId ?? this.companyId,
      assignedBuses: assignedBuses ?? this.assignedBuses,
      schedules: schedules ?? this.schedules,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignmentChangedBy: assignmentChangedBy ?? this.assignmentChangedBy,
      statusChangedBy: statusChangedBy ?? this.statusChangedBy,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      updatedByAdmin: updatedByAdmin ?? this.updatedByAdmin,
    );
  }

  /// Get full route description
  String get fullRoute => '$originName → $destinationName';

  /// Get status display name
  String get statusDisplayName => isActive ? 'Active' : 'Inactive';

  /// Get travel time in hours and minutes
  String get travelTimeFormatted {
    final hours = estimatedTravelTime ~/ 60;
    final minutes = estimatedTravelTime % 60;
    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    }
    return '$minutes min';
  }

  /// Check if route has assigned buses
  bool get hasAssignedBuses => assignedBuses.isNotEmpty;

  /// Get number of waypoints
  int get waypointCount => waypoints.length;

  @override
  String toString() {
    return 'RouteModel(id: $id, code: $routeCode, name: $routeName, route: $fullRoute, active: $isActive)';
  }
}
