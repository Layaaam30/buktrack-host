import 'package:flutter/material.dart';
import 'dashboard_analytics_service.dart';

/// Dashboard Analytics Provider
/// Manages analytics data state
class DashboardAnalyticsProvider with ChangeNotifier {
  final DashboardAnalyticsService _analyticsService =
      DashboardAnalyticsService();

  // State
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';

  // Analytics data
  Map<int, int>? _hourlyTrend;
  Map<String, int>? _weeklyTrend;
  List<WaypointPassengerData>? _routeDistribution;
  Map<String, double>? _busTypeOccupancy;
  Map<String, dynamic>? _dashboardSummary;

  // Selected route for distribution view
  String? _selectedRouteId;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<int, int>? get hourlyTrend => _hourlyTrend;
  Map<String, int>? get weeklyTrend => _weeklyTrend;
  List<WaypointPassengerData>? get routeDistribution => _routeDistribution;
  Map<String, double>? get busTypeOccupancy => _busTypeOccupancy;
  Map<String, dynamic>? get dashboardSummary => _dashboardSummary;
  String? get selectedRouteId => _selectedRouteId;

  /// Initialize with company ID
  void setCompanyId(String companyId) {
    if (_currentCompanyId == companyId) return;

    _currentCompanyId = companyId;
    _clearData();
    notifyListeners();
  }

  /// Clear all data
  void _clearData() {
    _hourlyTrend = null;
    _weeklyTrend = null;
    _routeDistribution = null;
    _busTypeOccupancy = null;
    _dashboardSummary = null;
    _error = null;
  }

  /// Load all analytics data progressively
  /// This loads data in priority order to show something quickly
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
      // Load summary first (fastest - uses count queries)
      await loadDashboardSummary();

      // Load hourly trend (second priority - today's data only)
      await loadHourlyTrend();

      // Load weekly trend (third priority - 7 days)
      await loadWeeklyTrend();

      // Load bus type occupancy (fourth priority - 30 days aggregation)
      await loadBusTypeOccupancy();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load dashboard summary statistics
  Future<void> loadDashboardSummary() async {
    try {
      _dashboardSummary = await _analyticsService.getDashboardSummary(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading dashboard summary: $e');
      // Don't throw - allow other data to load
    }
  }

  /// Load hourly passenger trend
  Future<void> loadHourlyTrend() async {
    try {
      _hourlyTrend = await _analyticsService.getDailyPassengerTrendByHour(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading hourly trend: $e');
      // Don't throw - allow other data to load
    }
  }

  /// Load weekly passenger trend
  Future<void> loadWeeklyTrend() async {
    try {
      _weeklyTrend = await _analyticsService.getWeeklyPassengerTrendByDay(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading weekly trend: $e');
      // Don't throw - allow other data to load
    }
  }

  /// Load route passenger distribution
  Future<void> loadRouteDistribution(String routeId) async {
    _selectedRouteId = routeId;
    notifyListeners();

    try {
      _routeDistribution = await _analyticsService
          .getRoutePassengerDistribution(routeId, _currentCompanyId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load route distribution: $e';
      notifyListeners();
    }
  }

  /// Load bus type average occupancy
  Future<void> loadBusTypeOccupancy() async {
    try {
      _busTypeOccupancy = await _analyticsService.getBusTypeAverageOccupancy(
        _currentCompanyId,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading bus type occupancy: $e');
      // Don't throw - allow other data to load
    }
  }

  /// Refresh all data (clears cache)
  Future<void> refreshAllData() async {
    _analyticsService.clearCache();
    _clearData();
    await loadAllAnalytics();
  }

  /// Refresh specific data
  Future<void> refreshHourlyTrend() async {
    _analyticsService.clearCache();
    await loadHourlyTrend();
  }

  Future<void> refreshWeeklyTrend() async {
    _analyticsService.clearCache();
    await loadWeeklyTrend();
  }

  Future<void> refreshRouteDistribution() async {
    if (_selectedRouteId != null) {
      _analyticsService.clearCache();
      await loadRouteDistribution(_selectedRouteId!);
    }
  }

  Future<void> refreshBusTypeOccupancy() async {
    _analyticsService.clearCache();
    await loadBusTypeOccupancy();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get peak hour from hourly trend
  int? get peakHour {
    if (_hourlyTrend == null || _hourlyTrend!.isEmpty) return null;

    int maxHour = 0;
    int maxCount = 0;

    for (var entry in _hourlyTrend!.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxHour = entry.key;
      }
    }

    return maxHour;
  }

  /// Get peak day from weekly trend
  String? get peakDay {
    if (_weeklyTrend == null || _weeklyTrend!.isEmpty) return null;

    String maxDay = '';
    int maxCount = 0;

    for (var entry in _weeklyTrend!.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxDay = entry.key;
      }
    }

    return maxDay;
  }

  /// Get total passengers today
  int get totalPassengersToday {
    if (_hourlyTrend == null) return 0;
    return _hourlyTrend!.values.fold(0, (sum, count) => sum + count);
  }

  /// Get total passengers this week
  int get totalPassengersThisWeek {
    if (_weeklyTrend == null) return 0;
    return _weeklyTrend!.values.fold(0, (sum, count) => sum + count);
  }

  /// Get busiest waypoint
  WaypointPassengerData? get busiestWaypoint {
    if (_routeDistribution == null || _routeDistribution!.isEmpty) return null;

    WaypointPassengerData? busiest;
    int maxActivity = 0;

    for (var waypoint in _routeDistribution!) {
      final activity = waypoint.boardingCount + waypoint.alightingCount;
      if (activity > maxActivity) {
        maxActivity = activity;
        busiest = waypoint;
      }
    }

    return busiest;
  }

  /// Get most efficient bus type (highest occupancy)
  String? get mostEfficientBusType {
    if (_busTypeOccupancy == null || _busTypeOccupancy!.isEmpty) return null;

    String maxType = '';
    double maxOccupancy = 0.0;

    for (var entry in _busTypeOccupancy!.entries) {
      if (entry.value > maxOccupancy) {
        maxOccupancy = entry.value;
        maxType = entry.key;
      }
    }

    return maxType;
  }
}
