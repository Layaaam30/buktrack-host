import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/common/stat_card.dart';
import '../auth/auth_provider.dart';
import 'dashboard_analytics_provider.dart';
import 'dashboard_analytics_service.dart';
import 'package:tabler_icons/tabler_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _bounceController.repeat(reverse: true);
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final analyticsProvider = Provider.of<DashboardAnalyticsProvider>(context, listen: false);
    
    final companyId = authProvider.companyId;
    
    if (companyId != null && companyId.isNotEmpty) {
      analyticsProvider.setCompanyId(companyId);
      await analyticsProvider.loadAllAnalytics();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Consumer<DashboardAnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        return RefreshIndicator(
          onRefresh: () => analyticsProvider.refreshAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Page Header
                _buildEnhancedHeader(isDark, isMobile, analyticsProvider),

                const SizedBox(height: AppSizes.xxl),

                // Summary Stats Grid
                _buildSummaryStatsGrid(isMobile, analyticsProvider, isDark),

                const SizedBox(height: AppSizes.xxxl),

                // Analytics Charts
                if (analyticsProvider.isLoading)
                  _buildLoadingState(isDark)
                else if (analyticsProvider.error != null)
                  _buildErrorState(analyticsProvider.error!, isDark)
                else ...[
                  // Row 1: Hourly Trend + Weekly Trend
                  _buildChartsRow(
                    isMobile,
                    [
                      _buildHourlyTrendChart(analyticsProvider, isDark),
                      _buildWeeklyTrendChart(analyticsProvider, isDark),
                    ],
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  // Row 2: Bus Type Occupancy
                  _buildBusTypeOccupancyChart(analyticsProvider, isDark, isMobile),

                  const SizedBox(height: AppSizes.xxl),

                  // Row 3: Route Distribution (optional - requires route selection)
                  _buildRouteDistributionSection(analyticsProvider, isDark, isMobile),
                ],

                // Bottom spacing
                const SizedBox(height: AppSizes.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDashboardIcon() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(TablerIcons.chart_bar, color: Colors.white, size: 32),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(bool isDark, bool isMobile, DashboardAnalyticsProvider analyticsProvider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: const LinearGradient(
          colors: [Color(0xFF4f46e5), Color(0xFF2563eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAnimatedDashboardIcon(),
                          const SizedBox(width: AppSizes.lg),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analytics Dashboard',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Text(
                        'Timely passenger analytics and insights to optimize your fleet\noperations and improve service efficiency.',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: const Color(0xFFe0e7ff),
                          height: 1.6,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: AppSizes.xl),
                  _buildRefreshButton(analyticsProvider),
                ],
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: AppSizes.xl),
              SizedBox(
                width: double.infinity,
                child: _buildRefreshButton(analyticsProvider),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(DashboardAnalyticsProvider analyticsProvider) {
    return ElevatedButton.icon(
      onPressed: () => analyticsProvider.refreshAllData(),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFdbeafe),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(TablerIcons.refresh, color: Color(0xFF2563eb), size: 20),
      ),
      label: const Text(
        'Refresh Data',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2563eb),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildSummaryStatsGrid(
    bool isMobile,
    DashboardAnalyticsProvider analyticsProvider,
    bool isDark,
  ) {
    final summary = analyticsProvider.dashboardSummary ?? {};
    
    return LayoutBuilder(
      builder: (context, constraints) {
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
              value: '${summary['total_buses'] ?? 0}',
              icon: TablerIcons.bus,
              color: AppColors.info,
              subtitle: 'Fleet size',
              isLoading: analyticsProvider.isLoading,
            ),
            StatCard(
              title: 'Active Trips',
              value: '${summary['active_trips_today'] ?? 0}',
              icon: TablerIcons.route,
              color: AppColors.success,
              subtitle: 'Today',
              isLoading: analyticsProvider.isLoading,
            ),
            StatCard(
              title: 'Passengers Today',
              value: '${analyticsProvider.totalPassengersToday}',
              icon: TablerIcons.users,
              color: AppColors.primary,
              subtitle: 'Total boardings',
              isLoading: analyticsProvider.isLoading,
            ),
            StatCard(
              title: 'Peak Hour',
              value: analyticsProvider.peakHour != null 
                  ? '${analyticsProvider.peakHour}:00' 
                  : '--',
              icon: TablerIcons.clock,
              color: AppColors.warning,
              subtitle: 'Busiest time',
              isLoading: analyticsProvider.isLoading,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsRow(bool isMobile, List<Widget> charts) {
    if (isMobile) {
      return Column(
        children: charts.map((chart) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.xxl),
          child: chart,
        )).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: charts.map((chart) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: AppSizes.xl),
          child: chart,
        ),
      )).toList(),
    );
  }

  // ========== 1. HOURLY TREND CHART ==========
  Widget _buildHourlyTrendChart(DashboardAnalyticsProvider provider, bool isDark) {
    final data = provider.hourlyTrend;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Passenger Trend',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeLg,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Boardings by hour (Today)',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => provider.refreshHourlyTrend(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xxl),
            if (data == null || data.isEmpty)
              _buildNoDataPlaceholder('No boarding data for today', isDark)
            else
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${value.toInt()}h',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: 23,
                    minY: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========== 2. WEEKLY TREND CHART ==========
  Widget _buildWeeklyTrendChart(DashboardAnalyticsProvider provider, bool isDark) {
    final data = provider.weeklyTrend;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Passenger Trend',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeLg,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Boardings by day (Past 7 days)',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => provider.refreshWeeklyTrend(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xxl),
            if (data == null || data.isEmpty)
              _buildNoDataPlaceholder('No boarding data for this week', isDark)
            else
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _weeklyDataToSpots(data),
                        isCurved: true,
                        color: AppColors.success,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.success.withOpacity(0.1),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _weeklyDataToSpots(Map<String, int> data) {
    final dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final spots = <FlSpot>[];
    
    for (int i = 0; i < dayOrder.length; i++) {
      final count = data[dayOrder[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    
    return spots;
  }

  // ========== 4. BUS TYPE OCCUPANCY CHART ==========
  Widget _buildBusTypeOccupancyChart(
    DashboardAnalyticsProvider provider,
    bool isDark,
    bool isMobile,
  ) {
    final data = provider.busTypeOccupancy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus Type Average Occupancy',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeLg,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Average capacity utilization (Past 30 days)',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => provider.refreshBusTypeOccupancy(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xxl),
            if (data == null || data.isEmpty)
              _buildNoDataPlaceholder('No occupancy data available', isDark)
            else
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)}%',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 20,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final types = ['Small', 'Medium', 'Large'];
                            if (value.toInt() >= 0 && value.toInt() < types.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  types[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: _busTypeDataToBarGroups(data),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _busTypeDataToBarGroups(Map<String, double> data) {
    final types = ['Small', 'Medium', 'Large'];
    final colors = [AppColors.info, AppColors.success, AppColors.primary];
    
    return List.generate(types.length, (index) {
      final busType = types[index];
      final value = data[busType] ?? 0.0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: colors[index],
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });
  }

  // ========== 3. ROUTE DISTRIBUTION SECTION ==========
  Widget _buildRouteDistributionSection(
    DashboardAnalyticsProvider provider,
    bool isDark,
    bool isMobile,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passenger Distribution Along Route',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Select a route to view boarding and alighting distribution',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'This feature requires route selection and will be available in the full implementation.',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Loading analytics data...',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Failed to load analytics',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              error,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataPlaceholder(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}