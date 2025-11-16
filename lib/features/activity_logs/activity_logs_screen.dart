import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../auth/auth_provider.dart';
import 'activity_log_model.dart';
import 'activity_log_provider.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  final ScrollController _scrollController = ScrollController();

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

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final logProvider = context.read<ActivityLogProvider>();
      
      if (authProvider.companyId != null) {
        logProvider.setCompanyId(authProvider.companyId!);
      }
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final logProvider = context.read<ActivityLogProvider>();
      if (!logProvider.isLoading && logProvider.hasMore) {
        logProvider.loadMoreLogs();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Consumer<ActivityLogProvider>(
      builder: (context, logProvider, child) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isDark, isMobile),
              const SizedBox(height: AppSizes.xxl),

              // Stats Cards
              _buildStatsCards(isDark, logProvider),
              const SizedBox(height: AppSizes.xxl),

              // Filters
              _buildFiltersSection(isDark, logProvider, isMobile),
              const SizedBox(height: AppSizes.xxl),

              // Logs Table
              if (logProvider.isLoading && logProvider.logs.isEmpty)
                _buildLoadingState(isDark)
              else if (logProvider.error != null)
                _buildErrorState(isDark, logProvider)
              else if (logProvider.filteredLogs.isEmpty)
                _buildEmptyState(isDark)
              else
                _buildLogsTable(isDark, isMobile, logProvider),

              // Loading more indicator
              if (logProvider.isLoading && logProvider.logs.isNotEmpty)
                _buildLoadingMoreIndicator(),

              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: const LinearGradient(
          colors: [Color(0xFFdc2626), Color(0xFFb91c1c)],
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
                          _buildAnimatedIcon(),
                          const SizedBox(width: AppSizes.lg),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity Logs',
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
                      const Text(
                        'Monitor all system activities, track changes, and review user actions\nfor security and compliance.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFe0e7ff),
                          height: 1.6,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
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
            ),
            child: const Icon(TablerIcons.file_text, color: Colors.white, size: 32),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(bool isDark, ActivityLogProvider logProvider) {
    final stats = logProvider.stats;

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
          childAspectRatio: 2.5,
          children: [
            _buildStatCard(
              'Total Activities',
              stats['total'].toString(),
              TablerIcons.activity,
              const Color(0xFF6366f1),
              isDark,
            ),
            _buildStatCard(
              'Critical',
              stats['critical'].toString(),
              TablerIcons.alert_triangle,
              AppColors.error,
              isDark,
            ),
            _buildStatCard(
              'High Risk',
              stats['high_risk'].toString(),
              TablerIcons.shield_x,
              const Color(0xFFf97316),
              isDark,
            ),
            _buildStatCard(
              'Errors',
              stats['errors'].toString(),
              TablerIcons.bug,
              AppColors.warning,
              isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXs,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: AppSizes.fontSize2xl,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection(
    bool isDark,
    ActivityLogProvider logProvider,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366f1), Color(0xFF4f46e5)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(TablerIcons.filter, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSizes.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
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
              ),
              if (logProvider.selectedCategory != 'All Categories' ||
                  logProvider.selectedRiskLevel != 'All Risk Levels' ||
                  logProvider.searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: logProvider.clearFilters,
                  icon: const Icon(TablerIcons.x, size: 16),
                  label: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),

          // Filters
          if (isMobile)
            Column(
              children: [
                _buildCategoryFilter(isDark, logProvider),
                const SizedBox(height: AppSizes.lg),
                _buildRiskFilter(isDark, logProvider),
                const SizedBox(height: AppSizes.lg),
                _buildSearchField(isDark, logProvider),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildCategoryFilter(isDark, logProvider)),
                const SizedBox(width: AppSizes.lg),
                Expanded(child: _buildRiskFilter(isDark, logProvider)),
                const SizedBox(width: AppSizes.lg),
                Expanded(child: _buildSearchField(isDark, logProvider)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark, ActivityLogProvider logProvider) {
    return _buildDropdown(
      label: 'Category',
      value: logProvider.selectedCategory,
      items: [
        'All Categories',
        'Authentication',
        'User Actions',
        'Business',
        'Permissions',
        'Errors',
      ],
      onChanged: logProvider.setCategoryFilter,
      isDark: isDark,
    );
  }

  Widget _buildRiskFilter(bool isDark, ActivityLogProvider logProvider) {
    return _buildDropdown(
      label: 'Risk Level',
      value: logProvider.selectedRiskLevel,
      items: [
        'All Risk Levels',
        'Critical',
        'High',
        'Medium',
        'Low',
      ],
      onChanged: logProvider.setRiskLevelFilter,
      isDark: isDark,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: AppSizes.fontSizeSm)),
                );
              }).toList(),
              onChanged: (val) => onChanged(val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(bool isDark, ActivityLogProvider logProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: TextField(
            onChanged: logProvider.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search logs...',
              prefixIcon: Icon(TablerIcons.search, size: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsTable(
    bool isDark,
    bool isMobile,
    ActivityLogProvider logProvider,
  ) {
    if (isMobile) {
      return Column(
        children: logProvider.filteredLogs
            .map((log) => _buildMobileLogCard(log, isDark))
            .toList(),
      );
    }

    return Card(
      child: Column(
        children: [
          _buildTableHeader(isDark),
          ...logProvider.filteredLogs.map((log) => _buildTableRow(log, isDark)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFf9fafb),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderText('Action', isDark)),
          Expanded(flex: 3, child: _buildHeaderText('Description', isDark)),
          Expanded(flex: 2, child: _buildHeaderText('User', isDark)),
          Expanded(flex: 1, child: _buildHeaderText('Risk', isDark)),
          Expanded(flex: 2, child: _buildHeaderText('Time', isDark)),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppSizes.fontSizeSm,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6b7280),
      ),
    );
  }

  Widget _buildTableRow(ActivityLog log, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(log.readableAction)),
          Expanded(flex: 3, child: Text(log.readableDescription, maxLines: 2)),
          Expanded(flex: 2, child: Text(log.userName)),
          Expanded(flex: 1, child: _buildRiskBadge(log.riskLevel, isDark)),
          Expanded(flex: 2, child: Text(log.formattedTimestamp)),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String riskLevel, bool isDark) {
    Color color;
    switch (riskLevel) {
      case 'critical':
        color = AppColors.error;
        break;
      case 'high':
        color = const Color(0xFFf97316);
        break;
      case 'medium':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMobileLogCard(ActivityLog log, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.readableAction,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _buildRiskBadge(log.riskLevel, isDark),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(log.readableDescription),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                const Icon(TablerIcons.user, size: 14),
                const SizedBox(width: 4),
                Text(log.userName, style: TextStyle(fontSize: 12)),
                const SizedBox(width: AppSizes.md),
                const Icon(TablerIcons.clock, size: 14),
                const SizedBox(width: 4),
                Text(log.formattedTimestamp, style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.xxxl),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppSizes.lg),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(bool isDark, ActivityLogProvider logProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxl),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSizes.lg),
              Text('Error: ${logProvider.error}'),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton(
                onPressed: logProvider.loadLogs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxl * 2),
        child: Center(
          child: Column(
            children: [
              Icon(
                TablerIcons.file_text,
                size: 64,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: AppSizes.lg),
              const Text(
                'No activity logs found',
                style: TextStyle(fontSize: AppSizes.fontSizeLg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}