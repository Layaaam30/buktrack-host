import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'route_model.dart';

/// Dialog for adding or editing a route
class RouteDialog extends StatefulWidget {
  final RouteModel? route; // null for add, RouteModel object for edit
  final String companyId;
  final String adminId;
  final String? suggestedRouteCode;

  const RouteDialog({
    super.key,
    this.route,
    required this.companyId,
    required this.adminId,
    this.suggestedRouteCode,
  });

  @override
  State<RouteDialog> createState() => _RouteDialogState();
}

class _RouteDialogState extends State<RouteDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _routeNameController;
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  late TextEditingController _travelTimeController;

  // Waypoints
  final List<TextEditingController> _waypointControllers = [];
  List<String> _waypoints = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    _routeNameController = TextEditingController(
      text: widget.route?.routeName ?? '',
    );
    _originController = TextEditingController(
      text: widget.route?.originName ?? '',
    );
    _destinationController = TextEditingController(
      text: widget.route?.destinationName ?? '',
    );
    _travelTimeController = TextEditingController(
      text: widget.route?.estimatedTravelTime.toString() ?? '',
    );

    // Initialize waypoints
    if (widget.route != null && widget.route!.waypoints.isNotEmpty) {
      _waypoints = List.from(widget.route!.waypoints);
      for (var waypoint in _waypoints) {
        final controller = TextEditingController(text: waypoint);
        _waypointControllers.add(controller);
      }
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _travelTimeController.dispose();
    for (var controller in _waypointControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get isEditing => widget.route != null;

  void _addWaypoint() {
    setState(() {
      _waypointControllers.add(TextEditingController());
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypointControllers[index].dispose();
      _waypointControllers.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Collect waypoints from controllers
      final waypoints = _waypointControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final route = RouteModel(
        id: widget.route?.id ?? '',
        routeCode:
            widget.route?.routeCode ??
            '', // Will be auto-generated for new routes
        routeName: _routeNameController.text.trim(),
        originName: _originController.text.trim(),
        destinationName: _destinationController.text.trim(),
        waypoints: waypoints,
        estimatedTravelTime: int.parse(_travelTimeController.text.trim()),
        isActive: widget.route?.isActive ?? true,
        companyId: widget.companyId,
        assignedBuses: widget.route?.assignedBuses ?? [],
        schedules: widget.route?.schedules ?? [],
        createdByAdmin: widget.adminId,
        createdAt: widget.route?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.of(context).pop(route);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(isDark),

                  const SizedBox(height: AppSizes.xxl),

                  // Form Fields
                  _buildFormFields(isDark),

                  const SizedBox(height: AppSizes.xxl),

                  // Actions
                  _buildActions(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Icon with green theme
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10b981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.add_road_rounded,
            color: Colors.white,
            size: AppSizes.iconLg,
          ),
        ),

        const SizedBox(width: AppSizes.lg),

        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Route' : 'Add New Route',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEditing
                    ? 'Update route information'
                    : 'Create a new bus route',
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

        // Close button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show auto-generated route code info (only for new routes)
        if (!isEditing) ...[
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: const Color(0xFFd1fae5),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: const Color(0xFF10b981)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF065f46),
                  size: 20,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    widget.suggestedRouteCode != null
                        ? 'Route code will be auto-generated: ${widget.suggestedRouteCode}'
                        : 'Route code will be auto-generated automatically',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: const Color(0xFF065f46),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],

        // Route Name
        TextFormField(
          controller: _routeNameController,
          decoration: InputDecoration(
            labelText: 'Route Name',
            hintText: 'e.g., CDO-Kibawe Express',
            prefixIcon: const Icon(Icons.directions_bus_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Route name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSizes.lg),

        // Origin and Destination
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: 'Origin',
                  hintText: 'Starting point',
                  prefixIcon: const Icon(Icons.location_on_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Origin is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.success,
              size: AppSizes.iconLg,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'End point',
                  prefixIcon: const Icon(Icons.flag_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Destination is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.lg),

        // Estimated Travel Time
        TextFormField(
          controller: _travelTimeController,
          decoration: InputDecoration(
            labelText: 'Estimated Travel Time (minutes)',
            hintText: 'e.g., 240',
            prefixIcon: const Icon(Icons.timer_outlined),
            suffixText: 'minutes',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Travel time is required';
            }
            final minutes = int.tryParse(value);
            if (minutes == null || minutes <= 0) {
              return 'Enter a valid number of minutes';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSizes.xl),

        // Waypoints Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Waypoints (Stops)',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMd,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            TextButton.icon(
              onPressed: _addWaypoint,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add Stop'),
              style: TextButton.styleFrom(foregroundColor: AppColors.success),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.md),

        // Waypoint List
        if (_waypointControllers.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.hoverDark : const Color(0xFFf9fafb),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    'No waypoints added. Click "Add Stop" to add intermediate stops.',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_waypointControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFd1fae5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF065f46),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: TextFormField(
                      controller: _waypointControllers[index],
                      decoration: InputDecoration(
                        hintText: 'e.g., Valencia, Malaybalay',
                        prefixIcon: const Icon(Icons.place_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  IconButton(
                    onPressed: () => _removeWaypoint(index),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.error,
                    tooltip: 'Remove stop',
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: AppSizes.md),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xxl,
              vertical: AppSizes.md,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEditing ? 'Save Changes' : 'Create Route'),
        ),
      ],
    );
  }
}
