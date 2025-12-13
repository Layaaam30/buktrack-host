import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../auth/auth_provider.dart';
import 'bus_model.dart';
import 'bus_provider.dart';
import 'bus_dialog.dart';
import '../../../shared/widgets/common/confirmation_dialog.dart';
import '../../../shared/widgets/common/stat_card.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  String _sortColumn = 'plateNumber';
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

  /// Handle Update Bus Status
  Future<void> _handleUpdateStatus(Bus bus) async {
    final statusOptions = ['active', 'inactive', 'maintenance'];

    String current = bus.status.toLowerCase();

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
                              'Update Status - ${bus.plateNumber}',
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
                                  color: const Color(0xFFf97316),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFFf97316),
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
                            'Bus Status *',
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
                                items: statusOptions.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(_formatStatusDisplay(status)),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Note: Status changes will affect bus availability for route assignments',
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
                                colors: [Color(0xFFf97316), Color(0xFFea580c)],
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pop(current),
                              icon: const Icon(
                                TablerIcons.refresh,
                                color: Colors.white,
                              ),
                              label: const Text('Update Status'),
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
      final busProvider = context.read<BusProvider>();

      // Create updated bus with new status
      final updatedBus = bus.copyWith(
        status: selected,
        lastUpdateTimestamp: DateTime.now(),
      );

      final success = await busProvider.updateBus(bus.id, updatedBus);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus status updated to "$selected"'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted && busProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${busProvider.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Bus> _getSortedBuses(List<Bus> buses) {
    final sorted = List<Bus>.from(buses);

    switch (_sortColumn) {
      case 'plateNumber':
        sorted.sort((a, b) => a.plateNumber.compareTo(b.plateNumber));
        break;
      case 'route':
        sorted.sort((a, b) => (a.routeName ?? '').compareTo(b.routeName ?? ''));
        break;
      case 'driver':
        sorted.sort(
          (a, b) => (a.driverName ?? '').compareTo(b.driverName ?? ''),
        );
        break;
      case 'capacity':
        sorted.sort((a, b) => a.totalCapacity.compareTo(b.totalCapacity));
        break;
      case 'status':
        sorted.sort((a, b) => a.status.compareTo(b.status));
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

  String _formatStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'maintenance':
        return 'Maintenance';
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
              _buildStatsCards(busProvider),
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

  Widget _buildStatsCards(BusProvider busProvider) {
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
            StatCard(
              title: 'Total Buses',
              value: stats['total'].toString(),
              icon: TablerIcons.bus,
              color: AppColors.info,
            ),
            StatCard(
              title: 'Active',
              value: stats['active'].toString(),
              icon: TablerIcons.circle_check,
              color: AppColors.success,
            ),
            StatCard(
              title: 'Maintenance',
              value: stats['maintenance'].toString(),
              icon: TablerIcons.tools,
              color: AppColors.warning,
            ),
            StatCard(
              title: 'Inactive',
              value: stats['inactive'].toString(),
              icon: TablerIcons.circle_x,
              color: AppColors.error,
            ),
          ],
        );
      },
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
                  const SizedBox(width: AppSizes.lg),
                  Expanded(
                    child: _buildSearchControl('Search', isDark, busProvider),
                  ),
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
                _buildHeaderCell(
                  'PLATE NUMBER',
                  'plateNumber',
                  isDark,
                  flex: 3,
                ),
                _buildHeaderCell('ROUTE', 'route', isDark, flex: 2),
                _buildHeaderCell('DRIVER', 'driver', isDark, flex: 2),
                _buildHeaderCell('CAPACITY', 'capacity', isDark, flex: 2),
                _buildHeaderCell('STATUS', 'status', isDark, flex: 2),
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

          ..._getSortedBuses(busProvider.filteredBuses).asMap().entries.map((
            entry,
          ) {
            return _buildTableRow(
              entry.value,
              isDark,
              entry.key == busProvider.filteredBuses.length - 1,
            );
          }).toList(),
        ],
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
                          ? const Color(0xFFf97316)
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
                        ? const Color(0xFFf97316)
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

  Widget _buildTableRow(Bus bus, bool isDark, bool isLast) {
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
          // PLATE NUMBER
          cell(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFfed7aa),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Icon(
                    TablerIcons.bus,
                    color: Color(0xFFea580c),
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
                        bus.plateNumber,
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
                        'Capacity: ${bus.passengerCount}/${bus.totalCapacity}',
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

          // ROUTE
          cell(
            flex: 2,
            child: Text(
              bus.routeName ?? 'No Route',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF374151),
              ),
            ),
          ),

          // DRIVER
          cell(
            flex: 2,
            child: Text(
              bus.driverName ?? 'Unassigned',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF374151),
              ),
            ),
          ),

          // CAPACITY
          cell(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFdbeafe),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TablerIcons.users,
                    size: 14,
                    color: Color(0xFF1e40af),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${bus.passengerCount}/${bus.totalCapacity}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e40af),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // STATUS - Now clickable
          cell(
            flex: 2,
            child: InkWell(
              onTap: () => _handleUpdateStatus(bus),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'Click to update status',
                  child: _buildStatusBadge(bus.status, isDark),
                ),
              ),
            ),
          ),

          // ACTION
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionsMenu(bus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bgColor, textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = const Color(0xFFd1fae5);
        textColor = const Color(0xFF065f46);
        icon = TablerIcons.circle_check;
        label = 'Active';
        break;
      case 'inactive':
        bgColor = const Color(0xFFfee2e2);
        textColor = const Color(0xFF991b1b);
        icon = TablerIcons.circle_x;
        label = 'Inactive';
        break;
      case 'maintenance':
        bgColor = const Color(0xFFfef3c7);
        textColor = const Color(0xFF92400e);
        icon = TablerIcons.tools;
        label = 'Maintenance';
        break;
      default:
        bgColor = const Color(0xFFf3f4f6);
        textColor = const Color(0xFF374151);
        icon = TablerIcons.circle_x;
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
          Icon(icon, size: 14, color: textColor),
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

  Widget _buildActionsMenu(Bus bus) {
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
          value: 'status',
          child: Row(
            children: [
              Icon(TablerIcons.refresh, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSizes.md),
              const Text('Update Status'),
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
          case 'status':
            _handleUpdateStatus(bus);
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
                InkWell(
                  onTap: () => _handleUpdateStatus(bus),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: _buildStatusBadge(bus.status, isDark),
                ),
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
