import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../auth/auth_provider.dart';
import 'bus_model.dart';
import 'bus_provider.dart';
import 'bus_dialog.dart';
import '../../shared/widgets/common/confirmation_dialog.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

// class _BusManagementScreenState extends State<BusManagementScreen> {
class _BusManagementScreenState extends State<BusManagementScreen>
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBusManagement();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _initializeBusManagement() {
    final authProvider = context.read<AuthProvider>();
    final busProvider = context.read<BusProvider>();

    final companyId = authProvider.companyId;

    print('🔧 Initializing Bus Management...');
    print('   Auth State: ${authProvider.isAuthenticated}');
    print('   Company ID: $companyId');
    print('   Admin ID: ${authProvider.adminId}');
    print('   Admin Name: ${authProvider.adminName}');

    if (companyId != null && companyId.isNotEmpty) {
      print('✅ Setting up bus provider for company: $companyId');
      busProvider.setCompanyId(companyId);
    } else {
      print('❌ ERROR: Company ID not found!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load company data. Please try logging in again.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  /// Show Add Bus Dialog
  Future<void> _showAddBusDialog() async {
    final authProvider = context.read<AuthProvider>();
    final busProvider = context.read<BusProvider>();

    final companyId = authProvider.companyId;

    if (companyId == null || companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company ID not available. Please log in again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await showDialog<Bus>(
      context: context,
      builder: (context) => BusDialog(companyId: companyId),
    );

    if (result != null && mounted) {
      final busId = await busProvider.createBus(result);

      if (busId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus "${result.plateNumber}" added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted && busProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bus: ${busProvider.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show Edit Bus Dialog
  Future<void> _showEditBusDialog(Bus bus) async {
    final authProvider = context.read<AuthProvider>();
    final busProvider = context.read<BusProvider>();

    final companyId = authProvider.companyId;

    if (companyId == null || companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company ID not available. Please log in again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await showDialog<Bus>(
      context: context,
      builder: (context) => BusDialog(bus: bus, companyId: companyId),
    );

    if (result != null && mounted) {
      final success = await busProvider.updateBus(bus.id, result);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus "${result.plateNumber}" updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted && busProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update bus: ${busProvider.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show Delete Confirmation Dialog
  Future<void> _showDeleteConfirmation(Bus bus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Bus',
        message:
            'Are you sure you want to delete "${bus.plateNumber}"? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        icon: Icons.delete_rounded,
        iconColor: AppColors.error,
        isDangerous: true,
      ),
    );

    if (confirmed == true && mounted) {
      final busProvider = context.read<BusProvider>();
      final success = await busProvider.deleteBus(bus.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus "${bus.plateNumber}" deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted && busProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete bus: ${busProvider.error}'),
            backgroundColor: AppColors.error,
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

    return Consumer<BusProvider>(
      builder: (context, busProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Orange Header Banner
              _buildEnhancedHeader(isDark, isMobile),
              const SizedBox(height: AppSizes.xxl),

              // Stats Cards
              _buildStatsCards(isDark, busProvider),
              const SizedBox(height: AppSizes.xxl),

              // Filters Section
              _buildFiltersSection(isDark, busProvider),
              const SizedBox(height: AppSizes.xxl),

              // Bus Fleet Table/List
              if (busProvider.isLoading)
                _buildLoadingState(isDark)
              else if (busProvider.error != null)
                _buildErrorState(isDark, busProvider)
              else if (busProvider.filteredBuses.isEmpty)
                _buildEmptyState(isDark)
              else
                _buildBusFleetTable(isDark, isMobile, busProvider),

              const SizedBox(height: AppSizes.xxl),
            ],
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
          colors: [Color(0xFFff6700), Color(0xFFcc3600)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
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
                              _buildAnimatedBusIcon(),
                              const SizedBox(width: AppSizes.lg),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bus Management',
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
                            'Monitor your entire fleet in real-time, track maintenance schedules, and\noptimize routes for maximum efficiency.',
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
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: _showAddBusDialog,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFfed7aa),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(TablerIcons.plus, color: Color(0xFFea580c), size: 20),
      ),
      label: const Text(
        'Add New Bus',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFea580c),
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

  Widget _buildAnimatedBusIcon() {
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
            child: const Icon(TablerIcons.bus, color: Colors.white, size: 32),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(bool isDark, BusProvider busProvider) {
    final stats = busProvider.stats;

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
              'Total Buses',
              stats['total'].toString(),
              TablerIcons.bus,
              AppColors.info,
              isDark,
            ),
            _buildStatCard(
              'Active',
              stats['active'].toString(),
              TablerIcons.circle_check,
              AppColors.success,
              isDark,
            ),
            _buildStatCard(
              'Maintenance',
              stats['maintenance'].toString(),
              TablerIcons.tools,
              AppColors.warning,
              isDark,
            ),
            _buildStatCard(
              'Inactive',
              stats['inactive'].toString(),
              TablerIcons.circle_x,
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

  Widget _buildFiltersSection(bool isDark, BusProvider busProvider) {
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
                    colors: [Color(0xFFf97316), Color(0xFFea580c)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFf97316).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  TablerIcons.filter,
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
                    'Refine your fleet view',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < AppSizes.tabletBreakpoint;

              if (isMobile) {
                return Column(
                  children: [
                    _buildStatusFilterControl('Status', isDark, busProvider),
                    const SizedBox(height: AppSizes.lg),
                    _buildSearchControl('Search', isDark, busProvider),
                    const SizedBox(height: AppSizes.lg),
                    // SizedBox(width: double.infinity, child: _buildAddButton2()),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildStatusFilterControl(
                      'Status',
                      isDark,
                      busProvider,
                    ),
                  ),
                  // const SizedBox(width: AppSizes.lg),
                  // Expanded(
                  //   child: _buildControl('Search', isDark, busProvider),
                  // ),
                  const SizedBox(width: AppSizes.lg),
                  Expanded(
                    child: _buildSearchControl('Search', isDark, busProvider),
                  ),
                  const SizedBox(width: AppSizes.lg),
                  // _buildAddButton2(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterControl(
    String label,
    bool isDark,
    BusProvider busProvider,
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
              value: busProvider.selectedStatus,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: ['All Status', 'Active', 'Inactive', 'Maintenance'].map((
                String item,
              ) {
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
                if (value != null) {
                  busProvider.setStatusFilter(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchControl(
    String label,
    bool isDark,
    BusProvider busProvider,
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
          child: TextField(
            onChanged: busProvider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search buses...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                fontSize: AppSizes.fontSizeSm,
              ),
              prefixIcon: Icon(
                TablerIcons.search,
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

  // Widget _buildAddButton2() {
  //   return ElevatedButton.icon(
  //     onPressed: _showAddBusDialog,
  //     icon: const Icon(TablerIcons.plus, size: 20),
  //     label: const Text('Add Bus'),
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: const Color(0xFFf97316),
  //       foregroundColor: Colors.white,
  //       padding: const EdgeInsets.symmetric(
  //         horizontal: AppSizes.xl,
  //         vertical: AppSizes.md + 2,
  //       ),
  //       elevation: 0,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(AppSizes.radiusMd),
  //       ),
  //       textStyle: const TextStyle(
  //         fontSize: AppSizes.fontSizeSm,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }

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
                'Loading buses...',
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

  Widget _buildErrorState(bool isDark, BusProvider busProvider) {
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
                'Failed to load buses',
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
                busProvider.error ?? 'Unknown error',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: busProvider.loadBuses,
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
                Icons.directions_bus_rounded,
                size: 64,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'No buses found',
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
                'Get started by adding your first bus',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: _showAddBusDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Bus'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusFleetTable(
    bool isDark,
    bool isMobile,
    BusProvider busProvider,
  ) {
    if (isMobile) {
      return Column(
        children: busProvider.filteredBuses
            .map((bus) => _buildMobileBusCard(bus, isDark))
            .toList(),
      );
    }

    return Card(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.5),
          5: FlexColumnWidth(1),
        },
        children: [
          _buildTableHeader(isDark),
          ...busProvider.filteredBuses.map(
            (bus) => _buildTableRow(bus, isDark),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader(bool isDark) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      children: [
        _buildTableHeaderCell('Plate Number', isDark),
        _buildTableHeaderCell('Route', isDark),
        _buildTableHeaderCell('Driver', isDark),
        _buildTableHeaderCell('Capacity', isDark),
        _buildTableHeaderCell('Status', isDark),
        _buildTableHeaderCell('Actions', isDark),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppSizes.fontSizeSm,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  TableRow _buildTableRow(Bus bus, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      children: [
        _buildTableCell(bus.plateNumber, isDark),
        _buildTableCell(bus.routeName ?? 'No Route', isDark),
        _buildTableCell(bus.driverName ?? 'Unassigned', isDark),
        _buildTableCell('${bus.passengerCount}/${bus.totalCapacity}', isDark),
        Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: _buildStatusBadge(bus.status, isDark),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: _buildActionsMenu(bus),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppSizes.fontSizeSm,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = const Color(0xFFd1fae5);
        textColor = const Color(0xFF065f46);
        icon = TablerIcons.circle_check;
        break;
      case 'inactive':
        backgroundColor = const Color(0xFFf3f4f6);
        textColor = const Color(0xFF374151);
        icon = TablerIcons.circle_x;
        break;
      case 'maintenance':
        backgroundColor = const Color(0xFFfef3c7);
        textColor = const Color(0xFF92400e);
        icon = TablerIcons.tools;
        break;
      default:
        backgroundColor = const Color(0xFFf3f4f6);
        textColor = const Color(0xFF374151);
        icon = TablerIcons.circle_x;
    }

    if (isDark) {
      backgroundColor = backgroundColor.withOpacity(0.2);
      textColor = textColor.withOpacity(0.9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(Bus bus) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
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
            _showEditBusDialog(bus);
            break;
          case 'delete':
            _showDeleteConfirmation(bus);
            break;
        }
      },
    );
  }

  Widget _buildMobileBusCard(Bus bus, bool isDark) {
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.plateNumber,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMd,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(bus.status, isDark),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Route',
                    bus.routeName ?? 'No Route',
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Driver',
                    bus.driverName ?? 'Unassigned',
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditBusDialog(bus),
                  icon: Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.info),
                ),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(bus),
                  icon: Icon(Icons.delete_rounded, size: 16),
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

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeXs,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
