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
  String _currentAdminId = '';
  StreamSubscription<List<Bus>>? _busesSubscription;

  String _selectedStatus = 'All Status';
  String _selectedRoute = 'All Routes';
  String _searchQuery = '';

  List<Bus> get buses => _buses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCompanyId => _currentCompanyId;
  String get currentAdminId => _currentAdminId;
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

  /// Set current company ID and admin ID, then start listening
  void setCompanyAndAdmin(String companyId, String adminId) {
    print('🔧 BusProvider.setCompanyAndAdmin called');
    print('   Company ID: $companyId');
    print('   Admin ID: $adminId');
    print('   Current Company ID: $_currentCompanyId');

    if (_currentCompanyId == companyId && _currentAdminId == adminId) {
      print('   ⚠️ IDs unchanged, skipping initialization');
      return;
    }

    _currentCompanyId = companyId;
    _currentAdminId = adminId;

    print('   ✅ IDs updated, cancelling previous subscription');
    _busesSubscription?.cancel();

    print('   📡 Starting new real-time subscription');
    _startRealtimeListener();

    notifyListeners();
  }

  @Deprecated('Use setCompanyAndAdmin instead')
  void setCompanyId(String companyId) {
    setCompanyAndAdmin(companyId, '');
  }

  /// checks for bus updates
  void _startRealtimeListener() {
    if (_currentCompanyId.isEmpty) {
      print('❌ Cannot start listener: Company ID is empty');
      return;
    }

    print('🎧 Starting real-time listener for company: $_currentCompanyId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    _busesSubscription = _busService
        .getBusesStream(_currentCompanyId)
        .listen(
          (buses) {
            print('✅ BusProvider received ${buses.length} buses from stream');
            _buses = buses;
            _isLoading = false;
            _error = null;
            notifyListeners();
            print(
              '   Buses in provider: ${_buses.map((b) => b.plateNumber).join(", ")}',
            );
          },
          onError: (error) {
            print('❌ BusProvider stream error: $error');
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

  // ========== OPTIMIZED CRUD OPERATIONS ==========

  Future<String?> createBus(Bus bus) async {
    // Keep loading state for create operations
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
    // ⭐ FIX: Don't set loading state - real-time listener will update UI
    // This prevents the table from reloading
    _error = null;

    try {
      await _busService.updateBus(busId, bus);
      // Real-time listener will automatically update the UI
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBus(String busId) async {
    // Keep loading state for delete operations
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

  /// Update bus status - optimized for real-time updates
  Future<bool> updateBusStatus(String busId, String status) async {
    // ⭐ FIX: Don't set loading state
    _error = null;

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

  /// Update bus passenger count - optimized
  Future<bool> updatePassengerCount(String busId, int count) async {
    // ⭐ FIX: Don't set loading state
    _error = null;

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

  /// Assign driver to bus - optimized
  Future<bool> assignDriver(String busId, String driverId) async {
    _error = null;

    try {
      await _busService.assignDriver(busId, driverId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign conductor to bus - optimized
  Future<bool> assignConductor(String busId, String conductorId) async {
    _error = null;

    try {
      await _busService.assignConductor(busId, conductorId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign route to bus - optimized
  Future<bool> assignRoute(String busId, String routeId) async {
    _error = null;

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
