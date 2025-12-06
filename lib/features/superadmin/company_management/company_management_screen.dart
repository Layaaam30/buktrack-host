import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_sizes.dart';
import 'superadmin_provider.dart';
import 'company.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  String _searchQuery = '';
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: Text(
          'Company Management',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SuperAdminProvider>(
        builder: (context, provider, _) {
          final filteredCompanies = provider.companies.where((company) {
            return company.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (company.email?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);
          }).toList();

          return Row(
            children: [
              // Companies List
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search companies...',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF6B7280),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF9CA3AF),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1F2937),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF374151),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF374151),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8B5CF6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Companies List
                    Expanded(
                      child: provider.isLoading && provider.companies.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF8B5CF6),
                              ),
                            )
                          : filteredCompanies.isEmpty
                          ? Center(
                              child: Text(
                                'No companies found',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filteredCompanies.length,
                              itemBuilder: (context, index) {
                                final company = filteredCompanies[index];
                                final isSelected =
                                    _selectedCompany?.id == company.id;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFF8B5CF6,
                                          ).withOpacity(0.1)
                                        : const Color(0xFF1F2937),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFF374151),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      setState(
                                        () => _selectedCompany = company,
                                      );
                                      provider.loadAdminsByCompany(company.id);
                                    },
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                    ),
                                    title: Text(
                                      company.name,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: company.email != null
                                        ? Text(
                                            company.email!,
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF9CA3AF),
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: company.isActive
                                            ? const Color(
                                                0xFF10B981,
                                              ).withOpacity(0.1)
                                            : const Color(
                                                0xFF6B7280,
                                              ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        company.isActive
                                            ? 'Active'
                                            : 'Inactive',
                                        style: GoogleFonts.poppins(
                                          color: company.isActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF9CA3AF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Company Details & Admins
              Expanded(
                flex: 3,
                child: _selectedCompany == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_outlined,
                              color: const Color(0xFF6B7280),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select a company to view details',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildCompanyDetails(provider, _selectedCompany!),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCompanyDialog(context),
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add),
        label: Text('Add Company', style: GoogleFonts.poppins()),
      ),
    );
  }

  Widget _buildCompanyDetails(SuperAdminProvider provider, Company company) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (company.email != null)
                        Text(
                          company.email!,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Edit Company', style: GoogleFonts.poppins()),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _showEditCompanyDialog(context, company),
                      ),
                    ),
                    PopupMenuItem(
                      child: Text(
                        'Delete Company',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _confirmDeleteCompany(context, company),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF374151), height: 1),
          // Admins Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Company Admins',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddAdminDialog(context, company.id),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'Add Admin',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                          ),
                        )
                      : provider.admins.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: const Color(0xFF6B7280),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No admins yet',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: provider.admins.length,
                          itemBuilder: (context, index) {
                            final admin = provider.admins[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111827),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    child: Text(
                                      admin['name']
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'A',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          admin['name'] ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          admin['email'] ?? '',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF9CA3AF),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () => _confirmDeleteAdmin(
                                      context,
                                      admin['admin_ID'],
                                      admin['name'],
                                      company.id,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCompanyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Add New Company',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Company Name *',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Company name is required',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              final success = await context
                  .read<SuperAdminProvider>()
                  .createCompany(
                    name: nameController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    phoneNumber: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Company created successfully'
                          : 'Failed to create company',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Create', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(BuildContext context, Company company) {
    final nameController = TextEditingController(text: company.name);
    final emailController = TextEditingController(text: company.email ?? '');
    final phoneController = TextEditingController(
      text: company.phoneNumber ?? '',
    );
    final addressController = TextEditingController(
      text: company.address ?? '',
    );
    final descriptionController = TextEditingController(
      text: company.description ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Edit Company',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Company Name *',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context
                  .read<SuperAdminProvider>()
                  .updateCompany(company.id, {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    'phone_number': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'address': addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Company updated successfully'
                          : 'Failed to update company',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Update', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompany(BuildContext context, Company company) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Company',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${company.name}? This will deactivate the company.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context
                  .read<SuperAdminProvider>()
                  .deleteCompany(company.id);
              if (context.mounted) {
                setState(() => _selectedCompany = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Company deleted successfully'
                          : 'Failed to delete company',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context, String companyId) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Add Admin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username *',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  labelStyle: GoogleFonts.poppins(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty ||
                  usernameController.text.trim().isEmpty ||
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please fill all required fields',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              final success = await context
                  .read<SuperAdminProvider>()
                  .createAdmin(
                    companyId: companyId,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    username: usernameController.text.trim(),
                    password: passwordController.text,
                    phoneNumber: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Admin created successfully'
                          : 'Failed to create admin',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Create', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAdmin(
    BuildContext context,
    String adminId,
    String adminName,
    String companyId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Admin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete $adminName?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context
                  .read<SuperAdminProvider>()
                  .deleteAdmin(adminId);
              if (context.mounted) {
                await context.read<SuperAdminProvider>().loadAdminsByCompany(
                  companyId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Admin deleted successfully'
                          : 'Failed to delete admin',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
