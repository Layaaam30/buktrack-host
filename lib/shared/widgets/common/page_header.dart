import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Page Header Widget
/// Large banner at the top of pages with icon, title, description, and action button
class PageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionButtonText,
    this.onActionPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSizes.xxl : AppSizes.xxxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? AppColors.primary,
            (backgroundColor ?? AppColors.primary).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              icon,
              size: 32,
              color: textColor ?? Colors.white,
            ),
          ),
          
          const SizedBox(width: AppSizes.xl),
          
          // Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? AppSizes.fontSize2xl : 32,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? AppSizes.fontSizeSm : AppSizes.fontSizeMd,
                    color: (textColor ?? Colors.white).withOpacity(0.95),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button
          if (actionButtonText != null && !isMobile) ...[
            const SizedBox(width: AppSizes.xl),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                actionButtonText!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: backgroundColor ?? AppColors.primary,
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
          ],
        ],
      ),
    );
  }
}
