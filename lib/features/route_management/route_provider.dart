import 'dart:async';
import 'package:flutter/material.dart';
import 'route_model.dart';
import 'route_service.dart';

/// Route Provider with real-time streaming and filtering
class RouteProvider with ChangeNotifier {
  final RouteService _routeService = RouteService();

  // State
  List<RouteModel> _routes = [];
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';
  String _currentAdminId = '';

  // Stream subscription for real-time updates
  StreamSubscription<List<RouteModel>>? _routesSubscription;

  // Filters
  String _selectedStatus = 'All Status';
  String _searchQuery = '';

  // Getters
  List<RouteModel> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCompanyId => _currentCompanyId;
  String get currentAdminId => _currentAdminId;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  @override
  void dispose() {
    _routesSubscription?.cancel();
    super.dispose();
  }

  /// Get filtered routes based on current filters
  List<RouteModel> get filteredRoutes {
    return _routes.where((route) {
      // Status filter
      if (_selectedStatus == 'Active') {
        if (!route.isActive) return false;
      } else if (_selectedStatus == 'Inactive') {
        if (route.isActive) return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return route.routeName.toLowerCase().contains(query) ||
            route.routeCode.toLowerCase().contains(query) ||
            route.originName.toLowerCase().contains(query) ||
            route.destinationName.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  /// Get route statistics
  Map<String, int> get stats {
    return {
      'total': _routes.length,
      'active': _routes.where((r) => r.isActive).length,
      'inactive': _routes.where((r) => !r.isActive).length,
      'with_buses': _routes.where((r) => r.hasAssignedBuses).length,
      'without_buses': _routes.where((r) => !r.hasAssignedBuses).length,
    };
  }

  /// Set current company ID and admin ID, then start listening
  void setCompanyAndAdmin(String companyId, String adminId) {
    print('🔧 RouteProvider.setCompanyAndAdmin called');
    print('   Company ID: $companyId');
    print('   Admin ID: $adminId');
    print('   Current Company ID: $_currentCompanyId');

    if (_currentCompanyId == companyId && _currentAdminId == adminId) {
      print('   ⚠️ IDs unchanged, skipping initialization');
      return; // Avoid redundant calls
    }

    _currentCompanyId = companyId;
    _currentAdminId = adminId;

    print('   ✅ IDs updated, cancelling previous subscription');
    // Cancel previous subscription
    _routesSubscription?.cancel();

    // Start new real-time subscription
    print('   📡 Starting new real-time subscription');
    _startRealtimeListener();

    notifyListeners();
  }

  /// Start real-time listener for route updates
  void _startRealtimeListener() {
    if (_currentCompanyId.isEmpty) {
      print('❌ Cannot start listener: Company ID is empty');
      return;
    }

    print('🎧 Starting real-time listener for company: $_currentCompanyId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    _routesSubscription = _routeService
        .getRoutesStream(_currentCompanyId)
        .listen(
          (routes) {
            print(
              '✅ RouteProvider received ${routes.length} routes from stream',
            );
            _routes = routes;
            _isLoading = false;
            _error = null;
            notifyListeners();
            print(
              '   Routes in provider: ${_routes.map((r) => r.routeName).join(", ")}',
            );
          },
          onError: (error) {
            print('❌ RouteProvider stream error: $error');
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Set status filter
  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedStatus = 'All Status';
    _searchQuery = '';
    notifyListeners();
  }

  /// Check if filters are active
  bool get hasFilters {
    return _searchQuery.isNotEmpty || _selectedStatus != 'All Status';
  }

  /// Manual refresh (force fetch from server)
  Future<void> loadRoutes() async {
    if (_currentCompanyId.isEmpty) {
      _error = 'Company ID not set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routes = await _routeService.getRoutes(_currentCompanyId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new route
  Future<String?> createRoute(RouteModel route) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final routeId = await _routeService.createRoute(
        route.copyWith(createdByAdmin: _currentAdminId),
      );

      // Real-time listener will automatically update the list
      _isLoading = false;
      notifyListeners();
      return routeId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update a route
  Future<bool> updateRoute(String routeId, RouteModel route) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _routeService.updateRoute(
        routeId,
        route.copyWith(updatedByAdmin: _currentAdminId),
      );

      // Real-time listener will automatically update the list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a route
  Future<bool> deleteRoute(String routeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _routeService.deleteRoute(routeId);

      // Real-time listener will automatically update the list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle route status
  Future<bool> toggleRouteStatus(String routeId, bool isActive) async {
    try {
      await _routeService.toggleRouteStatus(routeId, isActive, _currentAdminId);

      // Real-time listener will update the UI automatically
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign buses to route
  Future<bool> assignBuses(String routeId, List<String> busIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _routeService.assignBusesToRoute(routeId, busIds, _currentAdminId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get route by ID
  Future<RouteModel?> getRouteById(String routeId) async {
    try {
      return await _routeService.getRouteById(routeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get active routes
  Future<List<RouteModel>> getActiveRoutes() async {
    try {
      return await _routeService.getActiveRoutes(_currentCompanyId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Generate next route code
  Future<String> generateNextRouteCode() async {
    try {
      return await _routeService.generateNextRouteCode(_currentCompanyId);
    } catch (e) {
      return 'RT001';
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
