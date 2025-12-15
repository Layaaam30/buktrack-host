import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../auth/auth_provider.dart';
import 'account_provider.dart';
import 'account_dialog.dart';
import 'account_model.dart';
import 'bus_assignment_dialog.dart';

import '../../../../shared/widgets/common/stat_card.dart';
import '../../../../shared/widgets/common/confirmation_dialog.dart';

import '../bus_management/bus_provider.dart';

import 'package:tabler_icons/tabler_icons.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

// class _AccountManagementScreenState extends State<AccountManagementScreen> {
class _AccountManagementScreenState extends State<AccountManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  String _sortColumn = 'name';
  bool _sortAscending = true;
  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _bounceController.repeat(reverse: true);
    _initializeProvider();
  }

  void _initializeProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final busProvider = Provider.of<BusProvider>(context, listen: false);

      final companyId = authProvider.companyId;
      final adminId = authProvider.adminId;

      if (companyId != null && adminId != null) {
        print('✅ Setting up account provider');
        accountProvider.setCompanyAndAdmin(companyId, adminId);

        print('✅ Setting up bus provider');
        busProvider.setCompanyAndAdmin(companyId, adminId);
      } else {
        print('❌ ERROR: Company ID or Admin ID not found!');
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  bool get hasFilters {
    final provider = Provider.of<AccountProvider>(context, listen: false);
    return provider.searchQuery.isNotEmpty ||
        provider.selectedRole != 'All Roles' ||
        provider.selectedAvailability != 'All Availability';
  }

  void _resetFilters() {
    Provider.of<AccountProvider>(context, listen: false).clearFilters();
  }

  Future<void> _showAddDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AccountDialog(
        companyId: authProvider.companyId!,
        adminId: authProvider.adminId!,
      ),
    );

    if (result != null && mounted) {
      final account = result['account'] as Account;
      final password = result['password'] as String;

      final success = await accountProvider.createAccount(account, password);

      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (accountProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accountProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(Account account) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AccountDialog(
        account: account,
        companyId: authProvider.companyId!,
        adminId: authProvider.adminId!,
      ),
    );

    if (result != null && mounted) {
      final updatedAccount = result['account'] as Account;

      final success = await accountProvider.updateAccount(
        account.id,
        account.role,
        updatedAccount,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Delete Account',
        message:
            'Are you sure you want to delete this account? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        icon: Icons.delete_outline,
        iconColor: AppColors.error,
        isDangerous: true,
      ),
    );

    if (confirmed == true && mounted) {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final success = await accountProvider.deleteAccount(
        account.id,
        account.role,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (accountProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accountProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleUnassign(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Unassign from Bus',
        message: 'Are you sure you want to unassign this account from the bus?',
        confirmText: 'Unassign',
        cancelText: 'Cancel',
        icon: Icons.link_off,
        iconColor: AppColors.warning,
        isDangerous: false,
      ),
    );

    if (confirmed == true && mounted) {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final success = await accountProvider.unassignFromBus(
        account.id,
        account.role,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account unassigned successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleBusAssignment(Account account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BusAssignmentDialog(account: account),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            account.isAssigned
                ? 'Bus reassigned successfully'
                : 'Bus assigned successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleUpdateAvailability(Account account) async {
    final availabilityOptions = [
      'available',
      'standby',
      'in_transit',
      'on_leave',
      'unavailable',
    ];

    String current = account.availabilityStatus;

    String? selected = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Update Availability - ${account.name}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFFFA94D),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFFFFA94D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Availability Status *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: current,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => current = value);
                                },
                                items: availabilityOptions.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(_formatAvailability(status)),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Note: "In Transit" status is automatically set when assigned to a bus',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1),

                    // Footer buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.borderDark
                                    : const Color(0xFFD1D5DB),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFad47ff), Color(0xFF9911fb)],
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pop(current),
                              icon: const Icon(
                                TablerIcons.calendar_time,
                                color: Colors.white,
                              ),
                              label: const Text('Update Availability'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      try {
        final success = await accountProvider.updateAvailabilityStatus(
          account.id,
          account.role,
          selected,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Availability updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (!success && mounted) {
          // Show user-friendly error from provider
          final errorMessage =
              accountProvider.error ?? 'Failed to update availability';
          _showErrorDialog(errorMessage);
        }
      } catch (e) {
        if (mounted) {
          // Extract user-friendly message from exception
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring('Exception: '.length);
          }
          _showErrorDialog(errorMessage);
        }
      }
    }
  }

  /// Show user-friendly error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Cannot Update Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAvailability(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'in_transit':
        return 'In Transit';
      case 'on_leave':
        return 'On Leave';
      case 'unavailable':
        return 'Unavailable';
      default:
        return status;
    }
  }

  List<Account> _getSortedAccounts(List<Account> accounts) {
    final sorted = List<Account>.from(accounts);

    switch (_sortColumn) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'username':
        sorted.sort((a, b) => a.username.compareTo(b.username));
        break;
      case 'phone':
        sorted.sort((a, b) => a.phoneNumber.compareTo(b.phoneNumber));
        break;
      case 'role':
        sorted.sort((a, b) => a.role.compareTo(b.role));
        break;
      case 'availability':
        sorted.sort(
          (a, b) => a.availabilityStatus.compareTo(b.availabilityStatus),
        );
        break;
      case 'assigned':
        sorted.sort(
          (a, b) => (a.isAssigned ? 1 : 0).compareTo(b.isAssigned ? 1 : 0),
        );
        break;
    }

    if (!_sortAscending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  void _handleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnhancedHeader(isDark, isMobile),
              const SizedBox(height: AppSizes.xxl),

              _buildStatsCards(isDark, accountProvider),
              const SizedBox(height: AppSizes.xxl),

              _buildFiltersSection(isDark, accountProvider, isMobile),
              const SizedBox(height: AppSizes.xxl),

              if (accountProvider.isLoading)
                _buildLoadingState(isDark)
              else if (accountProvider.error != null)
                _buildErrorState(isDark, accountProvider)
              else if (accountProvider.filteredAccounts.isEmpty)
                _buildEmptyState(isDark)
              else
                _buildAccountsTable(isDark, isMobile, accountProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedAccountIcon() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(TablerIcons.users, color: Colors.white, size: 32),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: const LinearGradient(
          colors: [Color(0xFFad47ff), Color(0xFF7A07CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAnimatedAccountIcon(),
                          const SizedBox(width: AppSizes.lg),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Management',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Text(
                        'Manage drivers and conductors, track availability, and assign personnel\nto buses for efficient fleet operations.',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: const Color(0xFFfef3e3),
                          height: 1.6,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: AppSizes.xl),
                  _buildActionButton(),
                ],
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: AppSizes.xl),
              SizedBox(width: double.infinity, child: _buildActionButton()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: _showAddDialog,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFe9d5ff),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(Icons.add, color: Color(0xFF9911fb), size: 20),
      ),
      label: const Text(
        'Add Account',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF9911fb),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildStatsCards(bool isDark, AccountProvider accountProvider) {
    final stats = accountProvider.stats;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < AppSizes.mobileBreakpoint) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < AppSizes.desktopBreakpoint) {
          crossAxisCount = 2;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.xl,
          mainAxisSpacing: AppSizes.xl,
          childAspectRatio: 2.5,
          children: [
            StatCard(
              title: 'Total Accounts',
              value: stats['total'].toString(),
              icon: TablerIcons.users,
              color: const Color(0xFF7A07CD),
            ),
            StatCard(
              title: 'Available',
              value: stats['available'].toString(),
              icon: TablerIcons.check,
              color: AppColors.success,
            ),
            StatCard(
              title: 'In Transit',
              value: stats['in_transit'].toString(),
              icon: TablerIcons.bus,
              color: AppColors.info,
            ),
            StatCard(
              title: 'On Leave',
              value: stats['on_leave'].toString(),
              icon: TablerIcons.calendar_off,
              color: const Color(0xFFf59e0b),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersSection(
    bool isDark,
    AccountProvider accountProvider,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFad47ff), Color(0xFF9911fb)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeLg,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Refine your account view',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),

          if (isMobile)
            Column(
              children: [
                _buildFilterDropdown(
                  'Role',
                  accountProvider.selectedRole,
                  ['All Roles', 'Driver', 'Conductor'],
                  accountProvider.setRoleFilter,
                  isDark,
                ),
                const SizedBox(height: AppSizes.lg),
                _buildFilterDropdown(
                  'Availability',
                  accountProvider.selectedAvailability,
                  [
                    'All Availability',
                    'Available',
                    'In Transit',
                    'On Leave',
                    'Unavailable',
                  ],
                  accountProvider.setAvailabilityFilter,
                  isDark,
                ),
                const SizedBox(height: AppSizes.lg),
                _buildSearchField(isDark, accountProvider),
                if (hasFilters) ...[
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(width: double.infinity, child: _buildClearButton()),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    'Role',
                    accountProvider.selectedRole,
                    ['All Roles', 'Driver', 'Conductor'],
                    accountProvider.setRoleFilter,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSizes.lg),
                Expanded(
                  child: _buildFilterDropdown(
                    'Availability',
                    accountProvider.selectedAvailability,
                    [
                      'All Availability',
                      'Available',
                      'In Transit',
                      'On Leave',
                      'Unavailable',
                    ],
                    accountProvider.setAvailabilityFilter,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSizes.lg),
                Expanded(child: _buildSearchField(isDark, accountProvider)),
                if (hasFilters) ...[
                  const SizedBox(width: AppSizes.lg),
                  _buildClearButton(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String) onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(bool isDark, AccountProvider accountProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: TextField(
            onChanged: accountProvider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search accounts...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                fontSize: AppSizes.fontSizeSm,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
            ),
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClearButton() {
    return ElevatedButton.icon(
      onPressed: _resetFilters,
      icon: const Icon(Icons.close, size: 20),
      label: const Text('Clear'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.md + 2,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxl * 2),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Loading accounts...',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, AccountProvider accountProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxl * 2),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Failed to load accounts',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                accountProvider.error ?? 'Unknown error',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: accountProvider.loadAccounts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxl * 2),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'No accounts found',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Get started by adding your first account',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    String column,
    bool isDark, {
    required int flex,
  }) {
    const cellHPad = 12.0;
    final isActive = _sortColumn == column;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: cellHPad),
        child: InkWell(
          onTap: () => _handleSort(column),
          borderRadius: BorderRadius.circular(4),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isActive
                          ? const Color(0xFF9333EA)
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF6b7280)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isActive
                        ? (_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)
                        : Icons.unfold_more,
                    size: 14,
                    color: isActive
                        ? const Color(0xFF9333EA)
                        : (isDark
                              ? AppColors.textSecondaryDark.withOpacity(0.5)
                              : const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTable(
    bool isDark,
    bool isMobile,
    AccountProvider accountProvider,
  ) {
    if (isMobile) {
      return Column(
        children: accountProvider.filteredAccounts
            .map((account) => _buildMobileAccountCard(account, isDark))
            .toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : const Color(0xFFe5e7eb),
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.lg,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFf9fafb),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLg),
                topRight: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeaderCell('NAME', 'name', isDark, flex: 3),
                // _buildHeaderCell('', '', isDark, flex: 1),
                _buildHeaderCell('USERNAME', 'username', isDark, flex: 2),
                _buildHeaderCell('PHONE', 'phone', isDark, flex: 2),
                _buildHeaderCell('ROLE', 'role', isDark, flex: 2),
                _buildHeaderCell(
                  'AVAILABILITY',
                  'availability',
                  isDark,
                  flex: 2,
                ),
                _buildHeaderCell('ASSIGNED BUS', 'assigned', isDark, flex: 2),
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildHeaderLabel('ACTION', isDark),
                  ),
                ),
              ],
            ),
          ),

          ..._getSortedAccounts(
            accountProvider.filteredAccounts,
          ).asMap().entries.map((entry) {
            return _buildTableRow(
              entry.value,
              isDark,
              entry.key == accountProvider.filteredAccounts.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeaderLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6b7280),
      ),
    );
  }

  Widget _buildTableRow(Account account, bool isDark, bool isLast) {
    const cellHPad = 12.0;

    Widget cell({required int flex, required Widget child}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: cellHPad),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.lg,
      ),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFe5e7eb),
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // NAME
          cell(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF9333EA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        account.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.lastLoginTimestamp != null
                            ? 'Last login: ${_formatLastLogin(account.lastLoginTimestamp!)}'
                            : 'Never logged in',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // USERNAME
          cell(
            flex: 2,
            child: Text(
              account.username.length > 15
                  ? '${account.username.substring(0, 12)}...'
                  : account.username,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF374151),
              ),
            ),
          ),

          // PHONE
          cell(
            flex: 2,
            child: Text(
              account.phoneNumber,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF374151),
              ),
            ),
          ),

          // ROLE
          cell(flex: 2, child: _buildRoleBadge(account.role, isDark)),

          // AVAILABILITY
          cell(
            flex: 2,
            child:
                account
                    .isAssigned // ✅ Check if assigned to bus
                ? MouseRegion(
                    cursor: SystemMouseCursors.forbidden,
                    child: Tooltip(
                      message: account.availabilityStatus == 'in_transit'
                          ? 'Cannot change status during active trip'
                          : 'Cannot change status while assigned to bus',
                      child: Opacity(
                        opacity: 0.6,
                        child: _buildAvailabilityBadge(
                          account.availabilityStatus,
                          isDark,
                        ),
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () => _handleUpdateAvailability(account),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Tooltip(
                        message: 'Click to update availability',
                        child: _buildAvailabilityBadge(
                          account.availabilityStatus,
                          isDark,
                        ),
                      ),
                    ),
                  ),
          ),

          // ASSIGNED BUS
          cell(
            flex: 2,
            child: account.availabilityStatus == 'in_transit'
                ? MouseRegion(
                    cursor: SystemMouseCursors.forbidden,
                    child: Tooltip(
                      message: 'Cannot modify assignment during active trip',
                      child: Opacity(
                        opacity: 0.6,
                        child: _buildAssignmentBadge(account, isDark),
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () => _handleBusAssignment(account),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Tooltip(
                        message: account.isAssigned
                            ? 'Click to change bus assignment'
                            : 'Click to assign to a bus',
                        child: _buildAssignmentBadge(account, isDark),
                      ),
                    ),
                  ),
          ),

          // ACTION
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionsMenu(account),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastLogin(DateTime lastLogin) {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildRoleBadge(String role, bool isDark) {
    final bool isDriver = role.toLowerCase() == 'driver';

    final Color bgColor = isDriver
        ? const Color(0xFFE0F2FF)
        : const Color(0xFFF3E8FF);

    final Color fgColor = isDriver
        ? const Color(0xFF2563EB)
        : const Color(0xFF9333EA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Text(
            isDriver ? 'driver' : 'conductor',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(String status, bool isDark) {
    Color bgColor, textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'available':
        bgColor = const Color(0xFFd1fae5);
        textColor = const Color(0xFF065f46);
        icon = Icons.check_circle;
        label = 'Available';
        break;
      case 'standby':
        bgColor = const Color(0xFFfef3c7); // Light yellow/amber
        textColor = const Color(0xFFb45309); // Amber-700
        icon = Icons.timelapse; // Clock/waiting icon
        label = 'Standby';
        break;
      case 'in_transit':
        bgColor = const Color(0xFFdbeafe);
        textColor = const Color(0xFF1e40af);
        icon = Icons.directions_bus;
        label = 'In Transit';
        break;
      case 'on_leave':
        bgColor = const Color(0xFFfef3c7);
        textColor = const Color(0xFF92400e);
        icon = Icons.beach_access;
        label = 'On Leave';
        break;
      case 'unavailable':
        bgColor = const Color(0xFFfee2e2);
        textColor = const Color(0xFF991b1b);
        icon = Icons.cancel;
        label = 'Unavailable';
        break;
      default:
        bgColor = const Color(0xFFf3f4f6);
        textColor = const Color(0xFF374151);
        icon = Icons.help;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor, fontWeight: FontWeight.bold),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentBadge(Account account, bool isDark) {
    if (account.isAssigned) {
      return Consumer<BusProvider>(
        builder: (context, busProvider, child) {
          // Find the bus this account is assigned to
          final assignedBus = busProvider.buses.firstWhere(
            (bus) => bus.id == account.assignedBusId,
            orElse: () =>
                busProvider.buses.first, // Fallback (shouldn't happen)
          );

          final plateNumber = assignedBus.plateNumber;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFd1fae5),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_bus,
                  size: 14,
                  color: Color(0xFF065f46),
                ),
                const SizedBox(width: 6),
                Text(
                  plateNumber.isNotEmpty ? plateNumber : 'Assigned',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065f46),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.hoverDark : const Color(0xFFf3f4f6),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        'Unassigned',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6b7280),
        ),
      ),
    );
  }

  Widget _buildActionsMenu(Account account) {
    final bool isAssigned = account.isAssigned; // Assigned to a bus
    final bool isInTransit = account.availabilityStatus == 'in_transit';
    final bool isStandby = account.availabilityStatus == 'standby';
    final bool canChangeStatus =
        !isAssigned; // Can only change status when not assigned

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: AppColors.info),
              const SizedBox(width: AppSizes.md),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: canChangeStatus
              ? 'availability'
              : null, // ✅ Disable when assigned
          enabled: canChangeStatus,
          child: Tooltip(
            message: isInTransit
                ? 'Cannot change status during active trip'
                : isStandby
                ? 'Cannot change status while assigned to bus'
                : 'Update availability status',
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: canChangeStatus ? AppColors.success : Colors.grey,
                ),
                const SizedBox(width: AppSizes.md),
                Text(
                  'Update Availability',
                  style: TextStyle(color: canChangeStatus ? null : Colors.grey),
                ),
                if (!canChangeStatus) ...[
                  const SizedBox(width: AppSizes.sm),
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                ],
              ],
            ),
          ),
        ),
        if (account.isAssigned)
          PopupMenuItem(
            value: isInTransit ? null : 'unassign', // ✅ Disable when in transit
            enabled: !isInTransit,
            child: Tooltip(
              message: isInTransit
                  ? 'Cannot unassign during active trip'
                  : 'Unassign from bus',
              child: Row(
                children: [
                  Icon(
                    Icons.link_off,
                    size: 18,
                    color: isInTransit ? Colors.grey : AppColors.warning,
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    'Unassign',
                    style: TextStyle(color: isInTransit ? Colors.grey : null),
                  ),
                  if (isInTransit) ...[
                    const SizedBox(width: AppSizes.sm),
                    Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  ],
                ],
              ),
            ),
          ),
        PopupMenuItem(
          value: isInTransit
              ? null
              : 'delete', // ✅ Disable delete during transit too
          enabled: !isInTransit,
          child: Tooltip(
            message: isInTransit
                ? 'Cannot delete during active trip'
                : 'Delete account',
            child: Row(
              children: [
                Icon(
                  Icons.delete_rounded,
                  size: 18,
                  color: isInTransit ? Colors.grey : AppColors.error,
                ),
                const SizedBox(width: AppSizes.md),
                Text(
                  'Delete',
                  style: TextStyle(color: isInTransit ? Colors.grey : null),
                ),
                if (isInTransit) ...[
                  const SizedBox(width: AppSizes.sm),
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                ],
              ],
            ),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditDialog(account);
            break;
          case 'availability':
            _handleUpdateAvailability(account);
            break;
          case 'unassign':
            _handleUnassign(account);
            break;
          case 'delete':
            _handleDelete(account);
            break;
        }
      },
    );
  }

  Widget _buildMobileAccountCard(Account account, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf3e8ff),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF9333ea),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMd,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        account.username,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(account.role, isDark),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeXs,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      account
                              .isAssigned // ✅ Check if assigned to bus
                          ? Tooltip(
                              message:
                                  account.availabilityStatus == 'in_transit'
                                  ? 'Cannot change status during active trip'
                                  : 'Cannot change status while assigned to bus',
                              child: Opacity(
                                opacity: 0.6,
                                child: _buildAvailabilityBadge(
                                  account.availabilityStatus,
                                  isDark,
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: () => _handleUpdateAvailability(account),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                              child: _buildAvailabilityBadge(
                                account.availabilityStatus,
                                isDark,
                              ),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assignment',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeXs,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      account.availabilityStatus == 'in_transit'
                          ? Tooltip(
                              message:
                                  'Cannot modify assignment during active trip',
                              child: Opacity(
                                opacity: 0.6,
                                child: _buildAssignmentBadge(account, isDark),
                              ),
                            )
                          : InkWell(
                              onTap: () => _handleBusAssignment(account),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                              child: _buildAssignmentBadge(account, isDark),
                            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(account),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.info),
                ),
                TextButton.icon(
                  onPressed: () => _handleDelete(account),
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
