import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_log_model.dart';
import 'activity_log_service.dart';

/// Activity Log Provider with pagination and filtering
class ActivityLogProvider with ChangeNotifier {
  final ActivityLogService _service = ActivityLogService();

  // State
  List<ActivityLog> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  DocumentSnapshot? _lastDocument;

  // Filters
  String _selectedCategory = 'All Categories';
  String _selectedRiskLevel = 'All Risk Levels';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Current company context
  String _companyId = '';

  // Getters
  List<ActivityLog> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get selectedRiskLevel => _selectedRiskLevel;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  /// Set company ID
  void setCompanyId(String companyId) {
    if (_companyId == companyId) return;
    
    _companyId = companyId;
    _logs.clear();
    _lastDocument = null;
    _hasMore = true;
    
    loadLogs();
  }

  /// Get filtered logs (client-side filtering)
  List<ActivityLog> get filteredLogs {
    return _logs.where((log) {
      // Category filter
      if (_selectedCategory != 'All Categories') {
        if (log.category != _selectedCategory.toLowerCase().replaceAll(' ', '_')) {
          return false;
        }
      }

      // Risk level filter
      if (_selectedRiskLevel != 'All Risk Levels') {
        if (log.riskLevel != _selectedRiskLevel.toLowerCase()) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return log.readableAction.toLowerCase().contains(query) ||
            log.readableDescription.toLowerCase().contains(query) ||
            log.userName.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  /// Get activity statistics
  Map<String, int> get stats {
    final filtered = filteredLogs;
    
    return {
      'total': filtered.length,
      'authentication': filtered.where((l) => l.category == ActivityCategory.authentication).length,
      'user_actions': filtered.where((l) => l.category == ActivityCategory.userActions).length,
      'business': filtered.where((l) => l.category == ActivityCategory.business).length,
      'errors': filtered.where((l) => l.category == ActivityCategory.errors).length,
      'critical': filtered.where((l) => l.riskLevel == RiskLevel.critical).length,
      'high_risk': filtered.where((l) => l.riskLevel == RiskLevel.high).length,
      'medium_risk': filtered.where((l) => l.riskLevel == RiskLevel.medium).length,
      'low_risk': filtered.where((l) => l.riskLevel == RiskLevel.low).length,
    };
  }

  /// Load initial logs
  Future<void> loadLogs() async {
    if (_companyId.isEmpty) {
      print('⚠️ Cannot load logs: Company ID is empty');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 Loading activity logs for company: $_companyId');
      
      final fetchedLogs = await _service.getActivityLogs(
        companyId: _companyId,
        category: _selectedCategory != 'All Categories' 
            ? _selectedCategory.toLowerCase().replaceAll(' ', '_')
            : null,
        startDate: _startDate,
        endDate: _endDate,
        limit: 50,
      );

      print('✅ Received ${fetchedLogs.length} logs');

      _logs = fetchedLogs;
      _hasMore = fetchedLogs.length == 50;
      
      if (fetchedLogs.isNotEmpty) {
        _lastDocument = await _getLastDocument();
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading logs: $e');
      _error = 'Unable to load activity logs. Please check your internet connection.';
      _isLoading = false;
      _logs = []; // Clear logs on error
      notifyListeners();
    }
  }

  /// Load more logs (pagination)
  Future<void> loadMoreLogs() async {
    if (_isLoading || !_hasMore || _companyId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final fetchedLogs = await _service.getActivityLogs(
        companyId: _companyId,
        category: _selectedCategory != 'All Categories'
            ? _selectedCategory.toLowerCase().replaceAll(' ', '_')
            : null,
        startDate: _startDate,
        endDate: _endDate,
        limit: 50,
        lastDocument: _lastDocument,
      );

      _logs.addAll(fetchedLogs);
      _hasMore = fetchedLogs.length == 50;

      if (fetchedLogs.isNotEmpty) {
        _lastDocument = await _getLastDocument();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get last document for pagination
  Future<DocumentSnapshot?> _getLastDocument() async {
    if (_logs.isEmpty) return null;
    
    try {
      final lastLog = _logs.last;
      final doc = await FirebaseFirestore.instance
          .collection('global_audit_logs')
          .doc(lastLog.id)
          .get();
      return doc;
    } catch (e) {
      print('Error getting last document: $e');
      return null;
    }
  }

  /// Set category filter
  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _logs.clear();
    _lastDocument = null;
    _hasMore = true;
    loadLogs();
  }

  /// Set risk level filter
  void setRiskLevelFilter(String riskLevel) {
    _selectedRiskLevel = riskLevel;
    notifyListeners();
  }

  /// Set search query (client-side filtering)
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set date range
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _logs.clear();
    _lastDocument = null;
    _hasMore = true;
    loadLogs();
  }

  /// Clear filters
  void clearFilters() {
    _selectedCategory = 'All Categories';
    _selectedRiskLevel = 'All Risk Levels';
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _logs.clear();
    _lastDocument = null;
    _hasMore = true;
    loadLogs();
  }

  /// Export logs (for downloading)
  Future<List<ActivityLog>> exportLogs() async {
    if (_companyId.isEmpty) return [];

    try {
      return await _service.getActivityLogs(
        companyId: _companyId,
        startDate: _startDate,
        endDate: _endDate,
        limit: 1000, // Export up to 1000 logs
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}