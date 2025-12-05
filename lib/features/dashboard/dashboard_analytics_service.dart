import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Optimized Dashboard Analytics Service
/// Implements fast data loading with batching and caching
class DashboardAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, _CachedData> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cache bus IDs to avoid repeated queries
  Map<String, List<String>>? _busIdsCache;
  DateTime? _busIdsCacheTime;

  void clearCache() {
    _cache.clear();
    _busIdsCache = null;
    _busIdsCacheTime = null;
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

  // ========== OPTIMIZED: Get Bus IDs Once ==========
  Future<List<String>> _getBusIds(String companyId) async {
    // Check if cache is still valid (5 minutes)
    if (_busIdsCache != null &&
        _busIdsCache!.containsKey(companyId) &&
        _busIdsCacheTime != null &&
        DateTime.now().difference(_busIdsCacheTime!) < _cacheDuration) {
      return _busIdsCache![companyId]!;
    }

    final busesSnapshot = await _firestore
        .collection('buses')
        .where('company_ID', isEqualTo: companyId)
        .get();

    final busIds = busesSnapshot.docs.map((doc) => doc.id).toList();

    _busIdsCache = {companyId: busIds};
    _busIdsCacheTime = DateTime.now();

    return busIds;
  }

  // ========== HELPER: Get Week Number ==========
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  String _getWeekLabel(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return 'Week ${_getWeekNumber(date)} (${_formatReadableDate(weekStart)} - ${_formatReadableDate(weekEnd)}, ${weekEnd.year})';
  }

  String _formatReadableDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ========== OPTIMIZED: BATCH QUERY FOR MULTIPLE ANALYTICS ==========
  /// Fetch all boarding logs in one query, then process locally
  Future<Map<String, dynamic>> getBatchAnalytics(String companyId) async {
    final cacheKey = 'batch_analytics_$companyId';

    final cached = _getCached<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get bus IDs once
      final busIds = await _getBusIds(companyId);

      if (busIds.isEmpty) {
        return _emptyBatchResult();
      }

      // Initialize all data structures
      final hourlyData = _initializeHourlyData();
      final dailyData = <String, int>{};
      final weeklyData = <int, Map<String, Map<int, int>>>{};
      final weekLabels = <int, String>{};
      final waypointData = <String, Map<String, int>>{};

      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      // BATCH QUERY: Get all boarding logs for the last 30 days at once
      // Process in chunks to avoid memory issues with large datasets
      const int chunkSize = 10;
      for (int i = 0; i < busIds.length; i += chunkSize) {
        final chunk = busIds.skip(i).take(chunkSize).toList();

        // Query all logs for this chunk of buses in parallel
        final futures = chunk.map(
          (busId) => _firestore
              .collection('buses')
              .doc(busId)
              .collection('bus_occupancy_logs')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
              )
              .get(),
        );

        final results = await Future.wait(futures);

        // Process all logs locally
        for (var logsQuery in results) {
          for (var doc in logsQuery.docs) {
            final data = doc.data();
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final actionType = data['action_type'] as String?;
            final waypointName = data['waypoint_name'] as String? ?? 'Unknown';

            // Only process boarding for most analytics
            if (actionType == 'board') {
              final hour = timestamp.hour;
              final dateKey =
                  '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

              // 1. Live Hourly (Today only)
              if (timestamp.isAfter(startOfDay) &&
                  timestamp.isBefore(endOfDay)) {
                hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
              }

              // 2. Daily Trend (Last 30 days)
              dailyData[dateKey] = (dailyData[dateKey] ?? 0) + 1;

              // 3. Weekly Heatmap
              final weekNumber = _getWeekNumber(timestamp);
              final dayOfWeek = dayNames[timestamp.weekday - 1];

              if (!weeklyData.containsKey(weekNumber)) {
                weeklyData[weekNumber] = {};
                weekLabels[weekNumber] = _getWeekLabel(timestamp);
                for (var day in dayNames) {
                  weeklyData[weekNumber]![day] = _initializeHourlyData();
                }
              }

              weeklyData[weekNumber]![dayOfWeek]![hour] =
                  (weeklyData[weekNumber]![dayOfWeek]![hour] ?? 0) + 1;

              // 4. Location Stats - Boarding
              if (!waypointData.containsKey(waypointName)) {
                waypointData[waypointName] = {'boarding': 0, 'alighting': 0};
              }
              waypointData[waypointName]!['boarding'] =
                  (waypointData[waypointName]!['boarding'] ?? 0) + 1;
            }

            // Process alighting separately
            if (actionType == 'alight') {
              if (!waypointData.containsKey(waypointName)) {
                waypointData[waypointName] = {'boarding': 0, 'alighting': 0};
              }
              waypointData[waypointName]!['alighting'] =
                  (waypointData[waypointName]!['alighting'] ?? 0) + 1;
            }
          }
        }
      }

      // Create aggregated weekly data
      final aggregatedData = <String, Map<int, int>>{};
      for (var day in dayNames) {
        aggregatedData[day] = _initializeHourlyData();
      }

      for (var weekData in weeklyData.values) {
        for (var day in dayNames) {
          for (var hour = 0; hour < 24; hour++) {
            aggregatedData[day]![hour] =
                (aggregatedData[day]![hour] ?? 0) + (weekData[day]?[hour] ?? 0);
          }
        }
      }

      // Create week objects
      final weeks = weeklyData.keys.toList()..sort();
      final weekObjects = weeks.map((weekNum) {
        return {
          'weekNumber': weekNum,
          'weekLabel': weekLabels[weekNum]!,
          'data': weeklyData[weekNum]!,
        };
      }).toList();

      // Create location stats
      final locationStats = waypointData.entries.map((entry) {
        return {
          'waypointName': entry.key,
          'totalBoardings': entry.value['boarding'] ?? 0,
          'totalAlightings': entry.value['alighting'] ?? 0,
        };
      }).toList();

      locationStats.sort(
        (a, b) => ((b['totalBoardings'] as int) + (b['totalAlightings'] as int))
            .compareTo(
              (a['totalBoardings'] as int) + (a['totalAlightings'] as int),
            ),
      );

      final result = {
        'liveHourlyTrend': hourlyData,
        'dailyTrend30Days': dailyData,
        'weeklyHeatmap': {
          'weeks': weekObjects,
          'aggregatedData': aggregatedData,
        },
        'locationStats': locationStats,
        'waypoints': waypointData.keys.toList()..sort(),
      };

      _setCache(cacheKey, result);
      return result;
    } catch (e) {
      print('Error fetching batch analytics: $e');
      return _emptyBatchResult();
    }
  }

  Map<String, dynamic> _emptyBatchResult() {
    return {
      'liveHourlyTrend': _initializeHourlyData(),
      'dailyTrend30Days': <String, int>{},
      'weeklyHeatmap': {
        'weeks': [],
        'aggregatedData': <String, Map<int, int>>{},
      },
      'locationStats': [],
      'waypoints': [],
    };
  }

  // ========== 1. LIVE PASSENGER HOURLY TREND (Use batch data) ==========
  Future<Map<int, int>> getLivePassengerHourlyTrend(String companyId) async {
    final batchData = await getBatchAnalytics(companyId);
    return batchData['liveHourlyTrend'] as Map<int, int>;
  }

  // ========== 2. DAILY PASSENGER TREND (Use batch data) ==========
  Future<Map<String, int>> getDailyPassengerTrend30Days(
    String companyId,
  ) async {
    final batchData = await getBatchAnalytics(companyId);
    return batchData['dailyTrend30Days'] as Map<String, int>;
  }

  // ========== 3. WEEKLY PASSENGER HEATMAP (Use batch data) ==========
  Future<WeeklyHeatmapData> getWeeklyPassengerHeatmap(String companyId) async {
    final batchData = await getBatchAnalytics(companyId);
    final heatmapData = batchData['weeklyHeatmap'] as Map<String, dynamic>;

    final weeks = (heatmapData['weeks'] as List).map((w) {
      return WeekHeatmapData(
        weekNumber: w['weekNumber'] as int,
        weekLabel: w['weekLabel'] as String,
        data: Map<String, Map<int, int>>.from(
          (w['data'] as Map).map(
            (key, value) =>
                MapEntry(key as String, Map<int, int>.from(value as Map)),
          ),
        ),
      );
    }).toList();

    return WeeklyHeatmapData(
      weeks: weeks,
      aggregatedData: Map<String, Map<int, int>>.from(
        (heatmapData['aggregatedData'] as Map).map(
          (key, value) =>
              MapEntry(key as String, Map<int, int>.from(value as Map)),
        ),
      ),
    );
  }

  // ========== 4. LOCATION BASED PASSENGER STATISTICS (Use batch data) ==========
  Future<List<WaypointPassengerStats>> getLocationBasedPassengerStats(
    String companyId,
  ) async {
    final batchData = await getBatchAnalytics(companyId);
    final locationStats = batchData['locationStats'] as List;

    return locationStats.map((stat) {
      return WaypointPassengerStats(
        waypointName: stat['waypointName'] as String,
        totalBoardings: stat['totalBoardings'] as int,
        totalAlightings: stat['totalAlightings'] as int,
      );
    }).toList();
  }

  // ========== 5. HOURLY PASSENGER TREND PER LOCATION ==========
  Future<LocationHourlyTrend> getHourlyTrendPerLocation(
    String companyId,
    String waypointName,
  ) async {
    final cacheKey = 'location_hourly_${companyId}_$waypointName';

    final cached = _getCached<LocationHourlyTrend>(cacheKey);
    if (cached != null) return cached;

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final busIds = await _getBusIds(companyId);

      if (busIds.isEmpty) {
        return LocationHourlyTrend(
          waypointName: waypointName,
          boardingByHour: _initializeHourlyData(),
          alightingByHour: _initializeHourlyData(),
        );
      }

      final boardingByHour = _initializeHourlyData();
      final alightingByHour = _initializeHourlyData();

      // Process in chunks
      const int chunkSize = 10;
      for (int i = 0; i < busIds.length; i += chunkSize) {
        final chunk = busIds.skip(i).take(chunkSize).toList();

        final futures = chunk.map(
          (busId) => _firestore
              .collection('buses')
              .doc(busId)
              .collection('bus_occupancy_logs')
              .where('waypoint_name', isEqualTo: waypointName)
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
              )
              .get(),
        );

        final results = await Future.wait(futures);

        for (var logsQuery in results) {
          for (var doc in logsQuery.docs) {
            final data = doc.data();
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final hour = timestamp.hour;
            final actionType = data['action_type'] as String?;

            if (actionType == 'board') {
              boardingByHour[hour] = (boardingByHour[hour] ?? 0) + 1;
            } else if (actionType == 'alight') {
              alightingByHour[hour] = (alightingByHour[hour] ?? 0) + 1;
            }
          }
        }
      }

      final result = LocationHourlyTrend(
        waypointName: waypointName,
        boardingByHour: boardingByHour,
        alightingByHour: alightingByHour,
      );

      _setCache(cacheKey, result);
      return result;
    } catch (e) {
      print('Error fetching location hourly trend: $e');
      rethrow;
    }
  }

  // ========== 6. PREFERRED BUS TYPE ==========
  Future<Map<String, double>> getPreferredBusType(String companyId) async {
    final cacheKey = 'preferred_bus_type_$companyId';

    final cached = _getCached<Map<String, double>>(cacheKey);
    if (cached != null) return cached;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final busIds = await _getBusIds(companyId);
      if (busIds.isEmpty) return {};

      // Get bus capacities
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      final busCapacities = <String, int>{};
      for (var doc in busesSnapshot.docs) {
        final capacity = doc.data()['total_capacity'] as int? ?? 0;
        busCapacities[doc.id] = capacity;
      }

      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('company_ID', isEqualTo: companyId)
          .where('current_status', isEqualTo: 'completed')
          .where(
            'end_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .get();

      final tripsByCapacity = <String, List<int>>{};

      for (var doc in tripsSnapshot.docs) {
        final tripData = doc.data();
        final busId = tripData['bus_ID'] as String?;
        final finalCount = tripData['final_passenger_count'] as int? ?? 0;

        if (busId != null && busCapacities.containsKey(busId)) {
          final capacity = busCapacities[busId]!;
          final busType = _getBusTypeLabel(capacity);

          if (!tripsByCapacity.containsKey(busType)) {
            tripsByCapacity[busType] = [];
          }
          tripsByCapacity[busType]!.add(finalCount);
        }
      }

      final averages = <String, double>{};
      for (var entry in tripsByCapacity.entries) {
        if (entry.value.isNotEmpty) {
          final sum = entry.value.reduce((a, b) => a + b);
          averages[entry.key] = sum / entry.value.length;
        } else {
          averages[entry.key] = 0.0;
        }
      }

      _setCache(cacheKey, averages);
      return averages;
    } catch (e) {
      print('Error fetching preferred bus type: $e');
      rethrow;
    }
  }

  // ========== 7. MONTHLY PASSENGER TREND ==========
  Future<Map<String, int>> getMonthlyPassengerTrend(String companyId) async {
    final cacheKey = 'monthly_trend_$companyId';

    final cached = _getCached<Map<String, int>>(cacheKey);
    if (cached != null) return cached;

    try {
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

      final busIds = await _getBusIds(companyId);
      if (busIds.isEmpty) return {};

      final monthlyData = <String, int>{};

      // Process in chunks
      const int chunkSize = 10;
      for (int i = 0; i < busIds.length; i += chunkSize) {
        final chunk = busIds.skip(i).take(chunkSize).toList();

        final futures = chunk.map(
          (busId) => _firestore
              .collection('buses')
              .doc(busId)
              .collection('bus_occupancy_logs')
              .where('action_type', isEqualTo: 'board')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo),
              )
              .get(),
        );

        final results = await Future.wait(futures);

        for (var logsQuery in results) {
          for (var doc in logsQuery.docs) {
            final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
            final monthKey =
                '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
            monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
          }
        }
      }

      _setCache(cacheKey, monthlyData);
      return monthlyData;
    } catch (e) {
      print('Error fetching monthly trend: $e');
      rethrow;
    }
  }

  // ========== 8. PEAK DAY OF EVERY MONTH ==========
  Future<List<PeakDayData>> getPeakDayPerMonth(String companyId) async {
    final cacheKey = 'peak_day_per_month_$companyId';

    final cached = _getCached<List<PeakDayData>>(cacheKey);
    if (cached != null) return cached;

    try {
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

      final busIds = await _getBusIds(companyId);
      if (busIds.isEmpty) return [];

      final monthlyDailyCounts = <String, Map<String, int>>{};

      // Process in chunks
      const int chunkSize = 10;
      for (int i = 0; i < busIds.length; i += chunkSize) {
        final chunk = busIds.skip(i).take(chunkSize).toList();

        final futures = chunk.map(
          (busId) => _firestore
              .collection('buses')
              .doc(busId)
              .collection('bus_occupancy_logs')
              .where('action_type', isEqualTo: 'board')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo),
              )
              .get(),
        );

        final results = await Future.wait(futures);

        for (var logsQuery in results) {
          for (var doc in logsQuery.docs) {
            final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
            final monthKey =
                '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
            final dateKey =
                '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

            if (!monthlyDailyCounts.containsKey(monthKey)) {
              monthlyDailyCounts[monthKey] = {};
            }
            monthlyDailyCounts[monthKey]![dateKey] =
                (monthlyDailyCounts[monthKey]![dateKey] ?? 0) + 1;
          }
        }
      }

      final peakDays = <PeakDayData>[];

      for (var entry in monthlyDailyCounts.entries) {
        final monthKey = entry.key;
        final dailyCounts = entry.value;

        if (dailyCounts.isEmpty) continue;

        String peakDate = '';
        int maxCount = 0;

        for (var dayEntry in dailyCounts.entries) {
          if (dayEntry.value > maxCount) {
            maxCount = dayEntry.value;
            peakDate = dayEntry.key;
          }
        }

        int peakHour = await _findPeakHourForDate(companyId, peakDate, busIds);

        peakDays.add(
          PeakDayData(
            month: monthKey,
            peakDate: peakDate,
            totalPassengers: maxCount,
            peakHour: peakHour,
          ),
        );
      }

      peakDays.sort((a, b) => a.month.compareTo(b.month));

      _setCache(cacheKey, peakDays);
      return peakDays;
    } catch (e) {
      print('Error fetching peak days: $e');
      rethrow;
    }
  }

  Future<int> _findPeakHourForDate(
    String companyId,
    String date,
    List<String> busIds,
  ) async {
    final dateTime = DateTime.parse(date);
    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final hourCounts = _initializeHourlyData();

    // Process in chunks
    const int chunkSize = 10;
    for (int i = 0; i < busIds.length; i += chunkSize) {
      final chunk = busIds.skip(i).take(chunkSize).toList();

      final futures = chunk.map(
        (busId) => _firestore
            .collection('buses')
            .doc(busId)
            .collection('bus_occupancy_logs')
            .where('action_type', isEqualTo: 'board')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .get(),
      );

      final results = await Future.wait(futures);

      for (var logsQuery in results) {
        for (var doc in logsQuery.docs) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final hour = timestamp.hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        }
      }
    }

    int peakHour = 0;
    int maxCount = 0;
    for (var entry in hourCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        peakHour = entry.key;
      }
    }

    return peakHour;
  }

  // ========== HELPER METHODS ==========

  Map<int, int> _initializeHourlyData() {
    final data = <int, int>{};
    for (int i = 0; i < 24; i++) {
      data[i] = 0;
    }
    return data;
  }

  String _getBusTypeLabel(int capacity) {
    if (capacity <= 29) return '29-seater (Coaster)';
    if (capacity <= 35) return '35-seater (Orange)';
    if (capacity <= 45) return '45-seater (Deluxe)';
    if (capacity <= 56) return '56-seater (Deluxe)';
    if (capacity <= 57) return '57-seater (Deluxe)';
    return 'Other';
  }

  Future<Map<String, dynamic>> getDashboardSummary(String companyId) async {
    final cacheKey = 'dashboard_summary_$companyId';

    final cached = _getCached<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      // Run all queries in parallel
      final results = await Future.wait([
        _firestore
            .collection('buses')
            .where('company_ID', isEqualTo: companyId)
            .get(),
        _firestore
            .collection('routes')
            .where('company_ID', isEqualTo: companyId)
            .get(),
        _getActiveTripsCount(companyId),
      ]);

      final busesSnapshot = results[0] as QuerySnapshot;
      final routesSnapshot = results[1] as QuerySnapshot;
      final activeTripsCount = results[2] as int;

      final summary = {
        'total_buses': busesSnapshot.docs.length,
        'total_routes': routesSnapshot.docs.length,
        'active_trips_today': activeTripsCount,
      };

      _setCache(cacheKey, summary);
      return summary;
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      return {'total_buses': 0, 'total_routes': 0, 'active_trips_today': 0};
    }
  }

  Future<int> _getActiveTripsCount(String companyId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final activeTripsSnapshot = await _firestore
          .collection('trips')
          .where('company_ID', isEqualTo: companyId)
          .where('current_status', isEqualTo: 'active')
          .where(
            'start_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      return activeTripsSnapshot.docs.length;
    } catch (e) {
      print('Error fetching active trips: $e');
      return 0;
    }
  }

  Future<List<String>> getWaypointsList(String companyId) async {
    final batchData = await getBatchAnalytics(companyId);
    return (batchData['waypoints'] as List).cast<String>();
  }
}

