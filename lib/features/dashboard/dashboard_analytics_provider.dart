import 'package:flutter/material.dart';
import 'dashboard_analytics_service.dart';

/// Comprehensive Dashboard Analytics Provider
/// Manages all analytics data states from CAPSTONE.pdf requirements
class DashboardAnalyticsProvider with ChangeNotifier {
  final DashboardAnalyticsService _analyticsService =
      DashboardAnalyticsService();

  // State
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';

  // Time period filter
  String _selectedTimePeriod = 'today'; // today, daily, weekly, monthly

  // Week filter for heatmap
  int? _selectedWeekFilter; // null = "All Weeks", specific week number

  // Analytics data
  Map<int, int>? _liveHourlyTrend;
  Map<String, int>? _dailyTrend30Days;
  WeeklyHeatmapData? _weeklyHeatmapData; // Updated to use new model
  List<WaypointPassengerStats>? _locationStats;
  LocationHourlyTrend? _locationHourlyTrend;
  Map<String, double>? _preferredBusType;
  Map<String, int>? _monthlyTrend;
  List<PeakDayData>? _peakDaysPerMonth;
  Map<String, dynamic>? _dashboardSummary;

  // Waypoint selection for location-specific analytics
  String? _selectedWaypoint;
  List<String>? _availableWaypoints;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTimePeriod => _selectedTimePeriod;
  int? get selectedWeekFilter => _selectedWeekFilter;

  Map<int, int>? get liveHourlyTrend => _liveHourlyTrend;
  Map<String, int>? get dailyTrend30Days => _dailyTrend30Days;

  // Return the appropriate heatmap data based on filter
  Map<String, Map<int, int>>? get weeklyHeatmap {
    if (_weeklyHeatmapData == null) return null;

    if (_selectedWeekFilter == null) {
      // Return aggregated data (all weeks)
      return _weeklyHeatmapData!.aggregatedData;
    } else {
      // Return specific week's data
      final weekData = _weeklyHeatmapData!.weeks.firstWhere(
        (w) => w.weekNumber == _selectedWeekFilter,
        orElse: () => _weeklyHeatmapData!.weeks.first,
      );
      return weekData.data;
    }
  }

  // Get list of available weeks
  List<WeekHeatmapData>? get availableWeeks => _weeklyHeatmapData?.weeks;

  // Get current week label
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

  /// Initialize with company ID
  void setCompanyId(String companyId) {
    if (_currentCompanyId == companyId) return;

    _currentCompanyId = companyId;
    _clearData();
    notifyListeners();
  }

  /// Set time period filter
  void setTimePeriod(String period) {
    if (_selectedTimePeriod == period) return;
    _selectedTimePeriod = period;
    notifyListeners();
  }

  /// Set week filter for heatmap
  void setWeekFilter(int? weekNumber) {
    _selectedWeekFilter = weekNumber;
    notifyListeners();
  }

  /// Set selected waypoint for location-specific analytics
  Future<void> setSelectedWaypoint(String waypoint) async {
    _selectedWaypoint = waypoint;
    notifyListeners();
    await loadLocationHourlyTrend();
  }

