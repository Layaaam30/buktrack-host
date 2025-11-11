import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/common/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // TODO: Load actual data from Firebase
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          _buildPageHeader(isDark),

          const SizedBox(height: AppSizes.xxl),

          // Stats Grid
          _buildStatsGrid(isMobile),

          const SizedBox(height: AppSizes.xxxl),

          // TODO: Add more dashboard widgets
          // - Recent Activities
          // - Active Buses Map
          // - Revenue Charts
          // - Passenger Analytics
          _buildPlaceholderContent(isDark),

          // Bottom spacing
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  Widget _buildPageHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: AppSizes.fontSize2xl,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Welcome to your admin dashboard',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid
        int crossAxisCount = 4;
        if (constraints.maxWidth < AppSizes.mobileBreakpoint) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < AppSizes.desktopBreakpoint) {
          crossAxisCount = 2;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.xl,
          mainAxisSpacing: AppSizes.xl,
          childAspectRatio: isMobile ? 2.5 : 1.5,
          children: [
            StatCard(
              title: 'Total Buses',
              value: '24',
              icon: Icons.directions_bus_rounded,
              color: AppColors.info,
              subtitle: 'Fleet size',
              change: 8.5,
              isLoading: _isLoading,
            ),
            StatCard(
              title: 'Active Buses',
              value: '18',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              subtitle: 'Currently operational',
              change: 12.3,
              isLoading: _isLoading,
            ),
            StatCard(
              title: 'Maintenance',
              value: '4',
              icon: Icons.build_rounded,
              color: AppColors.warning,
              subtitle: 'Under maintenance',
              change: -5.2,
              isLoading: _isLoading,
            ),
            StatCard(
              title: 'Inactive',
              value: '2',
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              subtitle: 'Not operational',
              change: -15.0,
              isLoading: _isLoading,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderContent(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          children: [
            Icon(
              Icons.analytics_rounded,
              size: 64,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'More Dashboard Widgets Coming Soon',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Analytics, charts, and real-time tracking will be added in the next phase',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
