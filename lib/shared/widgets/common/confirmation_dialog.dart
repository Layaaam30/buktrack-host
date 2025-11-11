import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Confirmation dialog for destructive actions
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final Color? iconColor;
  final bool isDangerous;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.icon = Icons.warning_amber_rounded,
    this.iconColor,
    this.isDangerous = true,
  });

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
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.error, size: 32),
            ),

            const SizedBox(height: AppSizes.lg),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.md),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.xxl),

            // Actions
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.md,
                      ),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: Text(
                      cancelText,
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

                // Confirm Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDangerous
                          ? AppColors.error
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
