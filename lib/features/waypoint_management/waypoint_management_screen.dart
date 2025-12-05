import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../waypoint_management/waypoint_model.dart';
import '../waypoint_management/waypoint_provider.dart';
import '../waypoint_management/waypoint_dialog.dart';
import '../bus_management/bus_provider.dart';
import '../auth/auth_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';

class WaypointManagementScreen extends StatefulWidget {
  const WaypointManagementScreen({super.key});

  @override
  State<WaypointManagementScreen> createState() =>
      _WaypointManagementScreenState();
}

class _WaypointManagementScreenState extends State<WaypointManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Default center (Cagayan de Oro, Philippines)
  static const LatLng _defaultCenter = LatLng(8.4542, 124.6319);

  Set<Marker> _markers = {};
  bool _isMapReady = false;
  bool _isDialogOpen = false;

  // Custom marker colors
  static const Color terminalColor = Color(0xFFEF4444); // Red for terminals
  static const Color busStopColor = Color(0xFFF59E0B); // Amber for bus stops
  static const Color busColor = Color(0xFF3B82F6); // Blue for active buses

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _bounceController.repeat(reverse: true);
    _initializeProvider();
  }

  void _initializeProvider() {
    final authProvider = context.read<AuthProvider>();
    final waypointProvider = context.read<WaypointProvider>();
    final busProvider = context.read<BusProvider>();

    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final companyId = authProvider.currentUser!.companyId;
      final adminId = authProvider.currentUser!.id;

      waypointProvider.setCompanyAndAdmin(companyId, adminId);
      busProvider.setCompanyAndAdmin(companyId, adminId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    _updateMarkers();
  }

  void _updateMarkers() {
    final waypointProvider = context.read<WaypointProvider>();
    final busProvider = context.read<BusProvider>();

    final markers = <Marker>{};

    // Add waypoint markers with custom colors based on type
    for (var waypoint in waypointProvider.waypoints) {
      // Determine waypoint type based on name or description
      final isTerminal = _isTerminal(waypoint);
      final markerColor = isTerminal ? terminalColor : busStopColor;

      markers.add(
        Marker(
          markerId: MarkerId('waypoint_${waypoint.id}'),
          position: LatLng(waypoint.latitude, waypoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getHueFromColor(markerColor),
          ),
          infoWindow: InfoWindow(
            title: '${isTerminal ? '🚉 ' : '🚏 '}${waypoint.name}',
            snippet: waypoint.description ?? 'Tap to edit',
            onTap: () => _showWaypointDialog(waypoint: waypoint),
          ),
        ),
      );
    }

    // Add bus markers
    for (var bus in busProvider.buses) {
      if (bus.currentLocation != null) {
        markers.add(
          Marker(
            markerId: MarkerId('bus_${bus.id}'),
            position: LatLng(
              bus.currentLocation!.latitude,
              bus.currentLocation!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getHueFromColor(busColor),
            ),
            infoWindow: InfoWindow(
              title: '🚌 ${bus.plateNumber}',
              snippet: 'Status: ${bus.status}',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  bool _isTerminal(WaypointModel waypoint) {
    final name = waypoint.name.toLowerCase();
    final description = (waypoint.description ?? '').toLowerCase();

    return name.contains('terminal') ||
        name.contains('depot') ||
        description.contains('terminal') ||
        description.contains('depot');
  }

  double _getHueFromColor(Color color) {
    if (color == terminalColor) return BitmapDescriptor.hueRed;
    if (color == busStopColor) return BitmapDescriptor.hueOrange;
    if (color == busColor) return BitmapDescriptor.hueBlue;
    return BitmapDescriptor.hueRed;
  }

  void _onMapTap(LatLng location) {
    if (!_isDialogOpen) {
      _showWaypointDialog(location: location);
    }
  }

  Future<void> _showWaypointDialog({
    WaypointModel? waypoint,
    LatLng? location,
  }) async {
    setState(() => _isDialogOpen = true);

    final result = await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) =>
          WaypointDialog(waypoint: waypoint, initialLocation: location),
    );

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isDialogOpen = false);
      if (result == true) {
        _updateMarkers();
      }
    }
  }

  void _deleteWaypoint(WaypointModel waypoint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Waypoint'),
        content: Text('Are you sure you want to delete "${waypoint.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<WaypointProvider>().deleteWaypoint(
        waypoint.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waypoint deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _updateMarkers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<WaypointProvider>(
      builder: (context, waypointProvider, child) {
        final screen = MediaQuery.of(context).size;
        final isMobile = screen.width < 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnhancedHeader(isDark, isMobile),
              const SizedBox(height: AppSizes.xxl),
              _buildStatsCards(isDark, waypointProvider),
              const SizedBox(height: AppSizes.xxl),
              SizedBox(
                height: screen.height * 0.6,
                child: isMobile
                    ? Column(
                        children: [
                          Expanded(child: _buildMapView(isDark)),
                          const SizedBox(height: 20),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 7, child: _buildMapView(isDark)),
                        ],
                      ),
              ),
              _buildFiltersSection(isDark, waypointProvider, isMobile),
              const SizedBox(height: AppSizes.xxl),

              if (waypointProvider.isLoading)
                _buildLoadingState(isDark)
              else if (waypointProvider.error != null)
                _buildErrorState(isDark, waypointProvider)
              else if (waypointProvider.filteredWaypoints.isEmpty)
                _buildEmptyState(isDark)
              else
                _buildWaypointsTable(isDark, isMobile, waypointProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxl * 2),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.success),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Loading waypoints...',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, WaypointProvider waypointProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxxl * 2),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Failed to load waypoints',
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
                waypointProvider.error ?? 'Unknown error',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: () {
                  waypointProvider.loadWaypoints();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaypointsTable(
    bool isDark,
    bool isMobile,
    WaypointProvider waypointProvider,
  ) {
    if (isMobile) {
      return Column(
        children: waypointProvider.filteredWaypoints
            .map((waypoint) => _buildMobileWaypointCard(waypoint, isDark))
            .toList(),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : const Color(0xFFe5e7eb),
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.lg,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFf9fafb),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLg),
                topRight: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeaderCell('WAYPOINT', isDark, flex: 2),
                _buildHeaderCell('DESCRIPTION', isDark, flex: 2),
                _buildHeaderCell('LATITUDE', isDark, flex: 2),
                _buildHeaderCell('LONGITUDE', isDark, flex: 2),
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildHeaderLabel('ACTION', isDark),
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          ...waypointProvider.filteredWaypoints.asMap().entries.map((entry) {
            return _buildTableRow(
              entry.value,
              isDark,
              entry.key == waypointProvider.filteredWaypoints.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  // Replace the _buildTableRow method with this updated version:

  Widget _buildTableRow(WaypointModel waypoint, bool isDark, bool isLast) {
    const cellHPad = 12.0;

    Widget cell({required int flex, required Widget child}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: cellHPad),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.lg,
      ),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFe5e7eb),
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // WAYPOINT INFO (Name + ID)
          cell(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isTerminal(waypoint)
                        ? const Color(0xFFfee2e2)
                        : const Color(0xFFfef3c7),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Icon(
                    _isTerminal(waypoint)
                        ? Icons.place_rounded
                        : Icons.location_on_outlined,
                    color: _isTerminal(waypoint)
                        ? const Color(0xFFdc2626)
                        : const Color(0xFFd97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        waypoint.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1e293b)
                              : const Color(0xFFdbeafe),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          waypoint.friendlyId,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: isDark
                                ? const Color(0xFF60a5fa)
                                : const Color(0xFF1e40af),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DESCRIPTION
          cell(
            flex: 2,
            child: Text(
              waypoint.description ?? '-',
              style: TextStyle(
                fontSize: 13,
                color: waypoint.description != null
                    ? (isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF374151))
                    : (isDark
                          ? AppColors.textTertiaryDark
                          : const Color(0xFF9ca3af)),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),

          // LATITUDE
          cell(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.north,
                  size: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF6b7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    waypoint.latitudeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // LONGITUDE
          cell(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.east,
                  size: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF6b7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    waypoint.longitudeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ACTIONS
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionsMenu(waypoint),
            ),
          ),
        ],
      ),
    );
  }

  // Replace the _buildMobileWaypointCard method with this updated version:

  Widget _buildMobileWaypointCard(WaypointModel waypoint, bool isDark) {
    final isTerminal = _isTerminal(waypoint);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isTerminal
                        ? const Color(0xFFfee2e2)
                        : const Color(0xFFfef3c7),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Icon(
                    isTerminal
                        ? Icons.place_rounded
                        : Icons.location_on_outlined,
                    color: isTerminal
                        ? const Color(0xFFdc2626)
                        : const Color(0xFFd97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              waypoint.name,
                              style: TextStyle(
                                fontSize: AppSizes.fontSizeMd,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1e293b)
                                  : const Color(0xFFdbeafe),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              waypoint.friendlyId,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? const Color(0xFF60a5fa)
                                    : const Color(0xFF1e40af),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (waypoint.description != null &&
                          waypoint.description!.isNotEmpty)
                        Text(
                          waypoint.description!,
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
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1e293b)
                    : const Color(0xFFf9fafb),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.north,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Latitude:',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          waypoint.latitudeFormatted,
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSm,
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.east,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Longitude:',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          waypoint.longitudeFormatted,
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSm,
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showWaypointDialog(waypoint: waypoint),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.info),
                ),
                TextButton.icon(
                  onPressed: () => _deleteWaypoint(waypoint),
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, bool isDark, {required int flex}) {
    const cellHPad = 12.0;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: cellHPad),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _buildHeaderLabel(label, isDark),
        ),
      ),
    );
  }

  Widget _buildHeaderLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6b7280),
      ),
    );
  }

  Widget _buildActionsMenu(WaypointModel waypoint) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: AppColors.info),
              const SizedBox(width: AppSizes.md),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: AppSizes.md),
              const Text('Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showWaypointDialog(waypoint: waypoint);
            break;
          case 'delete':
            _deleteWaypoint(waypoint);
            break;
        }
      },
    );
  }

  Widget _buildAnimatedWaypointIcon() {
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
              TablerIcons.map_pin,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: const LinearGradient(
          colors: [Color(0xFF06b6d4), Color(0xFF0ea5e9)],
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
                          _buildAnimatedWaypointIcon(),
                          const SizedBox(width: AppSizes.lg),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Waypoint Management',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Text(
                        'Monitor active buses in real-time, manage waypoints, and ensure\naccurate route visibility for smoother operations.',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.6,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: AppSizes.xl),
                  _buildActionButton(),
                ],
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: AppSizes.xl),
              SizedBox(width: double.infinity, child: _buildActionButton()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: _showWaypointDialog,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 206, 232, 244),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(Icons.add, color: Color(0xFF0ea5e9), size: 20),
      ),
      label: const Text(
        'Add Waypoint',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0ea5e9),
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

  Widget _buildStatsCards(bool isDark, WaypointProvider waypointProvider) {
    final stats = waypointProvider.stats;

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
              'Total Waypoints',
              stats['total'].toString(),
              Icons.location_on,
              AppColors.info,
              isDark,
            ),
            _buildStatCard(
              'With Description',
              stats['with_description'].toString(),
              Icons.description,
              AppColors.success,
              isDark,
            ),
            _buildStatCard(
              'With Address',
              stats['with_address'].toString(),
              Icons.location_city,
              AppColors.warning,
              isDark,
            ),
            _buildStatCard(
              'Active Buses',
              context.watch<BusProvider>().buses.length.toString(),
              Icons.directions_bus_rounded,
              AppColors.error,
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
    WaypointProvider waypointProvider,
    bool isMobile,
  ) {
    final hasFilters = waypointProvider.searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06b6d4), Color(0xFF0ea5e9)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search & Filter',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeLg,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Find waypoints quickly',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          if (isMobile)
            Column(
              children: [
                _buildSearchField(isDark, waypointProvider),
                if (hasFilters) ...[
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(
                    width: double.infinity,
                    child: _buildClearButton(waypointProvider),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSearchField(isDark, waypointProvider),
                ),
                if (hasFilters) ...[
                  const SizedBox(width: AppSizes.lg),
                  _buildClearButton(waypointProvider),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark, WaypointProvider waypointProvider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Waypoints',
        hintText: 'Search by name, description, or address...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: AppSizes.iconSm),
                onPressed: () {
                  _searchController.clear();
                  waypointProvider.clearSearch();
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      onChanged: (value) {
        waypointProvider.setSearchQuery(value);
      },
    );
  }

  Widget _buildClearButton(WaypointProvider waypointProvider) {
    return ElevatedButton.icon(
      onPressed: () {
        _searchController.clear();
        waypointProvider.clearSearch();
      },
      icon: const Icon(Icons.close, size: 20),
      label: const Text('Clear'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.md + 2,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.getBorderColor(isDark)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: 12,
              ),
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              markers: _markers,
              myLocationButtonEnabled: !_isDialogOpen,
              myLocationEnabled: true,
              zoomControlsEnabled: !_isDialogOpen,
              zoomGesturesEnabled: !_isDialogOpen,
              scrollGesturesEnabled: !_isDialogOpen,
              tiltGesturesEnabled: !_isDialogOpen,
              rotateGesturesEnabled: !_isDialogOpen,
              mapToolbarEnabled: false,
            ),
            if (_isDialogOpen)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                  child: AbsorbPointer(absorbing: true, child: Container()),
                ),
              ),
            // Info banner
            Positioned(
              top: AppSizes.paddingLg,
              left: AppSizes.paddingLg,
              right: AppSizes.paddingLg,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(isDark),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: AppSizes.iconMd,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Click anywhere on the map to add a new waypoint',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.getTextColor(
                            isDark,
                            isPrimary: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: AppSizes.paddingLg,
              left: AppSizes.paddingLg,
              child: _buildMapLegend(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLegend(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.getBorderColor(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TablerIcons.list_details,
                size: 16,
                color: AppColors.getTextColor(isDark),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                'Map Legend',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _buildLegendItem('Bus Terminal', terminalColor, isDark),
          const SizedBox(height: AppSizes.xs),
          _buildLegendItem('Bus Stop', busStopColor, isDark),
          const SizedBox(height: AppSizes.xs),
          _buildLegendItem('Active Bus', busColor, isDark),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeXs,
            color: AppColors.getTextColor(isDark, isPrimary: false),
          ),
        ),
      ],
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
                Icons.location_off,
                size: 64,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'No waypoints found',
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
                'Click on the map to add your first waypoint',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: _showWaypointDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Waypoint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
