import 'package:cloud_firestore/cloud_firestore.dart';
import 'waypoint_model.dart';

/// Waypoint Firestore Service
/// Manages waypoint data in Firestore
class WaypointService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _waypointsCollection {
    return _firestore.collection('waypoints');
  }

  /// Get all waypoints for a company with real-time updates
  Stream<List<WaypointModel>> getWaypointsStream(String companyId) {
    print('🔥 Starting real-time stream for waypoints in company: $companyId');

    return _waypointsCollection
        .where('company_ID', isEqualTo: companyId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          print(
            '🔥 Received ${snapshot.docs.length} waypoint documents from Firestore',
          );

          final waypoints = <WaypointModel>[];

          for (var doc in snapshot.docs) {
            try {
              final waypoint = WaypointModel.fromFirestore(doc);
              waypoints.add(waypoint);
              print('   ✅ Successfully parsed: ${waypoint.name}');
            } catch (e) {
              print('❌ Error parsing waypoint ${doc.id}: $e');
            }
          }

          print('📊 Loaded ${waypoints.length} waypoints successfully');
          return waypoints;
        })
        .handleError((error) {
          print('❌ Stream error: $error');
          throw error;
        });
  }

  /// Get all waypoints (one-time fetch)
  Future<List<WaypointModel>> getWaypoints(String companyId) async {
    try {
      print('🔍 Fetching waypoints for company: $companyId');

      final snapshot = await _waypointsCollection
          .where('company_ID', isEqualTo: companyId)
          .orderBy('order')
          .get();

      final waypoints = <WaypointModel>[];

      for (var doc in snapshot.docs) {
        try {
          final waypoint = WaypointModel.fromFirestore(doc);
          waypoints.add(waypoint);
          print('✅ Loaded waypoint: ${waypoint.name}');
        } catch (e) {
          print('❌ Error parsing waypoint ${doc.id}: $e');
        }
      }

      print('📦 Total waypoints loaded: ${waypoints.length}');
      return waypoints;
    } catch (e) {
      print('❌ Error fetching waypoints: $e');
      throw Exception('Failed to fetch waypoints: $e');
    }
  }

  /// Get single waypoint by ID
  Future<WaypointModel?> getWaypointById(String waypointId) async {
    try {
      print('🔍 Fetching waypoint: $waypointId');

      final doc = await _waypointsCollection.doc(waypointId).get();

      if (!doc.exists) {
        print('❌ Waypoint not found: $waypointId');
        return null;
      }

      final waypoint = WaypointModel.fromFirestore(doc);
      print('✅ Loaded waypoint: ${waypoint.name}');
      return waypoint;
    } catch (e) {
      print('❌ Error fetching waypoint: $e');
      throw Exception('Failed to fetch waypoint: $e');
    }
  }

  /// Create a new waypoint
  Future<String> createWaypoint(WaypointModel waypoint) async {
    try {
      print('➕ Creating waypoint: ${waypoint.name}');
      print('   Location: ${waypoint.coordinatesFormatted}');
      print('   Company ID: ${waypoint.companyId}');

      final waypointData = waypoint
          .copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now())
          .toFirestore();

      final docRef = await _waypointsCollection.add(waypointData);

      print('✅ Waypoint created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating waypoint: $e');
      throw Exception('Failed to create waypoint: $e');
    }
  }

  /// Update an existing waypoint
  Future<void> updateWaypoint(String waypointId, WaypointModel waypoint) async {
    try {
      print('✏️ Updating waypoint: $waypointId');

      final waypointData = waypoint
          .copyWith(updatedAt: DateTime.now())
          .toFirestore();

      await _waypointsCollection.doc(waypointId).update(waypointData);

      print('✅ Waypoint updated successfully');
    } catch (e) {
      print('❌ Error updating waypoint: $e');
      throw Exception('Failed to update waypoint: $e');
    }
  }

  /// Delete a waypoint
  Future<void> deleteWaypoint(String waypointId) async {
    try {
      print('🗑️ Deleting waypoint: $waypointId');

      await _waypointsCollection.doc(waypointId).delete();

      print('✅ Waypoint deleted successfully');
    } catch (e) {
      print('❌ Error deleting waypoint: $e');
      throw Exception('Failed to delete waypoint: $e');
    }
  }

  /// Reorder waypoints
  Future<void> reorderWaypoints(
    List<String> waypointIds,
    String adminId,
  ) async {
    try {
      print('🔄 Reordering ${waypointIds.length} waypoints');

      final batch = _firestore.batch();

      for (int i = 0; i < waypointIds.length; i++) {
        final docRef = _waypointsCollection.doc(waypointIds[i]);
        batch.update(docRef, {
          'order': i,
          'updated_at': FieldValue.serverTimestamp(),
          'updated_by_admin': adminId,
        });
      }

      await batch.commit();

      print('✅ Waypoints reordered successfully');
    } catch (e) {
      print('❌ Error reordering waypoints: $e');
      throw Exception('Failed to reorder waypoints: $e');
    }
  }

  /// Get waypoints by IDs (for route display)
  Future<List<WaypointModel>> getWaypointsByIds(
    List<String> waypointIds,
  ) async {
    try {
      if (waypointIds.isEmpty) return [];

      print('🔍 Fetching ${waypointIds.length} waypoints by IDs');

      final waypoints = <WaypointModel>[];

      // Firestore 'in' query has a limit of 10 items, so we need to batch
      for (int i = 0; i < waypointIds.length; i += 10) {
        final batch = waypointIds.skip(i).take(10).toList();

        final snapshot = await _waypointsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          try {
            final waypoint = WaypointModel.fromFirestore(doc);
            waypoints.add(waypoint);
          } catch (e) {
            print('❌ Error parsing waypoint ${doc.id}: $e');
          }
        }
      }

      // Sort by the order they appear in waypointIds
      waypoints.sort((a, b) {
        final aIndex = waypointIds.indexOf(a.id);
        final bIndex = waypointIds.indexOf(b.id);
        return aIndex.compareTo(bIndex);
      });

      print('📦 Loaded ${waypoints.length} waypoints');
      return waypoints;
    } catch (e) {
      print('❌ Error fetching waypoints by IDs: $e');
      throw Exception('Failed to fetch waypoints: $e');
    }
  }

  /// Search waypoints by name
  Future<List<WaypointModel>> searchWaypoints(
    String companyId,
    String query,
  ) async {
    try {
      print('🔍 Searching waypoints with query: $query');

      final snapshot = await _waypointsCollection
          .where('company_ID', isEqualTo: companyId)
          .get();

      final waypoints = <WaypointModel>[];
      final lowerQuery = query.toLowerCase();

      for (var doc in snapshot.docs) {
        try {
          final waypoint = WaypointModel.fromFirestore(doc);
          if (waypoint.name.toLowerCase().contains(lowerQuery) ||
              (waypoint.description?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (waypoint.address?.toLowerCase().contains(lowerQuery) ?? false)) {
            waypoints.add(waypoint);
          }
        } catch (e) {
          print('❌ Error parsing waypoint ${doc.id}: $e');
        }
      }

      print('📦 Found ${waypoints.length} matching waypoints');
      return waypoints;
    } catch (e) {
      print('❌ Error searching waypoints: $e');
      throw Exception('Failed to search waypoints: $e');
    }
  }

  /// Get waypoints within a geographic area (for map view)
  Future<List<WaypointModel>> getWaypointsInArea(
    String companyId,
    GeoPoint southwest,
    GeoPoint northeast,
  ) async {
    try {
      print('🗺️ Fetching waypoints in area');
      print('   SW: ${southwest.latitude}, ${southwest.longitude}');
      print('   NE: ${northeast.latitude}, ${northeast.longitude}');

      final snapshot = await _waypointsCollection
          .where('company_ID', isEqualTo: companyId)
          .get();

      final waypoints = <WaypointModel>[];

      for (var doc in snapshot.docs) {
        try {
          final waypoint = WaypointModel.fromFirestore(doc);

          // Check if waypoint is within bounds
          if (waypoint.latitude >= southwest.latitude &&
              waypoint.latitude <= northeast.latitude &&
              waypoint.longitude >= southwest.longitude &&
              waypoint.longitude <= northeast.longitude) {
            waypoints.add(waypoint);
          }
        } catch (e) {
          print('❌ Error parsing waypoint ${doc.id}: $e');
        }
      }

      print('📦 Found ${waypoints.length} waypoints in area');
      return waypoints;
    } catch (e) {
      print('❌ Error fetching waypoints in area: $e');
      throw Exception('Failed to fetch waypoints in area: $e');
    }
  }

  /// Check if waypoint name exists
  Future<bool> waypointNameExists(String companyId, String name) async {
    try {
      final query = await _waypointsCollection
          .where('company_ID', isEqualTo: companyId)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
