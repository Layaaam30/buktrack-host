import 'dart:async';
import 'package:flutter/material.dart';
import 'bus_model.dart';
import 'bus_service.dart';

/// Optimized Bus Provider with timely streaming
class BusProvider with ChangeNotifier {
  final BusService _busService = BusService();

  List<Bus> _buses = [];
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';
  StreamSubscription<List<Bus>>? _busesSubscription;

  String _selectedStatus = 'All Status';
  String _selectedRoute = 'All Routes';
  String _searchQuery = '';

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

  /// get filtered buses based on current filters
  List<Bus> get filteredBuses {
    return _buses.where((bus) {
      if (_selectedStatus != 'All Status') {
        if (bus.status.toLowerCase() !=
            _selectedStatus.toLowerCase().replaceAll(' ', '')) {
          return false;
        }
      }

      if (_selectedRoute != 'All Routes' && bus.routeName != _selectedRoute) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return bus.plateNumber.toLowerCase().contains(query) ||
            (bus.driverName?.toLowerCase().contains(query) ?? false) ||
            (bus.conductorName?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  /// Get bus statistics
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

  /// Set current company ID and start check updates
  void setCompanyId(String companyId) {
    if (_currentCompanyId == companyId) return;
    _currentCompanyId = companyId;
    _busesSubscription?.cancel();
    _startRealtimeListener();
    notifyListeners();
  }

  /// checks for bus upadtes
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

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setRouteFilter(String route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedStatus = 'All Status';
    _selectedRoute = 'All Routes';
    _searchQuery = '';
    notifyListeners();
  }

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



// ========== IMPLMEENTS CRUD OPERATIONS FOR BUS ==========

  Future<String?> createBus(Bus bus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final busId = await _busService.createBus(bus);
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

  Future<bool> updateBus(String busId, Bus bus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _busService.updateBus(busId, bus);
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

  Future<bool> deleteBus(String busId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _busService.deleteBus(busId);
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

  /// Update bus status 
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
