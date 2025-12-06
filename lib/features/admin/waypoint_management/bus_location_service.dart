import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Optimized Bus Location Model
/// Contains only essential data for map display
class BusLocationData {
  final String id;
  final String plateNumber;
  final GeoPoint location;
  final String status;
  final DateTime lastUpdated;

  BusLocationData({
    required this.id,
    required this.plateNumber,
    required this.location,
    required this.status,
    required this.lastUpdated,
  });

  factory BusLocationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusLocationData(
      id: doc.id,
      plateNumber: data['plate_number']?.toString() ?? '',
      location: data['current_location'] as GeoPoint? ?? const GeoPoint(0, 0),
      status: data['status']?.toString() ?? 'inactive',
      lastUpdated:
          (data['last_location_update'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  double get latitude => location.latitude;
  double get longitude => location.longitude;
}

/// Optimized Bus Location Service
/// Fetches only location data when needed, with caching
class BusLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for bus locations
  final Map<String, BusLocationData> _locationCache = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(seconds: 30);

  StreamSubscription<QuerySnapshot>? _locationSubscription;

  /// Get bus locations stream (optimized - only location fields)
  Stream<List<BusLocationData>> getBusLocationsStream(String companyId) {
    print('🚌 Starting optimized bus location stream for company: $companyId');

    return _firestore
        .collection('buses')
        .where('company_ID', isEqualTo: companyId)
        .where('status', whereIn: ['active', 'in_transit'])
        .snapshots()
        .map((snapshot) {
          print('🚌 Received ${snapshot.docs.length} active bus locations');

          final locations = <BusLocationData>[];
          for (var doc in snapshot.docs) {
            try {
              final location = BusLocationData.fromFirestore(doc);
              // Only include buses with valid locations
              if (location.latitude != 0 && location.longitude != 0) {
                locations.add(location);
                _locationCache[location.id] = location;
              }
            } catch (e) {
              print('⚠️ Error parsing bus location ${doc.id}: $e');
            }
          }

          _lastFetchTime = DateTime.now();
          print('📍 Loaded ${locations.length} valid bus locations');
          return locations;
        })
        .handleError((error) {
          print('❌ Bus location stream error: $error');
          throw error;
        });
  }

  /// Get cached bus locations (for one-time fetch)
  Future<List<BusLocationData>> getBusLocations(String companyId) async {
    // Use cache if fresh
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiration &&
        _locationCache.isNotEmpty) {
      print('✅ Using cached bus locations (${_locationCache.length} buses)');
      return _locationCache.values.toList();
    }

    print('🔄 Fetching fresh bus locations...');

    try {
      final snapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .where('status', whereIn: ['active', 'in_transit'])
          .get();

      final locations = <BusLocationData>[];
      for (var doc in snapshot.docs) {
        try {
          final location = BusLocationData.fromFirestore(doc);
          if (location.latitude != 0 && location.longitude != 0) {
            locations.add(location);
            _locationCache[location.id] = location;
          }
        } catch (e) {
          print('⚠️ Error parsing bus location ${doc.id}: $e');
        }
      }

      _lastFetchTime = DateTime.now();
      print('✅ Fetched ${locations.length} bus locations');
      return locations;
    } catch (e) {
      print('❌ Error fetching bus locations: $e');
      throw Exception('Failed to fetch bus locations: $e');
    }
  }

  /// Get bus locations within a geographic area (for viewport optimization)
  Future<List<BusLocationData>> getBusLocationsInArea(
    String companyId,
    GeoPoint southwest,
    GeoPoint northeast,
  ) async {
    try {
      print('🗺️ Fetching buses in viewport area');

      final snapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .where('status', whereIn: ['active', 'in_transit'])
          .get();

      final locations = <BusLocationData>[];

      for (var doc in snapshot.docs) {
        try {
          final location = BusLocationData.fromFirestore(doc);

          // Check if location is within bounds
          if (location.latitude >= southwest.latitude &&
              location.latitude <= northeast.latitude &&
              location.longitude >= southwest.longitude &&
              location.longitude <= northeast.longitude) {
            locations.add(location);
          }
        } catch (e) {
          print('⚠️ Error parsing bus location ${doc.id}: $e');
        }
      }

      print('✅ Found ${locations.length} buses in viewport');
      return locations;
    } catch (e) {
      print('❌ Error fetching buses in area: $e');
      throw Exception('Failed to fetch buses in area: $e');
    }
  }

  /// Start listening to bus locations
  void startListening(
    String companyId,
    Function(List<BusLocationData>) onUpdate,
  ) {
    _locationSubscription?.cancel();
    StreamSubscription<List<BusLocationData>>? _busLocationSubscription;
  }

  /// Stop listening to bus locations
  void stopListening() {
    print('🛑 Stopping bus location stream');
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Clear cache
  void clearCache() {
    _locationCache.clear();
    _lastFetchTime = null;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    clearCache();
  }
}
