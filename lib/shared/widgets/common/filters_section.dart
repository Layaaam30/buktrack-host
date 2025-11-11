import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Filters Section Widget
/// Displays filter dropdowns, search input, and action button
class FiltersSection extends StatelessWidget {
  final String? selectedStatus;
  final String? selectedRoute;
  final String searchQuery;
  final List<String> statusOptions;
  final List<String> routeOptions;
  final ValueChanged<String?>? onStatusChanged;
  final ValueChanged<String?>? onRouteChanged;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAddPressed;
  final String? addButtonText;

  const FiltersSection({
    super.key,
    this.selectedStatus,
    this.selectedRoute,
    this.searchQuery = '',
    this.statusOptions = const [],
    this.routeOptions = const [],
    this.onStatusChanged,
    this.onRouteChanged,
    this.onSearchChanged,
    this.onAddPressed,
    this.addButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Container(
      padding: const EdgeInsets.all(AppSizes.xxl),
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
          // Header with Icon
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Refine your fleet view',
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontSizeXs,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.xl),
          
          // Filter Controls
          if (isMobile)
            _buildMobileFilters(isDark)
          else
            _buildDesktopFilters(isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopFilters(bool isDark) {
    return Row(
      children: [
        // Status Label
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildStatusDropdown(isDark),
            ],
          ),
        ),
        
        const SizedBox(width: AppSizes.lg),
        
        // Route Label
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route',
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildRouteDropdown(isDark),
            ],
          ),
        ),
        
        const SizedBox(width: AppSizes.lg),
        
        // Search Label
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search',
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildSearchField(isDark),
            ],
          ),
        ),
        
        if (addButtonText != null) ...[
          const SizedBox(width: AppSizes.lg),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                addButtonText!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.lg,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFilters(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusDropdown(isDark),
        const SizedBox(height: AppSizes.md),
        _buildRouteDropdown(isDark),
        const SizedBox(height: AppSizes.md),
        _buildSearchField(isDark),
        if (addButtonText != null) ...[
          const SizedBox(height: AppSizes.md),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add, size: 20),
            label: Text(addButtonText!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: selectedStatus,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(
          'All Status',
          style: GoogleFonts.poppins(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        items: statusOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList(),
        onChanged: onStatusChanged,
      ),
    );
  }

  Widget _buildRouteDropdown(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: selectedRoute,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(
          'All Routes',
          style: GoogleFonts.poppins(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        items: routeOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList(),
        onChanged: onRouteChanged,
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.3),
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          hintText: 'Search buses...',
          hintStyle: GoogleFonts.poppins(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
        ),
      ),
    );
  }
}
