import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'waypoint_model.dart';
import 'waypoint_provider.dart';
import '../../auth/auth_provider.dart';
import '../google_maps/widgets/places_autocomplete_field.dart';
import '../google_maps/google_places_service.dart';

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
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _showManualEntry = false;
  String? _selectedAddress;
  WaypointCategory _selectedCategory = WaypointCategory.busStop;
  String _previewWaypointId = 'WP-001';

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _calculateWaypointId();
  }

  void _initializeFields() {
    if (widget.waypoint != null) {
      // Editing existing waypoint
      _nameController.text = widget.waypoint!.name;
      _descriptionController.text = widget.waypoint!.description ?? '';
      _latitudeController.text = widget.waypoint!.latitude.toString();
      _longitudeController.text = widget.waypoint!.longitude.toString();
      _selectedAddress = widget.waypoint!.address;
      _selectedCategory = widget.waypoint!.category;
      _showManualEntry = true;
    } else if (widget.initialLocation != null) {
      // New waypoint from map click
      _latitudeController.text = widget.initialLocation!.latitude
          .toStringAsFixed(6);
      _longitudeController.text = widget.initialLocation!.longitude
          .toStringAsFixed(6);
      _showManualEntry = true;
    }
  }

  void _calculateWaypointId() {
    if (widget.waypoint == null) {
      // Calculate next waypoint ID for new waypoints
      final waypointProvider = context.read<WaypointProvider>();
      final waypointCount = waypointProvider.waypoints.length;
      setState(() {
        _previewWaypointId =
            'WP-${(waypointCount + 1).toString().padLeft(3, '0')}';
      });
    } else {
      // Show existing waypoint ID for editing
      setState(() {
        _previewWaypointId = widget.waypoint!.waypointId;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onPlaceSelected(PlaceDetails place) {
    setState(() {
      _nameController.text = place.name;
      _latitudeController.text = place.latitude.toStringAsFixed(6);
      _longitudeController.text = place.longitude.toStringAsFixed(6);
      _selectedAddress = place.formattedAddress;
      _showManualEntry = true;

      // Auto-detect category based on name
      final nameLower = place.name.toLowerCase();
      if (nameLower.contains('terminal')) {
        _selectedCategory = WaypointCategory.busTerminal;
      } else {
        _selectedCategory = WaypointCategory.busStop;
      }
    });
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
        order: widget.waypoint?.order ?? waypointProvider.waypoints.length,
        address: _selectedAddress,
        category: _selectedCategory,
        companyId: authProvider.currentUser!.companyId,
        createdAt: widget.waypoint?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdByAdmin:
            widget.waypoint?.createdByAdmin ?? authProvider.currentUser!.id,
        updatedByAdmin: authProvider.currentUser!.id,
      );

      bool success;
      if (widget.waypoint != null) {
        success = await waypointProvider.updateWaypoint(
          widget.waypoint!.id,
          waypoint,
        );
      } else {
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

  IconData _getCategoryIcon(WaypointCategory category) {
    switch (category) {
      case WaypointCategory.busTerminal:
        return TablerIcons.building_warehouse;
      case WaypointCategory.busStop:
        return TablerIcons.bus_stop;
    }
  }

  Color _getCategoryColor(WaypointCategory category) {
    switch (category) {
      case WaypointCategory.busTerminal:
        return const Color(0xFFef4444);
      case WaypointCategory.busStop:
        return const Color(0xFFf59e0b);
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Waypoint ID Display
                      _buildWaypointIdDisplay(isDark),
                      const SizedBox(height: AppSizes.lg),

                      // Search Places Section (only for new waypoints)
                      if (widget.waypoint == null) ...[
                        Text(
                          'Search Location',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.getTextColor(isDark),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'Search for a place or enter coordinates manually',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.getTextColor(
                                  isDark,
                                  isPrimary: false,
                                ),
                              ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        PlacesAutocompleteField(
                          controller: _searchController,
                          onPlaceSelected: _onPlaceSelected,
                          hintText:
                              'Search for a place (e.g., Kibawe Terminal)',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showManualEntry = !_showManualEntry;
                              });
                            },
                            icon: Icon(
                              _showManualEntry
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                            label: Text(
                              _showManualEntry
                                  ? 'Hide Manual Entry'
                                  : 'Or Enter Coordinates Manually',
                            ),
                          ),
                        ),
                        if (_showManualEntry)
                          const SizedBox(height: AppSizes.lg),
                      ],

                      // Manual Entry Fields
                      if (_showManualEntry) ...[
                        if (widget.waypoint == null)
                          Divider(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        if (widget.waypoint == null)
                          const SizedBox(height: AppSizes.lg),
                        _buildNameField(isDark),
                        const SizedBox(height: AppSizes.lg),
                        _buildCategoryField(isDark),
                        const SizedBox(height: AppSizes.lg),
                        _buildDescriptionField(isDark),
                        const SizedBox(height: AppSizes.lg),
                        _buildCoordinateFields(isDark),
                        if (_selectedAddress != null) ...[
                          const SizedBox(height: AppSizes.md),
                          _buildAddressDisplay(isDark),
                        ],
                      ],
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
            TablerIcons.map_pin,
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
                    : 'Search for a place or add coordinates',
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

  Widget _buildWaypointIdDisplay(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(TablerIcons.tag, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waypoint ID',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.getTextColor(isDark, isPrimary: false),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _previewWaypointId,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            TablerIcons.lock,
            color: AppColors.getTextColor(isDark, isPrimary: false),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isDark) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Waypoint Name',
        hintText: 'e.g., Kibawe Bus Terminal, Valencia Stop',
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

  Widget _buildCategoryField(bool isDark) {
    return DropdownButtonFormField<WaypointCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(_getCategoryIcon(_selectedCategory)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      ),
      items: WaypointCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(category.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
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
        prefixIcon: const Icon(TablerIcons.file_text),
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
              prefixIcon: const Icon(TablerIcons.compass),
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
              prefixIcon: const Icon(TablerIcons.current_location),
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

  Widget _buildAddressDisplay(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.map_pin, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.getTextColor(isDark, isPrimary: false),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedAddress!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
