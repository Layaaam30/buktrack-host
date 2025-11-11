import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final double? change;
  final double? progress;
  final bool isLoading;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.change,
    this.progress,
    this.isLoading = false,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  Color _getColorForTheme(bool isDark) {
    final baseColor = widget.color ?? AppColors.info;
    return baseColor;
  }

  Color _getBackgroundColor(bool isDark) {
    final baseColor = widget.color ?? AppColors.info;
    if (isDark) {
      return baseColor.withOpacity(0.1);
    }
    // Light mode: lighter shade
    return Color.lerp(baseColor, Colors.white, 0.9)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppSizes.transitionFast,
        child: Card(
          elevation: _isHovered ? 8 : 0,
          shadowColor: isDark ? Colors.transparent : AppColors.shadowLight,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Value Row
                Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(isDark),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      ),
                      child: Icon(
                        widget.icon,
                        color: _getColorForTheme(isDark),
                        size: AppSizes.iconLg,
                      ),
                    ),

                    const SizedBox(width: AppSizes.lg),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSm,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),

                          const SizedBox(height: AppSizes.xs),

                          // Value and Change
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              // Value
                              if (widget.isLoading)
                                _buildLoadingShimmer()
                              else
                                Text(
                                  widget.value,
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSize2xl,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),

                              // Change indicator
                              if (widget.change != null &&
                                  !widget.isLoading) ...[
                                const SizedBox(width: AppSizes.sm),
                                _buildChangeIndicator(widget.change!),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Progress Bar
                if (widget.progress != null && !widget.isLoading) ...[
                  const SizedBox(height: AppSizes.lg),
                  _buildProgressBar(isDark),
                ],

                // Subtitle
                if (widget.subtitle != null && !widget.isLoading) ...[
                  const SizedBox(height: AppSizes.md),
                  Container(
                    padding: const EdgeInsets.only(top: AppSizes.md),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : Color(0xFFf3f4f6),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeXs,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      width: 60,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }

  Widget _buildChangeIndicator(double change) {
    final isPositive = change > 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${change.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = widget.progress!.clamp(0.0, 100.0);
    final baseColor = widget.color ?? AppColors.info;

    return Column(
      children: [
        // Progress label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.sm),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(baseColor),
            ),
          ),
        ),
      ],
    );
  }
}
