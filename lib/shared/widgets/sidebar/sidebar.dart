import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../features/auth/auth_provider.dart';
import 'sidebar_link.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Sidebar extends StatelessWidget {
  final bool isExpanded;
  final bool isMobileOpen;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  const Sidebar({
    super.key,
    required this.isExpanded,
    required this.isMobileOpen,
    required this.onToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.wideDesktopBreakpoint;

    return AnimatedContainer(
      duration: AppSizes.transitionNormal,
      width: isExpanded
          ? AppSizes.sidebarWidthExpanded
          : AppSizes.sidebarWidthCollapsed,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Color(0xFFf3f4f6),
          border: Border(
            right: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: Column(
          children: [
            // Header Section
            _buildHeader(theme, isDark, isMobile),

            // Navigation Section
            Expanded(child: _buildNavigation(theme, isDark, context)),

            // User Section
            _buildUserSection(theme, isDark, context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, bool isMobile) {
    return Container(
      height: isExpanded
          ? AppSizes.headerHeight
          : null, // Auto height when collapsed
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: isExpanded
            ? AppSizes.md
            : AppSizes.xs, // Less padding when collapsed
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: isExpanded
          ? _buildExpandedHeader(isDark, isMobile)
          : _buildCollapsedHeader(isDark, isMobile),
    );
  }

  Widget _buildExpandedHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        _buildExpandedLogo(isDark),
        const Spacer(),
        if (!isMobile) _buildToggleButton(isDark),
        if (isMobile) _buildCloseButton(isDark),
      ],
    );
  }

  Widget _buildCollapsedHeader(bool isDark, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Use minimum space needed
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCollapsedLogo(),
        if (!isMobile) ...[
          const SizedBox(height: 4), // Reduced from AppSizes.sm (8px) to 4px
          _buildToggleButton(isDark),
        ],
      ],
    );
  }

  Widget _buildExpandedLogo(bool isDark) {
    return Row(
      children: [
        SvgPicture.asset(
          isDark
              ? 'assets/images/logos/light-logo.svg'
              : 'assets/images/logos/dark-logo.svg',
        ),
      ],
    );
  }

  Widget _buildCollapsedLogo() {
    return Container(
      width: 28, // Reduced from 32 to match toggle button
      height: 28,
      decoration: BoxDecoration(
        gradient: AppColors.orangeGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        color: Colors.white,
        size: 16, // Reduced from 20
      ),
    );
  }

  Widget _buildToggleButton(bool isDark) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        isExpanded ? Icons.chevron_left : Icons.chevron_right,
        size: 18, // Reduced from 20
      ),
      style: IconButton.styleFrom(
        backgroundColor: isDark ? AppColors.hoverDark : Colors.white,
        foregroundColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        padding: const EdgeInsets.all(6), // Reduced from 8
        minimumSize: const Size(28, 28), // Reduced from 32x32
        maximumSize: const Size(28, 28),
      ),
    );
  }

  Widget _buildCloseButton(bool isDark) {
    return IconButton(
      onPressed: onClose,
      icon: const Icon(Icons.close, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: isDark ? AppColors.hoverDark : Colors.white,
        foregroundColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildNavigation(ThemeData theme, bool isDark, BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Section
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: Text(
                    'MAIN',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXs,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textTertiaryLight
                          : AppColors.textTertiaryDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

              const SizedBox(height: AppSizes.sm),

              SidebarLink(
                icon: TablerIcons.dashboard,
                label: 'Dashboard',
                isExpanded: isExpanded,
                isActive: navigationProvider.isActive('/dashboard'),
                onTap: () {
                  navigationProvider.navigateTo('/dashboard');
                  if (isMobileOpen) onClose();
                },
              ),

              SidebarLink(
                icon: TablerIcons.users,
                label: 'Account Management',
                isExpanded: isExpanded,
                isActive: navigationProvider.isActive('/account-management'),
                onTap: () {
                  navigationProvider.navigateTo('/account-management');
                  if (isMobileOpen) onClose();
                },
              ),

              SidebarLink(
                icon: TablerIcons.bus,
                label: 'Bus Management',
                isExpanded: isExpanded,
                isActive: navigationProvider.isActive('/bus-management'),
                onTap: () {
                  navigationProvider.navigateTo('/bus-management');
                  if (isMobileOpen) onClose();
                },
              ),

              SidebarLink(
                icon: TablerIcons.route,
                label: 'Route Management',
                isExpanded: isExpanded,
                isActive: navigationProvider.isActive('/route-management'),
                onTap: () {
                  navigationProvider.navigateTo('/route-management');
                  if (isMobileOpen) onClose();
                },
              ),

              const SizedBox(height: AppSizes.xl),

              // Activity Section
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: Text(
                    'ACTIVITY',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXs,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textTertiaryLight
                          : AppColors.textTertiaryDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

              const SizedBox(height: AppSizes.sm),

              SidebarLink(
                icon: TablerIcons.activity,
                label: 'Activity Logs',
                isExpanded: isExpanded,
                isActive: navigationProvider.isActive('/activity-logs'),
                onTap: () {
                  navigationProvider.navigateTo('/activity-logs');
                  if (isMobileOpen) onClose();
                  // TODO: Implement activity logs screen
                },
              ),

              const SizedBox(height: AppSizes.xl),

              // System Section
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXs,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textTertiaryLight
                          : AppColors.textTertiaryDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

              const SizedBox(height: AppSizes.sm),

              SidebarLink(
                icon: TablerIcons.settings,
                label: 'Settings',
                isExpanded: isExpanded,
                isActive: navigationProvider.isActive('/settings'),
                onTap: () {
                  navigationProvider.navigateTo('/settings');
                  if (isMobileOpen) onClose();
                  // TODO: Implement settings screen
                },
              ),

              // Dark Mode Toggle
              const SizedBox(height: AppSizes.lg),
              _buildDarkModeToggle(theme, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDarkModeToggle(ThemeData theme, bool isDark) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (!isExpanded) {
          // When collapsed, show just a centered icon button
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.sm,
            ),
            child: Center(
              child: IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark ? TablerIcons.sun : TablerIcons.moon,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.hoverDark : Colors.white,
                  foregroundColor: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(40, 40),
                  maximumSize: const Size(40, 40),
                ),
                tooltip: isDark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              ),
            ),
          );
        }

        // When expanded, show full toggle with switch
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.sm,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.hoverDark.withOpacity(0.3)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.moon,
                  size: AppSizes.iconMd,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    'Dark mode',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserSection(ThemeData theme, bool isDark, BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final adminName = authProvider.adminName ?? 'Admin User';
        final adminEmail = authProvider.adminEmail ?? 'admin@example.com';
        final firstLetter = adminName.isNotEmpty
            ? adminName[0].toUpperCase()
            : 'A';

        return Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: isExpanded
              ? _buildExpandedUserSection(
                  isDark,
                  context,
                  authProvider,
                  adminName,
                  adminEmail,
                  firstLetter,
                )
              : _buildCollapsedUserSection(
                  isDark,
                  context,
                  authProvider,
                  firstLetter,
                ),
        );
      },
    );
  }

  Widget _buildExpandedUserSection(
    bool isDark,
    BuildContext context,
    AuthProvider authProvider,
    String adminName,
    String adminEmail,
    String firstLetter,
  ) {
    return InkWell(
      onTap: () {
        _showUserMenu(context, isDark, authProvider);
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            // Avatar with online indicator
            _buildUserAvatar(isDark, firstLetter),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adminName,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    adminEmail,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXs,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _handleLogout(context, authProvider),
              icon: const Icon(TablerIcons.logout, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              tooltip: 'Logout',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedUserSection(
    bool isDark,
    BuildContext context,
    AuthProvider authProvider,
    String firstLetter,
  ) {
    return Center(
      child: InkWell(
        onTap: () {
          _showUserMenu(context, isDark, authProvider);
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: _buildUserAvatar(isDark, firstLetter),
      ),
    );
  }

  Widget _buildUserAvatar(bool isDark, String firstLetter) {
    return Stack(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Center(
            child: Text(
              firstLetter,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.fontSizeSm,
              ),
            ),
          ),
        ),
        // Online indicator
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: isDark ? AppColors.surfaceDark : Color(0xFFf3f4f6),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUserMenu(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                TablerIcons.user,
                size: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSizes.sm),
              Text('Profile', style: TextStyle(fontSize: AppSizes.fontSizeSm)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                TablerIcons.settings,
                size: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSizes.sm),
              Text('Settings', style: TextStyle(fontSize: AppSizes.fontSizeSm)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(TablerIcons.logout, size: 16, color: AppColors.error),
              const SizedBox(width: AppSizes.sm),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'profile') {
        // TODO: Navigate to profile
      } else if (value == 'settings') {
        // TODO: Navigate to settings
      } else if (value == 'logout') {
        _handleLogout(context, authProvider);
      }
    });
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Perform logout
      await authProvider.signOut();
      // Navigation will be handled automatically by app.dart watching auth state
    }
  }
}
