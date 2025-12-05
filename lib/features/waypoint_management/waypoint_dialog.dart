import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'waypoint_model.dart';
import 'waypoint_provider.dart';
import '../auth/auth_provider.dart';

class WaypointDialog extends StatefulWidget {
  final WaypointModel? waypoint;
  final LatLng? initialLocation;

  const WaypointDialog({super.key, this.waypoint, this.initialLocation});

  @override
  State<WaypointDialog> createState() => _WaypointDialogState();
}

class _WaypointDialogState extends State<WaypointDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.waypoint != null) {
      // Editing existing waypoint
      _nameController.text = widget.waypoint!.name;
      _descriptionController.text = widget.waypoint!.description ?? '';
      _latitudeController.text = widget.waypoint!.latitude.toString();
      _longitudeController.text = widget.waypoint!.longitude.toString();
    } else if (widget.initialLocation != null) {
      // New waypoint from map click
      _latitudeController.text = widget.initialLocation!.latitude
          .toStringAsFixed(6);
      _longitudeController.text = widget.initialLocation!.longitude
          .toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final waypointProvider = context.read<WaypointProvider>();

      final latitude = double.parse(_latitudeController.text);
      final longitude = double.parse(_longitudeController.text);

      final waypoint = WaypointModel(
        id: widget.waypoint?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: GeoPoint(latitude, longitude),
        order:
            widget.waypoint?.order ?? 0, // Keep existing order or default to 0
        address: null, // No longer using address
        companyId: authProvider.currentUser!.companyId,
        createdAt: widget.waypoint?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdByAdmin:
            widget.waypoint?.createdByAdmin ?? authProvider.currentUser!.id,
        updatedByAdmin: authProvider.currentUser!.id,
      );

      bool success;
      if (widget.waypoint != null) {
        // Update existing
        success = await waypointProvider.updateWaypoint(
          widget.waypoint!.id,
          waypoint,
        );
      } else {
        // Create new - the service will generate the ID
        final waypointId = await waypointProvider.createWaypoint(waypoint);
        success = waypointId != null;
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.waypoint != null
                  ? 'Waypoint updated successfully'
                  : 'Waypoint created successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save waypoint'),
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
        constraints: const BoxConstraints(maxWidth: 600),
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
                    children: [
                      _buildNameField(isDark),
                      const SizedBox(height: AppSizes.lg),
                      _buildDescriptionField(isDark),
                      const SizedBox(height: AppSizes.lg),
                      _buildCoordinateFields(isDark),
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
            Icons.location_on,
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
                widget.waypoint != null ? 'Edit Waypoint' : 'Add Waypoint',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.getTextColor(isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                widget.waypoint != null
                    ? 'Update waypoint details'
                    : 'Create a new waypoint on the route',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.getTextColor(isDark, isPrimary: false),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }

  Widget _buildNameField(bool isDark) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Waypoint Name',
        hintText: 'e.g., Kibawe, Dangcagan, Valencia',
        prefixIcon: const Icon(Icons.label),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a waypoint name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Additional details about this waypoint',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      ),
      maxLines: 3,
      minLines: 1,
    );
  }

  Widget _buildCoordinateFields(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _latitudeController,
            decoration: InputDecoration(
              labelText: 'Latitude',
              hintText: '8.4542',
              prefixIcon: const Icon(Icons.my_location),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              filled: true,
              fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              final lat = double.tryParse(value);
              if (lat == null || lat < -90 || lat > 90) {
                return 'Invalid latitude';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: TextFormField(
            controller: _longitudeController,
            decoration: InputDecoration(
              labelText: 'Longitude',
              hintText: '124.6319',
              prefixIcon: const Icon(Icons.place),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              filled: true,
              fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              final lng = double.tryParse(value);
              if (lng == null || lng < -180 || lng > 180) {
                return 'Invalid longitude';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: AppSizes.md),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
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
              : Text(widget.waypoint != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
