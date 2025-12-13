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
            padding: EdgeInsets.all(
              isMobile ? AppSizes.lg * 0.8 : AppSizes.xxxl * 0.8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 336), // 420 * 0.8
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
                  padding: EdgeInsets.all(
                    isMobile ? AppSizes.xxl * 0.8 : 32,
                  ), // 40 * 0.8
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and Title
                        _buildHeader(),

                        const SizedBox(height: 32), // 40 * 0.8
                        // Email Field
                        _buildEmailField(),

                        SizedBox(height: AppSizes.lg * 0.8),

                        // Password Field
                        _buildPasswordField(),

                        SizedBox(height: AppSizes.lg * 0.8),

                        // Remember Me and Forgot Password
                        _buildRememberMeRow(),

                        SizedBox(height: AppSizes.xxl * 0.8),

                        // Sign In Button
                        _buildSignInButton(),

                        SizedBox(height: AppSizes.lg * 0.8),

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
          height: 48, // 60 * 0.8
          width: 48,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image not found
            return Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(10), // 12 * 0.8
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 26, // 32 * 0.8
              ),
            );
          },
        ),

        SizedBox(height: AppSizes.lg * 0.8),

        // Title
        Text(
          'BUKTRACK',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSize2xl * 0.8,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF6B35),
          ),
        ),

        SizedBox(height: AppSizes.xs * 0.8),

        // Subtitle
        Text(
          'Bus Tracking & Management System',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm * 0.8,
            color: const Color(0xFF6B7280),
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
            fontSize: AppSizes.fontSizeSm * 0.8,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: AppSizes.sm * 0.8),
        TextFormField(
          controller: _emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1F2937),
            fontSize: 14, // Standard readable size
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF6B7280),
              size: 18, // 20 * 0.8 (rounded)
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.lg * 0.8,
              vertical: AppSizes.md * 0.8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
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
            fontSize: AppSizes.fontSizeSm * 0.8,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: AppSizes.sm * 0.8),
        TextFormField(
          controller: _passwordController,
          validator: _validatePassword,
          obscureText: !_isPasswordVisible,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1F2937),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.lg * 0.8,
              vertical: AppSizes.md * 0.8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
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
                color: const Color(0xFF6B7280),
                size: 18,
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
          height: 18, // 20 * 0.8 (rounded)
          width: 18,
          child: Checkbox(
            value: _rememberMe,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
            activeColor: const Color(0xFFFF6B35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        SizedBox(width: AppSizes.sm * 0.8),

        Text(
          'Remember me',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSizeSm * 0.8,
            color: const Color(0xFF6B7280),
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
              fontSize: AppSizes.fontSizeSm * 0.8,
              color: const Color(0xFFFF6B35),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 40, // 48 * 0.8 (rounded)
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18, // 20 * 0.8 (rounded)
                height: 18,
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
                      fontSize: AppSizes.fontSizeMd * 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppSizes.sm * 0.8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: EdgeInsets.all(AppSizes.lg * 0.8),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            'Need Help?',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeSm * 0.8,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact your system administrator or BUKTRACK Support',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeXs * 0.8,
              color: const Color(0xFF60A5FA),
            ),
          ),
        ],
      ),
    );
  }
}
