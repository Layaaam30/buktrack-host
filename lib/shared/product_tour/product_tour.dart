import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'tour_provider.dart';
import 'tour_model.dart';

class ProductTour extends StatefulWidget {
  final List<TourStep> steps;
  final bool isSuperAdmin;

  const ProductTour({
    super.key,
    required this.steps,
    this.isSuperAdmin = false,
  });

  @override
  State<ProductTour> createState() => _ProductTourState();
}

class _ProductTourState extends State<ProductTour>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TourProvider>(
      builder: (context, tourProvider, child) {
        if (!tourProvider.isTourActive ||
            tourProvider.currentStep >= widget.steps.length) {
          return const SizedBox.shrink();
        }

        final currentStep = widget.steps[tourProvider.currentStep];
        final isFirstStep = tourProvider.currentStep == 0;
        final isLastStep = tourProvider.currentStep == widget.steps.length - 1;

        return Stack(
          children: [
            // Dark overlay with blur
            GestureDetector(
              onTap: () {}, // Prevent clicks through overlay
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(color: Colors.black.withOpacity(0.75)),
              ),
            ),

            // Spotlight effect with speech bubble
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildTourWithSpotlight(
                      context,
                      currentStep,
                      isFirstStep,
                      isLastStep,
                      tourProvider,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTourWithSpotlight(
    BuildContext context,
    TourStep step,
    bool isFirstStep,
    bool isLastStep,
    TourProvider tourProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < AppSizes.tabletBreakpoint;

    // For center position, show centered card
    if (step.position == TourStepPosition.center ||
        step.targetKey.currentContext == null) {
      return Center(
        child: _buildTourCard(
          context,
          step,
          isFirstStep,
          isLastStep,
          tourProvider,
          isDark,
          isMobile,
          showArrow: false,
          arrowPosition: ArrowPosition.none,
          targetPosition: null,
          targetSize: null,
        ),
      );
    }

    // Get target element position and size
    try {
      final RenderBox? renderBox =
          step.targetKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null || !renderBox.hasSize) {
        return Center(
          child: _buildTourCard(
            context,
            step,
            isFirstStep,
            isLastStep,
            tourProvider,
            isDark,
            isMobile,
            showArrow: false,
            arrowPosition: ArrowPosition.none,
            targetPosition: null,
            targetSize: null,
          ),
        );
      }

      final position = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      return Stack(
        children: [
          // Spotlight effect
          _buildSpotlight(position, targetSize),

          // Speech bubble positioned next to target
          _buildPositionedSpeechBubble(
            context,
            step,
            position,
            targetSize,
            screenSize,
            isFirstStep,
            isLastStep,
            tourProvider,
            isDark,
            isMobile,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Tour positioning error: $e');
      return Center(
        child: _buildTourCard(
          context,
          step,
          isFirstStep,
          isLastStep,
          tourProvider,
          isDark,
          isMobile,
          showArrow: false,
          arrowPosition: ArrowPosition.none,
          targetPosition: null,
          targetSize: null,
        ),
      );
    }
  }

  Widget _buildSpotlight(Offset position, Size size) {
    return Positioned(
      left: position.dx - 8,
      top: position.dy - 8,
      child: Container(
        width: size.width + 16,
        height: size.height + 16,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.primary, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 60,
              spreadRadius: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedSpeechBubble(
    BuildContext context,
    TourStep step,
    Offset position,
    Size targetSize,
    Size screenSize,
    bool isFirstStep,
    bool isLastStep,
    TourProvider tourProvider,
    bool isDark,
    bool isMobile,
  ) {
    double? left, right, top, bottom;
    ArrowPosition arrowPosition = ArrowPosition.left;
    const double cardWidth = 320.0;
    const double spacing = 20.0;
    const double cardEstimatedHeight = 200.0;

    // Determine best position for speech bubble
    switch (step.position) {
      case TourStepPosition.right:
        // Position to the right of the target
        left = position.dx + targetSize.width + spacing;
        // Vertically center with target
        top = position.dy + (targetSize.height / 2) - (cardEstimatedHeight / 2);
        arrowPosition = ArrowPosition.left;

        // Check if it goes off screen right side
        if (left + cardWidth > screenSize.width - 16) {
          left = position.dx - cardWidth - spacing;
          arrowPosition = ArrowPosition.right;
        }

        // Ensure it doesn't go off screen top/bottom
        if (top < 16) top = 16;
        if (top + cardEstimatedHeight > screenSize.height - 16) {
          top = screenSize.height - cardEstimatedHeight - 16;
        }
        break;

      case TourStepPosition.left:
        // Position to the left of the target
        left = position.dx - cardWidth - spacing;
        top = position.dy + (targetSize.height / 2) - (cardEstimatedHeight / 2);
        arrowPosition = ArrowPosition.right;

        // If goes off left side, switch to right
        if (left < 16) {
          left = position.dx + targetSize.width + spacing;
          arrowPosition = ArrowPosition.left;
        }

        // Ensure it doesn't go off screen top/bottom
        if (top < 16) top = 16;
        if (top + cardEstimatedHeight > screenSize.height - 16) {
          top = screenSize.height - cardEstimatedHeight - 16;
        }
        break;

      case TourStepPosition.bottom:
        // Position below the target
        left = position.dx + (targetSize.width / 2) - (cardWidth / 2);
        top = position.dy + targetSize.height + spacing;
        arrowPosition = ArrowPosition.top;

        // Keep within screen bounds horizontally
        if (left < 16) left = 16;
        if (left + cardWidth > screenSize.width - 16) {
          left = screenSize.width - cardWidth - 16;
        }

        // If goes off bottom, position above instead
        if (top + cardEstimatedHeight > screenSize.height - 16) {
          top = position.dy - cardEstimatedHeight - spacing;
          arrowPosition = ArrowPosition.bottom;
        }
        break;

      case TourStepPosition.top:
        // Position above the target
        left = position.dx + (targetSize.width / 2) - (cardWidth / 2);
        top = position.dy - cardEstimatedHeight - spacing;
        arrowPosition = ArrowPosition.bottom;

        // Keep within screen bounds horizontally
        if (left < 16) left = 16;
        if (left + cardWidth > screenSize.width - 16) {
          left = screenSize.width - cardWidth - 16;
        }

        // If goes off top, position below instead
        if (top < 16) {
          top = position.dy + targetSize.height + spacing;
          arrowPosition = ArrowPosition.top;
        }
        break;

      case TourStepPosition.center:
        arrowPosition = ArrowPosition.none;
        break;
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: _buildTourCard(
        context,
        step,
        isFirstStep,
        isLastStep,
        tourProvider,
        isDark,
        isMobile,
        showArrow: true,
        arrowPosition: arrowPosition,
        targetPosition: position,
        targetSize: targetSize,
      ),
    );
  }

  Widget _buildTourCard(
    BuildContext context,
    TourStep step,
    bool isFirstStep,
    bool isLastStep,
    TourProvider tourProvider,
    bool isDark,
    bool isMobile, {
    required bool showArrow,
    required ArrowPosition arrowPosition,
    Offset? targetPosition,
    Size? targetSize,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.9 : 320,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Arrow pointer
          if (showArrow && arrowPosition != ArrowPosition.none)
            _buildArrow(arrowPosition, isDark, targetPosition, targetSize),

          // Main card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and close button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          step.icon,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isFirstStep)
                        IconButton(
                          onPressed: () =>
                              tourProvider.skipTour(widget.isSuperAdmin),
                          icon: Icon(
                            Icons.close,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ),

                // Divider
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                ),

                // Footer with navigation
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress indicator
                      Text(
                        '${tourProvider.currentStep + 1} of ${widget.steps.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Navigation buttons
                      Row(
                        children: [
                          if (!isFirstStep)
                            TextButton(
                              onPressed: () async {
                                await _controller.reverse();
                                tourProvider.previousStep();
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                                if (mounted) _controller.forward();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Back'),
                            )
                          else
                            TextButton(
                              onPressed: () =>
                                  tourProvider.skipTour(widget.isSuperAdmin),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Skip'),
                            ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            onPressed: () async {
                              if (isLastStep) {
                                tourProvider.completeTour(widget.isSuperAdmin);
                              } else {
                                await _controller.reverse();
                                tourProvider.nextStep();
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                                if (mounted) _controller.forward();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(isLastStep ? 'Get Started' : 'Next'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(
    ArrowPosition position,
    bool isDark,
    Offset? targetPosition,
    Size? targetSize,
  ) {
    final color = isDark ? const Color(0xFF1F2937) : Colors.white;
    const double arrowSize = 20.0;

    Widget arrow;
    double? left, right, top, bottom;

    switch (position) {
      case ArrowPosition.left:
        // Arrow points left (bubble is to the right of target)
        left = -arrowSize + 1;
        top = 60; // Position near the top of the card
        arrow = CustomPaint(
          size: const Size(arrowSize, arrowSize * 1.5),
          painter: LeftArrowPainter(color),
        );
        break;

      case ArrowPosition.right:
        // Arrow points right (bubble is to the left of target)
        right = -arrowSize + 1;
        top = 60;
        arrow = CustomPaint(
          size: const Size(arrowSize, arrowSize * 1.5),
          painter: RightArrowPainter(color),
        );
        break;

      case ArrowPosition.top:
        // Arrow points up (bubble is below target)
        left = 130; // Center horizontally
        top = -arrowSize + 1;
        arrow = CustomPaint(
          size: const Size(arrowSize * 1.5, arrowSize),
          painter: TopArrowPainter(color),
        );
        break;

      case ArrowPosition.bottom:
        // Arrow points down (bubble is above target)
        left = 130; // Center horizontally
        bottom = -arrowSize + 1;
        arrow = CustomPaint(
          size: const Size(arrowSize * 1.5, arrowSize),
          painter: BottomArrowPainter(color),
        );
        break;

      case ArrowPosition.none:
        return const SizedBox.shrink();
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: arrow,
    );
  }
}

enum ArrowPosition { left, right, top, bottom, none }

// Custom painters for arrows with borders
class LeftArrowPainter extends CustomPainter {
  final Color color;
  LeftArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF374151).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);

    // Draw fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RightArrowPainter extends CustomPainter {
  final Color color;
  RightArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF374151).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height);

    canvas.drawPath(borderPath, borderPaint);

    // Draw fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TopArrowPainter extends CustomPainter {
  final Color color;
  TopArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF374151).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);

    // Draw fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomArrowPainter extends CustomPainter {
  final Color color;
  BottomArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF374151).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);

    // Draw fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
