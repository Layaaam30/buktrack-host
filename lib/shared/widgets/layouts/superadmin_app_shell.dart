import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/navigation_provider.dart';
import '../sidebar/superadmin_sidebar.dart';

import 'package:google_fonts/google_fonts.dart';

class SuperAdminShell extends StatefulWidget {
  final Map<String, Widget> routes;

  const SuperAdminShell({super.key, required this.routes});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  bool _isSidebarExpanded = true;
  bool _isMobileSidebarOpen = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
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
          Row(
            children: [
              if (isDesktop)
                SuperAdminSidebar(
                  isExpanded: _isSidebarExpanded,
                  isMobileOpen: false,
                  onToggle: _toggleSidebar,
                  onClose: _closeMobileSidebar,
                ),

              Expanded(
                child: Column(
                  children: [
                    if (isMobile) _buildMobileHeader(isDark),

                    Expanded(child: _buildContentArea(isMobile)),
                  ],
                ),
              ),
            ],
          ),

          if (isMobile && _isMobileSidebarOpen) ...[
            GestureDetector(
              onTap: _closeMobileSidebar,
              child: Container(color: AppColors.overlay),
            ),

            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SuperAdminSidebar(
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

          Text(
            'BUKTRACK',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'SUPERADMIN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(bool isMobile) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final currentRoute = navigationProvider.currentRoute;
        final screenWidget =
            widget.routes[currentRoute] ?? widget.routes['/dashboard']!;
        return Padding(
          padding: EdgeInsets.all(isMobile ? AppSizes.lg : AppSizes.xxxl),
          child: screenWidget,
        );
      },
    );
  }
}
