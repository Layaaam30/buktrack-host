import 'package:flutter/material.dart';
import 'dashboard_analytics_service.dart';

/// Optimized Dashboard Analytics Provider with Fast Loading
class DashboardAnalyticsProvider with ChangeNotifier {
  final DashboardAnalyticsService _analyticsService =
      DashboardAnalyticsService();

  // State
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';

  // Time period filter
  String _selectedTimePeriod = 'today';

  // Week filter for heatmap
  int? _selectedWeekFilter;

  // Analytics data
  Map<int, int>? _liveHourlyTrend;
  Map<String, int>? _dailyTrend30Days;
  WeeklyHeatmapData? _weeklyHeatmapData;
  List<WaypointPassengerStats>? _locationStats;
  LocationHourlyTrend? _locationHourlyTrend;
  Map<String, double>? _preferredBusType;
  Map<String, int>? _monthlyTrend;
  List<PeakDayData>? _peakDaysPerMonth;
  Map<String, dynamic>? _dashboardSummary;

  // Waypoint selection
  String? _selectedWaypoint;
  List<String>? _availableWaypoints;

  // Loading state tracking
  bool _summaryLoaded = false;
  bool _batchDataLoaded = false;
  bool _secondaryDataLoaded = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTimePeriod => _selectedTimePeriod;
  int? get selectedWeekFilter => _selectedWeekFilter;

  Map<int, int>? get liveHourlyTrend => _liveHourlyTrend;
  Map<String, int>? get dailyTrend30Days => _dailyTrend30Days;

  Map<String, Map<int, int>>? get weeklyHeatmap {
    if (_weeklyHeatmapData == null) return null;

    if (_selectedWeekFilter == null) {
      return _weeklyHeatmapData!.aggregatedData;
    } else {
      final weekData = _weeklyHeatmapData!.weeks.firstWhere(
        (w) => w.weekNumber == _selectedWeekFilter,
        orElse: () => _weeklyHeatmapData!.weeks.first,
      );
      return weekData.data;
    }
  }

  List<WeekHeatmapData>? get availableWeeks => _weeklyHeatmapData?.weeks;

  String? get currentWeekLabel {
    if (_weeklyHeatmapData == null) return null;
    if (_selectedWeekFilter == null) return 'All Weeks';

    final weekData = _weeklyHeatmapData!.weeks.firstWhere(
      (w) => w.weekNumber == _selectedWeekFilter,
      orElse: () => _weeklyHeatmapData!.weeks.first,
    );
    return weekData.weekLabel;
  }

  List<WaypointPassengerStats>? get locationStats => _locationStats;
  LocationHourlyTrend? get locationHourlyTrend => _locationHourlyTrend;
  Map<String, double>? get preferredBusType => _preferredBusType;
  Map<String, int>? get monthlyTrend => _monthlyTrend;
  List<PeakDayData>? get peakDaysPerMonth => _peakDaysPerMonth;
  Map<String, dynamic>? get dashboardSummary => _dashboardSummary;

  String? get selectedWaypoint => _selectedWaypoint;
  List<String>? get availableWaypoints => _availableWaypoints;

  void setCompanyId(String companyId) {
    if (_currentCompanyId == companyId) return;

    _currentCompanyId = companyId;
    _clearData();
    notifyListeners();
  }

  void setTimePeriod(String period) {
    if (_selectedTimePeriod == period) return;
    _selectedTimePeriod = period;
    notifyListeners();
  }

  void setWeekFilter(int? weekNumber) {
    _selectedWeekFilter = weekNumber;
    notifyListeners();
  }

  Future<void> setSelectedWaypoint(String waypoint) async {
    _selectedWaypoint = waypoint;
    notifyListeners();
    await loadLocationHourlyTrend();
  }

  void _clearData() {
    _liveHourlyTrend = null;
    _dailyTrend30Days = null;
    _weeklyHeatmapData = null;
    _locationStats = null;
    _locationHourlyTrend = null;
    _preferredBusType = null;
    _monthlyTrend = null;
    _peakDaysPerMonth = null;
    _dashboardSummary = null;
    _error = null;
    _selectedWeekFilter = null;
    _summaryLoaded = false;
    _batchDataLoaded = false;
    _secondaryDataLoaded = false;
  }

