import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../route_management/route_model.dart';
import '../route_management/route_provider.dart';
import '../waypoint_management/waypoint_model.dart';
import '../waypoint_management/waypoint_provider.dart';
import '../auth/auth_provider.dart';

class RouteDialog extends StatefulWidget {
  final RouteModel? route;

  const RouteDialog({super.key, this.route});

  @override
  State<RouteDialog> createState() => _RouteDialogState();
}

class _RouteDialogState extends State<RouteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _routeCodeController = TextEditingController();
  final _routeNameController = TextEditingController();
  final _estimatedTimeController = TextEditingController();

  List<WaypointModel> _selectedWaypoints = [];
  bool _isLoading = false;
  bool _isLoadingWaypoints = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() async {
    if (widget.route != null) {
      // Editing existing route
      _routeCodeController.text = widget.route!.routeCode;
      _routeNameController.text = widget.route!.routeName;
      _estimatedTimeController.text = widget.route!.estimatedTravelTime
          .toString();

      // Load waypoints if route has waypoint IDs
      if (widget.route!.waypoints.isNotEmpty) {
        setState(() => _isLoadingWaypoints = true);

        // For backward compatibility, check if waypoints are IDs or names
        final waypointProvider = context.read<WaypointProvider>();

        // Try to load waypoints by IDs
        try {
          final waypoints = await waypointProvider.getWaypointsByIds(
            widget.route!.waypoints,
          );
          if (mounted) {
            setState(() {
              _selectedWaypoints = waypoints;
              _isLoadingWaypoints = false;
            });
          }
        } catch (e) {
          // If loading fails, waypoints might be old string format
          if (mounted) {
            setState(() => _isLoadingWaypoints = false);
          }
        }
      }
    } else {
      // New route - generate route code
      final routeProvider = context.read<RouteProvider>();
      final nextCode = await routeProvider.generateNextRouteCode();
      if (mounted) {
        _routeCodeController.text = nextCode;
      }
    }
  }

  @override
  void dispose() {
    _routeCodeController.dispose();
    _routeNameController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWaypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least 2 waypoints (origin and destination)',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final routeProvider = context.read<RouteProvider>();

      // Get origin and destination from first and last waypoints
      final origin = _selectedWaypoints.first.name;
      final destination = _selectedWaypoints.last.name;

      // Get waypoint IDs in order
      final waypointIds = _selectedWaypoints.map((w) => w.id).toList();

      final route = RouteModel(
        id: widget.route?.id ?? '',
        routeCode: _routeCodeController.text.trim().toUpperCase(),
        routeName: _routeNameController.text.trim(),
        originName: origin,
        destinationName: destination,
        waypoints: waypointIds, // Store waypoint IDs
        estimatedTravelTime: int.parse(_estimatedTimeController.text),
        isActive: widget.route?.isActive ?? true,
        companyId: authProvider.currentUser!.companyId,
        assignedBuses: widget.route?.assignedBuses ?? [],
        schedules: widget.route?.schedules ?? [],
        createdByAdmin:
            widget.route?.createdByAdmin ?? authProvider.currentUser!.id,
        createdAt: widget.route?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        assignmentChangedBy: widget.route?.assignmentChangedBy,
        statusChangedBy: widget.route?.statusChangedBy,
        statusChangedAt: widget.route?.statusChangedAt,
        updatedByAdmin: authProvider.currentUser!.id,
      );

      bool success;
      if (widget.route != null) {
        success = await routeProvider.updateRoute(widget.route!.id, route);
      } else {
        final routeId = await routeProvider.createRoute(route);
        success = routeId != null;
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.route != null
                  ? 'Route updated successfully'
                  : 'Route created successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save route'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showWaypointSelector() async {
    final waypointProvider = context.read<WaypointProvider>();
    final availableWaypoints = waypointProvider.waypoints;

    if (availableWaypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No waypoints available. Please create waypoints first.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final selected = await showDialog<List<WaypointModel>>(
      context: context,
      builder: (context) => _WaypointSelectorDialog(
        availableWaypoints: availableWaypoints,
        selectedWaypoints: _selectedWaypoints,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedWaypoints = selected;
      });
    }
  }

  void _reorderWaypoint(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final waypoint = _selectedWaypoints.removeAt(oldIndex);
      _selectedWaypoints.insert(newIndex, waypoint);
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _selectedWaypoints.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: AppColors.getSurfaceColor(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(AppSizes.paddingXxl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: AppSizes.xl),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicFields(),
                      const SizedBox(height: AppSizes.xl),
                      _buildWaypointSection(isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: const Icon(
            Icons.route,
            color: AppColors.primary,
            size: AppSizes.iconLg,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.route != null ? 'Edit Route' : 'Add Route',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.getTextColor(isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                widget.route != null
                    ? 'Update route details and waypoints'
                    : 'Create a new route with waypoints',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.getTextColor(isDark, isPrimary: false),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBasicFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _routeCodeController,
                decoration: const InputDecoration(
                  labelText: 'Route Code *',
                  hintText: 'RT001',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter route code';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: TextFormField(
                controller: _estimatedTimeController,
                decoration: const InputDecoration(
                  labelText: 'Travel Time (minutes) *',
                  hintText: '120',
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        TextFormField(
          controller: _routeNameController,
          decoration: const InputDecoration(
            labelText: 'Route Name *',
            hintText: 'Kibawe to Cagayan de Oro Route',
            prefixIcon: Icon(Icons.label),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter route name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWaypointSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Route Waypoints',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.getTextColor(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSm,
                vertical: AppSizes.paddingXs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                '${_selectedWaypoints.length} selected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showWaypointSelector,
              icon: const Icon(Icons.add_location, size: AppSizes.iconSm),
              label: const Text('Select Waypoints'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        if (_isLoadingWaypoints)
          const Center(child: CircularProgressIndicator())
        else if (_selectedWaypoints.isEmpty)
          _buildEmptyWaypoints(isDark)
        else
          _buildWaypointsList(isDark),
      ],
    );
  }

  Widget _buildEmptyWaypoints(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXxl),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: AppColors.getTextColor(isDark, isPrimary: false),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No waypoints selected',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Click "Select Waypoints" to choose route stops',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.getTextColor(isDark, isPrimary: false),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointsList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.getBorderColor(isDark)),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _selectedWaypoints.length,
        onReorder: _reorderWaypoint,
        itemBuilder: (context, index) {
          final waypoint = _selectedWaypoints[index];
          final isOrigin = index == 0;
          final isDestination = index == _selectedWaypoints.length - 1;

          return _buildWaypointCard(
            waypoint,
            index,
            isOrigin,
            isDestination,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildWaypointCard(
    WaypointModel waypoint,
    int index,
    bool isOrigin,
    bool isDestination,
    bool isDark,
  ) {
    return Container(
      key: ValueKey(waypoint.id),
      margin: const EdgeInsets.all(AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isOrigin || isDestination
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.getBorderColor(isDark),
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: AppColors.getTextColor(isDark, isPrimary: false),
            ),
            const SizedBox(width: AppSizes.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isOrigin || isDestination
                    ? AppColors.primary
                    : AppColors.getTextColor(
                        isDark,
                        isPrimary: false,
                      ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Center(
                child: Text(
                  (index + 1).toString(),
                  style: TextStyle(
                    color: isOrigin || isDestination
                        ? Colors.white
                        : AppColors.getTextColor(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(
              waypoint.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.getTextColor(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isOrigin) ...[
              const SizedBox(width: AppSizes.sm),
              _buildBadge('Origin', AppColors.success, isDark),
            ],
            if (isDestination) ...[
              const SizedBox(width: AppSizes.sm),
              _buildBadge('Destination', AppColors.error, isDark),
            ],
          ],
        ),
        subtitle: Text(
          waypoint.coordinatesFormatted,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.getTextColor(isDark, isPrimary: false),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: AppSizes.iconSm),
          color: AppColors.error,
          onPressed: () => _removeWaypoint(index),
          tooltip: 'Remove',
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: AppSizes.md),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.route != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

// Waypoint Selector Dialog
class _WaypointSelectorDialog extends StatefulWidget {
  final List<WaypointModel> availableWaypoints;
  final List<WaypointModel> selectedWaypoints;

  const _WaypointSelectorDialog({
    required this.availableWaypoints,
    required this.selectedWaypoints,
  });

  @override
  State<_WaypointSelectorDialog> createState() =>
      _WaypointSelectorDialogState();
}

class _WaypointSelectorDialogState extends State<_WaypointSelectorDialog> {
  late List<WaypointModel> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedWaypoints);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WaypointModel> get _filteredWaypoints {
    if (_searchQuery.isEmpty) return widget.availableWaypoints;

    final query = _searchQuery.toLowerCase();
    return widget.availableWaypoints.where((w) {
      return w.name.toLowerCase().contains(query) ||
          (w.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: AppColors.getSurfaceColor(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(AppSizes.paddingXxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Waypoints',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.getTextColor(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search waypoints...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: AppSizes.md),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredWaypoints.length,
                itemBuilder: (context, index) {
                  final waypoint = _filteredWaypoints[index];
                  final isSelected = _selected.any((w) => w.id == waypoint.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(waypoint);
                        } else {
                          _selected.removeWhere((w) => w.id == waypoint.id);
                        }
                      });
                    },
                    title: Text(waypoint.name),
                    subtitle: Text(waypoint.coordinatesFormatted),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSizes.md),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text('Select (${_selected.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
