import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import 'dashboard_analytics_provider.dart';
import 'dashboard_export_service.dart';

class ExportControlsWidget extends StatefulWidget {
  const ExportControlsWidget({super.key});

  @override
  State<ExportControlsWidget> createState() => _ExportControlsWidgetState();
}

class _ExportControlsWidgetState extends State<ExportControlsWidget> {
  final DashboardExportService _exportService = DashboardExportService();
  bool _isExporting = false;
  bool _isPrinting = false;

  Future<void> _exportFullPdfReport(BuildContext context) async {
    final provider = Provider.of<DashboardAnalyticsProvider>(
      context,
      listen: false,
    );

    setState(() => _isExporting = true);

    try {
      await _exportService.exportToPdf(provider);

      if (context.mounted) {
        _showSuccessSnackbar(
          context,
          kIsWeb
              ? 'PDF report downloaded successfully!'
              : 'PDF report exported successfully!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error exporting PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _printPdfReport(BuildContext context) async {
    if (kIsWeb) {
      _showErrorSnackbar(
        context,
        'Printing is not supported on web. Please download the PDF instead.',
      );
      return;
    }

    final provider = Provider.of<DashboardAnalyticsProvider>(
      context,
      listen: false,
    );

    setState(() => _isPrinting = true);

    try {
      await _exportService.printPdf(provider);

      if (context.mounted) {
        _showSuccessSnackbar(context, 'Print dialog opened successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error printing PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, String type) async {
    final provider = Provider.of<DashboardAnalyticsProvider>(
      context,
      listen: false,
    );

    setState(() => _isExporting = true);

    try {
      switch (type) {
        case 'summary':
          await _exportService.exportSummaryToCsv(provider);
          break;
        case 'hourly':
          if (provider.liveHourlyTrend != null) {
            await _exportService.exportHourlyTrendToCsv(
              provider.liveHourlyTrend!,
            );
          }
          break;
        case 'daily':
          if (provider.dailyTrend30Days != null) {
            await _exportService.exportDailyTrendToCsv(
              provider.dailyTrend30Days!,
            );
          }
          break;
        case 'monthly':
          if (provider.monthlyTrend != null) {
            await _exportService.exportMonthlyTrendToCsv(
              provider.monthlyTrend!,
            );
          }
          break;
        case 'locations':
          if (provider.locationStats != null) {
            await _exportService.exportLocationStatsToCsv(
              provider.locationStats!,
            );
          }
          break;
        case 'heatmap':
          if (provider.weeklyHeatmap != null) {
            await _exportService.exportHeatmapToCsv(provider.weeklyHeatmap!);
          }
          break;
        case 'bustype':
          if (provider.preferredBusType != null) {
            await _exportService.exportBusTypeToCsv(provider.preferredBusType!);
          }
          break;
        case 'peakdays':
          if (provider.peakDaysPerMonth != null) {
            await _exportService.exportPeakDaysToCsv(
              provider.peakDaysPerMonth!,
            );
          }
          break;
      }

      if (context.mounted) {
        _showSuccessSnackbar(
          context,
          kIsWeb
              ? 'CSV downloaded successfully!'
              : 'CSV exported successfully!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error exporting CSV: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      TablerIcons.file_export,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Export Dashboard Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb
                    ? 'Choose what you want to download'
                    : 'Choose what you want to export or print',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // PDF Export Section
              _buildExportSection(
                context,
                'PDF Report',
                'Complete analytics report with all visualizations',
                TablerIcons.file_text,
                Colors.red,
                [
                  _buildExportOption(
                    context,
                    'Download PDF',
                    kIsWeb
                        ? 'Download complete dashboard as PDF'
                        : 'Export complete dashboard as PDF',
                    TablerIcons.file_download,
                    () {
                      Navigator.pop(context);
                      _exportFullPdfReport(context);
                    },
                  ),
                  if (!kIsWeb)
                    _buildExportOption(
                      context,
                      'Print Report',
                      'Send report directly to printer',
                      TablerIcons.printer,
                      () {
                        Navigator.pop(context);
                        _printPdfReport(context);
                      },
                    ),
                ],
              ),

              const Divider(height: 32),

              // CSV Export Section
              _buildExportSection(
                context,
                'CSV Data',
                'Export specific data sets as spreadsheets',
                TablerIcons.file_spreadsheet,
                Colors.green,
                [
                  _buildExportOption(
                    context,
                    'Summary Statistics',
                    'Total buses, routes, trips, passengers',
                    TablerIcons.layout_dashboard,
                    () {
                      Navigator.pop(context);
                      _exportCsv(context, 'summary');
                    },
                  ),
                  _buildExportOption(
                    context,
                    'Passenger Trends',
                    'Hourly, daily, and monthly data',
                    TablerIcons.chart_line,
                    () => _showTrendExportOptions(context),
                  ),
                  _buildExportOption(
                    context,
                    'Location Statistics',
                    'Boarding and alighting by waypoint',
                    TablerIcons.map_pin,
                    () {
                      Navigator.pop(context);
                      _exportCsv(context, 'locations');
                    },
                  ),
                  _buildExportOption(
                    context,
                    'Weekly Heatmap',
                    'Hourly activity by day of week',
                    TablerIcons.calendar_stats,
                    () {
                      Navigator.pop(context);
                      _exportCsv(context, 'heatmap');
                    },
                  ),
                  _buildExportOption(
                    context,
                    'Bus Type Preferences',
                    'Average passengers by bus capacity',
                    TablerIcons.bus,
                    () {
                      Navigator.pop(context);
                      _exportCsv(context, 'bustype');
                    },
                  ),
                  _buildExportOption(
                    context,
                    'Peak Days Analysis',
                    'Busiest days per month',
                    TablerIcons.trending_up,
                    () {
                      Navigator.pop(context);
                      _exportCsv(context, 'peakdays');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrendExportOptions(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Trend Period',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(TablerIcons.clock, color: AppColors.primary),
              title: const Text('Hourly Trend (Today)'),
              subtitle: const Text('Passenger count per hour'),
              onTap: () {
                Navigator.pop(context);
                _exportCsv(context, 'hourly');
              },
            ),
            ListTile(
              leading: const Icon(
                TablerIcons.calendar,
                color: AppColors.success,
              ),
              title: const Text('Daily Trend (30 Days)'),
              subtitle: const Text('Passenger count per day'),
              onTap: () {
                Navigator.pop(context);
                _exportCsv(context, 'daily');
              },
            ),
            ListTile(
              leading: const Icon(
                TablerIcons.calendar_event,
                color: AppColors.info,
              ),
              title: const Text('Monthly Trend (12 Months)'),
              subtitle: const Text('Passenger count per month'),
              onTap: () {
                Navigator.pop(context);
                _exportCsv(context, 'monthly');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    List<Widget> options,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...options,
      ],
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        TablerIcons.chevron_right,
        size: 20,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(TablerIcons.check, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(TablerIcons.alert_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Print Button (mobile/desktop only)
        if (!kIsWeb)
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: _isPrinting ? null : () => _printPdfReport(context),
              icon: _isPrinting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(TablerIcons.printer, size: 20),
              label: Text(_isPrinting ? 'Printing...' : 'Print'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
            ),
          ),

        // Export Button
        ElevatedButton.icon(
          onPressed: _isExporting ? null : () => _showExportMenu(context),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(TablerIcons.file_export, size: 20),
          label: Text(_isExporting ? 'Exporting...' : 'Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
