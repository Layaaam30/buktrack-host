import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../models/bus_model.dart';

/// Bus Fleet Table Widget
/// Displays list of buses in a data table format
class BusFleetTable extends StatelessWidget {
  final List<Bus> buses;
  final Function(Bus)? onEdit;
  final Function(Bus)? onDelete;
  final Function(Bus)? onViewDetails;

  const BusFleetTable({
    super.key,
    required this.buses,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          _buildTableHeader(isDark),
          
          // Table Content
          if (buses.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildTableContent(isDark),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
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
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            'Showing ${buses.length} of ${buses.length} buses',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 40,
        horizontalMargin: AppSizes.xl,
        headingRowHeight: 56,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 72,
        headingTextStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontSizeXs,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
        columns: const [
          DataColumn(label: Text('BUS DETAILS')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CAPACITY')),
          DataColumn(label: Text('DRIVER')),
          DataColumn(label: Text('CONDUCTOR')),
          DataColumn(label: Text('ROUTE')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: buses.map((bus) => _buildDataRow(bus, isDark)).toList(),
      ),
    );
  }

  DataRow _buildDataRow(Bus bus, bool isDark) {
    return DataRow(
      cells: [
        // Bus Details
        DataCell(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bus.plateNumber,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontSizeSm,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Last updated: ${bus.lastUpdatedText}',
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontSizeXs,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Status
        DataCell(
          _buildStatusChip(bus.status, isDark),
        ),
        
        // Capacity
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${bus.currentCapacity} / ${bus.totalCapacity}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.fontSizeSm,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${bus.capacityPercentage.toStringAsFixed(0)}% full',
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontSizeXs,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        
        // Driver
        DataCell(
          bus.hasDriver
              ? Text(
                  bus.driverName!,
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeSm,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                )
              : Text(
                  'Unassigned',
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeSm,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
        ),
        
        // Conductor
        DataCell(
          bus.hasConductor
              ? Text(
                  bus.conductorName!,
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeSm,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                )
              : Text(
                  'Unassigned',
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeSm,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
        ),
        
        // Route
        DataCell(
          bus.hasRoute
              ? Text(
                  bus.routeName!,
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeSm,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                )
              : Text(
                  'No Route',
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeSm,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
        ),
        
        // Actions
        DataCell(
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit?.call(bus);
                  break;
                case 'delete':
                  onDelete?.call(bus);
                  break;
                case 'details':
                  onViewDetails?.call(bus);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 18),
                    const SizedBox(width: AppSizes.sm),
                    Text('View Details', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
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
                    const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: AppSizes.sm),
                    Text('Delete', style: GoogleFonts.poppins(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, bool isDark) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case 'maintenance':
        bgColor = AppColors.warningBg;
        textColor = AppColors.warning;
        icon = Icons.build_outlined;
        break;
      case 'inactive':
      default:
        bgColor = AppColors.errorBg;
        textColor = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xxxl * 2),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'No buses found',
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add your first bus to get started',
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontSizeSm,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
