import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../auth/auth_provider.dart';
import 'route_provider.dart';
import 'route_dialog.dart';
import 'route_model.dart';
import '../../../shared/widgets/common/confirmation_dialog.dart';
import 'package:tabler_icons/tabler_icons.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen>
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
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);

      final companyId = authProvider.companyId;
      final adminId = authProvider.adminId;

      print('🔧 Initializing Route Management...');
      print('   Company ID: $companyId');
      print('   Admin ID: $adminId');

      if (companyId != null && adminId != null) {
        print('✅ Setting up route provider');
        routeProvider.setCompanyAndAdmin(companyId, adminId);
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
    final provider = Provider.of<RouteProvider>(context, listen: false);
    return provider.searchQuery.isNotEmpty ||
        provider.selectedStatus != 'All Status';
  }

  void _resetFilters() {
    Provider.of<RouteProvider>(context, listen: false).clearFilters();
  }

  Future<void> _showAddDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    final suggestedCode = await routeProvider.generateNextRouteCode();

    if (!mounted) return;

    final result = await showDialog<RouteModel>(
      context: context,
      builder: (context) => RouteDialog(
        companyId: authProvider.companyId!,
        adminId: authProvider.adminId!,
        suggestedRouteCode: suggestedCode,
      ),
    );

    if (result != null && mounted) {
      final routeCode = await routeProvider.generateNextRouteCode();
      final routeWithCode = result.copyWith(routeCode: routeCode);

      print('🎯 Creating route with auto-generated code: $routeCode');

      final success = await routeProvider.createRoute(routeWithCode);

      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route created successfully with code: $routeCode'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (routeProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(routeProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(RouteModel route) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    final result = await showDialog<RouteModel>(
      context: context,
      builder: (context) => RouteDialog(
        route: route,
        companyId: authProvider.companyId!,
        adminId: authProvider.adminId!,
      ),
    );

    if (result != null && mounted) {
      final success = await routeProvider.updateRoute(route.id, result);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(RouteModel route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Delete Route',
        message:
            'Are you sure you want to delete this route? All assigned buses will be unassigned.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        icon: Icons.delete_outline,
        iconColor: AppColors.error,
        isDangerous: true,
      ),
    );

    if (confirmed == true && mounted) {
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      final success = await routeProvider.deleteRoute(route.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (routeProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(routeProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleStatus(RouteModel route) async {
    final newStatus = !route.isActive;
    final action = newStatus ? 'activate' : 'deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: '${action == 'activate' ? 'Activate' : 'Deactivate'} Route',
        message:
            'Are you sure you want to $action this route? ${!newStatus ? 'Assigned buses may be affected.' : ''}',
        confirmText: action == 'activate' ? 'Activate' : 'Deactivate',
        cancelText: 'Cancel',
        icon: newStatus ? Icons.check_circle_outline : Icons.cancel_outlined,
        iconColor: newStatus ? AppColors.success : AppColors.warning,
        isDangerous: !newStatus,
      ),
    );

    if (confirmed == true && mounted) {
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      final success = await routeProvider.toggleRouteStatus(
        route.id,
        newStatus,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route ${newStatus ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildEnhancedHeader(isDark, isMobile),
              const SizedBox(height: AppSizes.xxl),

              // Stats Cards
              _buildStatsCards(isDark, routeProvider),
              const SizedBox(height: AppSizes.xxl),

              // Filters Section
              _buildFiltersSection(isDark, routeProvider, isMobile),
              const SizedBox(height: AppSizes.xxl),

              // Routes Table
              if (routeProvider.isLoading)
                _buildLoadingState(isDark)
              else if (routeProvider.error != null)
                _buildErrorState(isDark, routeProvider)
              else if (routeProvider.filteredRoutes.isEmpty)
                _buildEmptyState(isDark)
              else
                _buildRoutesTable(isDark, isMobile, routeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedRouteIcon() {
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
            child: const Icon(TablerIcons.route, color: Colors.white, size: 32),
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
          colors: [Color(0xFF10b981), Color(0xFF059669)],
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
                          _buildAnimatedRouteIcon(),
                          const SizedBox(width: AppSizes.lg),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Route Management',
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
                        'Create and manage bus routes, define stops and schedules, and\noptimize your fleet\'s operational efficiency.',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: const Color(0xFFd1fae5),
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
          color: const Color(0xFFd1fae5),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(Icons.add, color: Color(0xFF059669), size: 20),
      ),
      label: const Text(
        'Add Route',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF059669),
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

  Widget _buildStatsCards(bool isDark, RouteProvider routeProvider) {
    final stats = routeProvider.stats;

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
              'Total Routes',
              stats['total'].toString(),
              Icons.route_rounded,
              AppColors.info,
              isDark,
            ),
            _buildStatCard(
              'Active',
              stats['active'].toString(),
              Icons.check_circle_rounded,
              AppColors.success,
              isDark,
            ),
            _buildStatCard(
              'Inactive',
              stats['inactive'].toString(),
              Icons.cancel_rounded,
              AppColors.error,
              isDark,
            ),
            _buildStatCard(
              'With Buses',
              stats['with_buses'].toString(),
              Icons.directions_bus_rounded,
              AppColors.warning,
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
    RouteProvider routeProvider,
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
                    colors: [Color(0xFF10b981), Color(0xFF059669)],
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
                    'Refine your route view',
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
                  'Status',
                  routeProvider.selectedStatus,
                  ['All Status', 'Active', 'Inactive'],
                  routeProvider.setStatusFilter,
                  isDark,
                ),
                const SizedBox(height: AppSizes.lg),
                _buildSearchField(isDark, routeProvider),
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
                    'Status',
                    routeProvider.selectedStatus,
                    ['All Status', 'Active', 'Inactive'],
                    routeProvider.setStatusFilter,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSizes.lg),
                Expanded(
                  flex: 2,
                  child: _buildSearchField(isDark, routeProvider),
                ),
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

  Widget _buildSearchField(bool isDark, RouteProvider routeProvider) {
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
            onChanged: routeProvider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search routes...',
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
              CircularProgressIndicator(color: AppColors.success),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Loading routes...',
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

  Widget _buildErrorState(bool isDark, RouteProvider routeProvider) {
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
                'Failed to load routes',
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
                routeProvider.error ?? 'Unknown error',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: () {
                  // Reload routes logic
                },
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
                Icons.route_outlined,
                size: 64,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'No routes found',
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
                'Get started by adding your first route',
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
                label: const Text('Add Route'),
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

  Widget _buildRoutesTable(
    bool isDark,
    bool isMobile,
    RouteProvider routeProvider,
  ) {
    if (isMobile) {
      return Column(
        children: routeProvider.filteredRoutes
            .map((route) => _buildMobileRouteCard(route, isDark))
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
                _buildHeaderCell('ROUTE', isDark, flex: 2),
                _buildHeaderCell('', isDark, flex: 1),
                _buildHeaderCell('ORIGIN -> DESTINATION', isDark, flex: 3),
                _buildHeaderCell('TRAVEL TIME', isDark, flex: 2),
                _buildHeaderCell('ASSIGNED BUSES', isDark, flex: 2),
                _buildHeaderCell('STATUS', isDark, flex: 2),
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

          // Table Body
          ...routeProvider.filteredRoutes.asMap().entries.map((entry) {
            return _buildTableRow(
              entry.value,
              isDark,
              entry.key == routeProvider.filteredRoutes.length - 1,
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

  Widget _buildTableRow(RouteModel route, bool isDark, bool isLast) {
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
          // ROUTE INFO
          cell(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFd1fae5),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: Color(0xFF065f46),
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
                        route.routeName,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.hoverDark
                              : const Color(0xFFf3f4f6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          route.routeCode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF6b7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ORIGIN -> DESTINATION
          cell(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      route.originName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      route.destinationName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (route.waypointCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${route.waypointCount} stop${route.waypointCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : const Color(0xFF9ca3af),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // TRAVEL TIME
          cell(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF6b7280),
                ),
                const SizedBox(width: 6),
                Text(
                  '${route.estimatedTravelTime} min',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),

          // ASSIGNED BUSES
          cell(
            flex: 2,
            child: _buildAssignedBusesBadge(route.assignedBuses.length, isDark),
          ),

          // STATUS
          cell(flex: 2, child: _buildStatusBadge(route.isActive, isDark)),

          // ACTIONS
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionsMenu(route),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedBusesBadge(int count, bool isDark) {
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.hoverDark : const Color(0xFFf3f4f6),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF6b7280),
            ),
            const SizedBox(width: 6),
            Text(
              'No buses',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF6b7280),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFdbeafe),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_bus, size: 14, color: Color(0xFF1e40af)),
          const SizedBox(width: 6),
          Text(
            '$count bus${count != 1 ? 'es' : ''}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1e40af),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFd1fae5)
            : isDark
            ? const Color(0xFF7f1d1d)
            : const Color(0xFFfee2e2),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? const Color(0xFF065f46) : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF065f46) : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(RouteModel route) {
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
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                route.isActive
                    ? Icons.cancel_outlined
                    : Icons.check_circle_outline,
                size: 18,
                color: route.isActive ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: AppSizes.md),
              Text(route.isActive ? 'Deactivate' : 'Activate'),
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
            _showEditDialog(route);
            break;
          case 'toggle':
            _handleToggleStatus(route);
            break;
          case 'delete':
            _handleDelete(route);
            break;
        }
      },
    );
  }

  Widget _buildMobileRouteCard(RouteModel route, bool isDark) {
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
                    color: const Color(0xFFd1fae5),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: Color(0xFF065f46),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.routeName,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMd,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        route.routeCode,
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
                _buildStatusBadge(route.isActive, isDark),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.originName,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    route.destinationName,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.lg,
              runSpacing: AppSizes.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${route.estimatedTravelTime} min',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${route.assignedBuses.length} buses',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                if (route.waypointCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route.waypointCount} stops',
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
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(route),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.info),
                ),
                TextButton.icon(
                  onPressed: () => _handleDelete(route),
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