  /// Clear all data
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
  }

  /// Load all analytics data progressively
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
      // Priority 1: Summary (fastest)
      await loadDashboardSummary();

      // Priority 2: Current day data
      await loadLiveHourlyTrend();

      // Priority 3: Recent trends
      await loadDailyTrend30Days();
      await loadWeeklyHeatmap();

      // Priority 4: Location data
      await loadLocationStats();
      await loadWaypointsList();

      // Priority 5: Bus type analytics
      await loadPreferredBusType();

      // Priority 6: Long-term trends
      await loadMonthlyTrend();
      await loadPeakDaysPerMonth();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== INDIVIDUAL DATA LOADERS ==========

  Future<void> loadDashboardSummary() async {
    try {
      _dashboardSummary = await _analyticsService.getDashboardSummary(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading dashboard summary: $e');
    }
  }

  Future<void> loadLiveHourlyTrend() async {
    try {
      _liveHourlyTrend = await _analyticsService.getLivePassengerHourlyTrend(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading live hourly trend: $e');
    }
  }

  Future<void> loadDailyTrend30Days() async {
    try {
      _dailyTrend30Days = await _analyticsService.getDailyPassengerTrend30Days(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading daily trend: $e');
    }
  }

  Future<void> loadWeeklyHeatmap() async {
    try {
      print(
        '🔍 Starting to load weekly heatmap for company: $_currentCompanyId',
      );

      _weeklyHeatmapData = await _analyticsService.getWeeklyPassengerHeatmap(
        _currentCompanyId,
      );

      print('📊 Weekly heatmap data loaded:');
      print('   - Weeks count: ${_weeklyHeatmapData?.weeks.length ?? 0}');
      print(
        '   - Aggregated data keys: ${_weeklyHeatmapData?.aggregatedData.keys.toList() ?? []}',
      );

      if (_weeklyHeatmapData != null) {
        print(
          '   - Sample aggregated data for Monday: ${_weeklyHeatmapData!.aggregatedData['Monday']}',
        );

        for (var week in _weeklyHeatmapData!.weeks) {
          print('   - Week ${week.weekNumber}: ${week.weekLabel}');
        }
      }

      // Default to showing all weeks
      _selectedWeekFilter = null;
      print('✅ Weekly heatmap loaded successfully');

      notifyListeners();
    } catch (e) {
      print('❌ Error loading weekly heatmap: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> loadLocationStats() async {
    try {
      _locationStats = await _analyticsService.getLocationBasedPassengerStats(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading location stats: $e');
    }
  }

  Future<void> loadLocationHourlyTrend() async {
    if (_selectedWaypoint == null) return;

    try {
      _locationHourlyTrend = await _analyticsService.getHourlyTrendPerLocation(
        _currentCompanyId,
        _selectedWaypoint!,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading location hourly trend: $e');
    }
  }

  Future<void> loadPreferredBusType() async {
    try {
      _preferredBusType = await _analyticsService.getPreferredBusType(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading preferred bus type: $e');
    }
  }

  Future<void> loadMonthlyTrend() async {
    try {
      _monthlyTrend = await _analyticsService.getMonthlyPassengerTrend(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading monthly trend: $e');
    }
  }

  Future<void> loadPeakDaysPerMonth() async {
    try {
      _peakDaysPerMonth = await _analyticsService.getPeakDayPerMonth(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading peak days: $e');
    }
  }

  Future<void> loadWaypointsList() async {
    try {
      _availableWaypoints = await _analyticsService.getWaypointsList(
        _currentCompanyId,
      );
      if (_availableWaypoints != null && _availableWaypoints!.isNotEmpty) {
        _selectedWaypoint = _availableWaypoints!.first;
        await loadLocationHourlyTrend();
      }
      notifyListeners();
    } catch (e) {
      print('Error loading waypoints list: $e');
    }
  }

  // ========== REFRESH METHODS ==========

  Future<void> refreshAllData() async {
    _analyticsService.clearCache();
    _clearData();
    await loadAllAnalytics();
  }

  Future<void> refreshLiveHourlyTrend() async {
    _analyticsService.clearCache();
    await loadLiveHourlyTrend();
  }

  Future<void> refreshDailyTrend() async {
    _analyticsService.clearCache();
    await loadDailyTrend30Days();
  }

  Future<void> refreshWeeklyHeatmap() async {
    _analyticsService.clearCache();
    await loadWeeklyHeatmap();
  }

  Future<void> refreshLocationStats() async {
    _analyticsService.clearCache();
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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== COMPUTED PROPERTIES ==========

  /// Get total passengers today
  int get totalPassengersToday {
    if (_liveHourlyTrend == null) return 0;
    return _liveHourlyTrend!.values.fold(0, (sum, count) => sum + count);
  }

  /// Get peak hour today
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

  /// Get busiest waypoint
  WaypointPassengerStats? get busiestWaypoint {
    if (_locationStats == null || _locationStats!.isEmpty) return null;
    return _locationStats!.first; // Already sorted by activity
  }

  /// Get most preferred bus type
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

  /// Get busiest month
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

  /// Get trend data based on selected time period
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

    // Use the currently displayed heatmap data
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
