import 'dart:async';
import 'package:flutter/material.dart';
import 'account_model.dart';
import 'account_service.dart';

/// Account Provider with real-time streaming and filtering
class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();

  // State
  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';
  String _currentAdminId = '';

  // Stream subscription for real-time updates
  StreamSubscription<List<Account>>? _accountsSubscription;

  // Filters
  String _selectedRole = 'All Roles';
  String _selectedAvailability = 'All Availability';
  String _searchQuery = '';

  // Getters
  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCompanyId => _currentCompanyId;
  String get currentAdminId => _currentAdminId;
  String get selectedRole => _selectedRole;
  String get selectedAvailability => _selectedAvailability;
  String get searchQuery => _searchQuery;

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    super.dispose();
  }

  /// Get filtered accounts based on current filters
  List<Account> get filteredAccounts {
    return _accounts.where((account) {
      // Role filter
      if (_selectedRole != 'All Roles') {
        if (account.roleDisplayName != _selectedRole) {
          return false;
        }
      }

      // Availability filter
      if (_selectedAvailability != 'All Availability') {
        if (account.availabilityDisplayName != _selectedAvailability) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return account.name.toLowerCase().contains(query) ||
            account.username.toLowerCase().contains(query) ||
            account.phoneNumber.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  /// Get account statistics
  Map<String, int> get stats {
    return {
      'total': _accounts.length,
      'drivers': _accounts.where((a) => a.role == 'driver').length,
      'conductors': _accounts.where((a) => a.role == 'conductor').length,
      'available': _accounts
          .where((a) => a.availabilityStatus == 'available')
          .length,
      'in_transit': _accounts
          .where((a) => a.availabilityStatus == 'in_transit')
          .length,
      'on_leave': _accounts
          .where((a) => a.availabilityStatus == 'on_leave')
          .length,
      'unavailable': _accounts
          .where((a) => a.availabilityStatus == 'unavailable')
          .length,
      'assigned': _accounts.where((a) => a.isAssigned).length,
      'active': _accounts.where((a) => a.isActive).length,
    };
  }

  /// Set current company ID and admin ID, then start listening
  void setCompanyAndAdmin(String companyId, String adminId) {
    if (_currentCompanyId == companyId && _currentAdminId == adminId) {
      return; // Avoid redundant calls
    }

    _currentCompanyId = companyId;
    _currentAdminId = adminId;

    // Cancel previous subscription
    _accountsSubscription?.cancel();

    // Start new real-time subscription
    _startRealtimeListener();

    notifyListeners();
  }

  /// Start real-time listener for account updates
  void _startRealtimeListener() {
    if (_currentCompanyId.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _accountsSubscription = _accountService
        .getAccountsStream(_currentCompanyId)
        .listen(
          (accounts) {
            _accounts = accounts;
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

  /// Set role filter
  void setRoleFilter(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  /// Set availability filter
  void setAvailabilityFilter(String availability) {
    _selectedAvailability = availability;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedRole = 'All Roles';
    _selectedAvailability = 'All Availability';
    _searchQuery = '';
    notifyListeners();
  }

  /// Manual refresh (force fetch from server)
  Future<void> loadAccounts() async {
    if (_currentCompanyId.isEmpty) {
      _error = 'Company ID not set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _accountService.getAccounts(_currentCompanyId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new account
  Future<String?> createAccount(Account account, String plainPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final accountId = await _accountService.createAccount(
        account.copyWith(createdByAdmin: _currentAdminId),
        plainPassword,
      );

      // Real-time listener will automatically update the list
      _isLoading = false;
      notifyListeners();
      return accountId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update an account
  Future<bool> updateAccount(
    String accountId,
    String role,
    Account account,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.updateAccount(accountId, role, account);

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

  /// Delete an account
  Future<bool> deleteAccount(String accountId, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.deleteAccount(accountId, role);

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

  /// Update availability status
  Future<bool> updateAvailabilityStatus(
    String accountId,
    String role,
    String status,
  ) async {
    try {
      await _accountService.updateAvailabilityStatus(
        accountId,
        role,
        status,
        _currentAdminId,
      );

      // Real-time listener will update the UI automatically
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Set leave for an account
  Future<bool> setLeave(
    String accountId,
    String role,
    DateTime startDate,
    DateTime endDate,
    String reason,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.setLeave(
        accountId,
        role,
        startDate,
        endDate,
        reason,
        _currentAdminId,
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

  /// Clear leave for an account
  Future<bool> clearLeave(String accountId, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.clearLeave(accountId, role, _currentAdminId);

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

  /// Assign account to bus
  Future<bool> assignToBus(String accountId, String role, String busId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.assignToBus(
        accountId,
        role,
        busId,
        _currentAdminId,
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

  /// Unassign account from bus
  Future<bool> unassignFromBus(String accountId, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.unassignFromBus(accountId, role, _currentAdminId);

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

  /// Update password
  Future<bool> updatePassword(
    String accountId,
    String role,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.updatePassword(accountId, role, newPassword);

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

  /// Activate or deactivate account
  Future<bool> setActiveStatus(
    String accountId,
    String role,
    bool isActive,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.setActiveStatus(
        accountId,
        role,
        isActive,
        _currentAdminId,
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

  /// Get account by ID
  Future<Account?> getAccountById(String accountId, String role) async {
    try {
      return await _accountService.getAccountById(accountId, role);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get available accounts for assignment
  Future<List<Account>> getAvailableAccounts(String role) async {
    try {
      return await _accountService.getAvailableAccounts(
        _currentCompanyId,
        role,
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
}