  /// OPTIMIZED: Fast Progressive Loading
  Future<void> loadAllAnalytics() async {
    if (_currentCompanyId.isEmpty) {
      _error = 'Company ID not set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // PHASE 1: Critical Summary Data (Fastest - Single Query)
      await _loadPhase1Summary();

      // PHASE 2: Batch Analytics (Single Query for Multiple Charts)
      await _loadPhase2BatchData();

      // PHASE 3: Secondary Analytics (Lower Priority)
      _loadPhase3SecondaryData(); // Fire and forget

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Phase 1: Load critical summary data first (fastest)
  Future<void> _loadPhase1Summary() async {
    if (_summaryLoaded) return;

    try {
      print('📊 PHASE 1: Loading summary...');
      _dashboardSummary = await _analyticsService.getDashboardSummary(
        _currentCompanyId,
      );
      _summaryLoaded = true;
      notifyListeners(); // Update UI immediately
      print('✅ PHASE 1: Summary loaded');
    } catch (e) {
      print('❌ Error loading summary: $e');
    }
  }

  /// Phase 2: Load batch analytics (most efficient)
  Future<void> _loadPhase2BatchData() async {
    if (_batchDataLoaded) return;

    try {
      print('📊 PHASE 2: Loading batch analytics...');

      // Single query gets: hourly, daily, weekly, and location data
      final batchData = await _analyticsService.getBatchAnalytics(
        _currentCompanyId,
      );

      // Extract all data from batch result
      _liveHourlyTrend = batchData['liveHourlyTrend'] as Map<int, int>?;
      _dailyTrend30Days = batchData['dailyTrend30Days'] as Map<String, int>?;

      // Parse weekly heatmap data
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

      _weeklyHeatmapData = WeeklyHeatmapData(
        weeks: weeks,
        aggregatedData: Map<String, Map<int, int>>.from(
          (heatmapData['aggregatedData'] as Map).map(
            (key, value) =>
                MapEntry(key as String, Map<int, int>.from(value as Map)),
          ),
        ),
      );

      // Parse location stats
      final locationStatsData = batchData['locationStats'] as List;
      _locationStats = locationStatsData.map((stat) {
        return WaypointPassengerStats(
          waypointName: stat['waypointName'] as String,
          totalBoardings: stat['totalBoardings'] as int,
          totalAlightings: stat['totalAlightings'] as int,
        );
      }).toList();

      // Get waypoints
      _availableWaypoints = (batchData['waypoints'] as List).cast<String>();
      if (_availableWaypoints != null && _availableWaypoints!.isNotEmpty) {
        _selectedWaypoint = _availableWaypoints!.first;
      }

      _batchDataLoaded = true;
      notifyListeners(); // Update UI with all batch data
      print('✅ PHASE 2: Batch analytics loaded');
    } catch (e) {
      print('❌ Error loading batch analytics: $e');
    }
  }

  /// Phase 3: Load secondary data asynchronously
  Future<void> _loadPhase3SecondaryData() async {
    if (_secondaryDataLoaded) return;

    print('📊 PHASE 3: Loading secondary analytics...');

    // Load these in parallel (fire and forget)
    final futures = <Future>[];

    // Location hourly trend for selected waypoint
    if (_selectedWaypoint != null) {
      futures.add(_loadLocationHourlyTrendAsync());
    }

    // Preferred bus type
    futures.add(_loadPreferredBusTypeAsync());

    // Monthly trend
    futures.add(_loadMonthlyTrendAsync());

    // Peak days
    futures.add(_loadPeakDaysAsync());

    // Wait for all secondary data
    await Future.wait(futures);

    _secondaryDataLoaded = true;
    notifyListeners(); // Final update with all data
    print('✅ PHASE 3: Secondary analytics loaded');
  }

  Future<void> _loadLocationHourlyTrendAsync() async {
    try {
      if (_selectedWaypoint == null) return;
      _locationHourlyTrend = await _analyticsService.getHourlyTrendPerLocation(
        _currentCompanyId,
        _selectedWaypoint!,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading location hourly trend: $e');
    }
  }

  Future<void> _loadPreferredBusTypeAsync() async {
    try {
      _preferredBusType = await _analyticsService.getPreferredBusType(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading preferred bus type: $e');
    }
  }

  Future<void> _loadMonthlyTrendAsync() async {
    try {
      _monthlyTrend = await _analyticsService.getMonthlyPassengerTrend(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading monthly trend: $e');
    }
  }

  Future<void> _loadPeakDaysAsync() async {
    try {
      _peakDaysPerMonth = await _analyticsService.getPeakDayPerMonth(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading peak days: $e');
    }
  }

  // Individual loaders maintained for compatibility
  Future<void> loadDashboardSummary() async => await _loadPhase1Summary();

  Future<void> loadLiveHourlyTrend() async {
    if (!_batchDataLoaded) await _loadPhase2BatchData();
  }

  Future<void> loadDailyTrend30Days() async {
    if (!_batchDataLoaded) await _loadPhase2BatchData();
  }

  Future<void> loadWeeklyHeatmap() async {
    if (!_batchDataLoaded) await _loadPhase2BatchData();
  }

  Future<void> loadLocationStats() async {
    if (!_batchDataLoaded) await _loadPhase2BatchData();
  }

  Future<void> loadLocationHourlyTrend() async {
    await _loadLocationHourlyTrendAsync();
  }

  Future<void> loadPreferredBusType() async {
    await _loadPreferredBusTypeAsync();
  }

  Future<void> loadMonthlyTrend() async {
    await _loadMonthlyTrendAsync();
  }

  Future<void> loadPeakDaysPerMonth() async {
    await _loadPeakDaysAsync();
  }

  Future<void> loadWaypointsList() async {
    if (!_batchDataLoaded) await _loadPhase2BatchData();
  }

  // ========== REFRESH METHODS ==========

  Future<void> refreshAllData() async {
    _analyticsService.clearCache();
    _clearData();
    await loadAllAnalytics();
  }

  Future<void> refreshLiveHourlyTrend() async {
    _analyticsService.clearCache();
    _batchDataLoaded = false;
    await loadLiveHourlyTrend();
  }

  Future<void> refreshDailyTrend() async {
    _analyticsService.clearCache();
    _batchDataLoaded = false;
    await loadDailyTrend30Days();
  }

  Future<void> refreshWeeklyHeatmap() async {
    _analyticsService.clearCache();
    _batchDataLoaded = false;
    await loadWeeklyHeatmap();
  }

  Future<void> refreshLocationStats() async {
    _analyticsService.clearCache();
    _batchDataLoaded = false;
    await loadLocationStats();
  }

  Future<void> refreshPreferredBusType() async {
    _analyticsService.clearCache();
    await loadPreferredBusType();
  }

  Future<void> refreshMonthlyTrend() async {
    _analyticsService.clearCache();
    await loadMonthlyTrend();
  }

  Future<void> refreshPeakDays() async {
    _analyticsService.clearCache();
    await loadPeakDaysPerMonth();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== COMPUTED PROPERTIES ==========

  int get totalPassengersToday {
    if (_liveHourlyTrend == null) return 0;
    return _liveHourlyTrend!.values.fold(0, (sum, count) => sum + count);
  }

  int? get peakHourToday {
    if (_liveHourlyTrend == null || _liveHourlyTrend!.isEmpty) return null;

    int maxHour = 0;
    int maxCount = 0;

    for (var entry in _liveHourlyTrend!.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxHour = entry.key;
      }
    }

    return maxHour;
  }

  WaypointPassengerStats? get busiestWaypoint {
    if (_locationStats == null || _locationStats!.isEmpty) return null;
    return _locationStats!.first;
  }

  String? get mostPreferredBusType {
    if (_preferredBusType == null || _preferredBusType!.isEmpty) return null;

    String maxType = '';
    double maxAvg = 0.0;

    for (var entry in _preferredBusType!.entries) {
      if (entry.value > maxAvg) {
        maxAvg = entry.value;
        maxType = entry.key;
      }
    }

    return maxType;
  }

  String? get busiestMonth {
    if (_monthlyTrend == null || _monthlyTrend!.isEmpty) return null;

    String maxMonth = '';
    int maxCount = 0;

    for (var entry in _monthlyTrend!.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxMonth = entry.key;
      }
    }

    return maxMonth;
  }

  Map<dynamic, int>? get currentTrendData {
    switch (_selectedTimePeriod) {
      case 'today':
        return _liveHourlyTrend;
      case 'daily':
        return _dailyTrend30Days;
      case 'monthly':
        return _monthlyTrend;
      default:
        return _liveHourlyTrend;
    }
  }

  String? get busiestDayOfWeek {
    if (_weeklyHeatmapData == null) return null;

    final heatmapToAnalyze = weeklyHeatmap;
    if (heatmapToAnalyze == null || heatmapToAnalyze.isEmpty) return null;

    String maxDay = '';
    int maxCount = 0;

    for (var entry in heatmapToAnalyze.entries) {
      final totalForDay = entry.value.values.fold(
        0,
        (sum, count) => sum + count,
      );
      if (totalForDay > maxCount) {
        maxCount = totalForDay;
        maxDay = entry.key;
      }
    }

    return maxDay.isNotEmpty ? maxDay : null;
  }
}
