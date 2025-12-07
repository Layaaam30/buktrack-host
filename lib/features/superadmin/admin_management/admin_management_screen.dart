import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'admin_management_service.dart';
import '../company_management/company_management_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _adminService = AdminManagementService();
  final _companyService = CompanyManagementService();

  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCompanyFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final companies = await _companyService.getAllCompanies();
      final admins = await _adminService.getAllAdmins();
      setState(() {
        _companies = companies;
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredAdmins {
    var filtered = _admins;

    if (_selectedCompanyFilter != null) {
      filtered = filtered
          .where((admin) => admin['company_ID'] == _selectedCompanyFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((admin) {
        final name = admin['name']?.toString().toLowerCase() ?? '';
        final email = admin['email']?.toString().toLowerCase() ?? '';
        final username = admin['username']?.toString().toLowerCase() ?? '';
        return name.contains(query) ||
            email.contains(query) ||
            username.contains(query);
      }).toList();
    }

    return filtered;
  }

  String _getCompanyName(String? companyId) {
    if (companyId == null) return 'Unknown';
    final company = _companies.firstWhere(
      (c) => c['id'] == companyId,
      orElse: () => {'company_name': 'Unknown'},
    );
    return company['company_name'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: AppSizes.xxl),
          _buildFiltersAndActions(isDark),
          const SizedBox(height: AppSizes.xl),
          Expanded(child: _buildAdminList(isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(TablerIcons.users, color: Colors.white, size: 28),
        ),
        const SizedBox(width: AppSizes.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Management',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage administrator accounts across all companies',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use wrap layout for smaller screens
          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or username...',
                    hintStyle: GoogleFonts.poppins(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    prefixIcon: Icon(
                      TablerIcons.search,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: const BorderSide(
                        color: Color(0xFFD97706),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedCompanyFilter,
                        decoration: InputDecoration(
                          labelText: 'Company',
                          prefixIcon: const Icon(
                            TablerIcons.building,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: AppSizes.md,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All'),
                          ),
                          ..._companies.map(
                            (company) => DropdownMenuItem(
                              value: company['id'] as String,
                              child: Text(company['company_name'] ?? 'Unknown'),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCompanyFilter = value),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    ElevatedButton.icon(
                      onPressed: _companies.isEmpty
                          ? null
                          : () => _showAdminDialog(),
                      icon: const Icon(TablerIcons.plus, size: 20),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                          vertical: AppSizes.lg,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Row layout for larger screens
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or username...',
                    hintStyle: GoogleFonts.poppins(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    prefixIcon: Icon(
                      TablerIcons.search,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: const BorderSide(
                        color: Color(0xFFD97706),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Flexible(
                child: DropdownButtonFormField<String?>(
                  value: _selectedCompanyFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter by Company',
                    prefixIcon: const Icon(TablerIcons.building, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Companies'),
                    ),
                    ..._companies.map(
                      (company) => DropdownMenuItem(
                        value: company['id'] as String,
                        child: Text(company['company_name'] ?? 'Unknown'),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCompanyFilter = value),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              ElevatedButton.icon(
                onPressed: _companies.isEmpty ? null : () => _showAdminDialog(),
                icon: const Icon(TablerIcons.plus, size: 20),
                label: Text(
                  'Add Admin',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: AppSizes.lg,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                TablerIcons.building,
                size: 64,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              'No companies available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Create a company first before adding admins',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredAdmins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? TablerIcons.user_off
                    : TablerIcons.search_off,
                size: 64,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              _searchQuery.isEmpty ? 'No admins yet' : 'No admins found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first admin to get started'
                  : 'Try adjusting your search or filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredAdmins.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final admin = _filteredAdmins[index];
        return _buildAdminCard(admin, isDark);
      },
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin, bool isDark) {
    final companyName = _getCompanyName(admin['company_ID']);
    final initial = (admin['name'] ?? 'A')[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Stack layout for very small screens
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Text(
                        admin['name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  spacing: AppSizes.md,
                  runSpacing: AppSizes.xs,
                  children: [
                    _buildInfoChip(
                      TablerIcons.mail,
                      admin['email'] ?? '',
                      isDark,
                    ),
                    _buildInfoChip(
                      TablerIcons.user,
                      '@${admin['username'] ?? ''}',
                      isDark,
                    ),
                    _buildInfoChip(TablerIcons.building, companyName, isDark),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAdminDialog(admin: admin),
                        icon: const Icon(TablerIcons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.sm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    OutlinedButton(
                      onPressed: () => _showResetPasswordDialog(admin),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFD97706)),
                        padding: const EdgeInsets.all(AppSizes.sm),
                      ),
                      child: const Icon(TablerIcons.lock, size: 18),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    OutlinedButton(
                      onPressed: () => _deleteAdmin(admin['admin_ID']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.all(AppSizes.sm),
                      ),
                      child: const Icon(TablerIcons.trash, size: 18),
                    ),
                  ],
                ),
              ],
            );
          }

          // Row layout for larger screens
          return Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin['name'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: AppSizes.lg,
                      runSpacing: AppSizes.xs,
                      children: [
                        _buildInfoChip(
                          TablerIcons.mail,
                          admin['email'] ?? '',
                          isDark,
                        ),
                        _buildInfoChip(
                          TablerIcons.user,
                          '@${admin['username'] ?? ''}',
                          isDark,
                        ),
                        _buildInfoChip(
                          TablerIcons.building,
                          companyName,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showAdminDialog(admin: admin),
                      icon: const Icon(TablerIcons.edit, size: 20),
                      tooltip: 'Edit',
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                    ),
                    IconButton(
                      onPressed: () => _showResetPasswordDialog(admin),
                      icon: const Icon(TablerIcons.lock, size: 20),
                      tooltip: 'Reset Password',
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                    ),
                    IconButton(
                      onPressed: () => _deleteAdmin(admin['admin_ID']),
                      icon: const Icon(TablerIcons.trash, size: 20),
                      tooltip: 'Delete',
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  void _showAdminDialog({Map<String, dynamic>? admin}) {
    final isEdit = admin != null;
    final nameController = TextEditingController(text: admin?['name']);
    final emailController = TextEditingController(text: admin?['email']);
    final usernameController = TextEditingController(text: admin?['username']);
    final phoneController = TextEditingController(text: admin?['phone_number']);
    final passwordController = TextEditingController();
    String? selectedCompanyId = admin?['company_ID'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? TablerIcons.edit : TablerIcons.user_plus,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                isEdit ? 'Edit Admin' : 'Add Admin',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCompanyId,
                  decoration: InputDecoration(
                    labelText: 'Company *',
                    prefixIcon: const Icon(TablerIcons.building, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  items: _companies
                      .map(
                        (company) => DropdownMenuItem(
                          value: company['id'] as String,
                          child: Text(company['company_name'] ?? 'Unknown'),
                        ),
                      )
                      .toList(),
                  onChanged: isEdit
                      ? null
                      : (value) {
                          setDialogState(() => selectedCompanyId = value);
                        },
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: const Icon(TablerIcons.user, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: const Icon(TablerIcons.mail, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username *',
                    prefixIcon: const Icon(TablerIcons.at, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(TablerIcons.phone, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: AppSizes.md),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(TablerIcons.lock, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isEdit) {
                    await _adminService.updateAdmin(
                      adminId: admin['admin_ID'],
                      name: nameController.text,
                      email: emailController.text,
                      username: usernameController.text,
                      phoneNumber: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                    );
                  } else {
                    if (selectedCompanyId == null) {
                      _showError('Please select a company');
                      return;
                    }
                    await _adminService.createAdmin(
                      name: nameController.text,
                      email: emailController.text,
                      username: usernameController.text,
                      password: passwordController.text,
                      companyId: selectedCompanyId!,
                      phoneNumber: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    _showSuccess(isEdit ? 'Admin updated' : 'Admin created');
                  }
                } catch (e) {
                  _showError(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> admin) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                TablerIcons.lock_open,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Text(
              'Reset Password',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset password for ${admin['name']}',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: AppSizes.xl),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(TablerIcons.lock, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(TablerIcons.lock_access_off, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text != confirmController.text) {
                _showError('Passwords do not match');
                return;
              }
              try {
                await _adminService.resetAdminPassword(
                  adminId: admin['admin_ID'],
                  newPassword: passwordController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccess('Password reset successfully');
                }
              } catch (e) {
                _showError(e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdmin(String adminId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                TablerIcons.alert_triangle,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Text(
              'Delete Admin',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text('Are you sure you want to delete this admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteAdmin(adminId);
        _loadData();
        _showSuccess('Admin deleted');
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }
}
