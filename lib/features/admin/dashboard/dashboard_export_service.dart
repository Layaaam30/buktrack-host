import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';
import 'dashboard_analytics_provider.dart';
import 'dashboard_analytics_service.dart';

import 'dart:html' as html;
import 'dart:convert';

class DashboardExportService {
  static final PdfColor primaryOrange = PdfColor.fromHex('#f97316');
  static final PdfColor primaryOrangeLight = PdfColor.fromHex('#fb923c');
  static final PdfColor primaryOrangeDark = PdfColor.fromHex('#ea580c');
  static final PdfColor primaryOrangeLighter = PdfColor.fromHex('#ffedd5');
  static final PdfColor textDark = PdfColor.fromHex('#111827');
  static final PdfColor textGray = PdfColor.fromHex('#4B5563');
  static final PdfColor textLight = PdfColor.fromHex('#9ca3af');
  static final PdfColor borderGray = PdfColor.fromHex('#e5e7eb');
  static final PdfColor backgroundGray = PdfColor.fromHex('#f9fafb');

  Future<void> exportToPdf(DashboardAnalyticsProvider provider) async {
    final pdf = pw.Document();

    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/buktrack_logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Logo not found, proceeding without it');
    }

    pdf.addPage(_buildCoverPage(provider, logo));

    pdf.addPage(_buildSummaryPage(provider, logo));

    if (provider.liveHourlyTrend != null ||
        provider.dailyTrend30Days != null ||
        provider.monthlyTrend != null) {
      pdf.addPage(_buildTrendsPage(provider, logo));
    }

    if (provider.locationStats != null && provider.locationStats!.isNotEmpty) {
      pdf.addPage(_buildLocationStatsPage(provider, logo));
    }

    if (provider.weeklyHeatmap != null) {
      pdf.addPage(_buildHeatmapPage(provider, logo));
    }

    if (provider.preferredBusType != null &&
        provider.preferredBusType!.isNotEmpty) {
      pdf.addPage(_buildBusTypePage(provider, logo));
    }

