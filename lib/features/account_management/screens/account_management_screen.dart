import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  // Filter state
  String? selectedRole;
  String? selectedAvailability;
  String searchQuery = '';

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;

  // Dummy data
  final List<Map<String, dynamic>> accounts = [
    {
      'name': 'Joshua Periodico',
      'username': 'joshua...',
      'phone': '1234567890',
      'role': 'Conductor',
      'availability': 'Available',
      'assignedBus': 'Assigned',
      'lastLogin': 'Never logged in',
      'initials': 'JP',
    },
  ];

  bool get hasFilters =>
      searchQuery.isNotEmpty ||
      (selectedRole != null && selectedRole!.isNotEmpty) ||
      (selectedAvailability != null && selectedAvailability!.isNotEmpty);

  void resetFilters() {
    setState(() {
      selectedRole = null;
      selectedAvailability = null;
      searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            _buildPageHeader(isDark),
            const SizedBox(height: AppSizes.xxl),

            // Filters and Actions Card
            _buildFiltersCard(isDark),
            const SizedBox(height: AppSizes.xxl),

            // Accounts Table Card
            _buildAccountsTable(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Management',
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
          'Manage drivers and conductors',
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

  Widget _buildFiltersCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filters Row
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            alignment: WrapAlignment.start,
            children: [
              // Filter Icon and Label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.hoverDark
                          : const Color(0xFFF3F4F6),
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
                ],
              ),

              const SizedBox(width: AppSizes.sm),

              // Role Dropdown
              SizedBox(
                width: 180,
                child: _buildDropdown(
                  value: selectedRole,
                  hint: 'All Roles',
                  items: const ['All Roles', 'Driver', 'Conductor'],
                  onChanged: (value) => setState(() => selectedRole = value),
                  isDark: isDark,
                ),
              ),

              // Availability Dropdown
              SizedBox(
                width: 180,
                child: _buildDropdown(
                  value: selectedAvailability,
                  hint: 'All Availability',
                  items: const [
                    'All Availability',
                    'Available',
                    'In Transit',
                    'On Leave',
                    'Unavailable',
                  ],
                  onChanged: (value) =>
                      setState(() => selectedAvailability = value),
                  isDark: isDark,
                ),
              ),

              // Search Field
              SizedBox(width: 300, child: _buildSearchField(isDark)),

              // Clear Filters Button
              if (hasFilters)
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: resetFilters,
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(
                      'Clear Filters',
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      backgroundColor: isDark
                          ? AppColors.errorBgDark.withOpacity(0.2)
                          : AppColors.errorBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSizes.lg),

          // Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Add Conductor Button (Purple)
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Conductor',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSizeSm,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: AppSizes.md,
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),

              const SizedBox(width: AppSizes.md),

              // Add Driver Button (Blue)
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Driver',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSizeSm,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: AppSizes.md,
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),
            ],
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight.withOpacity(0.5),
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        style: GoogleFonts.poppins(
          fontSize: AppSizes.fontSizeSm,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name, username, or phone...',
          hintStyle: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSizes.sm,
            horizontal: AppSizes.md,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table
          Container(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth:
                      MediaQuery.of(context).size.width -
                      280, // Account for sidebar
                ),
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: AppSizes.xl,
                  headingRowHeight: 48,
                  dataRowMinHeight: 72,
                  dataRowMaxHeight: 72,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? AppColors.hoverDark : const Color(0xFFF9FAFB),
                  ),
                  headingTextStyle: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeXs,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                  columns: const [
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('USERNAME')),
                    DataColumn(label: Text('PHONE')),
                    DataColumn(label: Text('ROLE')),
                    DataColumn(label: Text('AVAILABILITY')),
                    DataColumn(label: Text('ASSIGNED BUS')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: accounts
                      .map((account) => _buildDataRow(account, isDark))
                      .toList(),
                ),
              ),
            ),
          ),

          // Pagination Footer
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              color: isDark
                  ? AppColors.hoverDark.withOpacity(0.3)
                  : const Color(0xFFF9FAFB),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1 to 1 of 1 results',
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSizeSm,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: currentPage > 1 ? () {} : null,
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      disabledColor:
                          (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)
                              .withOpacity(0.3),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppSizes.fontSizeSm,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 20,
                      disabledColor:
                          (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)
                              .withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> account, bool isDark) {
    return DataRow(
      cells: [
        // Name with Avatar
        DataCell(
          SizedBox(
            width: 200,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDDD6FE),
                  child: Text(
                    account['initials'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        account['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.watch_later_outlined,
                            size: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              account['lastLogin'],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Username
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              account['username'],
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Phone
        DataCell(
          SizedBox(
            width: 110,
            child: Text(
              account['phone'],
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),

        // Role Badge
        DataCell(
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(
                  color: const Color(0xFF9333EA).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    account['role'] == 'Conductor'
                        ? Icons.person_outline
                        : Icons.drive_eta,
                    size: 13,
                    color: const Color(0xFF9333EA),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    account['role'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9333EA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Availability Badge
        DataCell(
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    account['availability'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Assigned Bus
        DataCell(
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    account['assignedBus'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Actions Menu
        DataCell(
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              size: 20,
            ),
            onSelected: (value) {},
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'View Details',
                      style: GoogleFonts.poppins(fontSize: AppSizes.fontSizeSm),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'availability',
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Update Availability',
                      style: GoogleFonts.poppins(fontSize: AppSizes.fontSizeSm),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'unassign',
                child: Row(
                  children: [
                    Icon(Icons.link_off, size: 18, color: AppColors.warning),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Unassign from Bus',
                      style: GoogleFonts.poppins(fontSize: AppSizes.fontSizeSm),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Delete Account',
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontSizeSm,
                        color: AppColors.error,
                      ),
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
