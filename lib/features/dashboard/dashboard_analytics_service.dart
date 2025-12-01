import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Dashboard Analytics Service
/// Implements analytical data gathered from commuting and operations
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

  // ========== 1. LIVE PASSENGER HOURLY TREND (TODAY) ==========
  /// Shows hourly boarding trend for today (0-23 hours)
  Future<Map<int, int>> getLivePassengerHourlyTrend(String companyId) async {
    final cacheKey = 'live_hourly_trend_$companyId';

    final cached = _getCached<Map<int, int>>(cacheKey);
    if (cached != null) return cached;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return _initializeHourlyData();
      }

      final hourlyData = _initializeHourlyData();

      for (var busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where('action_type', isEqualTo: 'board')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        for (var doc in logsQuery.docs) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final hour = timestamp.hour;
          hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
        }
      }

      _setCache(cacheKey, hourlyData);
      return hourlyData;
    } catch (e) {
      print('Error fetching live hourly trend: $e');
      rethrow;
    }
  }

  // ========== 2. DAILY PASSENGER TREND (LAST 30 DAYS) ==========
  /// Shows daily totals for the past 30 days
  Future<Map<String, int>> getDailyPassengerTrend30Days(
    String companyId,
  ) async {
    final cacheKey = 'daily_trend_30days_$companyId';

    final cached = _getCached<Map<String, int>>(cacheKey);
    if (cached != null) return cached;

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return {};
      }

      final dailyData = <String, int>{};

      for (var busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where('action_type', isEqualTo: 'board')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
            )
            .get();

        for (var doc in logsQuery.docs) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final dateKey =
              '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
          dailyData[dateKey] = (dailyData[dateKey] ?? 0) + 1;
        }
      }

      _setCache(cacheKey, dailyData);
      return dailyData;
    } catch (e) {
      print('Error fetching daily trend: $e');
      rethrow;
    }
  }

  // ========== 3. WEEKLY PASSENGER HEATMAP WITH WEEK INFORMATION ==========
  /// Returns data for heatmap with week information
  /// Last 30 days grouped by week, day of week, and hour
  Future<WeeklyHeatmapData> getWeeklyPassengerHeatmap(String companyId) async {
    final cacheKey = 'weekly_heatmap_$companyId';

    final cached = _getCached<WeeklyHeatmapData>(cacheKey);
    if (cached != null) {
      print('📦 Returning cached heatmap data');
      return cached;
    }

    try {
      print('🔍 Fetching heatmap data for company: $companyId');

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      print('   Date range: ${thirtyDaysAgo.toString()} to ${now.toString()}');

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      print('   Found ${busesSnapshot.docs.length} buses');

      if (busesSnapshot.docs.isEmpty) {
        print('⚠️ No buses found for company');
        return WeeklyHeatmapData(weeks: [], aggregatedData: {});
      }

      // Track data by week
      final weeklyData = <int, Map<String, Map<int, int>>>{};
      final weekLabels = <int, String>{};
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      int totalLogs = 0;

      for (var busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where('action_type', isEqualTo: 'board')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
            )
            .get();

        print('   Bus ${busDoc.id}: ${logsQuery.docs.length} boarding logs');
        totalLogs += logsQuery.docs.length;

        for (var doc in logsQuery.docs) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final weekNumber = _getWeekNumber(timestamp);
          final dayOfWeek = dayNames[timestamp.weekday - 1];
          final hour = timestamp.hour;

          // Initialize week data if needed
          if (!weeklyData.containsKey(weekNumber)) {
            weeklyData[weekNumber] = {};
            weekLabels[weekNumber] = _getWeekLabel(timestamp);
            for (var day in dayNames) {
              weeklyData[weekNumber]![day] = _initializeHourlyData();
            }
          }

          // Increment count
          weeklyData[weekNumber]![dayOfWeek]![hour] =
              (weeklyData[weekNumber]![dayOfWeek]![hour] ?? 0) + 1;
        }
      }

      print('   📊 Total boarding logs processed: $totalLogs');
      print('   📅 Weeks with data: ${weeklyData.keys.toList()}');

      // Create aggregated data (all weeks combined)
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

      // Create week objects sorted by week number
      final weeks = weeklyData.keys.toList()..sort();
      final weekObjects = weeks.map((weekNum) {
        return WeekHeatmapData(
          weekNumber: weekNum,
          weekLabel: weekLabels[weekNum]!,
          data: weeklyData[weekNum]!,
        );
      }).toList();

      print('   ✅ Created ${weekObjects.length} week objects');
      print('   ✅ Aggregated data has ${aggregatedData.length} days');

      // Sample output
      if (aggregatedData.isNotEmpty) {
        final mondayData = aggregatedData['Monday'];
        final totalMonday =
            mondayData?.values.fold(0, (sum, count) => sum + count) ?? 0;
        print('   📈 Monday total across all weeks: $totalMonday passengers');
      }

      final result = WeeklyHeatmapData(
        weeks: weekObjects,
        aggregatedData: aggregatedData,
      );

      _setCache(cacheKey, result);
      return result;
    } catch (e) {
      print('❌ Error fetching weekly heatmap: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // ========== 4. LOCATION BASED PASSENGER STATISTICS ==========
  /// Grouped bar chart: boarding and alighting by waypoint (last 30 days)
  Future<List<WaypointPassengerStats>> getLocationBasedPassengerStats(
    String companyId,
  ) async {
    final cacheKey = 'location_stats_$companyId';

    final cached = _getCached<List<WaypointPassengerStats>>(cacheKey);
    if (cached != null) return cached;

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return [];
      }

      final waypointData = <String, Map<String, int>>{};

      for (var busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
            )
            .get();

        for (var doc in logsQuery.docs) {
          final data = doc.data();
          final actionType = data['action_type'] as String?;
          final waypointName = data['waypoint_name'] as String? ?? 'Unknown';

          if (!waypointData.containsKey(waypointName)) {
            waypointData[waypointName] = {'boarding': 0, 'alighting': 0};
          }

          if (actionType == 'board') {
            waypointData[waypointName]!['boarding'] =
                (waypointData[waypointName]!['boarding'] ?? 0) + 1;
          } else if (actionType == 'alight') {
            waypointData[waypointName]!['alighting'] =
                (waypointData[waypointName]!['alighting'] ?? 0) + 1;
          }
        }
      }

      final statsList = waypointData.entries.map((entry) {
        return WaypointPassengerStats(
          waypointName: entry.key,
          totalBoardings: entry.value['boarding'] ?? 0,
          totalAlightings: entry.value['alighting'] ?? 0,
        );
      }).toList();

      statsList.sort(
        (a, b) => (b.totalBoardings + b.totalAlightings).compareTo(
          a.totalBoardings + a.totalAlightings,
        ),
      );

      _setCache(cacheKey, statsList);
      return statsList;
    } catch (e) {
      print('Error fetching location stats: $e');
      rethrow;
    }
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

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return LocationHourlyTrend(
          waypointName: waypointName,
          boardingByHour: _initializeHourlyData(),
          alightingByHour: _initializeHourlyData(),
        );
      }

      final boardingByHour = _initializeHourlyData();
      final alightingByHour = _initializeHourlyData();

      for (var busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where('waypoint_name', isEqualTo: waypointName)
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
            )
            .get();

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

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return {};
      }

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

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return {};
      }

      final monthlyData = <String, int>{};

      for (var busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where('action_type', isEqualTo: 'board')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo),
            )
            .get();

        for (var doc in logsQuery.docs) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final monthKey =
              '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
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

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        return [];
      }

      final monthlyDailyCounts = <String, Map<String, int>>{};

      for (var busDoc in busesSnapshot.docs) {
        final logsQuery = await _firestore
            .collection('buses')
            .doc(busDoc.id)
            .collection('bus_occupancy_logs')
            .where('action_type', isEqualTo: 'board')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo),
            )
            .get();

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

        int peakHour = await _findPeakHourForDate(
          companyId,
          peakDate,
          busesSnapshot.docs,
        );

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
    List<QueryDocumentSnapshot> busDocs,
  ) async {
    final dateTime = DateTime.parse(date);
    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final hourCounts = _initializeHourlyData();

    for (var busDoc in busDocs) {
      final logsQuery = await _firestore
          .collection('buses')
          .doc(busDoc.id)
          .collection('bus_occupancy_logs')
          .where('action_type', isEqualTo: 'board')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in logsQuery.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        final hour = timestamp.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
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

    try {
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      if (busesSnapshot.docs.isEmpty) {
        final allBusesSnapshot = await _firestore
            .collection('buses')
            .limit(5)
            .get();

        if (allBusesSnapshot.docs.isNotEmpty) {
          for (var doc in allBusesSnapshot.docs) {
            final data = doc.data();
            print('      - Bus ID: ${doc.id}');
            print('        company_ID field: "${data['company_ID']}"');
            print('        company_ID type: ${data['company_ID'].runtimeType}');
            print(
              '        Matches your companyId? ${data['company_ID'] == companyId}',
            );
          }
        } else {}
      } else {
        print('   ✅ Found buses for this company');
        print(
          '   🔍 Sample bus IDs: ${busesSnapshot.docs.take(3).map((d) => d.id).toList()}',
        );
      }
      print('');

      // ========== ROUTES QUERY ==========
      print('🛣️  QUERYING ROUTES...');
      final routesSnapshot = await _firestore
          .collection('routes')
          .where('company_ID', isEqualTo: companyId)
          .get();

      print('   ✅ Routes query completed');
      print('   📊 Total documents returned: ${routesSnapshot.docs.length}');

      if (routesSnapshot.docs.isEmpty) {
        print('   ⚠️  NO ROUTES FOUND - Checking why...');
        final allRoutesSnapshot = await _firestore
            .collection('routes')
            .limit(5)
            .get();

        print(
          '   📊 Total routes in entire collection: ${allRoutesSnapshot.docs.length}',
        );

        if (allRoutesSnapshot.docs.isNotEmpty) {
          print('   🔍 Sample route data:');
          for (var doc in allRoutesSnapshot.docs) {
            final data = doc.data();
            print('      - Route ID: ${doc.id}');
            print('        company_ID field: "${data['company_ID']}"');
            print('        company_ID type: ${data['company_ID'].runtimeType}');
            print(
              '        Matches your companyId? ${data['company_ID'] == companyId}',
            );
            print('        route_name: ${data['route_name']}');
          }
        } else {
          print('   ⚠️  NO ROUTES EXIST IN THE ENTIRE COLLECTION!');
        }
      } else {
        print('   ✅ Found routes for this company');
        print(
          '   🔍 Sample route IDs: ${routesSnapshot.docs.take(3).map((d) => d.id).toList()}',
        );
      }
      print('');

      // ========== TRIPS QUERY (with error handling) ==========
      print('🎫 QUERYING ACTIVE TRIPS...');
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      print('   📅 Today: $today');
      print('   📅 Start of day: $startOfDay');

      int activeTripsCount = 0;

      try {
        final activeTripsSnapshot = await _firestore
            .collection('trips')
            .where('company_ID', isEqualTo: companyId)
            .where('current_status', isEqualTo: 'active')
            .where(
              'start_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .get();

        activeTripsCount = activeTripsSnapshot.docs.length;
        print('   ✅ Active trips query completed');
        print('   📊 Total documents returned: $activeTripsCount');

        if (activeTripsSnapshot.docs.isEmpty) {
          print('   ⚠️  NO ACTIVE TRIPS FOUND - Checking why...');
          final allCompanyTripsSnapshot = await _firestore
              .collection('trips')
              .where('company_ID', isEqualTo: companyId)
              .limit(5)
              .get();

          print(
            '   📊 Total trips for this company: ${allCompanyTripsSnapshot.docs.length}',
          );

          if (allCompanyTripsSnapshot.docs.isNotEmpty) {
            print('   🔍 Sample trip data:');
            for (var doc in allCompanyTripsSnapshot.docs) {
              final data = doc.data();
              print('      - Trip ID: ${doc.id}');
              print('        current_status: ${data['current_status']}');
              print('        start_time: ${data['start_time']}');
            }
          } else {
            print('   ⚠️  NO TRIPS EXIST FOR THIS COMPANY!');
          }
        } else {
          print('   ✅ Found active trips for today');
        }
      } catch (tripsError) {
        print(
          '   ⚠️  TRIPS QUERY FAILED (but continuing with buses & routes data)',
        );
        print('   Error: $tripsError');

        // Check if it's the missing index error
        if (tripsError.toString().contains('requires an index')) {
          print('   💡 ACTION REQUIRED: Create a Firestore composite index');
          print(
            '   The trips query needs: company_ID + current_status + start_time',
          );
          print(
            '   Click the URL in the error message to create the index automatically',
          );
        }

        activeTripsCount = 0; // Default to 0 on error
      }

      final summary = {
        'total_buses': busesSnapshot.docs.length,
        'total_routes': routesSnapshot.docs.length,
        'active_trips_today': activeTripsCount,
      };
      _setCache(cacheKey, summary);
      return summary;
    } catch (e, stackTrace) {
      print('Error: $e');
      print(stackTrace);
      return {'total_buses': 0, 'total_routes': 0, 'active_trips_today': 0};
    }
  }

  Future<List<String>> getWaypointsList(String companyId) async {
    final cacheKey = 'waypoints_list_$companyId';

    final cached = _getCached<List<String>>(cacheKey);
    if (cached != null) return cached;

    try {
      final routesSnapshot = await _firestore
          .collection('routes')
          .where('company_ID', isEqualTo: companyId)
          .get();

      final waypointsSet = <String>{};

      for (var doc in routesSnapshot.docs) {
        final waypoints = doc.data()['waypoints'] as List<dynamic>? ?? [];
        for (var waypoint in waypoints) {
          if (waypoint is String && waypoint.isNotEmpty) {
            waypointsSet.add(waypoint);
          }
        }
      }

      final waypointsList = waypointsSet.toList()..sort();
      _setCache(cacheKey, waypointsList);
      return waypointsList;
    } catch (e) {
      print('Error fetching waypoints: $e');
      return [];
    }
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

// ========== NEW MODELS FOR WEEKLY HEATMAP ==========

class WeekHeatmapData {
  final int weekNumber;
  final String weekLabel; // e.g., "Week 48 (11/25 - 12/1)"
  final Map<String, Map<int, int>> data; // Day -> Hour -> Count

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
