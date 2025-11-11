import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/navigation_provider.dart';
import '../sidebar/sidebar.dart';

/// App Shell - for single page application navigation
/// The sidebar stays persistent while content area switches screens
class AppShell extends StatefulWidget {
  final Map<String, Widget> routes;

  const AppShell({super.key, required this.routes});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isSidebarExpanded = true;
  bool _isMobileSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    // TODO: Load sidebar state from shared preferences
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
    // TODO: Save sidebar state to shared preferences
  }

  void _closeMobileSidebar() {
    setState(() {
      _isMobileSidebarOpen = false;
    });
  }

  void _openMobileSidebar() {
    setState(() {
      _isMobileSidebarOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= AppSizes.wideDesktopBreakpoint;
    final isMobile = size.width < AppSizes.wideDesktopBreakpoint;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Main Content with Sidebar
          Row(
            children: [
              // Sidebar (Desktop) - This stays persistent
              if (isDesktop)
                Sidebar(
                  isExpanded: _isSidebarExpanded,
                  isMobileOpen: false,
                  onToggle: _toggleSidebar,
                  onClose: _closeMobileSidebar,
                ),

              // Main Content Area - This switches between screens
              Expanded(
                child: Column(
                  children: [
                    // Mobile Header with Menu Button
                    if (isMobile) _buildMobileHeader(isDark),

                    // Page Content - SPA style content switcher
                    Expanded(child: _buildContentArea(isMobile)),
                  ],
                ),
              ),
            ],
          ),

          // Mobile Sidebar Overlay
          if (isMobile && _isMobileSidebarOpen) ...[
            // Backdrop
            GestureDetector(
              onTap: _closeMobileSidebar,
              child: Container(color: AppColors.overlay),
            ),

            // Sidebar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Sidebar(
                isExpanded: true,
                isMobileOpen: _isMobileSidebarOpen,
                onToggle: _toggleSidebar,
                onClose: _closeMobileSidebar,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileHeader(bool isDark) {
    return Container(
      height: AppSizes.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu Button
          IconButton(
            onPressed: _openMobileSidebar,
            icon: const Icon(Icons.menu_rounded),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.hoverDark
                  : AppColors.hoverLight,
            ),
          ),

          const SizedBox(width: AppSizes.md),

          // Logo
          Row(
            children: [
              Text(
                'BUK',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'TRACK',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),

          const Spacer(),

          // User Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.orangeGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.fontSizeSm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SPA-style content switcher - no animations, instant switching
  Widget _buildContentArea(bool isMobile) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        // Get the current screen widget based on route
        final currentRoute = navigationProvider.currentRoute;
        final screenWidget =
            widget.routes[currentRoute] ?? widget.routes['/dashboard']!;

        // Wrap in padding for consistent spacing
        return Padding(
          padding: EdgeInsets.all(isMobile ? AppSizes.lg : AppSizes.xxxl),
          child: screenWidget,
        );
      },
    );
  }
}
