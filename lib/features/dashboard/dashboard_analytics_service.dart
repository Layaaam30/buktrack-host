import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Dashboard Analytics Service
/// Optimized for lowest network latency and Firebase quota
class DashboardAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for analytics data with timestamps
  final Map<String, _CachedData> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// Check if cache is valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final cached = _cache[key]!;
    return DateTime.now().difference(cached.timestamp) < _cacheDuration;
  }

  /// Get cached data or null
  T? _getCached<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key]!.data as T;
    }
    return null;
  }

  /// Set cached data
  void _setCache<T>(String key, T data) {
    _cache[key] = _CachedData(data: data, timestamp: DateTime.now());
  }

  // ========== 1. DAILY PASSENGER TREND BY HOUR ==========
  /// Get passenger boarding count by hour for today
  /// Returns: Map<hour, count>
  Future<Map<int, int>> getDailyPassengerTrendByHour(String companyId) async {
    const cacheKey = 'daily_trend_hour';
    
    // Check cache first
    final cached = _getCached<Map<int, int>>(cacheKey);
    if (cached != null) {
      print('📊 Using cached hourly trend data');
      return cached;
    }

    try {
      print('📊 Fetching hourly passenger trend...');

      // Get start and end of today
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Use Collection Group Query to get all bus_occupancy_logs
      // This queries across all buses efficiently with a single network call
      final query = await _firestore
          .collectionGroup('bus_occupancy_logs')
          .where('action_type', isEqualTo: 'board')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      print('📦 Retrieved ${query.docs.length} boarding logs for today');

      // Aggregate by hour (client-side aggregation)
      final hourlyData = <int, int>{};
      
      // Initialize all hours with 0
      for (int i = 0; i < 24; i++) {
        hourlyData[i] = 0;
      }

      // Count boardings per hour
      for (var doc in query.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final hour = timestamp.hour;
        hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
      }

      // Cache the result
      _setCache(cacheKey, hourlyData);

      print('✅ Hourly trend aggregated successfully');
      return hourlyData;
    } catch (e) {
      print('❌ Error fetching hourly trend: $e');
      rethrow;
    }
  }

  // ========== 2. WEEKLY PASSENGER TREND BY DAY ==========
  /// Get passenger boarding count by day for the past 7 days
  /// Returns: Map<day_name, count>
  Future<Map<String, int>> getWeeklyPassengerTrendByDay(String companyId) async {
    const cacheKey = 'weekly_trend_day';
    
    // Check cache first
    final cached = _getCached<Map<String, int>>(cacheKey);
    if (cached != null) {
      print('📊 Using cached weekly trend data');
      return cached;
    }

    try {
      print('📊 Fetching weekly passenger trend...');

      // Get date range for last 7 days
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = startOfToday.subtract(const Duration(days: 7));

      // Collection Group Query for the past 7 days
      final query = await _firestore
          .collectionGroup('bus_occupancy_logs')
          .where('action_type', isEqualTo: 'board')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .where('timestamp', isLessThan: Timestamp.fromDate(startOfToday.add(const Duration(days: 1))))
          .get();

      print('📦 Retrieved ${query.docs.length} boarding logs for past 7 days');

      // Aggregate by day of week
      final weeklyData = <String, int>{};
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      // Initialize all days with 0
      for (var day in dayNames) {
        weeklyData[day] = 0;
      }

      // Count boardings per day
      for (var doc in query.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dayOfWeek = timestamp.weekday; // 1 = Monday, 7 = Sunday
        final dayName = dayNames[dayOfWeek - 1];
        weeklyData[dayName] = (weeklyData[dayName] ?? 0) + 1;
      }

      // Cache the result
      _setCache(cacheKey, weeklyData);

      print('✅ Weekly trend aggregated successfully');
      return weeklyData;
    } catch (e) {
      print('❌ Error fetching weekly trend: $e');
      rethrow;
    }
  }

  // ========== 3. PASSENGER DISTRIBUTION ALONG ROUTE ==========
  /// Get passenger boarding and alighting distribution along a specific route
  /// Returns: List of waypoint data with boarding and alighting counts
  Future<List<WaypointPassengerData>> getRoutePassengerDistribution(
    String routeId,
    String companyId,
  ) async {
    final cacheKey = 'route_distribution_$routeId';
    
    // Check cache first
    final cached = _getCached<List<WaypointPassengerData>>(cacheKey);
    if (cached != null) {
      print('📊 Using cached route distribution data');
      return cached;
    }

    try {
      print('📊 Fetching route passenger distribution for route: $routeId');

      // Step 1: Get route waypoints
      final routeDoc = await _firestore.collection('routes').doc(routeId).get();
      
      if (!routeDoc.exists) {
        throw Exception('Route not found');
      }

      final routeData = routeDoc.data()!;
      final stopSequence = routeData['stop_sequence'] as List<dynamic>? ?? [];

      print('📍 Found ${stopSequence.length} waypoints');

      // Step 2: Get occupancy logs for this route (last 7 days for reasonable data)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final query = await _firestore
          .collectionGroup('bus_occupancy_logs')
          .where('route_ID', isEqualTo: routeId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      print('📦 Retrieved ${query.docs.length} occupancy logs for route');

      // Step 3: Initialize waypoint data
      final waypointDataList = <WaypointPassengerData>[];
      
      for (int i = 0; i < stopSequence.length; i++) {
        final stop = stopSequence[i] as Map<String, dynamic>;
        waypointDataList.add(WaypointPassengerData(
          waypointName: stop['name'] as String? ?? 'Stop ${i + 1}',
          waypointIndex: i,
          latitude: (stop['location'] as GeoPoint?)?.latitude ?? 0.0,
          longitude: (stop['location'] as GeoPoint?)?.longitude ?? 0.0,
          boardingCount: 0,
          alightingCount: 0,
        ));
      }

      // Step 4: Match occupancy logs to nearest waypoints
      // Using a simple proximity-based approach (within ~200 meters)
      const proximityThresholdKm = 0.2; // 200 meters

      for (var doc in query.docs) {
        final data = doc.data();
        final actionType = data['action_type'] as String;
        final location = data['location'] as GeoPoint?;
        
        if (location == null) continue;

        // Find nearest waypoint
        int nearestIndex = -1;
        double minDistance = double.infinity;

        for (int i = 0; i < waypointDataList.length; i++) {
          final waypoint = waypointDataList[i];
          final distance = _calculateDistance(
            location.latitude,
            location.longitude,
            waypoint.latitude,
            waypoint.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestIndex = i;
          }
        }

        // If within threshold, count it
        if (nearestIndex != -1 && minDistance <= proximityThresholdKm) {
          if (actionType == 'board') {
            waypointDataList[nearestIndex].boardingCount++;
          } else if (actionType == 'alight') {
            waypointDataList[nearestIndex].alightingCount++;
          }
        }
      }

      // Cache the result
      _setCache(cacheKey, waypointDataList);

      print('✅ Route distribution aggregated successfully');
      return waypointDataList;
    } catch (e) {
      print('❌ Error fetching route distribution: $e');
      rethrow;
    }
  }

  // ========== 4. BUS TYPE AVERAGE OCCUPANCY PERCENTAGE ==========
  /// Get average occupancy percentage by bus type for the past 30 days
  /// Returns: Map<bus_type, average_occupancy_percentage>
  Future<Map<String, double>> getBusTypeAverageOccupancy(String companyId) async {
    const cacheKey = 'bus_type_occupancy';
    
    // Check cache first
    final cached = _getCached<Map<String, double>>(cacheKey);
    if (cached != null) {
      print('📊 Using cached bus type occupancy data');
      return cached;
    }

    try {
      print('📊 Fetching bus type average occupancy...');

      // Step 1: Get all buses for the company
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      print('🚌 Found ${busesSnapshot.docs.length} buses');

      // Create a map of bus_ID -> bus_data
      final busMap = <String, Map<String, dynamic>>{};
      for (var doc in busesSnapshot.docs) {
        final data = doc.data();
        busMap[doc.id] = {
          'total_capacity': data['total_capacity'] as int? ?? 50,
          'bus_type': _inferBusType(data['total_capacity'] as int? ?? 50),
        };
      }

      // Step 2: Get completed trips for the past 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('company_ID', isEqualTo: companyId)
          .where('current_status', isEqualTo: 'completed')
          .where('end_time', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      print('🎫 Found ${tripsSnapshot.docs.length} completed trips in last 30 days');

      // Step 3: Aggregate occupancy by bus type
      final busTypeData = <String, List<double>>{};

      for (var doc in tripsSnapshot.docs) {
        final tripData = doc.data();
        final busId = tripData['bus_ID'] as String?;
        final finalPassengerCount = tripData['final_passenger_count'] as int? ?? 0;

        if (busId == null || !busMap.containsKey(busId)) continue;

        final busData = busMap[busId]!;
        final totalCapacity = busData['total_capacity'] as int;
        final busType = busData['bus_type'] as String;

        // Calculate occupancy percentage for this trip
        final occupancyPercentage = (finalPassengerCount / totalCapacity) * 100;

        // Store in bus type data
        if (!busTypeData.containsKey(busType)) {
          busTypeData[busType] = [];
        }
        busTypeData[busType]!.add(occupancyPercentage);
      }

      // Step 4: Calculate averages
      final averageOccupancy = <String, double>{};
      
      for (var entry in busTypeData.entries) {
        final busType = entry.key;
        final percentages = entry.value;
        
        if (percentages.isEmpty) {
          averageOccupancy[busType] = 0.0;
        } else {
          final sum = percentages.reduce((a, b) => a + b);
          averageOccupancy[busType] = sum / percentages.length;
        }
      }

      // Ensure all bus types are represented
      if (!averageOccupancy.containsKey('Small')) averageOccupancy['Small'] = 0.0;
      if (!averageOccupancy.containsKey('Medium')) averageOccupancy['Medium'] = 0.0;
      if (!averageOccupancy.containsKey('Large')) averageOccupancy['Large'] = 0.0;

      // Cache the result
      _setCache(cacheKey, averageOccupancy);

      print('✅ Bus type occupancy aggregated successfully');
      return averageOccupancy;
    } catch (e) {
      print('❌ Error fetching bus type occupancy: $e');
      rethrow;
    }
  }

  // ========== HELPER METHODS ==========

  /// Calculate distance between two coordinates (Haversine formula)
  /// Returns distance in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Infer bus type based on capacity
  String _inferBusType(int capacity) {
    if (capacity <= 30) return 'Small';
    if (capacity <= 50) return 'Medium';
    return 'Large';
  }

  // ========== SUMMARY STATS ==========
  /// Get overall dashboard summary statistics
  Future<Map<String, dynamic>> getDashboardSummary(String companyId) async {
    try {
      // Get basic counts with minimal queries
      final busesCount = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .count()
          .get();

      final routesCount = await _firestore
          .collection('routes')
          .where('company_ID', isEqualTo: companyId)
          .count()
          .get();

      // Get active trips (today)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final activeTripsCount = await _firestore
          .collection('trips')
          .where('company_ID', isEqualTo: companyId)
          .where('current_status', isEqualTo: 'active')
          .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get();

      return {
        'total_buses': busesCount.count ?? 0,
        'total_routes': routesCount.count ?? 0,
        'active_trips_today': activeTripsCount.count ?? 0,
      };
    } catch (e) {
      print('❌ Error fetching dashboard summary: $e');
      return {
        'total_buses': 0,
        'total_routes': 0,
        'active_trips_today': 0,
      };
    }
  }
}

// ========== DATA MODELS ==========

/// Cached data with timestamp
class _CachedData {
  final dynamic data;
  final DateTime timestamp;

  _CachedData({
    required this.data,
    required this.timestamp,
  });
}

/// Waypoint passenger data for route distribution
class WaypointPassengerData {
  final String waypointName;
  final int waypointIndex;
  final double latitude;
  final double longitude;
  int boardingCount;
  int alightingCount;

  WaypointPassengerData({
    required this.waypointName,
    required this.waypointIndex,
    required this.latitude,
    required this.longitude,
    required this.boardingCount,
    required this.alightingCount,
  });

  int get netPassengers => boardingCount - alightingCount;
}