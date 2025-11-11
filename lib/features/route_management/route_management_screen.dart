import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/route_model.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  // Filter state
  String? selectedStatus;

  // Dummy data
  List<BusRoute> routes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      // Empty routes for now
      routes = [];
      isLoading = false;
    });
  }

  List<BusRoute> get filteredRoutes {
    return routes.where((route) {
      // Filter by status
      if (selectedStatus != null &&
          selectedStatus!.isNotEmpty &&
          selectedStatus != 'All Status') {
        if (route.status.toLowerCase() != selectedStatus!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _handleAddRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Route dialog (to be implemented)')),
    );
  }

  void _handleEditRoute(BusRoute route) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit route: ${route.routeCode}')));
  }

  void _handleDeleteRoute(BusRoute route) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Delete route: ${route.routeCode}')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple Page Header
          _buildPageHeader(isDark),

          const SizedBox(height: AppSizes.xxl),

          // Filters Section
          _buildFiltersSection(isDark),

          const SizedBox(height: AppSizes.xxl),

          // Routes Content
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.xxxl),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (routes.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildRoutesTable(isDark),

          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  Widget _buildPageHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Management',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Manage bus routes and schedules',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeMd,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Filter Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Text(
            'Filters',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeMd,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: AppSizes.xl),

          // Status Dropdown
          Expanded(
            child: _buildDropdown(
              value: selectedStatus,
              hint: 'All Status',
              items: const ['All Status', 'Active', 'Inactive'],
              onChanged: (value) => setState(() => selectedStatus = value),
              isDark: isDark,
            ),
          ),

          const Spacer(),

          // Add New Route Button (Green)
          ElevatedButton.icon(
            onPressed: _handleAddRoute,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Add New Route',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight.withOpacity(0.5),
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(
          hint,
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.poppins(fontSize: AppSizes.fontSizeSm),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xxxl * 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Table Headers
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTableHeader('ROUTE', isDark),
                _buildTableHeader('ORIGIN - DESTINATION', isDark),
                _buildTableHeader('TRAVEL TIME', isDark),
                _buildTableHeader('ASSIGNED BUSES', isDark),
                _buildTableHeader('STATUS', isDark),
                _buildTableHeader('ACTION', isDark),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.xxxl),

          // Empty State Icon and Text
          Icon(
            Icons.route_outlined,
            size: 64,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'No routes created yet',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Create your first route to start organizing your bus services and\noptimize passenger transportation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSizes.xxl),

          // Create First Route Button
          ElevatedButton.icon(
            onPressed: _handleAddRoute,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Create Your First Route',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xxl,
                vertical: AppSizes.lg,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, bool isDark) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: AppSizes.fontSizeXs,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRoutesTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 40,
          horizontalMargin: AppSizes.xl,
          headingRowHeight: 48,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          headingTextStyle: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeXs,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            letterSpacing: 0.5,
          ),
          columns: const [
            DataColumn(label: Text('ROUTE')),
            DataColumn(label: Text('ORIGIN - DESTINATION')),
            DataColumn(label: Text('TRAVEL TIME')),
            DataColumn(label: Text('ASSIGNED BUSES')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTION')),
          ],
          rows: filteredRoutes
              .map((route) => _buildDataRow(route, isDark))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BusRoute route, bool isDark) {
    return DataRow(
      cells: [
        // Route Code
        DataCell(
          Text(
            route.routeCode,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.fontSizeSm,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),

        // Origin - Destination
        DataCell(
          Text(
            route.fullRouteName,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),

        // Travel Time
        DataCell(
          Text(
            route.travelTime,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),

        // Assigned Buses
        DataCell(
          Text(
            route.assignedBusesText,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),

        // Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: route.status == 'active'
                  ? AppColors.successBg
                  : AppColors.errorBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              route.statusText,
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontSizeXs,
                fontWeight: FontWeight.w600,
                color: route.status == 'active'
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ),
        ),

        // Actions
        DataCell(
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _handleEditRoute(route);
                  break;
                case 'delete':
                  _handleDeleteRoute(route);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: AppSizes.sm),
                    Text('Edit', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Delete',
                      style: GoogleFonts.poppins(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
