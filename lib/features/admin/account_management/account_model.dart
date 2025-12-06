import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final String id;
  final String name;
  final String username;
  final String phoneNumber;
  final String role;
  final String companyId;
  final String passwordHash;

  final String? assignedBusId;
  final String? currentRouteId;
  final String? assignedByAdmin;
  final DateTime? assignmentDate;
  final String? unassignedByAdmin;
  final DateTime? unassignedAt;

  final String availabilityStatus;
  final bool isActive;

  final DateTime? leaveStartDate;
  final DateTime? leaveEndDate;
  final String? leaveReason;

  final String createdByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? statusChangedBy;
  final DateTime? lastLoginTimestamp;

  final String? firebaseUid;
  final String? firebaseEmail;

  Account({
    required this.id,
    required this.name,
    required this.username,
    required this.phoneNumber,
    required this.role,
    required this.companyId,
    required this.passwordHash,
    this.assignedBusId,
    this.currentRouteId,
    this.assignedByAdmin,
    this.assignmentDate,
    this.unassignedByAdmin,
    this.unassignedAt,
    this.availabilityStatus = 'available',
    this.isActive = true,
    this.leaveStartDate,
    this.leaveEndDate,
    this.leaveReason,
    required this.createdByAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.statusChangedBy,
    this.lastLoginTimestamp,
    this.firebaseUid,
    this.firebaseEmail,
  });

  factory Account.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Document data is null');
      }

      return Account(
        id: doc.id,
        name: data['name'] ?? '',
        username: data['username'] ?? '',
        phoneNumber: data['phone_number'] ?? '',
        role: data['role'] ?? 'conductor',
        companyId: data['company_ID'] ?? '',
        passwordHash: data['password_hash'] ?? '',
        assignedBusId: data['assigned_bus_ID'],
        currentRouteId: data['current_route_ID'],
        assignedByAdmin: data['assigned_by_admin'],
        assignmentDate: _toDateTime(data['assignment_date']),
        unassignedByAdmin: data['unassigned_by_admin'],
        unassignedAt: _toDateTime(data['unassigned_at']),
        availabilityStatus: data['availability_status'] ?? 'available',
        isActive: data['is_active'] ?? true,
        leaveStartDate: _toDateTime(data['leave_start_date']),
        leaveEndDate: _toDateTime(data['leave_end_date']),
        leaveReason: data['leave_reason'],
        createdByAdmin: data['created_by_admin'] ?? '',
        createdAt: _toDateTime(data['created_at']) ?? DateTime.now(),
        updatedAt: _toDateTime(data['updated_at']) ?? DateTime.now(),
        statusChangedBy: data['status_changed_by'],
        lastLoginTimestamp: _toDateTime(data['last_login_timestamp']),
        firebaseUid: data['firebase_uid'],
        firebaseEmail: data['firebase_email'],
      );
    } catch (e) {
      print('Error parsing account document ${doc.id}: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'username': username,
      'phone_number': phoneNumber,
      'role': role,
      'company_ID': companyId,
      'password_hash': passwordHash,
      'assigned_bus_ID': assignedBusId,
      'current_route_ID': currentRouteId,
      'assigned_by_admin': assignedByAdmin,
      'assignment_date': assignmentDate != null
          ? Timestamp.fromDate(assignmentDate!)
          : null,
      'unassigned_by_admin': unassignedByAdmin,
      'unassigned_at': unassignedAt != null
          ? Timestamp.fromDate(unassignedAt!)
          : null,
      'availability_status': availabilityStatus,
      'is_active': isActive,
      'leave_start_date': leaveStartDate != null
          ? Timestamp.fromDate(leaveStartDate!)
          : null,
      'leave_end_date': leaveEndDate != null
          ? Timestamp.fromDate(leaveEndDate!)
          : null,
      'leave_reason': leaveReason,
      'created_by_admin': createdByAdmin,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'status_changed_by': statusChangedBy,
      'last_login_timestamp': lastLoginTimestamp != null
          ? Timestamp.fromDate(lastLoginTimestamp!)
          : null,
      'firebase_uid': firebaseUid,
      'firebase_email': firebaseEmail,
    };
  }

  Account copyWith({
    String? id,
    String? name,
    String? username,
    String? phoneNumber,
    String? role,
    String? companyId,
    String? passwordHash,
    String? assignedBusId,
    String? currentRouteId,
    String? assignedByAdmin,
    DateTime? assignmentDate,
    String? unassignedByAdmin,
    DateTime? unassignedAt,
    String? availabilityStatus,
    bool? isActive,
    DateTime? leaveStartDate,
    DateTime? leaveEndDate,
    String? leaveReason,
    String? createdByAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? statusChangedBy,
    DateTime? lastLoginTimestamp,
    String? firebaseUid,
    String? firebaseEmail,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      passwordHash: passwordHash ?? this.passwordHash,
      assignedBusId: assignedBusId ?? this.assignedBusId,
      currentRouteId: currentRouteId ?? this.currentRouteId,
      assignedByAdmin: assignedByAdmin ?? this.assignedByAdmin,
      assignmentDate: assignmentDate ?? this.assignmentDate,
      unassignedByAdmin: unassignedByAdmin ?? this.unassignedByAdmin,
      unassignedAt: unassignedAt ?? this.unassignedAt,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      isActive: isActive ?? this.isActive,
      leaveStartDate: leaveStartDate ?? this.leaveStartDate,
      leaveEndDate: leaveEndDate ?? this.leaveEndDate,
      leaveReason: leaveReason ?? this.leaveReason,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusChangedBy: statusChangedBy ?? this.statusChangedBy,
      lastLoginTimestamp: lastLoginTimestamp ?? this.lastLoginTimestamp,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      firebaseEmail: firebaseEmail ?? this.firebaseEmail,
    );
  }

  String get availabilityDisplayName {
    switch (availabilityStatus) {
      case 'available':
        return 'Available';
      case 'in_transit':
        return 'In Transit';
      case 'on_leave':
        return 'On Leave';
      case 'unavailable':
        return 'Unavailable';
      default:
        return availabilityStatus;
    }
  }

  String get roleDisplayName {
    return role == 'driver' ? 'Driver' : 'Conductor';
  }

  bool get isAssigned => assignedBusId != null && assignedBusId!.isNotEmpty;

  bool get isOnLeave {
    if (availabilityStatus != 'on_leave') return false;
    if (leaveStartDate == null || leaveEndDate == null) return false;

    final now = DateTime.now();
    return now.isAfter(leaveStartDate!) && now.isBefore(leaveEndDate!);
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, username: $username, role: $role, status: $availabilityStatus)';
  }
}
