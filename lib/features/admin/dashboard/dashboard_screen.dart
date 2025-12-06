import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/common/stat_card.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_provider.dart';
import 'dashboard_analytics_provider.dart';
import 'dashboard_analytics_service.dart';

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
    final analyticsProvider = Provider.of<DashboardAnalyticsProvider>(
      context,
      listen: false,
    );

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
                _buildEnhancedHeader(isDark, isMobile, analyticsProvider),
                const SizedBox(height: AppSizes.xxl),

                _buildSummaryStatsGrid(isMobile, analyticsProvider, isDark),
                const SizedBox(height: AppSizes.xxxl),

                if (analyticsProvider.isLoading)
                  _buildLoadingState(isDark)
                else if (analyticsProvider.error != null)
                  _buildErrorState(analyticsProvider.error!, isDark)
                else ...[
                  _buildPassengerTrendsSection(
                    analyticsProvider,
                    isDark,
                    isMobile,
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  _buildWeeklyHeatmapSection(
                    analyticsProvider,
                    isDark,
                    isMobile,
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  _buildLocationStatsSection(
                    analyticsProvider,
                    isDark,
                    isMobile,
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  _buildLocationHourlyTrendSection(
                    analyticsProvider,
                    isDark,
                    isMobile,
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  _buildPreferredBusTypeSection(
                    analyticsProvider,
                    isDark,
                    isMobile,
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  _buildPeakDaysSection(analyticsProvider, isDark, isMobile),
                ],

                const SizedBox(height: AppSizes.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(
    bool isDark,
    bool isMobile,
    DashboardAnalyticsProvider analyticsProvider,
  ) {
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
            child: const Icon(
              TablerIcons.chart_bar,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefreshButton(DashboardAnalyticsProvider provider) {
    return ElevatedButton.icon(
      onPressed: provider.isLoading ? null : () => provider.refreshAllData(),
      icon: const Icon(TablerIcons.refresh, size: 20),
      label: const Text('Refresh Data'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4f46e5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
    );
  }

  Widget _buildSummaryStatsGrid(
    bool isMobile,
    DashboardAnalyticsProvider provider,
    bool isDark,
  ) {
    final summary = provider.dashboardSummary ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile
            ? 1
            : (constraints.maxWidth > 1200 ? 4 : 2);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.lg,
          mainAxisSpacing: AppSizes.lg,
          childAspectRatio: isMobile ? 2.5 : 2.2,
          children: [
            StatCard(
              title: 'Total Buses',
              value: '${summary['total_buses'] ?? 0}',
              icon: TablerIcons.bus,
              color: AppColors.primary,
              // hoverDescription:
              //     'Total number of buses registered and available in your fleet for active operations.',
            ),
            StatCard(
              title: 'Active Routes',
              value: '${summary['total_routes'] ?? 0}',
              icon: TablerIcons.route,
              color: AppColors.success,
              // hoverDescription:
              //     'Number of bus routes currently in operation and available for passenger travel.',
            ),
            StatCard(
              title: 'Active Trips Today',
              value: '${summary['active_trips_today'] ?? 0}',
              icon: TablerIcons.map_pin,
              color: AppColors.warning,
              // hoverDescription:
              //     'Total trips scheduled and completed today across all routes and buses in the system.',
            ),
            StatCard(
              title: 'Passengers Today',
              value: '${provider.totalPassengersToday}',
              icon: TablerIcons.users,
              color: AppColors.info,
              // hoverDescription:
              //     'Total number of passengers who have traveled on your buses today across all routes.',
            ),
          ],
        );
      },
    );
  }

  // First chart. Passenger Trend Widgets
  Widget _buildPassengerTrendsSection(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passenger Trend',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeLg,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View passenger boarding trends by time period',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildTimePeriodFilter(provider, isDark),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(height: 350, child: _buildTrendChart(provider, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePeriodFilter(
    DashboardAnalyticsProvider provider,
    bool isDark,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: DropdownButton<String>(
          value: provider.selectedTimePeriod,
          isDense: true,
          isExpanded: false,
          icon: Icon(
            TablerIcons.chevron_down,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          underline: const SizedBox(),
          items: [
            DropdownMenuItem(
              value: 'today',
              child: Text(
                'Today (Hourly)',
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'daily',
              child: Text(
                'Last 30 Days (Daily)',
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'monthly',
              child: Text(
                'Last 12 Months',
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
          selectedItemBuilder: (context) {
            return [
              _buildTimePeriodItem('Today (Hourly)', isDark),
              _buildTimePeriodItem('Last 30 Days (Daily)', isDark),
              _buildTimePeriodItem('Last 12 Months', isDark),
            ];
          },
          onChanged: (value) {
            if (value != null) {
              provider.setTimePeriod(value);
            }
          },
          dropdownColor: isDark ? AppColors.backgroundDark : Colors.white,
        ),
      ),
    );
  }

  Widget _buildTimePeriodItem(String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          TablerIcons.clock,
          size: 18,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(DashboardAnalyticsProvider provider, bool isDark) {
    final period = provider.selectedTimePeriod;

    if (period == 'today') {
      return _buildHourlyTrendChart(
        provider.liveHourlyTrend,
        isDark,
        'Live - Today',
      );
    } else if (period == 'daily') {
      return _buildDailyTrendChart(provider.dailyTrend30Days, isDark);
    } else if (period == 'monthly') {
      return _buildMonthlyLineChart(provider.monthlyTrend, isDark);
    }

    return const Center(child: Text('No data'));
  }

  Widget _buildHourlyTrendChart(
    Map<int, int>? data,
    bool isDark,
    String title,
  ) {
    if (data == null || data.isEmpty) {
      return _buildNoDataPlaceholder('No hourly data available', isDark);
    }

    final spots = data.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                final period = hour >= 12 ? 'PM' : 'AM';
                final displayHour = hour == 0
                    ? 12
                    : (hour > 12 ? hour - 12 : hour);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '$displayHour$period',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final hour = spot.x.toInt();
              final period = hour >= 12 ? 'PM' : 'AM';
              final displayHour = hour == 0
                  ? 12
                  : (hour > 12 ? hour - 12 : hour);
              return LineTooltipItem(
                '$displayHour:00 $period\n${spot.y.toInt()} passengers',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTrendChart(Map<String, int>? data, bool isDark) {
    if (data == null || data.isEmpty) {
      return _buildNoDataPlaceholder('No daily data available', isDark);
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withOpacity(0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (sortedEntries.length / 6).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length) {
                  final date = DateTime.parse(sortedEntries[value.toInt()].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              if (spot.spotIndex >= 0 &&
                  spot.spotIndex < sortedEntries.length) {
                final date = DateTime.parse(sortedEntries[spot.spotIndex].key);
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} passengers',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyLineChart(Map<String, int>? data, bool isDark) {
    if (data == null || data.isEmpty) {
      return _buildNoDataPlaceholder('No monthly data available', isDark);
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.info,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.info.withOpacity(0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                '${(value / 1000).toStringAsFixed(0)}k',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length) {
                  final monthKey = sortedEntries[value.toInt()].key;
                  final date = DateTime.parse('$monthKey-01');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              if (spot.spotIndex >= 0 &&
                  spot.spotIndex < sortedEntries.length) {
                final monthKey = sortedEntries[spot.spotIndex].key;
                final date = DateTime.parse('$monthKey-01');
                return LineTooltipItem(
                  '${DateFormat('MMM yyyy').format(date)}\n${spot.y.toInt()} passengers',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            }).toList(),
          ),
        ),
      ),
    );
  }
  // end first chart - Passenger Trend

  // Second chart - Heatmaps (start)
  Widget _buildHeatmap(Map<String, Map<int, int>> data, bool isDark) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    int maxValue = 0;
    for (var dayData in data.values) {
      for (var value in dayData.values) {
        if (value > maxValue) maxValue = value;
      }
    }

    const double cellSize = 34.0;
    const double dayLabelWidth = 120.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: cellSize, width: dayLabelWidth),
                ...dayNames.map(
                  (day) => Container(
                    height: cellSize,
                    width: dayLabelWidth,
                    padding: const EdgeInsets.only(right: 15),
                    alignment: Alignment.centerRight,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Heatmap grid
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(24, (hour) {
                    String label;
                    if (hour == 0) {
                      label = '12AM';
                    } else if (hour < 12) {
                      label = '${hour}AM';
                    } else if (hour == 12) {
                      label = '12PM';
                    } else {
                      label = '${hour - 12}PM';
                    }

                    return SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Heatmap cells
                ...dayNames.map((day) {
                  final dayData = data[day] ?? {};
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(24, (hour) {
                      final value = dayData[hour] ?? 0;
                      final intensity = maxValue > 0 ? value / maxValue : 0.0;

                      return Container(
                        width: cellSize - 2,
                        height: cellSize - 2,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: _getHeatmapColor(intensity, isDark),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: value > 0
                              ? Text(
                                  value.toString(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: intensity > 0.5
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHeatmapColor(double intensity, bool isDark) {
    if (intensity == 0) {
      return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    }

    final baseColor = AppColors.primary;
    return Color.lerp(
      isDark ? Colors.grey.shade700 : Colors.grey.shade200,
      baseColor,
      intensity,
    )!;
  }

  Map<String, Map<int, int>> _ensureHeatmapData(
    Map<String, Map<int, int>>? data,
  ) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final result = <String, Map<int, int>>{};

    for (var day in dayNames) {
      result[day] = {};
      for (int hour = 0; hour < 24; hour++) {
        result[day]![hour] = data?[day]?[hour] ?? 0;
      }
    }

    return result;
  }

  Widget _buildWeeklyHeatmapSection(
    DashboardAnalyticsProvider provider,
    bool isDark,
    bool isMobile,
  ) {
    final rawHeatmapData = provider.weeklyHeatmap;

    if (rawHeatmapData == null || rawHeatmapData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          child: _buildNoDataPlaceholder('No heatmap data', isDark),
        ),
      );
    }

    final heatmapData = _ensureHeatmapData(rawHeatmapData);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Activity Heatmap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Passenger activity by day and hour',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              provider.currentWeekLabel ?? 'All Weeks',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Busiest Day Badge and Week Filter
                Row(
                  children: [
                    if (provider.busiestDayOfWeek != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              TablerIcons.flame,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Busiest: ${provider.busiestDayOfWeek}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 12),
                    _buildWeekFilterDropdown(provider, isDark),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSizes.xl),

            // Heatmap and Legend Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 0, child: _buildHeatmap(heatmapData, isDark)),

                const SizedBox(width: AppSizes.xl),

                if (!isMobile)
                  SizedBox(
                    width: 524,
                    child: _buildHeatmapLegend(heatmapData, isDark),
                  ),
              ],
            ),

            if (isMobile) ...[
              const SizedBox(height: AppSizes.xl),
              _buildHeatmapLegend(heatmapData, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekFilterDropdown(
    DashboardAnalyticsProvider provider,
    bool isDark,
  ) {
    final availableWeeks = provider.availableWeeks ?? [];

    if (availableWeeks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: DropdownButton<int?>(
          value: provider.selectedWeekFilter,
          isDense: true,
          isExpanded: false,

          icon: Icon(
            TablerIcons.chevron_down,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),

          underline: const SizedBox(),

          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All Weeks',
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            ...availableWeeks.map((week) {
              return DropdownMenuItem(
                value: week.weekNumber,
                child: Text(
                  week.weekLabel,
                  style: TextStyle(
                    fontFamily: GoogleFonts.poppins().fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              );
            }).toList(),
          ],

          selectedItemBuilder: (context) {
            return [
              _buildCenteredItem("All Weeks", isDark),
              ...availableWeeks.map(
                (week) => _buildCenteredItem(week.weekLabel, isDark),
              ),
            ];
          },

          onChanged: (value) {
            provider.setWeekFilter(value);
          },

          dropdownColor: isDark ? AppColors.backgroundDark : Colors.white,
        ),
      ),
    );
  }

  Widget _buildCenteredItem(String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          TablerIcons.calendar,
          size: 18,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapLegend(Map<String, Map<int, int>> data, bool isDark) {
    int maxValue = 0;
    for (var dayData in data.values) {
      for (var value in dayData.values) {
        if (value > maxValue) maxValue = value;
      }
    }

    final legendItems = _generateLegendItems(maxValue, isDark);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                TablerIcons.info_circle,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Heatmap Guide',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            'This heatmap visualizes passenger activity patterns across different days and hours. Darker colors indicate higher passenger volume.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: 20),

          // Intensity Scale
          Text(
            'Passenger Volume',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: legendItems
                  .map(
                    (item) => Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.range,
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(TablerIcons.bulb, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Use the week filter to analyze specific time periods',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<LegendItem> _generateLegendItems(int maxValue, bool isDark) {
    if (maxValue == 0) {
      return [
        LegendItem(
          label: 'No Activity',
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          range: '0 passengers',
        ),
      ];
    }

    final q1 = (maxValue * 0.25).ceil();
    final q2 = (maxValue * 0.5).ceil();
    final q3 = (maxValue * 0.75).ceil();

    return [
      LegendItem(
        label: 'Very High',
        color: _getHeatmapColor(1.0, isDark),
        range: '$q3+ passengers',
      ),
      LegendItem(
        label: 'High',
        color: _getHeatmapColor(0.75, isDark),
        range: '$q2-$q3 passengers',
      ),
      LegendItem(
        label: 'Medium',
        color: _getHeatmapColor(0.5, isDark),
        range: '$q1-$q2 passengers',
      ),
      LegendItem(
        label: 'Low',
        color: _getHeatmapColor(0.25, isDark),
        range: '1-$q1 passengers',
      ),
      LegendItem(
        label: 'No Activity',
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        range: '0 passengers',
      ),
    ];
  }

  Widget _buildLocationStatsSection(
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
              'Location-Based Passenger Statistics',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total boardings and alightings by waypoint (last 30 days)',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              height: 400,
              child: _buildLocationStatsChart(provider.locationStats, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatsChart(
    List<WaypointPassengerStats>? stats,
    bool isDark,
  ) {
    if (stats == null || stats.isEmpty) {
      return _buildNoDataPlaceholder('No location data available', isDark);
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            stats
                .map(
                  (s) =>
                      (s.totalBoardings > s.totalAlightings
                              ? s.totalBoardings
                              : s.totalAlightings)
                          .toDouble(),
                )
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barGroups: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.totalBoardings.toDouble(),
                color: AppColors.success,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: stat.totalAlightings.toDouble(),
                color: AppColors.error,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < stats.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      stats[value.toInt()].waypointName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final stat = stats[group.x.toInt()];
              final label = rodIndex == 0 ? 'Boardings' : 'Alightings';
              final value = rod.toY.toInt();
              return BarTooltipItem(
                '${stat.waypointName}\n$label: $value',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHourlyTrendSection(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hourly Passenger Trend per Location',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeLg,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a location to view hourly boarding and alighting patterns',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildWaypointDropdown(provider, isDark),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              height: 350,
              child: _buildLocationHourlyChart(
                provider.locationHourlyTrend,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointDropdown(
    DashboardAnalyticsProvider provider,
    bool isDark,
  ) {
    final waypoints = provider.availableWaypoints ?? [];

    if (waypoints.isEmpty) {
      return const Text('No waypoints available');
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: DropdownButton<String>(
          value: provider.selectedWaypoint,
          isDense: true,
          isExpanded: false,
          icon: Icon(
            TablerIcons.chevron_down,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          underline: const SizedBox(),
          items: waypoints.map((waypoint) {
            return DropdownMenuItem(
              value: waypoint,
              child: Text(
                waypoint,
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return waypoints.map((waypoint) {
              return _buildWaypointItem(waypoint, isDark);
            }).toList();
          },
          onChanged: (value) {
            if (value != null) {
              provider.setSelectedWaypoint(value);
            }
          },
          dropdownColor: isDark ? AppColors.backgroundDark : Colors.white,
        ),
      ),
    );
  }

  Widget _buildWaypointItem(String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          TablerIcons.map_pin,
          size: 18,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHourlyChart(LocationHourlyTrend? data, bool isDark) {
    if (data == null) {
      return _buildNoDataPlaceholder(
        'No location hourly data available',
        isDark,
      );
    }

    final boardingSpots = data.boardingByHour.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    final alightingSpots = data.alightingByHour.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: boardingSpots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: alightingSpots,
            isCurved: true,
            color: AppColors.error,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.error.withOpacity(0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                final period = hour >= 12 ? 'PM' : 'AM';
                final displayHour = hour == 0
                    ? 12
                    : (hour > 12 ? hour - 12 : hour);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '$displayHour$period',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final hour = spot.x.toInt();
              final period = hour >= 12 ? 'PM' : 'AM';
              final displayHour = hour == 0
                  ? 12
                  : (hour > 12 ? hour - 12 : hour);
              final label = spot.barIndex == 0 ? 'Boardings' : 'Alightings';
              return LineTooltipItem(
                '$displayHour:00 $period\n$label: ${spot.y.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferredBusTypeSection(
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
              'Preferred Bus Type / Most Passenger Bus Type',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Average passengers per trip by bus size.',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            SizedBox(
              height: 300,
              child: _buildPreferredBusTypeChart(
                provider.preferredBusType,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferredBusTypeChart(Map<String, double>? data, bool isDark) {
    if (data == null || data.isEmpty) {
      return _buildNoDataPlaceholder('No bus type data available', isDark);
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) *
            1.2,
        barGroups: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final busType = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: busType.value,
                color: _getBusTypeColor(index),
                width: 40,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 120,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      sortedEntries[value.toInt()].key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                final period = hour >= 12 ? 'PM' : 'AM';
                final displayHour = hour == 0
                    ? 12
                    : (hour > 12 ? hour - 12 : hour);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '$displayHour$period',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: false,
          getDrawingVerticalLine: (value) => FlLine(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final busType = sortedEntries[group.x.toInt()];
              return BarTooltipItem(
                '${busType.key}\nAvg: ${busType.value.toStringAsFixed(1)} passengers/trip',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getBusTypeColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }

  Widget _buildPeakDaysSection(
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
              'Peak Day of Every Month',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Busiest day and peak hour for each month',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              height: 350,
              child: _buildPeakDaysChart(provider.peakDaysPerMonth, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakDaysChart(List<PeakDayData>? data, bool isDark) {
    if (data == null || data.isEmpty) {
      return _buildNoDataPlaceholder('No peak day data available', isDark);
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            data
                .map((d) => d.totalPassengers.toDouble())
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final peakDay = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: peakDay.totalPassengers.toDouble(),
                color: AppColors.success,
                width: 30,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final monthKey = data[value.toInt()].month;
                  final date = DateTime.parse('$monthKey-01');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final peakDay = data[group.x.toInt()];
              final date = DateTime.parse(peakDay.peakDate);
              final hour = peakDay.peakHour;
              final period = hour >= 12 ? 'PM' : 'AM';
              final displayHour = hour == 0
                  ? 12
                  : (hour > 12 ? hour - 12 : hour);
              return BarTooltipItem(
                'Month: ${DateFormat('MMM yyyy').format(date)}\nBusiest Day: ${DateFormat('MMM d').format(date)}\nTotal Passengers: ${peakDay.totalPassengers}\nPeak Hour: $displayHour:00 $period',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: AppSizes.lg),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataPlaceholder(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Text(
          message,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class HeatmapLegend {
  final String title;
  final String description;
  final List<LegendItem> items;

  HeatmapLegend({
    required this.title,
    required this.description,
    required this.items,
  });
}

class LegendItem {
  final String label;
  final Color color;
  final String range;

  LegendItem({required this.label, required this.color, required this.range});
}
