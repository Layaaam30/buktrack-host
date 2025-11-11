/// Route Model
/// Represents a bus route
class BusRoute {
  final String id;
  final String routeCode;
  final String origin;
  final String destination;
  final String travelTime; // e.g., "2h 30m"
  final String status; // 'active', 'inactive'
  final List<String> assignedBusIds;
  final double? distance; // in kilometers
  final double? fare;

  BusRoute({
    required this.id,
    required this.routeCode,
    required this.origin,
    required this.destination,
    required this.travelTime,
    required this.status,
    this.assignedBusIds = const [],
    this.distance,
    this.fare,
  });

  // Get full route name
  String get fullRouteName => '$origin - $destination';

  // Get status display text
  String get statusText {
    return status == 'active' ? 'Active' : 'Inactive';
  }

  // Get assigned buses count
  int get assignedBusesCount => assignedBusIds.length;

  // Get assigned buses display text
  String get assignedBusesText {
    if (assignedBusIds.isEmpty) return 'No buses';
    if (assignedBusIds.length == 1) return '1 bus';
    return '${assignedBusIds.length} buses';
  }

  // Check if route has assigned buses
  bool get hasAssignedBuses => assignedBusIds.isNotEmpty;

  // Convert from JSON (for Firebase integration later)
  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] ?? '',
      routeCode: json['routeCode'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      travelTime: json['travelTime'] ?? '',
      status: json['status'] ?? 'inactive',
      assignedBusIds: json['assignedBusIds'] != null
          ? List<String>.from(json['assignedBusIds'])
          : [],
      distance: json['distance']?.toDouble(),
      fare: json['fare']?.toDouble(),
    );
  }

  // Convert to JSON (for Firebase integration later)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeCode': routeCode,
      'origin': origin,
      'destination': destination,
      'travelTime': travelTime,
      'status': status,
      'assignedBusIds': assignedBusIds,
      'distance': distance,
      'fare': fare,
    };
  }
}
