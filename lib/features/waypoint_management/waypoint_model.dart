import 'package:cloud_firestore/cloud_firestore.dart';

/// Waypoint Model
/// Represents a location point along a route with GPS coordinates
class WaypointModel {
  final String id;
  final String name;
  final String? description;
  final GeoPoint location; // latitude, longitude
  final int order; // Position in the route sequence
  final String? address; // Optional formatted address
  final String companyId;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByAdmin;
  final String? updatedByAdmin;

  WaypointModel({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    required this.order,
    this.address,
    required this.companyId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByAdmin,
    this.updatedByAdmin,
  });

  /// Create WaypointModel from Firestore document
  factory WaypointModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Document data is null');
      }

      return WaypointModel(
        id: doc.id,
        name: data['name']?.toString() ?? '',
        description: data['description']?.toString(),
        location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
        order: _parseInt(data['order']) ?? 0,
        address: data['address']?.toString(),
        companyId: data['company_ID']?.toString() ?? '',
        createdAt: _toDateTime(data['created_at']) ?? DateTime.now(),
        updatedAt: _toDateTime(data['updated_at']) ?? DateTime.now(),
        createdByAdmin: data['created_by_admin']?.toString() ?? '',
        updatedByAdmin: data['updated_by_admin']?.toString(),
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing waypoint document ${doc.id}:');
      print('   Error: $e');
      print('   Stack: $stackTrace');
      rethrow;
    }
  }

  /// Create from map (for route waypoints)
  factory WaypointModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return WaypointModel(
      id: id ?? data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      order: _parseInt(data['order']) ?? 0,
      address: data['address']?.toString(),
      companyId: data['company_ID']?.toString() ?? '',
      createdAt: _toDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _toDateTime(data['updated_at']) ?? DateTime.now(),
      createdByAdmin: data['created_by_admin']?.toString() ?? '',
      updatedByAdmin: data['updated_by_admin']?.toString(),
    );
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

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'order': order,
      'address': address,
      'company_ID': companyId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'created_by_admin': createdByAdmin,
      'updated_by_admin': updatedByAdmin,
    };
  }

  /// Convert to map (for embedding in routes)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'order': order,
      'address': address,
    };
  }

  /// Create a copy with updated fields
  WaypointModel copyWith({
    String? id,
    String? name,
    String? description,
    GeoPoint? location,
    int? order,
    String? address,
    String? companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByAdmin,
    String? updatedByAdmin,
  }) {
    return WaypointModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      order: order ?? this.order,
      address: address ?? this.address,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      updatedByAdmin: updatedByAdmin ?? this.updatedByAdmin,
    );
  }

  /// Get latitude
  double get latitude => location.latitude;

  /// Get longitude
  double get longitude => location.longitude;

  /// Get formatted coordinates
  String get coordinatesFormatted =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  /// Get formatted latitude only
  String get latitudeFormatted => latitude.toStringAsFixed(6);

  /// Get formatted longitude only
  String get longitudeFormatted => longitude.toStringAsFixed(6);

  /// Get user-friendly waypoint ID (e.g., "WP-001", "WP-042")
  String get friendlyId {
    // Use order + 1 to create a human-readable ID
    // Pad with zeros to make it look professional
    return 'WP-${(order + 1).toString().padLeft(3, '0')}';
  }

  /// Get short ID for display (first 8 characters of Firestore ID)
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  @override
  String toString() {
    return 'WaypointModel(id: $id, name: $name, order: $order, location: $coordinatesFormatted)';
  }
}
