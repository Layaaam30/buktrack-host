import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:tabler_icons/tabler_icons.dart';

enum WaypointCategory {
  busTerminal,
  busStop;

  String get displayName {
    switch (this) {
      case WaypointCategory.busTerminal:
        return 'Bus Terminal';
      case WaypointCategory.busStop:
        return 'Bus Stop';
    }
  }

  String get value {
    switch (this) {
      case WaypointCategory.busTerminal:
        return 'bus_terminal';
      case WaypointCategory.busStop:
        return 'bus_stop';
    }
  }

  static WaypointCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'bus_terminal':
      case 'busterminal':
        return WaypointCategory.busTerminal;
      case 'bus_stop':
      case 'busstop':
        return WaypointCategory.busStop;
      default:
        return WaypointCategory.busStop;
    }
  }
}

class WaypointModel {
  final String id;
  final String name;
  final String? description;
  final GeoPoint location;
  final int order;
  final String? address;
  final WaypointCategory category;
  final String companyId;

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
    required this.category,
    required this.companyId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByAdmin,
    this.updatedByAdmin,
  });

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
        category: WaypointCategory.fromString(data['category']?.toString()),
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

  factory WaypointModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return WaypointModel(
      id: id ?? data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      order: _parseInt(data['order']) ?? 0,
      address: data['address']?.toString(),
      category: WaypointCategory.fromString(data['category']?.toString()),
      companyId: data['company_ID']?.toString() ?? '',
      createdAt: _toDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _toDateTime(data['updated_at']) ?? DateTime.now(),
      createdByAdmin: data['created_by_admin']?.toString() ?? '',
      updatedByAdmin: data['updated_by_admin']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
      'description': description,
      'location': location,
      'order': order,
      'address': address,
      'category': category.value,
      'company_ID': companyId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'created_by_admin': createdByAdmin,
      'updated_by_admin': updatedByAdmin,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'order': order,
      'address': address,
      'category': category.value,
    };
  }

  WaypointModel copyWith({
    String? id,
    String? name,
    String? description,
    GeoPoint? location,
    int? order,
    String? address,
    WaypointCategory? category,
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
      category: category ?? this.category,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      updatedByAdmin: updatedByAdmin ?? this.updatedByAdmin,
    );
  }

  double get latitude => location.latitude;
  double get longitude => location.longitude;
  String get coordinatesFormatted =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  String get latitudeFormatted => latitude.toStringAsFixed(6);

  String get longitudeFormatted => longitude.toStringAsFixed(6);

  String get waypointId {
    return 'WP-${(order + 1).toString().padLeft(3, '0')}';
  }

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  IconData get categoryIcon {
    switch (category) {
      case WaypointCategory.busTerminal:
        return TablerIcons.building_warehouse;
      case WaypointCategory.busStop:
        return TablerIcons.bus_stop;
    }
  }

  @override
  String toString() {
    return 'WaypointModel(id: $id, name: $name, category: ${category.displayName}, order: $order, location: $coordinatesFormatted)';
  }
}