    if (provider.peakDaysPerMonth != null &&
        provider.peakDaysPerMonth!.isNotEmpty) {
      pdf.addPage(_buildPeakDaysPage(provider, logo));
    }

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      _downloadFileWeb(
        pdfBytes,
        'buktrack_dashboard_report.pdf',
        'application/pdf',
      );
    } else {
      final output = await _getOutputFile('buktrack_dashboard_report.pdf');
      await output.writeAsBytes(pdfBytes);
      await shareFile(output);
    }
  }

  Future<void> printPdf(DashboardAnalyticsProvider provider) async {
    if (kIsWeb) {
      throw Exception('Printing is not supported on web');
    }

    // Load logo
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Logo not found, proceeding without it');
    }

    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();

        // Add all pages
        pdf.addPage(_buildCoverPage(provider, logo));
        pdf.addPage(_buildSummaryPage(provider, logo));

        if (provider.liveHourlyTrend != null ||
            provider.dailyTrend30Days != null ||
            provider.monthlyTrend != null) {
          pdf.addPage(_buildTrendsPage(provider, logo));
        }

        if (provider.locationStats != null &&
            provider.locationStats!.isNotEmpty) {
          pdf.addPage(_buildLocationStatsPage(provider, logo));
        }

        if (provider.weeklyHeatmap != null) {
          pdf.addPage(_buildHeatmapPage(provider, logo));
        }

        if (provider.preferredBusType != null &&
            provider.preferredBusType!.isNotEmpty) {
          pdf.addPage(_buildBusTypePage(provider, logo));
        }

        if (provider.peakDaysPerMonth != null &&
            provider.peakDaysPerMonth!.isNotEmpty) {
          pdf.addPage(_buildPeakDaysPage(provider, logo));
        }

        return pdf.save();
      },
    );
  }

  Future<void> exportSummaryToCsv(DashboardAnalyticsProvider provider) async {
    final List<List<dynamic>> rows = [];

    // Headers
    rows.add(['Metric', 'Value']);

    // Summary data
    final summary = provider.dashboardSummary ?? {};
    rows.add(['Total Buses', summary['total_buses'] ?? 0]);
    rows.add(['Active Routes', summary['total_routes'] ?? 0]);
    rows.add(['Active Trips Today', summary['active_trips_today'] ?? 0]);
    rows.add(['Total Passengers Today', provider.totalPassengersToday]);

    if (provider.peakHourToday != null) {
      rows.add(['Peak Hour Today', _formatHour(provider.peakHourToday!)]);
    }

    if (provider.busiestWaypoint != null) {
      rows.add(['Busiest Waypoint', provider.busiestWaypoint!.waypointName]);
    }

    await _saveCsvFile('dashboard_summary.csv', rows);
  }

  Future<void> exportHourlyTrendToCsv(Map<int, int> data) async {
    final List<List<dynamic>> rows = [];

    rows.add(['Hour', 'Passengers']);

    for (var entry in data.entries) {
      rows.add([_formatHour(entry.key), entry.value]);
    }

    await _saveCsvFile('hourly_trend.csv', rows);
  }

  Future<void> exportDailyTrendToCsv(Map<String, int> data) async {
    final List<List<dynamic>> rows = [];

    rows.add(['Date', 'Passengers']);

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (var entry in sortedEntries) {
      final date = DateTime.parse(entry.key);
      rows.add([DateFormat('MMM d, yyyy').format(date), entry.value]);
    }

    await _saveCsvFile('daily_trend_30days.csv', rows);
  }

  Future<void> exportMonthlyTrendToCsv(Map<String, int> data) async {
    final List<List<dynamic>> rows = [];

    rows.add(['Month', 'Passengers']);

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (var entry in sortedEntries) {
      final date = DateTime.parse('${entry.key}-01');
      rows.add([DateFormat('MMMM yyyy').format(date), entry.value]);
    }

    await _saveCsvFile('monthly_trend.csv', rows);
  }

  Future<void> exportLocationStatsToCsv(
    List<WaypointPassengerStats> stats,
  ) async {
    final List<List<dynamic>> rows = [];

    rows.add([
      'Waypoint',
      'Total Boardings',
      'Total Alightings',
      'Total Activity',
    ]);

    for (var stat in stats) {
      rows.add([
        stat.waypointName,
        stat.totalBoardings,
        stat.totalAlightings,
        stat.totalActivity,
      ]);
    }

    await _saveCsvFile('location_statistics.csv', rows);
  }

  Future<void> exportHeatmapToCsv(
    Map<String, Map<int, int>> heatmapData,
  ) async {
    final List<List<dynamic>> rows = [];

    // Header row with hours
    final header = ['Day'];
    for (int i = 0; i < 24; i++) {
      header.add(_formatHour(i));
    }
    rows.add(header);

    // Data rows
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (var day in dayNames) {
      final row = [day];
      final dayData = heatmapData[day] ?? {};
      for (int hour = 0; hour < 24; hour++) {
        row.add('${dayData[hour] ?? 0}');
      }
      rows.add(row);
    }

    await _saveCsvFile('weekly_heatmap.csv', rows);
  }

  Future<void> exportBusTypeToCsv(Map<String, double> data) async {
    final List<List<dynamic>> rows = [];

    rows.add(['Bus Type', 'Average Passengers per Trip']);

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedEntries) {
      rows.add([entry.key, entry.value.toStringAsFixed(2)]);
    }

    await _saveCsvFile('bus_type_preferences.csv', rows);
  }

  Future<void> exportPeakDaysToCsv(List<PeakDayData> peakDays) async {
    final List<List<dynamic>> rows = [];

    rows.add(['Month', 'Peak Date', 'Total Passengers', 'Peak Hour']);

    for (var peakDay in peakDays) {
      final date = DateTime.parse(peakDay.peakDate);
      final month = DateTime.parse('${peakDay.month}-01');
      rows.add([
        DateFormat('MMMM yyyy').format(month),
        DateFormat('MMM d, yyyy').format(date),
        peakDay.totalPassengers,
        _formatHour(peakDay.peakHour),
      ]);
    }

    await _saveCsvFile('peak_days.csv', rows);
  }

  Future<void> shareFile(File file) async {
    if (!kIsWeb) {
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'BukTrack Dashboard Analytics Report');
    }
  }

  void _downloadFileWeb(List<int> bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  pw.Page _buildCoverPage(
    DashboardAnalyticsProvider provider,
    pw.ImageProvider? logo,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryOrange, primaryOrangeDark],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Logo
                if (logo != null)
                  pw.Container(
                    width: 140,
                    height: 140,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(24),
                      // boxShadow: [
                      //   pw.BoxShadow(
                      //     color: PdfColors.grey800,
                      //     blurRadius: 30,
                      //     offset: const PdfPoint(0, 15),
                      //   ),
                      // ],
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(24),
                      child: pw.Image(logo),
                    ),
                  )
                else
                  pw.Container(
                    width: 140,
                    height: 140,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(24),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColors.grey800,
                          blurRadius: 30,
                          offset: const PdfPoint(0, 15),
                        ),
                      ],
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'BT',
                        style: pw.TextStyle(
                          fontSize: 56,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryOrange,
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 50),
                // Title
                pw.Text(
                  'BUKTRACK ',
                  style: pw.TextStyle(
                    fontSize: 48,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Dashboard Analytics Report',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.normal,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 80),
                // Date & Time Card - White with proper contrast
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 28,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(16),
                    // boxShadow: [
                    //   pw.BoxShadow(
                    //     color: PdfColors.black,
                    //     blurRadius: 25,
                    //     offset: const PdfPoint(0, 10),
                    //   ),
                    // ],
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Generated on',
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        DateFormat('MMMM d, yyyy').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryOrange,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        DateFormat('h:mm a').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  pw.Page _buildSummaryPage(
    DashboardAnalyticsProvider provider,
    pw.ImageProvider? logo,
  ) {
    final summary = provider.dashboardSummary ?? {};

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Dashboard Summary', logo),
            pw.SizedBox(height: 30),

            // Stats Grid
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildStatCard(
                    'Total Buses',
                    '${summary['total_buses'] ?? 0}',
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _buildStatCard(
                    'Active Routes',
                    '${summary['total_routes'] ?? 0}',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildStatCard(
                    'Active Trips Today',
                    '${summary['active_trips_today'] ?? 0}',
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _buildStatCard(
                    'Total Passengers',
                    '${provider.totalPassengersToday}',
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Key Insights Section
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryOrangeLighter,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: primaryOrangeLight, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: primaryOrangeDark,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'Key Insights',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  if (provider.peakHourToday != null)
                    _buildInsightRow(
                      'Peak Hour Today',
                      _formatHour(provider.peakHourToday!),
                    ),
                  if (provider.busiestWaypoint != null)
                    _buildInsightRow(
                      'Busiest Location',
                      provider.busiestWaypoint!.waypointName,
                    ),
                  if (provider.busiestDayOfWeek != null)
                    _buildInsightRow(
                      'Busiest Day of Week',
                      provider.busiestDayOfWeek!,
                    ),
                  if (provider.mostPreferredBusType != null)
                    _buildInsightRow(
                      'Most Used Bus Type',
                      provider.mostPreferredBusType!,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildTrendsPage(
    DashboardAnalyticsProvider provider,
    pw.ImageProvider? logo,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Passenger Trends', logo),
            pw.SizedBox(height: 30),

            // Today's hourly trend
            if (provider.liveHourlyTrend != null) ...[
              _buildSubHeader('Today\'s Hourly Trend'),
              pw.SizedBox(height: 15),
              if (provider.totalPassengersToday > 0)
                _buildEnhancedDataTable(
                  ['Hour', 'Passengers'],
                  provider.liveHourlyTrend!.entries
                      .where((e) => e.value > 0)
                      .map((e) => [_formatHour(e.key), '${e.value}'])
                      .toList(),
                )
              else
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: backgroundGray,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: borderGray),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No passenger data recorded for today',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: textGray,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(height: 30),
            ],

            // Daily trend (last 30 days)
            if (provider.dailyTrend30Days != null) ...[
              _buildSubHeader('Daily Trend (Last 30 Days)'),
              pw.SizedBox(height: 15),
              pw.Text(
                'Total passengers per day over the past month',
                style: pw.TextStyle(fontSize: 11, color: textGray),
              ),
              pw.SizedBox(height: 10),
              _buildDailyTrendTable(provider.dailyTrend30Days!),
            ],
          ],
        );
      },
    );
  }

  pw.Page _buildLocationStatsPage(
    DashboardAnalyticsProvider provider,
    pw.ImageProvider? logo,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Location-Based Statistics', logo),
            pw.SizedBox(height: 30),

            _buildSubHeader('Passenger Activity by Waypoint'),
            pw.SizedBox(height: 15),

            _buildEnhancedDataTable(
              ['Waypoint', 'Boardings', 'Alightings', 'Total'],
              provider.locationStats!
                  .map(
                    (stat) => [
                      stat.waypointName,
                      '${stat.totalBoardings}',
                      '${stat.totalAlightings}',
                      '${stat.totalActivity}',
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildHeatmapPage(
    DashboardAnalyticsProvider provider,
    pw.ImageProvider? logo,
  ) {
    final heatmapData = provider.weeklyHeatmap!;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Weekly Activity Heatmap', logo),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total passengers by day and hour',
              style: pw.TextStyle(fontSize: 12, color: textGray),
            ),
            pw.SizedBox(height: 15),

            // Heatmap table
            pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.5),
              columnWidths: {0: const pw.FixedColumnWidth(70)},
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryOrange),
                  children: [
                    _buildHeatmapCell('Day', true, true),
                    ...List.generate(
                      24,
                      (hour) => _buildHeatmapCell('${hour}h', true, false),
                    ),
                  ],
                ),
                // Data rows
                ...dayNames.map((day) {
                  final dayData = heatmapData[day] ?? {};
                  final isWeekend = day == 'Saturday' || day == 'Sunday';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isWeekend ? primaryOrangeLighter : null,
                    ),
                    children: [
                      _buildHeatmapCell(day.substring(0, 3), false, true),
                      ...List.generate(24, (hour) {
                        final value = dayData[hour] ?? 0;
                        return _buildHeatmapDataCell(value);
                      }),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 15),

            // Legend
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Intensity: ',
                  style: pw.TextStyle(fontSize: 10, color: textGray),
                ),
                pw.SizedBox(width: 10),
                ...[0, 25, 50, 75, 100].map((intensity) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(left: 5),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 15,
                          height: 15,
                          decoration: pw.BoxDecoration(
                            color: _getHeatmapColor(intensity),
                            border: pw.Border.all(color: borderGray),
                          ),
                        ),
                        pw.SizedBox(width: 3),
                        pw.Text(
                          '$intensity+',
                          style: pw.TextStyle(fontSize: 9, color: textGray),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildBusTypePage(
    DashboardAnalyticsProvider provider,
    pw.ImageProvider? logo,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Bus Type Preferences', logo),
            pw.SizedBox(height: 30),

            _buildSubHeader('Average Passengers per Trip by Bus Capacity'),
            pw.SizedBox(height: 15),

            _buildEnhancedDataTable(
              ['Bus Type', 'Avg Passengers/Trip'],
              provider.preferredBusType!.entries
                  .map((e) => [e.key, e.value.toStringAsFixed(1)])
                  .toList(),
            ),

            pw.SizedBox(height: 30),

            // Visual bar chart
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: backgroundGray,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: borderGray),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Comparative View',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  ...provider.preferredBusType!.entries.map((entry) {
                    final maxValue = provider.preferredBusType!.values.reduce(
                      (a, b) => a > b ? a : b,
                    );
                    final percentage = (entry.value / maxValue);
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            entry.key,
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: textGray,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Container(
                                width: percentage * 350,
                                height: 25,
                                decoration: pw.BoxDecoration(
                                  gradient: pw.LinearGradient(
                                    colors: [primaryOrange, primaryOrangeLight],
                                  ),
                                  borderRadius: pw.BorderRadius.circular(6),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    entry.value.toStringAsFixed(1),
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildPeakDaysPage(
    DashboardAnalyticsProvider provider,
    pw.ImageProvider? logo,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Peak Days Per Month', logo),
            pw.SizedBox(height: 30),

            _buildSubHeader('Busiest Days and Peak Hours'),
            pw.SizedBox(height: 15),

            _buildEnhancedDataTable(
              ['Month', 'Peak Date', 'Passengers', 'Peak Hour'],
              provider.peakDaysPerMonth!.map((peak) {
                final date = DateTime.parse(peak.peakDate);
                final month = DateTime.parse('${peak.month}-01');
                return [
                  DateFormat('MMM yyyy').format(month),
                  DateFormat('MMM d').format(date),
                  '${peak.totalPassengers}',
                  _formatHour(peak.peakHour),
                ];
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  pw.Widget _buildPageHeader(String title, pw.ImageProvider? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryOrange, width: 3),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
              ),
            ),
          ),
          if (logo != null)
            pw.Container(width: 40, height: 40, child: pw.Image(logo))
          else
            pw.Container(
              width: 40,
              height: 40,
              decoration: pw.BoxDecoration(
                color: primaryOrange,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'BT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSubHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: primaryOrangeLighter,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryOrangeLight, width: 1),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: primaryOrangeDark,
        ),
      ),
    );
  }

  pw.Widget _buildStatCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryOrange, primaryOrangeLight],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
        boxShadow: [
          pw.BoxShadow(
            color: primaryOrangeLight,
            blurRadius: 10,
            offset: const PdfPoint(0, 4),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 42,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 13, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInsightRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              color: primaryOrangeDark,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(fontSize: 11, color: textGray),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEnhancedDataTable(
    List<String> headers,
    List<List<String>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 1),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryOrange, primaryOrangeLight],
            ),
          ),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Rows
        ...rows.asMap().entries.map(
          (entry) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: entry.key.isEven ? PdfColors.white : backgroundGray,
            ),
            children: entry.value
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(
                      cell,
                      style: pw.TextStyle(fontSize: 10, color: textDark),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHeatmapCell(String text, bool isHeader, bool isDay) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isDay ? 9 : 7,
          color: isHeader ? PdfColors.white : textDark,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildHeatmapDataCell(int value) {
    return pw.Container(
      decoration: pw.BoxDecoration(color: _getHeatmapColor(value)),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          '$value',
          style: pw.TextStyle(
            fontSize: 7,
            color: value > 50 ? PdfColors.white : textDark,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  PdfColor _getHeatmapColor(int value) {
    if (value == 0) return PdfColors.white;
    if (value < 25) return primaryOrangeLighter;
    if (value < 50) return primaryOrangeLighter;
    if (value < 75) return primaryOrangeLight;
    if (value < 100) return primaryOrange;
    return primaryOrangeDark;
  }

  pw.Widget _buildDailyTrendTable(Map<String, int> dailyData) {
    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final lastEntries = sortedEntries.length > 10
        ? sortedEntries.sublist(sortedEntries.length - 10)
        : sortedEntries;

    return _buildEnhancedDataTable(
      ['Date', 'Passengers'],
      lastEntries.map((e) {
        final date = DateTime.parse(e.key);
        return [DateFormat('MMM d, yyyy').format(date), '${e.value}'];
      }).toList(),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  Future<void> _saveCsvFile(String fileName, List<List<dynamic>> rows) async {
    final csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      _downloadFileWeb(utf8.encode(csv), fileName, 'text/csv');
    } else {
      final file = await _getOutputFile(fileName);
      await file.writeAsString(csv);
      await shareFile(file);
    }
  }

  Future<File> _getOutputFile(String fileName) async {
    try {
      Directory directory;

      if (Platform.isAndroid) {
        directory = await getTemporaryDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getTemporaryDirectory();
      }

      return File('${directory.path}/$fileName');
    } catch (e) {
      final directory = await getTemporaryDirectory();
      return File('${directory.path}/$fileName');
    }
  }
}
