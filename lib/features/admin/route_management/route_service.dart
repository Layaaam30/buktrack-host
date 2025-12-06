import 'package:cloud_firestore/cloud_firestore.dart';
import 'route_model.dart';

/// Route Firestore Service
/// Web-optimized with efficient queries and real-time updates
class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _routesCollection {
    return _firestore.collection('routes');
  }

  /// Get all routes with real-time updates
  Stream<List<RouteModel>> getRoutesStream(String companyId) {
    print('🔥 Starting real-time stream for routes in company: $companyId');

    return _routesCollection
        .where('company_ID', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
          print(
            '📥 Received ${snapshot.docs.length} route documents from Firestore',
          );

          final routes = <RouteModel>[];

          for (var doc in snapshot.docs) {
            try {
              print('📄 Processing route document: ${doc.id}');
              final data = doc.data() as Map<String, dynamic>?;
              print('   Data: ${data?.keys.join(", ")}');

              final route = RouteModel.fromFirestore(doc);
              routes.add(route);
              print('   ✅ Successfully parsed: ${route.routeName}');
            } catch (e, stackTrace) {
              print('❌ Error parsing route ${doc.id}: $e');
              print('   Stack trace: $stackTrace');
              print('   Document data: ${doc.data()}');
            }
          }

          print('📊 Loaded ${routes.length} routes successfully');
          return routes;
        })
        .handleError((error) {
          print('❌ Stream error: $error');
          throw error;
        });
  }

  /// Get all routes (one-time fetch)
  Future<List<RouteModel>> getRoutes(String companyId) async {
    try {
      print('🔍 Fetching routes for company: $companyId');

      final snapshot = await _routesCollection
          .where('company_ID', isEqualTo: companyId)
          .orderBy('created_at', descending: true)
          .get();

      final routes = <RouteModel>[];

      for (var doc in snapshot.docs) {
        try {
          final route = RouteModel.fromFirestore(doc);
          routes.add(route);
          print('✅ Loaded route: ${route.routeName}');
        } catch (e) {
          print('❌ Error parsing route ${doc.id}: $e');
        }
      }

      print('📦 Total routes loaded: ${routes.length}');
      return routes;
    } catch (e) {
      print('❌ Error fetching routes: $e');
      throw Exception('Failed to fetch routes: $e');
    }
  }

  /// Get single route by ID
  Future<RouteModel?> getRouteById(String routeId) async {
    try {
      print('🔍 Fetching route: $routeId');

      final doc = await _routesCollection.doc(routeId).get();

      if (!doc.exists) {
        print('❌ Route not found: $routeId');
        return null;
      }

      final route = RouteModel.fromFirestore(doc);
      print('✅ Loaded route: ${route.routeName}');
      return route;
    } catch (e) {
      print('❌ Error fetching route: $e');
      throw Exception('Failed to fetch route: $e');
    }
  }

  /// Create a new route
  Future<String> createRoute(RouteModel route) async {
    try {
      print('➕ Creating route: ${route.routeName}');
      print('   Route code: ${route.routeCode}');
      print('   Company ID: ${route.companyId}');

      // Route code is auto-generated, so it should be unique
      // But let's do a safety check just in case
      if (route.routeCode.isEmpty) {
        throw Exception(
          'Route code is empty - auto-generation may have failed',
        );
      }

      // Create route
      final routeData = route
          .copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now())
          .toFirestore();

      final docRef = await _routesCollection.add(routeData);

      print('✅ Route created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating route: $e');
      throw Exception('Failed to create route: $e');
    }
  }

  /// Update an existing route
  Future<void> updateRoute(String routeId, RouteModel route) async {
    try {
      print('✏️ Updating route: $routeId');

      final routeData = route.copyWith(updatedAt: DateTime.now()).toFirestore();

      await _routesCollection.doc(routeId).update(routeData);

      print('✅ Route updated successfully');
    } catch (e) {
      print('❌ Error updating route: $e');
      throw Exception('Failed to update route: $e');
    }
  }

  /// Update specific fields of a route
  Future<void> updateRouteFields(
    String routeId,
    Map<String, dynamic> fields,
  ) async {
    try {
      print('✏️ Updating route fields: $routeId');

      fields['updated_at'] = FieldValue.serverTimestamp();

      await _routesCollection.doc(routeId).update(fields);

      print('✅ Fields updated successfully');
    } catch (e) {
      print('❌ Error updating route fields: $e');
      throw Exception('Failed to update route fields: $e');
    }
  }

  /// Toggle route status (active/inactive)
  Future<void> toggleRouteStatus(
    String routeId,
    bool isActive,
    String adminId,
  ) async {
    try {
      print('🔄 Toggling route status: $routeId to $isActive');

      await _routesCollection.doc(routeId).update({
        'is_active': isActive,
        'status_changed_by': adminId,
        'status_changed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Route status updated successfully');
    } catch (e) {
      print('❌ Error toggling route status: $e');
      throw Exception('Failed to toggle route status: $e');
    }
  }

  /// Delete a route
  Future<void> deleteRoute(String routeId) async {
    try {
      print('🗑️ Deleting route: $routeId');

      // First, get the route to unassign buses
      final routeDoc = await _routesCollection.doc(routeId).get();
      if (routeDoc.exists) {
        final routeData = routeDoc.data() as Map<String, dynamic>?;
        final assignedBuses = routeData?['assigned_buses'] as List?;

        // Unassign buses from this route
        if (assignedBuses != null && assignedBuses.isNotEmpty) {
          for (var busId in assignedBuses) {
            await _firestore.collection('buses').doc(busId.toString()).update({
              'route_ID': null,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Delete the route
      await _routesCollection.doc(routeId).delete();

      print('✅ Route deleted successfully');
    } catch (e) {
      print('❌ Error deleting route: $e');
      throw Exception('Failed to delete route: $e');
    }
  }

  /// Assign buses to a route
  Future<void> assignBusesToRoute(
    String routeId,
    List<String> busIds,
    String adminId,
  ) async {
    try {
      print('🚌 Assigning ${busIds.length} buses to route: $routeId');

      // Get current route to check existing assignments
      final routeDoc = await _routesCollection.doc(routeId).get();
      final oldBuses =
          (routeDoc.data() as Map<String, dynamic>?)?['assigned_buses']
              as List? ??
          [];

      // Update route with new bus assignments
      await _routesCollection.doc(routeId).update({
        'assigned_buses': busIds,
        'assignment_changed_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update each bus with route assignment
      for (var busId in busIds) {
        await _firestore.collection('buses').doc(busId).update({
          'route_ID': routeId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Remove route assignment from previously assigned buses
      final removedBuses = oldBuses
          .where((bus) => !busIds.contains(bus))
          .toList();
      for (var busId in removedBuses) {
        await _firestore.collection('buses').doc(busId.toString()).update({
          'route_ID': null,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Buses assigned successfully');
    } catch (e) {
      print('❌ Error assigning buses: $e');
      throw Exception('Failed to assign buses to route: $e');
    }
  }

  /// Get active routes
  Future<List<RouteModel>> getActiveRoutes(String companyId) async {
    try {
      final snapshot = await _routesCollection
          .where('company_ID', isEqualTo: companyId)
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => RouteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch active routes: $e');
    }
  }

  /// Get route statistics
  Future<Map<String, int>> getRouteStats(String companyId) async {
    try {
      final routes = await getRoutes(companyId);

      return {
        'total': routes.length,
        'active': routes.where((r) => r.isActive).length,
        'inactive': routes.where((r) => !r.isActive).length,
        'with_buses': routes.where((r) => r.hasAssignedBuses).length,
        'without_buses': routes.where((r) => !r.hasAssignedBuses).length,
      };
    } catch (e) {
      throw Exception('Failed to get route stats: $e');
    }
  }

  /// Check if route code exists
  Future<bool> _checkRouteCodeExists(String routeCode, String companyId) async {
    try {
      final query = await _routesCollection
          .where('company_ID', isEqualTo: companyId)
          .where('route_code', isEqualTo: routeCode.toUpperCase())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Generate next route code (auto-increment)
  /// Format: RT001, RT002, RT003, etc.
  Future<String> generateNextRouteCode(String companyId) async {
    try {
      print('🔢 Generating next route code for company: $companyId');

      // Get all routes for this company
      final snapshot = await _routesCollection
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('   No existing routes, returning RT001');
        return 'RT001';
      }

      print('   Found ${snapshot.docs.length} existing routes');

      // Extract all numeric parts from existing route codes
      final existingNumbers = <int>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final routeCode = data?['route_code']?.toString() ?? '';

        // Try to extract number from various formats: RT001, RT-001, RT 001, etc.
        final match = RegExp(
          r'RT[-\s]?(\d+)',
          caseSensitive: false,
        ).firstMatch(routeCode);
        if (match != null) {
          final number = int.tryParse(match.group(1)!);
          if (number != null && number > 0) {
            existingNumbers.add(number);
            print('   Found route code: $routeCode → number: $number');
          }
        }
      }

      // Find the highest number and increment
      int nextNumber;
      if (existingNumbers.isEmpty) {
        print('   No valid RT codes found, starting from RT001');
        nextNumber = 1;
      } else {
        existingNumbers.sort();
        final highestNumber = existingNumbers.last;
        nextNumber = highestNumber + 1;
        print('   Highest number: $highestNumber, next: $nextNumber');
      }

      // Format with leading zeros (RT001, RT002, etc.)
      final nextCode = 'RT${nextNumber.toString().padLeft(3, '0')}';
      print('   ✅ Generated route code: $nextCode');

      return nextCode;
    } catch (e) {
      print('❌ Error generating route code: $e');
      // Fallback: return a timestamp-based code
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fallbackCode =
          'RT${timestamp.toString().substring(timestamp.toString().length - 3)}';
      print('   Using fallback code: $fallbackCode');
      return fallbackCode;
    }
  }
}
