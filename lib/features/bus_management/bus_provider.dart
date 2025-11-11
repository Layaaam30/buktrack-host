import 'dart:async';
import 'package:flutter/material.dart';
import 'bus_model.dart';
import 'bus_service.dart';

/// Optimized Bus Provider with real-time streaming
class BusProvider with ChangeNotifier {
  final BusService _busService = BusService();

  // State
  List<Bus> _buses = [];
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';

  // Stream subscription for real-time updates
  StreamSubscription<List<Bus>>? _busesSubscription;

  // Filters
  String _selectedStatus = 'All Status';
  String _selectedRoute = 'All Routes';
  String _searchQuery = '';

  // Getters
  List<Bus> get buses => _buses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCompanyId => _currentCompanyId;
  String get selectedStatus => _selectedStatus;
  String get selectedRoute => _selectedRoute;
  String get searchQuery => _searchQuery;

  @override
  void dispose() {
    _busesSubscription?.cancel();
    super.dispose();
  }

  /// Get filtered buses based on current filters (optimized client-side)
  List<Bus> get filteredBuses {
    return _buses.where((bus) {
      // Status filter
      if (_selectedStatus != 'All Status') {
        if (bus.status.toLowerCase() !=
            _selectedStatus.toLowerCase().replaceAll(' ', '')) {
          return false;
        }
      }

      // Route filter
      if (_selectedRoute != 'All Routes' && bus.routeName != _selectedRoute) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return bus.plateNumber.toLowerCase().contains(query) ||
            (bus.driverName?.toLowerCase().contains(query) ?? false) ||
            (bus.conductorName?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  /// Get bus statistics (computed from cached data)
  Map<String, int> get stats {
    return {
      'total': _buses.length,
      'active': _buses.where((b) => b.status == 'active').length,
      'inactive': _buses.where((b) => b.status == 'inactive').length,
      'maintenance': _buses.where((b) => b.status == 'maintenance').length,
      'standby': _buses.where((b) => b.status == 'standby').length,
      'delayed': _buses.where((b) => b.status == 'delayed').length,
    };
  }

  /// Set current company ID and start listening to updates
  void setCompanyId(String companyId) {
    if (_currentCompanyId == companyId) return; // Avoid redundant calls

    _currentCompanyId = companyId;

    // Cancel previous subscription
    _busesSubscription?.cancel();

    // Start new real-time subscription
    _startRealtimeListener();

    notifyListeners();
  }

  /// Start real-time listener for bus updates
  void _startRealtimeListener() {
    if (_currentCompanyId.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _busesSubscription = _busService
        .getBusesStream(_currentCompanyId)
        .listen(
          (buses) {
            _buses = buses;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
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

  /// Set route filter
  void setRouteFilter(String route) {
    _selectedRoute = route;
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
    _selectedRoute = 'All Routes';
    _searchQuery = '';
    notifyListeners();
  }

  /// Manual refresh (force fetch from server)
  Future<void> loadBuses() async {
    if (_currentCompanyId.isEmpty) {
      _error = 'Company ID not set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _buses = await _busService.getBuses(_currentCompanyId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new bus
  Future<String?> createBus(Bus bus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final busId = await _busService.createBus(bus);

      // Real-time listener will automatically update the list
      _isLoading = false;
      notifyListeners();
      return busId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update a bus
  Future<bool> updateBus(String busId, Bus bus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _busService.updateBus(busId, bus);

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

  /// Delete a bus
  Future<bool> deleteBus(String busId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _busService.deleteBus(busId);

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

  /// Update bus status (optimized - only updates one field)
  Future<bool> updateBusStatus(String busId, String status) async {
    try {
      await _busService.updateBusStatus(busId, status);

      // Real-time listener will update the UI automatically
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update bus passenger count
  Future<bool> updatePassengerCount(String busId, int count) async {
    try {
      await _busService.updatePassengerCount(busId, count);

      // Real-time listener will update the UI automatically
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign driver to bus
  Future<bool> assignDriver(String busId, String driverId) async {
    try {
      await _busService.assignDriver(busId, driverId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign conductor to bus
  Future<bool> assignConductor(String busId, String conductorId) async {
    try {
      await _busService.assignConductor(busId, conductorId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign route to bus
  Future<bool> assignRoute(String busId, String routeId) async {
    try {
      await _busService.assignRoute(busId, routeId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get bus by ID
  Future<Bus?> getBusById(String busId) async {
    try {
      return await _busService.getBusById(busId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Batch update bus status
  Future<bool> batchUpdateStatus(List<String> busIds, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _busService.batchUpdateStatus(busIds, status);

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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
