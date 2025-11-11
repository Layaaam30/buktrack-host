/// Bus Model
/// Represents a bus in the fleet
class Bus {
  final String id;
  final String plateNumber;
  final String status; // 'active', 'inactive', 'maintenance'
  final int currentCapacity;
  final int totalCapacity;
  final String? driverName;
  final String? conductorName;
  final String? routeName;
  final DateTime? lastUpdated;

  Bus({
    required this.id,
    required this.plateNumber,
    required this.status,
    this.currentCapacity = 0,
    required this.totalCapacity,
    this.driverName,
    this.conductorName,
    this.routeName,
    this.lastUpdated,
  });

  // Calculate capacity percentage
  double get capacityPercentage {
    if (totalCapacity == 0) return 0;
    return (currentCapacity / totalCapacity) * 100;
  }

  // Check if driver is assigned
  bool get hasDriver => driverName != null && driverName!.isNotEmpty;

  // Check if conductor is assigned
  bool get hasConductor => conductorName != null && conductorName!.isNotEmpty;

  // Check if route is assigned
  bool get hasRoute => routeName != null && routeName!.isNotEmpty;

  // Get status display text
  String get statusText {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  // Get last updated display text
  String get lastUpdatedText {
    if (lastUpdated == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Factory constructor for dummy data
  factory Bus.dummy(int index) {
    final plateNumbers = ['QWE-321', 'ABC-123', 'XYZ-789'];
    return Bus(
      id: 'bus_$index',
      plateNumber: plateNumbers[index % plateNumbers.length],
      status: 'inactive',
      currentCapacity: 0,
      totalCapacity: 45,
      lastUpdated: null,
    );
  }

  // Convert from JSON (for Firebase integration later)
  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      status: json['status'] ?? 'inactive',
      currentCapacity: json['currentCapacity'] ?? 0,
      totalCapacity: json['totalCapacity'] ?? 45,
      driverName: json['driverName'],
      conductorName: json['conductorName'],
      routeName: json['routeName'],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // Convert to JSON (for Firebase integration later)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'status': status,
      'currentCapacity': currentCapacity,
      'totalCapacity': totalCapacity,
      'driverName': driverName,
      'conductorName': conductorName,
      'routeName': routeName,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}
