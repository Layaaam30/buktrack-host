import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Dashboard Analytics Service - Optimized for Schema & Quota
/// Changes:
/// - Added company_ID filtering to all queries
/// - Fixed routes schema (waypoints are strings, not objects)
/// - Optimized query strategies for lower quota usage
/// - Improved caching with company-specific keys
class DashboardAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, _CachedData> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  void clearCache() {
    _cache.clear();
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final cached = _cache[key]!;
    return DateTime.now().difference(cached.timestamp) < _cacheDuration;
  }

  T? _getCached<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key]!.data as T;
    }
    return null;
  }

  void _setCache<T>(String key, T data) {
    _cache[key] = _CachedData(data: data, timestamp: DateTime.now());
  }

  // ========== 1. DAILY PASSENGER TREND BY HOUR ==========
  /// Optimized: Fetches only logs for company's buses today
  Future<Map<int, int>> getDailyPassengerTrendByHour(String companyId) async {
    final cacheKey = 'daily_trend_hour_$companyId';

    final cached = _getCached<Map<int, int>>(cacheKey);
    if (cached != null) {
      print('ðŸ“Š Using cached hourly trend data');
      return cached;
    }

    try {
      print('ðŸ“Š Fetching hourly passenger trend for company: $companyId');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // OPTIMIZATION: First get company's bus IDs to limit scope
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        print('âš ï¸ No buses found for company');
        return _initializeHourlyData();
      }

      final busIds = busesSnapshot.docs.map((doc) => doc.id).toList();
      print('ðŸšŒ Found ${busIds.length} buses for company');

      // OPTIMIZATION: Batch queries in chunks to avoid "IN" query limits (max 10)
      final hourlyData = _initializeHourlyData();
      const chunkSize = 10;

      for (int i = 0; i < busIds.length; i += chunkSize) {
        final chunk = busIds.skip(i).take(chunkSize).toList();

        // Query each bus's occupancy logs subcollection
        for (final busId in chunk) {
          final logsQuery = await _firestore
              .collection('buses')
              .doc(busId)
              .collection('bus_occupancy_logs')
              .where('action_type', isEqualTo: 'board')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

          // Aggregate
          for (var doc in logsQuery.docs) {
            final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
            final hour = timestamp.hour;
            hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
          }
        }
      }

      _setCache(cacheKey, hourlyData);
      print(
        'âœ… Hourly trend aggregated: ${hourlyData.values.fold(0, (a, b) => a + b)} total boardings',
      );
      return hourlyData;
    } catch (e) {
      print('âŒ Error fetching hourly trend: $e');
      rethrow;
    }
  }

  Map<int, int> _initializeHourlyData() {
    final data = <int, int>{};
    for (int i = 0; i < 24; i++) {
      data[i] = 0;
    }
    return data;
  }

  // ========== 2. WEEKLY PASSENGER TREND BY DAY ==========
  /// Optimized: Company-filtered, 7-day window
  Future<Map<String, int>> getWeeklyPassengerTrendByDay(
    String companyId,
  ) async {
    final cacheKey = 'weekly_trend_day_$companyId';

    final cached = _getCached<Map<String, int>>(cacheKey);
    if (cached != null) {
      print('ðŸ“Š Using cached weekly trend data');
      return cached;
    }

    try {
      print('ðŸ“Š Fetching weekly passenger trend for company: $companyId');

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = startOfToday.subtract(const Duration(days: 7));

      // Get company's bus IDs
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return _initializeWeeklyData();
      }

      final busIds = busesSnapshot.docs.map((doc) => doc.id).toList();
      final weeklyData = _initializeWeeklyData();
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      // Query each bus's logs
      for (final busId in busIds) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busId)
            .collection('bus_occupancy_logs')
            .where('action_type', isEqualTo: 'board')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
            )
            .where(
              'timestamp',
              isLessThan: Timestamp.fromDate(
                startOfToday.add(const Duration(days: 1)),
              ),
            )
            .get();

        for (var doc in logsQuery.docs) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final dayOfWeek = timestamp.weekday;
          final dayName = dayNames[dayOfWeek - 1];
          weeklyData[dayName] = (weeklyData[dayName] ?? 0) + 1;
        }
      }

      _setCache(cacheKey, weeklyData);
      print(
        'âœ… Weekly trend aggregated: ${weeklyData.values.fold(0, (a, b) => a + b)} total boardings',
      );
      return weeklyData;
    } catch (e) {
      print('âŒ Error fetching weekly trend: $e');
      rethrow;
    }
  }

  Map<String, int> _initializeWeeklyData() {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final data = <String, int>{};
    for (var day in dayNames) {
      data[day] = 0;
    }
    return data;
  }

  // ========== 3. PASSENGER DISTRIBUTION ALONG ROUTE ==========
  /// CRITICAL FIX: Schema shows waypoints as array of strings, not objects
  /// This requires the waypoint names to be matched against log data
  /// NOTE: The schema notes mention this needs modification to store waypoint names in logs
  Future<List<WaypointPassengerData>> getRoutePassengerDistribution(
    String routeId,
    String companyId,
  ) async {
    final cacheKey = 'route_distribution_${companyId}_$routeId';

    final cached = _getCached<List<WaypointPassengerData>>(cacheKey);
    if (cached != null) {
      print('ðŸ“Š Using cached route distribution data');
      return cached;
    }

    try {
      print('ðŸ“Š Fetching route passenger distribution for route: $routeId');

      // Get route document
      final routeDoc = await _firestore.collection('routes').doc(routeId).get();

      if (!routeDoc.exists) {
        throw Exception('Route not found');
      }

      final routeData = routeDoc.data()!;

      // SCHEMA FIX: waypoints is an array of strings
      final waypoints = routeData['waypoints'] as List<dynamic>? ?? [];

      if (waypoints.isEmpty) {
        print('âš ï¸ No waypoints found for route');
        return [];
      }

      print('ðŸ›£ï¸ Found ${waypoints.length} waypoints');

      // Initialize waypoint data with string names
      final waypointDataList = <WaypointPassengerData>[];
      for (int i = 0; i < waypoints.length; i++) {
        waypointDataList.add(
          WaypointPassengerData(
            waypointName: waypoints[i].toString(),
            waypointIndex: i,
            latitude: 0.0, // Not available in current schema
            longitude: 0.0, // Not available in current schema
            boardingCount: 0,
            alightingCount: 0,
          ),
        );
      }

      // Get occupancy logs for this route (past 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Get company's buses that are on this route
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .where('route_ID', isEqualTo: routeId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        print('âš ï¸ No buses found on this route');
        _setCache(cacheKey, waypointDataList);
        return waypointDataList;
      }

      // Query logs for each bus
      for (final busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where('route_ID', isEqualTo: routeId)
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
            )
            .get();

        // LIMITATION: Without waypoint_name field in logs, we can't accurately
        // map logs to waypoints. The schema document notes this needs to be added.
        // For now, we'll use location-based proximity if available
        for (var doc in logsQuery.docs) {
          final data = doc.data();
          final actionType = data['action_type'] as String?;
          final location = data['location'] as GeoPoint?;

          if (actionType == null || location == null) continue;

          // Since we don't have waypoint coordinates in schema,
          // we can't match properly. This is a known limitation.
          // Distribution will be empty until schema is updated with waypoint_name field
        }
      }

      _setCache(cacheKey, waypointDataList);
      print(
        'âš ï¸ Route distribution limited: Schema needs waypoint_name field in logs',
      );
      return waypointDataList;
    } catch (e) {
      print('âŒ Error fetching route distribution: $e');
      rethrow;
    }
  }

  // ========== 4. BUS TYPE AVERAGE OCCUPANCY ==========
  /// Optimized: Company-filtered trips with efficient aggregation
  Future<Map<String, double>> getBusTypeAverageOccupancy(
    String companyId,
  ) async {
    final cacheKey = 'bus_type_occupancy_$companyId';

    final cached = _getCached<Map<String, double>>(cacheKey);
    if (cached != null) {
      print('ðŸ“Š Using cached bus type occupancy data');
      return cached;
    }

    try {
      print('ðŸ“Š Fetching bus type average occupancy for company: $companyId');

      // Get company's buses with capacity info
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        print('âš ï¸ No buses found for company');
        return _initializeBusTypeData();
      }

      print('ðŸšŒ Found ${busesSnapshot.docs.length} buses');

      // Create bus lookup map
      final busMap = <String, Map<String, dynamic>>{};
      for (var doc in busesSnapshot.docs) {
        final data = doc.data();
        busMap[doc.id] = {
          'total_capacity': data['total_capacity'] as int? ?? 50,
          'bus_type': _inferBusType(data['total_capacity'] as int? ?? 50),
        };
      }

      // Get completed trips (past 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('company_ID', isEqualTo: companyId)
          .where('current_status', isEqualTo: 'completed')
          .where(
            'end_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .get();

      print(
        'ðŸŽ« Found ${tripsSnapshot.docs.length} completed trips in last 30 days',
      );

      // Aggregate occupancy by bus type
      final busTypeData = <String, List<double>>{
        'Small': [],
        'Medium': [],
        'Large': [],
      };

      for (var doc in tripsSnapshot.docs) {
        final tripData = doc.data();
        final busId = tripData['bus_ID'] as String?;
        final finalPassengerCount =
            tripData['final_passenger_count'] as int? ?? 0;

        if (busId == null || !busMap.containsKey(busId)) continue;

        final busData = busMap[busId]!;
        final totalCapacity = busData['total_capacity'] as int;
        final busType = busData['bus_type'] as String;

        if (totalCapacity > 0) {
          final occupancyPercentage =
              (finalPassengerCount / totalCapacity) * 100;
          busTypeData[busType]!.add(occupancyPercentage);
        }
      }

      // Calculate averages
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

      _setCache(cacheKey, averageOccupancy);
      print('âœ… Bus type occupancy aggregated successfully');
      return averageOccupancy;
    } catch (e) {
      print('âŒ Error fetching bus type occupancy: $e');
      rethrow;
    }
  }

  Map<String, double> _initializeBusTypeData() {
    return {'Small': 0.0, 'Medium': 0.0, 'Large': 0.0};
  }

  String _inferBusType(int capacity) {
    if (capacity <= 30) return 'Small';
    if (capacity <= 50) return 'Medium';
    return 'Large';
  }

  // ========== DASHBOARD SUMMARY - OPTIMIZED ==========
  /// Uses count() queries for maximum efficiency
  Future<Map<String, dynamic>> getDashboardSummary(String companyId) async {
    final cacheKey = 'dashboard_summary_$companyId';

    final cached = _getCached<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      print('ðŸ“Š Using cached dashboard summary');
      return cached;
    }

    try {
      print('ðŸ“Š Fetching dashboard summary for company: $companyId');

      // OPTIMIZATION: Use count() queries - only 1 document read each!
      final busesCountFuture = _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .count()
          .get();

      final routesCountFuture = _firestore
          .collection('routes')
          .where('company_ID', isEqualTo: companyId)
          .count()
          .get();

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final activeTripsCountFuture = _firestore
          .collection('trips')
          .where('company_ID', isEqualTo: companyId)
          .where('current_status', isEqualTo: 'active')
          .where(
            'start_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .count()
          .get();

      // Execute all count queries in parallel
      final results = await Future.wait([
        busesCountFuture,
        routesCountFuture,
        activeTripsCountFuture,
      ]);

      final summary = {
        'total_buses': results[0].count ?? 0,
        'total_routes': results[1].count ?? 0,
        'active_trips_today': results[2].count ?? 0,
      };

      _setCache(cacheKey, summary);
      print('âœ… Dashboard summary fetched with only 3 reads!');
      return summary;
    } catch (e) {
      print('âŒ Error fetching dashboard summary: $e');
      return {'total_buses': 0, 'total_routes': 0, 'active_trips_today': 0};
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
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
}

class _CachedData {
  final dynamic data;
  final DateTime timestamp;

  _CachedData({required this.data, required this.timestamp});
}

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
