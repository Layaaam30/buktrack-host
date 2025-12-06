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
  final VoidCallback? onTap;
  final String? trendLabel;
  final Widget? customTrailing;

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
    this.onTap,
    this.trendLabel,
    this.customTrailing,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForTheme(bool isDark) {
    return widget.color ?? AppColors.info;
  }

  Color _getBackgroundColor(bool isDark) {
    final baseColor = widget.color ?? AppColors.info;
    if (isDark) {
      return baseColor.withOpacity(0.15);
    }
    return Color.lerp(baseColor, Colors.white, 0.88)!;
  }

  void _onHoverEnter(PointerEvent event) {
    if (!_isHovered) {
      setState(() => _isHovered = true);
      _animationController.forward();
    }
  }

  void _onHoverExit(PointerEvent event) {
    if (_isHovered) {
      setState(() => _isHovered = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: _onHoverEnter,
      onExit: _onHoverExit,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: _isHovered ? 12 : 2,
            shadowColor: isDark
                ? _getColorForTheme(isDark).withOpacity(0.3)
                : AppColors.shadowLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              side: BorderSide(
                color: _isHovered
                    ? _getColorForTheme(isDark).withOpacity(0.2)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                child: Stack(
                  children: [
                    // Large transparent background icon
                    Positioned(
                      right: -40,
                      top: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: isDark ? 0.08 : 0.05,
                        child: Icon(
                          widget.icon,
                          size: 160,
                          color: _getColorForTheme(isDark),
                        ),
                      ),
                    ),

                    // Subtle gradient overlay
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getColorForTheme(isDark).withOpacity(0.03),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(AppSizes.cardPadding),
                      child: Row(
                        children: [
                          // Icon on the left
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getColorForTheme(isDark),
                                  _getColorForTheme(isDark).withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getColorForTheme(
                                    isDark,
                                  ).withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: AppSizes.md),

                          // Main content on the right
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title with change indicator
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        style: TextStyle(
                                          fontSize: AppSizes.fontSizeSm,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Change indicator badge
                                    if (widget.change != null &&
                                        !widget.isLoading) ...[
                                      const SizedBox(width: AppSizes.xs),
                                      _buildModernChangeIndicator(
                                        widget.change!,
                                        isDark,
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: AppSizes.xs),

                                // Value
                                if (widget.isLoading)
                                  _buildLoadingShimmer()
                                else
                                  Text(
                                    widget.value,
                                    style: TextStyle(
                                      fontSize: AppSizes.fontSize2xl,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                // Progress Bar
                                if (widget.progress != null &&
                                    !widget.isLoading) ...[
                                  const SizedBox(height: AppSizes.md),
                                  _buildModernProgressBar(isDark),
                                ],

                                // Subtitle
                                if (widget.subtitle != null &&
                                    !widget.isLoading) ...[
                                  const SizedBox(height: AppSizes.md),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 12,
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.subtitle!,
                                          style: TextStyle(
                                            fontSize: AppSizes.fontSizeXs,
                                            height: 1.3,
                                            color: isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiaryLight,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Right side content
                          if (widget.customTrailing != null) ...[
                            const SizedBox(width: AppSizes.md),
                            widget.customTrailing!,
                          ] else if (widget.trendLabel != null ||
                              widget.onTap != null) ...[
                            const SizedBox(width: AppSizes.md),
                            _buildDefaultTrailing(isDark),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      width: 100,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
    );
  }

  Widget _buildModernChangeIndicator(double change, bool isDark) {
    final isPositive = change > 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProgressBar(bool isDark) {
    final progress = widget.progress!.clamp(0.0, 100.0);
    final baseColor = widget.color ?? AppColors.info;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: AppSizes.fontSizeXs,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXs,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.xs),

        // Modern progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.borderDark.withOpacity(0.3)
                : AppColors.borderLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(baseColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultTrailing(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Trend label or action icon
        if (widget.trendLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _getColorForTheme(isDark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  widget.trendLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.show_chart_rounded,
                  size: 20,
                  color: _getColorForTheme(isDark),
                ),
              ],
            ),
          ),

        // Action button if onTap is provided
        if (widget.onTap != null) ...[
          if (widget.trendLabel != null) const SizedBox(height: AppSizes.sm),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getColorForTheme(
                isDark,
              ).withOpacity(_isHovered ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: _getColorForTheme(isDark),
            ),
          ),
        ],
      ],
    );
  }
}
