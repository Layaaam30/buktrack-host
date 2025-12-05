import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'account_model.dart';

class AccountDialog extends StatefulWidget {
  final Account? account; // null for add, Account object for edit
  final String companyId;
  final String adminId;

  const AccountDialog({
    super.key,
    this.account,
    required this.companyId,
    required this.adminId,
  });

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String _selectedRole = 'conductor';
  String _selectedAvailability = 'available';

  final List<String> _roleOptions = ['driver', 'conductor'];
  final List<String> _availabilityOptions = [
    'available',
    'in_transit',
    'on_leave',
    'unavailable',
  ];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _usernameController = TextEditingController(
      text: widget.account?.username ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.account?.phoneNumber ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _selectedRole = widget.account?.role ?? 'conductor';
    _selectedAvailability = widget.account?.availabilityStatus ?? 'available';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.account != null;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final account = Account(
        id: widget.account?.id ?? '',
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole,
        companyId: widget.companyId,
        passwordHash: widget.account?.passwordHash ?? '',
        availabilityStatus: _selectedAvailability,
        isActive: widget.account?.isActive ?? true,
        createdByAdmin: widget.adminId,
        createdAt: widget.account?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        assignedBusId: widget.account?.assignedBusId,
        currentRouteId: widget.account?.currentRouteId,
        assignedByAdmin: widget.account?.assignedByAdmin,
        assignmentDate: widget.account?.assignmentDate,
        leaveStartDate: widget.account?.leaveStartDate,
        leaveEndDate: widget.account?.leaveEndDate,
        leaveReason: widget.account?.leaveReason,
        firebaseUid: widget.account?.firebaseUid,
        firebaseEmail: widget.account?.firebaseEmail,
      );

      if (mounted) {
        Navigator.of(context).pop({
          'account': account,
          'password': _passwordController.text.trim(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: AppSizes.xxl),

                  _buildFormFields(isDark),
                  const SizedBox(height: AppSizes.xxl),

                  _buildActions(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.violetGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
            color: Colors.white,
            size: AppSizes.iconLg,
          ),
        ),

        const SizedBox(width: AppSizes.lg),

        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Account' : 'Add New Account',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                isEditing
                    ? 'Update account information'
                    : 'Create a new driver or conductor account',
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

        // Close button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.hoverDark
                : AppColors.hoverLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter full name',
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSizes.lg),

        // Username Field
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
          hint: 'Enter username',
          icon: Icons.account_circle_outlined,
          isDark: isDark,
          enabled: !isEditing,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSizes.lg),

        // Phone Field
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter phone number',
          icon: Icons.phone_outlined,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSizes.lg),

        // Role Dropdown
        _buildDropdown(
          label: 'Role',
          value: _selectedRole,
          items: _roleOptions,
          onChanged: (value) => setState(() => _selectedRole = value!),
          isDark: isDark,
          icon: Icons.badge_outlined,
        ),

        const SizedBox(height: AppSizes.lg),

        // Availability Dropdown
        _buildDropdown(
          label: 'Availability Status',
          value: _selectedAvailability,
          items: _availabilityOptions,
          onChanged: (value) => setState(() => _selectedAvailability = value!),
          isDark: isDark,
          icon: Icons.event_available_rounded,
        ),

        const SizedBox(height: AppSizes.lg),

        // Password Field
        if (!isEditing) ...[
          Text(
            'Password',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter password',
            isDark: isDark,
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.md),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            isDark: isDark,
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              icon,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              size: AppSizes.iconMd,
            ),
            filled: true,
            fillColor: isDark ? AppColors.hoverDark : AppColors.hoverLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        fontSize: AppSizes.fontSizeSm,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          size: AppSizes.iconMd,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        filled: true,
        fillColor: isDark ? AppColors.hoverDark : AppColors.hoverLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item == 'driver' || item == 'conductor'
                        ? item[0].toUpperCase() + item.substring(1)
                        : _formatAvailability(item),
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              size: AppSizes.iconMd,
            ),
            filled: true,
            fillColor: isDark ? AppColors.hoverDark : AppColors.hoverLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAvailability(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'in_transit':
        return 'In Transit';
      case 'on_leave':
        return 'On Leave';
      case 'unavailable':
        return 'Unavailable';
      default:
        return status;
    }
  }

  Widget _buildActions(bool isDark) {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppSizes.md),

        // Submit Button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isEditing ? 'Update Account' : 'Create Account',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
