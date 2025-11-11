import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_sizes.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (!success) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Failed to sign in',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFFEF4444), // Red
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          );
        }
        // If success, app.dart will handle navigation automatically
      }
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please contact your system administrator to reset your password.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSizes.lg : AppSizes.xxxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: const BorderSide(
                    color: Color(0xFFE5E7EB), // Light border
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? AppSizes.xxl : 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and Title
                        _buildHeader(),

                        const SizedBox(height: 40),

                        // Email Field
                        _buildEmailField(),

                        const SizedBox(height: AppSizes.lg),

                        // Password Field
                        _buildPasswordField(),

                        const SizedBox(height: AppSizes.lg),

                        // Remember Me and Forgot Password
                        _buildRememberMeRow(),

                        const SizedBox(height: AppSizes.xxl),

                        // Sign In Button
                        _buildSignInButton(),

                        const SizedBox(height: AppSizes.lg),

                        // Help Section
                        _buildHelpSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo from assets
        Image.asset(
          'assets/images/logos/favicon.png',
          height: 60,
          width: 60,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image not found
            return Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 32,
              ),
            );
          },
        ),

        const SizedBox(height: AppSizes.lg),

        // Title
        Text(
          'BUKTRACK',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSize2xl,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF6B35), // Dark gray
          ),
        ),

        const SizedBox(height: AppSizes.xs),

        // Subtitle
        Text(
          'Bus Tracking & Management System',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm,
            color: const Color(0xFF6B7280), // Gray
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937), // Dark gray
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: _emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(color: const Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF), // Light gray
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB), // Very light gray
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB), // Light border
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B35), // Orange
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFEF4444)), // Red
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          autofillHints: const [AutofillHints.email],
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937), // Dark gray
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: _passwordController,
          validator: _validatePassword,
          obscureText: !_isPasswordVisible,
          style: GoogleFonts.poppins(color: const Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF), // Light gray
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB), // Very light gray
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB), // Light border
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B35), // Orange
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFEF4444)), // Red
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF6B7280), // Gray
                size: 20,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          enabled: !_isLoading,
          autofillHints: const [AutofillHints.password],
        ),
      ],
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        // Remember Me Checkbox
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: _rememberMe,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
            activeColor: const Color(0xFFFF6B35), // Orange
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        const SizedBox(width: AppSizes.sm),

        Text(
          'Remember me',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm,
            color: const Color(0xFF6B7280), // Gray
          ),
        ),

        const Spacer(),

        // Forgot Password Link
        TextButton(
          onPressed: _isLoading ? null : _handleForgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              color: const Color(0xFFFF6B35), // Orange
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35), // Orange
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontSizeMd,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE), // Light blue background
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            'Need Help?',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2563EB), // Blue text
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact your system administrator or BUKTRACK Support',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeXs,
              color: const Color(0xFF60A5FA), // Light blue text
            ),
          ),
        ],
      ),
    );
  }
}