// ========== DATA MODELS ==========

class _CachedData {
  final dynamic data;
  final DateTime timestamp;

  _CachedData({required this.data, required this.timestamp});
}

class WaypointPassengerStats {
  final String waypointName;
  final int totalBoardings;
  final int totalAlightings;

  WaypointPassengerStats({
    required this.waypointName,
    required this.totalBoardings,
    required this.totalAlightings,
  });

  int get totalActivity => totalBoardings + totalAlightings;
}

class LocationHourlyTrend {
  final String waypointName;
  final Map<int, int> boardingByHour;
  final Map<int, int> alightingByHour;

  LocationHourlyTrend({
    required this.waypointName,
    required this.boardingByHour,
    required this.alightingByHour,
  });
}

class PeakDayData {
  final String month;
  final String peakDate;
  final int totalPassengers;
  final int peakHour;

  PeakDayData({
    required this.month,
    required this.peakDate,
    required this.totalPassengers,
    required this.peakHour,
  });
}

class WeekHeatmapData {
  final int weekNumber;
  final String weekLabel;
  final Map<String, Map<int, int>> data;

  WeekHeatmapData({
    required this.weekNumber,
    required this.weekLabel,
    required this.data,
  });
}

class WeeklyHeatmapData {
  final List<WeekHeatmapData> weeks;
  final Map<String, Map<int, int>> aggregatedData; // All weeks combined

  WeeklyHeatmapData({required this.weeks, required this.aggregatedData});
}
