import 'dart:async';
import 'package:flutter/material.dart';
import 'waypoint_model.dart';
import 'waypoint_service.dart';

/// Waypoint Provider
/// Manages waypoint state with real-time streaming
class WaypointProvider with ChangeNotifier {
  final WaypointService _waypointService = WaypointService();

  // State
  List<WaypointModel> _waypoints = [];
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';
  String _currentAdminId = '';

  // Stream subscription
  StreamSubscription<List<WaypointModel>>? _waypointsSubscription;

  // Filters
  String _searchQuery = '';

  // Getters
  List<WaypointModel> get waypoints => _waypoints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCompanyId => _currentCompanyId;
  String get currentAdminId => _currentAdminId;
  String get searchQuery => _searchQuery;

  @override
  void dispose() {
    _waypointsSubscription?.cancel();
    super.dispose();
  }

  /// Get filtered waypoints based on search query
  List<WaypointModel> get filteredWaypoints {
    if (_searchQuery.isEmpty) return _waypoints;

    final query = _searchQuery.toLowerCase();
    return _waypoints.where((waypoint) {
      return waypoint.name.toLowerCase().contains(query) ||
          (waypoint.description?.toLowerCase().contains(query) ?? false) ||
          (waypoint.address?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Get waypoint statistics
  Map<String, int> get stats {
    return {
      'total': _waypoints.length,
      'with_description': _waypoints
          .where((w) => w.description != null && w.description!.isNotEmpty)
          .length,
      'with_address': _waypoints
          .where((w) => w.address != null && w.address!.isNotEmpty)
          .length,
    };
  }

  /// Set current company ID and admin ID
  void setCompanyAndAdmin(String companyId, String adminId) {
    print('🔧 WaypointProvider.setCompanyAndAdmin called');
    print('   Company ID: $companyId');
    print('   Admin ID: $adminId');

    if (_currentCompanyId == companyId && _currentAdminId == adminId) {
      print('   ⚠️ IDs unchanged, skipping initialization');
      return;
    }

    _currentCompanyId = companyId;
    _currentAdminId = adminId;

    print('   ✅ IDs updated, cancelling previous subscription');
    _waypointsSubscription?.cancel();

    print('   📡 Starting new real-time subscription');
    _startRealtimeListener();

    notifyListeners();
  }

  /// Start real-time listener for waypoint updates
  void _startRealtimeListener() {
    if (_currentCompanyId.isEmpty) {
      print('❌ Cannot start listener: Company ID is empty');
      return;
    }

    print('🎧 Starting real-time listener for company: $_currentCompanyId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    _waypointsSubscription = _waypointService
        .getWaypointsStream(_currentCompanyId)
        .listen(
          (waypoints) {
            print(
              '✅ WaypointProvider received ${waypoints.length} waypoints from stream',
            );
            _waypoints = waypoints;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            print('❌ WaypointProvider stream error: $error');
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Manual refresh
  Future<void> loadWaypoints() async {
    if (_currentCompanyId.isEmpty) {
      _error = 'Company ID not set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _waypoints = await _waypointService.getWaypoints(_currentCompanyId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new waypoint
  Future<String?> createWaypoint(WaypointModel waypoint) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final waypointId = await _waypointService.createWaypoint(
        waypoint.copyWith(createdByAdmin: _currentAdminId),
      );

      _isLoading = false;
      notifyListeners();
      return waypointId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update a waypoint
  Future<bool> updateWaypoint(String waypointId, WaypointModel waypoint) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _waypointService.updateWaypoint(
        waypointId,
        waypoint.copyWith(updatedByAdmin: _currentAdminId),
      );

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

  /// Delete a waypoint
  Future<bool> deleteWaypoint(String waypointId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _waypointService.deleteWaypoint(waypointId);

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

  /// Reorder waypoints
  Future<bool> reorderWaypoints(List<String> waypointIds) async {
    try {
      await _waypointService.reorderWaypoints(waypointIds, _currentAdminId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get waypoint by ID
  Future<WaypointModel?> getWaypointById(String waypointId) async {
    try {
      return await _waypointService.getWaypointById(waypointId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get waypoints by IDs
  Future<List<WaypointModel>> getWaypointsByIds(
    List<String> waypointIds,
  ) async {
    try {
      return await _waypointService.getWaypointsByIds(waypointIds);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Search waypoints
  Future<List<WaypointModel>> searchWaypoints(String query) async {
    try {
      return await _waypointService.searchWaypoints(_currentCompanyId, query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Check if waypoint name exists
  Future<bool> waypointNameExists(String name) async {
    try {
      return await _waypointService.waypointNameExists(_currentCompanyId, name);
    } catch (e) {
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
