import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../auth/auth_provider.dart';
import 'account_provider.dart';
import 'account_dialog.dart';
import 'account_model.dart';
import '../../../shared/widgets/common/confirmation_dialog.dart';

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

      final companyId = authProvider.companyId;
      final adminId = authProvider.adminId;

      print('🔧 Initializing Account Management...');
      print('   Company ID: $companyId');
      print('   Admin ID: $adminId');

      if (companyId != null && adminId != null) {
        print('✅ Setting up account provider');
        accountProvider.setCompanyAndAdmin(companyId, adminId);
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

  Future<void> _handleUpdateAvailability(Account account) async {
    final availabilityOptions = [
      'available',
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
      }
    }
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
              // Header
              _buildEnhancedHeader(isDark, isMobile),
              const SizedBox(height: AppSizes.xxl),

              // Stats Cards
              _buildStatsCards(isDark, accountProvider),
              const SizedBox(height: AppSizes.xxl),

              // Filters Section
              _buildFiltersSection(isDark, accountProvider, isMobile),
              const SizedBox(height: AppSizes.xxl),

              // Accounts Table
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
            _buildStatCard(
              'Total Accounts',
              stats['total'].toString(),
              Icons.people_rounded,
              AppColors.info,
              isDark,
            ),
            _buildStatCard(
              'Available',
              stats['available'].toString(),
              Icons.check_circle_rounded,
              AppColors.success,
              isDark,
            ),
            _buildStatCard(
              'In Transit',
              stats['in_transit'].toString(),
              Icons.directions_bus_rounded,
              AppColors.warning,
              isDark,
            ),
            _buildStatCard(
              'On Leave',
              stats['on_leave'].toString(),
              Icons.beach_access_rounded,
              AppColors.error,
              isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXs,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: AppSizes.fontSize2xl,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          // Filters Header
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

          // Filter Controls
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

  Widget _buildHeaderCell(String label, bool isDark, {required int flex}) {
    const cellHPad = 12.0;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: cellHPad),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _buildHeaderLabel(label, isDark),
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
                _buildHeaderCell('NAME', isDark, flex: 2),
                _buildHeaderCell('', isDark, flex: 1),
                _buildHeaderCell('USERNAME', isDark, flex: 2),
                _buildHeaderCell('PHONE', isDark, flex: 2),
                _buildHeaderCell('ROLE', isDark, flex: 2),
                _buildHeaderCell('AVAILABILITY', isDark, flex: 2),
                _buildHeaderCell('ASSIGNED BUS', isDark, flex: 2),
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

          ...accountProvider.filteredAccounts.asMap().entries.map((entry) {
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
        fontWeight: FontWeight.w600,
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
            child: _buildAvailabilityBadge(account.availabilityStatus, isDark),
          ),

          // ASSIGNED BUS
          cell(
            flex: 2,
            child: _buildAssignmentBadge(account.isAssigned, isDark),
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

  Widget _buildAssignmentBadge(bool isAssigned, bool isDark) {
    if (isAssigned) {
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
              'Assigned',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF065f46),
              ),
            ),
          ],
        ),
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
          value: 'availability',
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: AppColors.success),
              const SizedBox(width: AppSizes.md),
              const Text('Update Availability'),
            ],
          ),
        ),
        if (account.isAssigned)
          PopupMenuItem(
            value: 'unassign',
            child: Row(
              children: [
                Icon(Icons.link_off, size: 18, color: AppColors.warning),
                const SizedBox(width: AppSizes.md),
                const Text('Unassign'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: AppSizes.md),
              const Text('Delete'),
            ],
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
                      _buildAvailabilityBadge(
                        account.availabilityStatus,
                        isDark,
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
                      _buildAssignmentBadge(account.isAssigned, isDark),
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
