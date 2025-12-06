import 'dart:async';
import 'package:flutter/material.dart';
import 'account_model.dart';
import 'account_service.dart';

class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();

  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _error;
  String _currentCompanyId = '';
  String _currentAdminId = '';

  StreamSubscription<List<Account>>? _accountsSubscription;

  String _selectedRole = 'All Roles';
  String _selectedAvailability = 'All Availability';
  String _searchQuery = '';

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

  List<Account> get filteredAccounts {
    return _accounts.where((account) {
      if (_selectedRole != 'All Roles') {
        if (account.roleDisplayName != _selectedRole) {
          return false;
        }
      }

      if (_selectedAvailability != 'All Availability') {
        if (account.availabilityDisplayName != _selectedAvailability) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return account.name.toLowerCase().contains(query) ||
            account.username.toLowerCase().contains(query) ||
            account.phoneNumber.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

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

  void setCompanyAndAdmin(String companyId, String adminId) {
    if (_currentCompanyId == companyId && _currentAdminId == adminId) {
      return;
    }

    _currentCompanyId = companyId;
    _currentAdminId = adminId;

    _accountsSubscription?.cancel();

    _startRealtimeListener();

    notifyListeners();
  }

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

  void setRoleFilter(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setAvailabilityFilter(String availability) {
    _selectedAvailability = availability;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedRole = 'All Roles';
    _selectedAvailability = 'All Availability';
    _searchQuery = '';
    notifyListeners();
  }

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

  Future<String?> createAccount(Account account, String plainPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final accountId = await _accountService.createAccount(
        account.copyWith(createdByAdmin: _currentAdminId),
        plainPassword,
      );

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

  Future<bool> deleteAccount(String accountId, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.deleteAccount(accountId, role);

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

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

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

  Future<Account?> getAccountById(String accountId, String role) async {
    try {
      return await _accountService.getAccountById(accountId, role);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
