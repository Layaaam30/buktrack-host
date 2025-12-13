import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'validation_utils.dart';
import 'account_model.dart';

/// Dialog for adding or editing an account (driver or conductor)
/// Enhanced with REAL-TIME validation feedback
class AccountDialog extends StatefulWidget {
  final Account? account;
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

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Dropdowns
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

  // Real-time validation states
  String? _nameError;
  String? _usernameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _nameValid = false;
  bool _usernameValid = false;
  bool _phoneValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;

  // Password strength
  int _passwordStrength = 0;

  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

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

    // Add real-time validation listeners
    _nameController.addListener(_validateName);
    _usernameController.addListener(_validateUsername);
    _phoneController.addListener(_validateAndFormatPhone);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);

    // Initial validation for edit mode
    if (isEditing) {
      _validateName();
      _validateUsername();
      _validateAndFormatPhone();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool get isEditing => widget.account != null;

  // Real-time validation methods
  void _validateName() {
    final error = ValidationUtils.validateFullName(_nameController.text);
    setState(() {
      _nameError = error;
      _nameValid = error == null && _nameController.text.isNotEmpty;
    });
  }

  void _validateUsername() {
    final error = ValidationUtils.validateUsername(_usernameController.text);
    setState(() {
      _usernameError = error;
      _usernameValid = error == null && _usernameController.text.isNotEmpty;
    });
  }

  void _validateAndFormatPhone() {
    final text = _phoneController.text;
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    // Auto-format when complete
    if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
      final formatted = ValidationUtils.formatPhilippinePhoneNumber(digitsOnly);
      if (formatted != text) {
        final cursorPos = _phoneController.selection.baseOffset;
        _phoneController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: cursorPos + (formatted.length - text.length),
          ),
        );
      }
    }

    // Validate
    final error = ValidationUtils.validatePhilippinePhoneNumber(
      _phoneController.text,
    );
    setState(() {
      _phoneError = error;
      _phoneValid = error == null && _phoneController.text.isNotEmpty;
    });
  }

  void _validatePassword() {
    final error = ValidationUtils.validatePassword(_passwordController.text);
    final strength = ValidationUtils.calculatePasswordStrength(
      _passwordController.text,
    );

    setState(() {
      _passwordError = error;
      _passwordValid = error == null && _passwordController.text.isNotEmpty;
      _passwordStrength = strength;
    });

    // Re-validate confirm password if it has content
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  void _validateConfirmPassword() {
    final error = ValidationUtils.validatePasswordConfirmation(
      _confirmPasswordController.text,
      _passwordController.text,
    );
    setState(() {
      _confirmPasswordError = error;
      _confirmPasswordValid =
          error == null && _confirmPasswordController.text.isNotEmpty;
    });
  }

  bool _canSubmit() {
    if (isEditing) {
      return _nameValid && _usernameValid && _phoneValid;
    } else {
      return _nameValid &&
          _usernameValid &&
          _phoneValid &&
          _passwordValid &&
          _confirmPasswordValid;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_canSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all validation errors'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cleanedPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      String formattedPhone = cleanedPhone;
      if (cleanedPhone.startsWith('63')) {
        formattedPhone = '0${cleanedPhone.substring(2)}';
      } else if (!cleanedPhone.startsWith('0')) {
        formattedPhone = '0$cleanedPhone';
      }

      final account = Account(
        id: widget.account?.id ?? '',
        name: ValidationUtils.sanitizeInput(_nameController.text),
        username: _usernameController.text.trim().toLowerCase(),
        phoneNumber: formattedPhone,
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
              autovalidateMode:
                  AutovalidateMode.disabled, // We handle validation manually
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
        // Name Field with real-time validation
        _buildValidatedTextField(
          controller: _nameController,
          focusNode: _nameFocus,
          label: 'Full Name',
          hint: 'e.g., Juan Dela Cruz',
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          textCapitalization: TextCapitalization.words,
          error: _nameError,
          isValid: _nameValid,
          helperText: 'Enter first and last name (2-100 characters)',
        ),

        const SizedBox(height: AppSizes.lg),

        // Username Field
        _buildValidatedTextField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          label: 'Username',
          hint: 'e.g., juan_delacruz',
          icon: Icons.account_circle_outlined,
          isDark: isDark,
          enabled: !isEditing,
          error: _usernameError,
          isValid: _usernameValid,
          helperText: isEditing
              ? 'Username cannot be changed'
              : 'Lowercase letters, numbers, underscore, hyphen (3-30 chars)',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_-]')),
            LengthLimitingTextInputFormatter(30),
          ],
        ),

        const SizedBox(height: AppSizes.lg),

        // Phone Field
        _buildValidatedTextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          label: 'Phone Number',
          hint: 'e.g., 0917 123 4567',
          icon: Icons.phone_outlined,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          error: _phoneError,
          isValid: _phoneValid,
          helperText: 'Philippine mobile number (09XX XXX XXXX)',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
            LengthLimitingTextInputFormatter(13),
          ],
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
          helperText: 'Select account type',
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
          helperText: 'Current availability status',
        ),

        const SizedBox(height: AppSizes.lg),

        // Password Fields (only for new accounts)
        if (!isEditing) ...[
          const Divider(),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Security',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMd,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Password Field
          _buildValidatedPasswordField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Password',
            hint: 'Create a strong password',
            isDark: isDark,
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            error: _passwordError,
            isValid: _passwordValid,
          ),

          const SizedBox(height: AppSizes.sm),
          _buildPasswordStrengthIndicator(isDark),

          const SizedBox(height: AppSizes.md),

          // Confirm Password Field
          _buildValidatedPasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            isDark: isDark,
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            error: _confirmPasswordError,
            isValid: _confirmPasswordValid,
          ),

          const SizedBox(height: AppSizes.sm),
          _buildPasswordRequirements(isDark),
        ],
      ],
    );
  }

  Widget _buildValidatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? error,
    bool isValid = false,
    TextInputType? keyboardType,
    bool enabled = true,
    String? helperText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final hasContent = controller.text.isNotEmpty;

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
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: error ?? helperText,
            helperStyle: TextStyle(
              fontSize: 11,
              color: error != null
                  ? AppColors.error
                  : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
            ),
            helperMaxLines: 2,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              icon,
              color: error != null
                  ? AppColors.error
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              size: AppSizes.iconMd,
            ),
            suffixIcon: hasContent
                ? Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color: isValid ? AppColors.success : AppColors.error,
                    size: 20,
                  )
                : null,
            filled: true,
            fillColor: isDark ? AppColors.hoverDark : AppColors.hoverLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.error
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.error
                    : (isValid
                          ? AppColors.success
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight)),
                width: isValid ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.error
                    : (isValid ? AppColors.success : AppColors.primary),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.borderDark.withOpacity(0.5)
                    : AppColors.borderLight.withOpacity(0.5),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
          ),
          validator: (_) => null, // Validation handled in real-time
        ),
      ],
    );
  }

  Widget _buildValidatedPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isDark,
    required bool obscure,
    required VoidCallback onToggle,
    String? error,
    bool isValid = false,
  }) {
    final hasContent = controller.text.isNotEmpty;

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
          focusNode: focusNode,
          obscureText: obscure,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: error,
            helperStyle: TextStyle(fontSize: 11, color: AppColors.error),
            helperMaxLines: 2,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: error != null
                  ? AppColors.error
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              size: AppSizes.iconMd,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasContent)
                  Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color: isValid ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            filled: true,
            fillColor: isDark ? AppColors.hoverDark : AppColors.hoverLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.error
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.error
                    : (isValid
                          ? AppColors.success
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight)),
                width: isValid ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.error
                    : (isValid ? AppColors.success : AppColors.primary),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
          ),
          validator: (_) => null,
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(bool isDark) {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    final strengthText = ValidationUtils.getPasswordStrengthText(
      _passwordStrength,
    );
    final strengthColor = ValidationUtils.getPasswordStrengthColor(
      _passwordStrength,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _passwordStrength / 4,
                backgroundColor: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: strengthColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          _buildRequirement(
            'At least 8 characters',
            _passwordController.text.length >= 8,
            isDark,
          ),
          _buildRequirement(
            'One uppercase letter (A-Z)',
            RegExp(r'[A-Z]').hasMatch(_passwordController.text),
            isDark,
          ),
          _buildRequirement(
            'One lowercase letter (a-z)',
            RegExp(r'[a-z]').hasMatch(_passwordController.text),
            isDark,
          ),
          _buildRequirement(
            'One number (0-9)',
            RegExp(r'[0-9]').hasMatch(_passwordController.text),
            isDark,
          ),
          _buildRequirement(
            'One special character (!@#\$%^&*)',
            RegExp(
              r'[!@#$%^&*(),.?":{}|<>]',
            ).hasMatch(_passwordController.text),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet
                ? AppColors.success
                : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
          ),
          const SizedBox(width: AppSizes.xs),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet
                  ? (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight)
                  : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
    required IconData icon,
    String? helperText,
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
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: 11,
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
    final canSubmit = _canSubmit();

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
            onPressed: (_isLoading || !canSubmit) ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: canSubmit ? AppColors.violet : Colors.grey,
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
