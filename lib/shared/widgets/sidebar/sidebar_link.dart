import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SidebarLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarLink({
    super.key,
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<SidebarLink> createState() => _SidebarLinkState();
}

class _SidebarLinkState extends State<SidebarLink>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SidebarLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // When collapsed, show ONLY the icon - absolutely no text
    if (!widget.isExpanded) {
      return _buildCollapsedLink(isDark);
    }

    // When expanded, show full link with icon and label
    return _buildExpandedLink(isDark);
  }

  // Collapsed state - ONLY icon, no text whatsoever
  Widget _buildCollapsedLink(bool isDark) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Tooltip(
          message: widget.label,
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isActive ? null : widget.onTap,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: widget.isActive
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFf97316), // orange-500
                            Color(0xFFea580c), // orange-600
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isActive
                      ? null
                      : (_isHovered
                            ? (isDark ? AppColors.hoverDark : Colors.white)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFFf97316).withOpacity(0.25),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                            spreadRadius: -8,
                          ),
                        ]
                      : (_isHovered
                            ? [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : []),
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: _isHovered && !widget.isActive ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      size: AppSizes.iconMd,
                      color: widget.isActive
                          ? Colors.white
                          : (_isHovered
                                ? const Color(0xFFf97316)
                                : (isDark
                                      ? const Color(0xFF9ca3af)
                                      : const Color(0xFF6b7280))),
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

  // Expanded state - Full link with icon and label
  Widget _buildExpandedLink(bool isDark) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(_isHovered && !widget.isActive ? 4.0 : 0.0, 0.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isActive ? null : widget.onTap,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              child: Stack(
                children: [
                  // Background with gradient for active state
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.isActive
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFf97316), // orange-500
                                Color(0xFFea580c), // orange-600
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: widget.isActive
                          ? null
                          : (_isHovered
                                ? (isDark ? AppColors.hoverDark : Colors.white)
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFf97316,
                                ).withOpacity(0.25),
                                blurRadius: 25,
                                offset: const Offset(0, 8),
                                spreadRadius: -8,
                              ),
                            ]
                          : (_isHovered
                                ? [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : []),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Icon with scale animation on hover
                        AnimatedScale(
                          scale: _isHovered && !widget.isActive ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.icon,
                            size: AppSizes.iconMd,
                            color: widget.isActive
                                ? Colors.white
                                : (_isHovered
                                      ? const Color(0xFFf97316)
                                      : (isDark
                                            ? const Color(0xFF9ca3af)
                                            : const Color(0xFF6b7280))),
                          ),
                        ),

                        const SizedBox(width: AppSizes.md),

                        // Label
                        Expanded(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSm,
                              fontWeight: FontWeight.normal,
                              color: widget.isActive
                                  ? Colors.white
                                  : (_isHovered
                                        ? const Color(0xFFf97316)
                                        : (isDark
                                              ? const Color(0xFF9ca3af)
                                              : const Color(0xFF374151))),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),

                        // Active indicator dot
                        if (widget.isActive)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: AppSizes.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Pulse animation overlay for active state
                  if (widget.isActive)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFfb923c).withOpacity(
                                    0.2 * (1 - _pulseAnimation.value),
                                  ),
                                  const Color(0xFFea580c).withOpacity(
                                    0.2 * (1 - _pulseAnimation.value),
                                  ),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusXl,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Shimmer overlay effect on hover
                  if (!widget.isActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(_isHovered ? 0.1 : 0.0),
                              Colors.white.withOpacity(_isHovered ? 0.05 : 0.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusXl,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
