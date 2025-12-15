import 'package:cloud_firestore/cloud_firestore.dart';
import 'bus_model.dart';

/// Web-Optimized Bus Firestore Service
/// Optimized for lowest network latency on Flutter Web
class BusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _busesCollection => _firestore.collection('buses');

  /// Get all buses for a company with real-time updates (WEB OPTIMIZED)
  /// Uses server-side filtering and efficient snapshots
  Stream<List<Bus>> getBusesStream(String companyId) {
    print('🔥 Starting real-time stream for company: $companyId');

    return _busesCollection
        .where('company_ID', isEqualTo: companyId)
        .orderBy('last_update_timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Received ${snapshot.docs.length} buses from stream');

          final buses = <Bus>[];
          for (var doc in snapshot.docs) {
            try {
              final bus = Bus.fromFirestore(doc);
              buses.add(bus);
              print('✅ Parsed bus: ${bus.plateNumber} (${bus.id})');
            } catch (e) {
              print('❌ Error parsing bus ${doc.id}: $e');
              print('   Data: ${doc.data()}');
            }
          }

          return buses;
        })
        .handleError((error) {
          print('❌ Stream error: $error');
          return <Bus>[];
        });
  }

  /// Get all buses for a company (one-time fetch) - WEB OPTIMIZED
  Future<List<Bus>> getBuses(String companyId) async {
    try {
      print('🔍 Fetching buses for company: $companyId');

      final snapshot = await _busesCollection
          .where('company_ID', isEqualTo: companyId)
          .orderBy('last_update_timestamp', descending: true)
          .get();

      print('📦 Received ${snapshot.docs.length} bus documents');

      final buses = <Bus>[];
      for (var doc in snapshot.docs) {
        try {
          final bus = Bus.fromFirestore(doc);
          buses.add(bus);
          print('✅ Loaded: ${bus.plateNumber} - Status: ${bus.status}');
        } catch (e) {
          print('❌ Error parsing bus ${doc.id}: $e');
          print('   Document data: ${doc.data()}');
        }
      }

      return buses;
    } catch (e) {
      print('❌ Error fetching buses: $e');
      throw Exception('Failed to fetch buses: $e');
    }
  }

  /// Get a single bus by ID
  Future<Bus?> getBusById(String busId) async {
    try {
      print('🔍 Fetching bus: $busId');

      final doc = await _busesCollection.doc(busId).get();

      if (!doc.exists) {
        print('❌ Bus not found: $busId');
        return null;
      }

      final bus = Bus.fromFirestore(doc);
      print('✅ Loaded bus: ${bus.plateNumber}');
      return bus;
    } catch (e) {
      print('❌ Error fetching bus: $e');
      throw Exception('Failed to fetch bus: $e');
    }
  }

  /// Create a new bus
  Future<String> createBus(Bus bus) async {
    try {
      print('➕ Creating bus: ${bus.plateNumber}');

      final docRef = await _busesCollection.add(bus.toFirestore());

      print('✅ Bus created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating bus: $e');
      throw Exception('Failed to create bus: $e');
    }
  }

  /// Update an existing bus
  Future<void> updateBus(String busId, Bus bus) async {
    try {
      print('✏️ Updating bus: $busId');

      await _busesCollection.doc(busId).update(bus.toFirestore());

      print('✅ Bus updated successfully');
    } catch (e) {
      print('❌ Error updating bus: $e');
      throw Exception('Failed to update bus: $e');
    }
  }

  /// Update specific fields of a bus (most efficient)
  Future<void> updateBusFields(
    String busId,
    Map<String, dynamic> fields,
  ) async {
    try {
      print('✏️ Updating bus fields: $busId');

      await _busesCollection.doc(busId).update(fields);

      print('✅ Fields updated successfully');
    } catch (e) {
      print('❌ Error updating bus fields: $e');
      throw Exception('Failed to update bus fields: $e');
    }
  }

  /// Delete a bus
  Future<void> deleteBus(String busId) async {
    try {
      print('🗑️ Deleting bus: $busId');

      await _busesCollection.doc(busId).delete();

      print('✅ Bus deleted successfully');
    } catch (e) {
      print('❌ Error deleting bus: $e');
      throw Exception('Failed to delete bus: $e');
    }
  }

  /// Update bus status (optimized - only updates changed fields)
  Future<void> updateBusStatus(String busId, String status) async {
    try {
      await _busesCollection.doc(busId).update({
        'status': status,
        'last_update_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update bus status: $e');
    }
  }

  /// Update bus location (optimized for real-time tracking)
  Future<void> updateBusLocation(
    String busId,
    GeoPoint location,
    double speed,
    double heading,
  ) async {
    try {
      await _busesCollection.doc(busId).update({
        'current_location': location,
        'speed': speed,
        'heading': heading,
        'last_update_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update bus location: $e');
    }
  }

  /// Update bus passenger count
  Future<void> updatePassengerCount(String busId, int count) async {
    try {
      await _busesCollection.doc(busId).update({
        'passenger_count': count,
        'last_update_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update passenger count: $e');
    }
  }

  /// Assign driver to bus
  Future<void> assignDriver(String busId, String driverId) async {
    try {
      await _busesCollection.doc(busId).update({
        'driver_ID': driverId,
        'status': 'standby', // ✅ Set to standby when driver assigned
        'last_update_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign driver: $e');
    }
  }

  /// Assign conductor to bus
  Future<void> assignConductor(String busId, String conductorId) async {
    try {
      await _busesCollection.doc(busId).update({
        'conductor_ID': conductorId,
        'status': 'standby', // ✅ Set to standby when conductor assigned
        'last_update_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign conductor: $e');
    }
  }

  /// Assign route to bus
  Future<void> assignRoute(String busId, String routeId) async {
    try {
      await _busesCollection.doc(busId).update({
        'route_ID': routeId,
        'last_update_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign route: $e');
    }
  }

  /// Get buses by status
  Future<List<Bus>> getBusesByStatus(String companyId, String status) async {
    try {
      final snapshot = await _busesCollection
          .where('company_ID', isEqualTo: companyId)
          .where('status', isEqualTo: status)
          .get();

      return snapshot.docs.map((doc) => Bus.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch buses by status: $e');
    }
  }

  /// Get buses by route
  Future<List<Bus>> getBusesByRoute(String companyId, String routeId) async {
    try {
      final snapshot = await _busesCollection
          .where('company_ID', isEqualTo: companyId)
          .where('route_ID', isEqualTo: routeId)
          .get();

      return snapshot.docs.map((doc) => Bus.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch buses by route: $e');
    }
  }

  /// Get bus count by status (optimized)
  Future<Map<String, int>> getBusCountByStatus(String companyId) async {
    try {
      final buses = await getBuses(companyId);

      return {
        'total': buses.length,
        'active': buses.where((b) => b.status == 'active').length,
        'inactive': buses.where((b) => b.status == 'inactive').length,
        'maintenance': buses.where((b) => b.status == 'maintenance').length,
        'standby': buses.where((b) => b.status == 'standby').length,
        'delayed': buses.where((b) => b.status == 'delayed').length,
      };
    } catch (e) {
      throw Exception('Failed to get bus count: $e');
    }
  }

  /// Batch update bus status (uses batched writes)
  Future<void> batchUpdateStatus(List<String> busIds, String status) async {
    try {
      final batch = _firestore.batch();

      for (final busId in busIds) {
        batch.update(_busesCollection.doc(busId), {
          'status': status,
          'last_update_timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update status: $e');
    }
  }
}
