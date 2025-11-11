import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/bus_model.dart';
import 'package:tabler_icons/tabler_icons.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  // Filter state
  String selectedStatus = 'All Status';
  String selectedRoute = 'All Routes';
  String searchQuery = '';

  // Dummy data
  List<Bus> buses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      buses = [Bus.dummy(0), Bus.dummy(1), Bus.dummy(2)];
      isLoading = false;
    });
  }

  List<Bus> get filteredBuses {
    return buses.where((bus) {
      if (selectedStatus != 'All Status') {
        if (bus.status.toLowerCase() !=
            selectedStatus.toLowerCase().replaceAll(' ', '')) {
          return false;
        }
      }
      if (selectedRoute != 'All Routes' && bus.routeName != selectedRoute) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return bus.plateNumber.toLowerCase().contains(query) ||
            (bus.driverName?.toLowerCase().contains(query) ?? false) ||
            (bus.conductorName?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();
  }

  int get totalBuses => buses.length;
  int get activeBuses => buses.where((b) => b.status == 'active').length;
  int get maintenanceBuses =>
      buses.where((b) => b.status == 'maintenance').length;
  int get inactiveBuses => buses.where((b) => b.status == 'inactive').length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Orange Header Banner
          _buildEnhancedHeader(isDark, isMobile),
          const SizedBox(height: AppSizes.xxl),

          // Stats Cards
          _buildStatsCards(isDark),
          const SizedBox(height: AppSizes.xxl),

          // Filters Section
          _buildFiltersSection(isDark),
          const SizedBox(height: AppSizes.xxl),

          // Bus Fleet Table
          _buildBusFleetTable(isDark, isMobile),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
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
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusXl,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  TablerIcons.bus,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
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
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add New Bus functionality')),
        );
      },
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
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          side: BorderSide(color: const Color(0xFFfed7aa).withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppSizes.tabletBreakpoint;

        if (isMobile) {
          return Column(
            children: [
              _buildStatCard(
                'Total Buses',
                totalBuses.toString(),
                TablerIcons.bus,
                const Color(0xFF3b82f6),
                'Fleet size',
                isDark,
              ),
              const SizedBox(height: AppSizes.lg),
              _buildStatCard(
                'Active Buses',
                activeBuses.toString(),
                TablerIcons.circle_check,
                const Color(0xFF22c55e),
                'Currently operational',
                isDark,
              ),
              const SizedBox(height: AppSizes.lg),
              _buildStatCard(
                'Maintenance',
                maintenanceBuses.toString(),
                TablerIcons.tools,
                const Color(0xFFf59e0b),
                'Under maintenance',
                isDark,
              ),
              const SizedBox(height: AppSizes.lg),
              _buildStatCard(
                'Inactive',
                inactiveBuses.toString(),
                TablerIcons.circle_x,
                const Color(0xFFef4444),
                'Not operational',
                isDark,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Buses',
                totalBuses.toString(),
                TablerIcons.bus,
                const Color(0xFF3b82f6),
                'Fleet size',
                isDark,
              ),
            ),
            const SizedBox(width: AppSizes.lg),
            Expanded(
              child: _buildStatCard(
                'Active Buses',
                activeBuses.toString(),
                TablerIcons.circle_check,
                const Color(0xFF22c55e),
                'Currently operational',
                isDark,
              ),
            ),
            const SizedBox(width: AppSizes.lg),
            Expanded(
              child: _buildStatCard(
                'Maintenance',
                maintenanceBuses.toString(),
                TablerIcons.tools,
                const Color(0xFFf59e0b),
                'Under maintenance',
                isDark,
              ),
            ),
            const SizedBox(width: AppSizes.lg),
            Expanded(
              child: _buildStatCard(
                'Inactive',
                inactiveBuses.toString(),
                TablerIcons.circle_x,
                const Color(0xFFef4444),
                'Not operational',
                isDark,
              ),
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
    String subtitle,
    bool isDark,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSizes.lg),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.xs),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.xs),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(bool isDark) {
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
                    _buildFilterControl('Status', isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildRouteControl('Route', isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildSearchControl('Search', isDark),
                    const SizedBox(height: AppSizes.lg),
                    SizedBox(width: double.infinity, child: _buildAddButton2()),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _buildFilterControl('Status', isDark)),
                  const SizedBox(width: AppSizes.lg),
                  Expanded(child: _buildRouteControl('Route', isDark)),
                  const SizedBox(width: AppSizes.lg),
                  Expanded(child: _buildSearchControl('Search', isDark)),
                  const SizedBox(width: AppSizes.lg),
                  _buildAddButton2(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControl(String label, bool isDark) {
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
              value: selectedStatus,
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
                setState(() => selectedStatus = value!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteControl(String label, bool isDark) {
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
              value: selectedRoute,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: ['All Routes', 'Route 1', 'Route 2', 'Route 3'].map((
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
                setState(() => selectedRoute = value!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchControl(String label, bool isDark) {
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
            onChanged: (value) => setState(() => searchQuery = value),
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

  Widget _buildAddButton2() {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add Bus functionality')));
      },
      icon: const Icon(TablerIcons.plus, size: 20),
      label: const Text('Add Bus'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFf97316),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.md + 2,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: AppSizes.fontSizeSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBusFleetTable(bool isDark, bool isMobile) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.xxxl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (filteredBuses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.xxxl * 2),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                TablerIcons.bus,
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
                selectedStatus != 'All Status' ||
                        selectedRoute != 'All Routes' ||
                        searchQuery.isNotEmpty
                    ? 'Try adjusting your filters'
                    : 'Get started by adding your first bus',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMd,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1f2937).withOpacity(0.5)
                  : const Color(0xFFf9fafb),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMd),
                topRight: Radius.circular(AppSizes.radiusMd),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bus Fleet',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Showing ${filteredBuses.length} of ${buses.length} buses',
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
          // Table Content
          if (isMobile)
            ...filteredBuses.map((bus) => _buildMobileBusCard(bus, isDark))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: MediaQuery.of(context).size.width - 280,
                child: _buildDesktopTable(isDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(bool isDark) {
    return DataTable(
      columnSpacing: AppSizes.xl,
      horizontalMargin: AppSizes.xl,
      headingRowHeight: 56,
      dataRowMinHeight: 72,
      dataRowMaxHeight: 72,
      dividerThickness: 0,
      headingRowColor: WidgetStateProperty.all(Colors.transparent),
      columns: [
        DataColumn(
          label: Text(
            'BUS DETAILS',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'STATUS',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'CAPACITY',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'DRIVER',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'CONDUCTOR',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'ROUTE',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'ACTIONS',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
      rows: filteredBuses.asMap().entries.map((entry) {
        final index = entry.key;
        final bus = entry.value;
        final isEven = index % 2 == 0;

        return DataRow(
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return isDark
                  ? const Color(0xFF374151).withOpacity(0.3)
                  : const Color(0xFFf9fafb);
            }
            return isEven
                ? Colors.transparent
                : (isDark
                      ? const Color(0xFF1f2937).withOpacity(0.2)
                      : const Color(0xFFfafafa));
          }),
          cells: [
            DataCell(
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFfed7aa).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Icon(
                      TablerIcons.bus,
                      color: Color(0xFFea580c),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bus.plateNumber,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Last updated: Never',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeXs,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DataCell(_buildStatusBadge(bus.status, isDark)),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'dummy',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'dummy',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXs,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              bus.driverName != null
                  ? Text(
                      bus.driverName!,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    )
                  : TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Assign Driver',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: Color(0xFFea580c),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
            DataCell(
              bus.conductorName != null
                  ? Text(
                      bus.conductorName!,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    )
                  : TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Assign Conductor',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: Color(0xFFea580c),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
            DataCell(
              Text(
                bus.routeName ?? 'No Route',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            DataCell(
              PopupMenuButton<String>(
                icon: Icon(
                  TablerIcons.dots_vertical,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        const Icon(
                          TablerIcons.eye,
                          size: 18,
                          color: Color(0xFF3b82f6),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSm,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          TablerIcons.edit,
                          size: 18,
                          color: Color(0xFF22c55e),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Text(
                          'Edit Bus',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSm,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          TablerIcons.trash,
                          size: 18,
                          color: Color(0xFFef4444),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Text(
                          'Delete Bus',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSm,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value: ${bus.plateNumber}')),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
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

  Widget _buildMobileBusCard(Bus bus, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFfed7aa).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
        ],
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
