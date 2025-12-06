import 'package:cloud_firestore/cloud_firestore.dart';

/// Bus Model - Matches your Firestore structure exactly
class Bus {
  final String id;
  final String plateNumber;
  final String companyId;
  final String? driverId;
  final String? conductorId;
  final String? routeId;
  final GeoPoint? currentLocation;
  final double speed;
  final double heading;
  final int totalCapacity;
  final int passengerCount;
  final DateTime lastUpdateTimestamp;
  final String status;

  // Denormalized fields
  final String? driverName;
  final String? conductorName;
  final String? routeName;

  Bus({
    required this.id,
    required this.plateNumber,
    required this.companyId,
    this.driverId,
    this.conductorId,
    this.routeId,
    this.currentLocation,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.totalCapacity,
    this.passengerCount = 0,
    required this.lastUpdateTimestamp,
    this.status = 'inactive',
    this.driverName,
    this.conductorName,
    this.routeName,
  });

  /// Create Bus from Firestore document
  /// Matches your exact Firestore field names
  factory Bus.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Document data is null');
      }

      return Bus(
        id: doc.id,
        plateNumber: data['plate_number'] ?? '',
        companyId: data['company_ID'] ?? '',
        driverId: data['driver_ID'],
        conductorId: data['conductor_ID'],
        routeId: data['route_ID'],
        currentLocation: data['current_location'] as GeoPoint?,
        speed: _toDouble(data['speed']),
        heading: _toDouble(data['heading']),
        totalCapacity: _toInt(data['total_capacity']),
        passengerCount: _toInt(data['passenger_count']),
        lastUpdateTimestamp: _toDateTime(data['last_update_timestamp']),
        status: data['status']?.toString() ?? 'inactive',
        // Denormalized fields (may not exist in Firestore)
        driverName: data['driver_name'],
        conductorName: data['conductor_name'],
        routeName: data['route_name'],
      );
    } catch (e) {
      print('Error parsing bus document ${doc.id}: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  /// Helper: Safely convert to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper: Safely convert to int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper: Safely convert to DateTime
  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Convert Bus to Firestore document
  /// Uses exact field names from your Firestore structure
  Map<String, dynamic> toFirestore() {
    return {
      'plate_number': plateNumber,
      'company_ID': companyId,
      'driver_ID': driverId,
      'conductor_ID': conductorId,
      'route_ID': routeId,
      'current_location': currentLocation,
      'speed': speed,
      'heading': heading,
      'total_capacity': totalCapacity,
      'passenger_count': passengerCount,
      'last_update_timestamp': Timestamp.fromDate(lastUpdateTimestamp),
      'status': status,
    };
  }

  /// Create a copy with updated fields
  Bus copyWith({
    String? id,
    String? plateNumber,
    String? companyId,
    String? driverId,
    String? conductorId,
    String? routeId,
    GeoPoint? currentLocation,
    double? speed,
    double? heading,
    int? totalCapacity,
    int? passengerCount,
    DateTime? lastUpdateTimestamp,
    String? status,
    String? driverName,
    String? conductorName,
    String? routeName,
  }) {
    return Bus(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      companyId: companyId ?? this.companyId,
      driverId: driverId ?? this.driverId,
      conductorId: conductorId ?? this.conductorId,
      routeId: routeId ?? this.routeId,
      currentLocation: currentLocation ?? this.currentLocation,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      passengerCount: passengerCount ?? this.passengerCount,
      lastUpdateTimestamp: lastUpdateTimestamp ?? this.lastUpdateTimestamp,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      conductorName: conductorName ?? this.conductorName,
      routeName: routeName ?? this.routeName,
    );
  }

  @override
  String toString() {
    return 'Bus(id: $id, plateNumber: $plateNumber, status: $status, companyId: $companyId)';
  }
}
