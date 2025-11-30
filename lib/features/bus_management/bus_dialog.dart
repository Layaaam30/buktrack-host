import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'bus_model.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// Dialog for adding or editing a bus
class BusDialog extends StatefulWidget {
  final Bus? bus; // null for add, Bus object for edit
  final String companyId;

  const BusDialog({super.key, this.bus, required this.companyId});

  @override
  State<BusDialog> createState() => _BusDialogState();
}

class _BusDialogState extends State<BusDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _plateNumberController;
  late TextEditingController _totalCapacityController;
  late TextEditingController _passengerCountController;

  // Status dropdown
  String _selectedStatus = 'inactive';
  final List<String> _statusOptions = [
    'active',
    'inactive',
    'standby',
    'maintenance',
    'delayed',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    _plateNumberController = TextEditingController(
      text: widget.bus?.plateNumber ?? '',
    );
    _totalCapacityController = TextEditingController(
      text: widget.bus?.totalCapacity.toString() ?? '50',
    );
    _passengerCountController = TextEditingController(
      text: widget.bus?.passengerCount.toString() ?? '0',
    );
    _selectedStatus = widget.bus?.status ?? 'inactive';
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _totalCapacityController.dispose();
    _passengerCountController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.bus != null;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bus = Bus(
        id: widget.bus?.id ?? '', // Will be auto-generated if empty
        plateNumber: _plateNumberController.text.trim(),
        companyId: widget.companyId,
        driverId: widget.bus?.driverId,
        conductorId: widget.bus?.conductorId,
        routeId: widget.bus?.routeId,
        currentLocation:
            widget.bus?.currentLocation ??
            GeoPoint(8.4542, 124.6319), // Default location
        speed: widget.bus?.speed ?? 0.0,
        heading: widget.bus?.heading ?? 0.0,
        totalCapacity: int.parse(_totalCapacityController.text.trim()),
        passengerCount: int.parse(_passengerCountController.text.trim()),
        lastUpdateTimestamp: DateTime.now(),
        status: _selectedStatus,
        driverName: widget.bus?.driverName,
        conductorName: widget.bus?.conductorName,
        routeName: widget.bus?.routeName,
      );

      if (mounted) {
        Navigator.of(context).pop(bus);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < AppSizes.tabletBreakpoint;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? size.width * 0.9 : 500,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isDark),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.xxl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _plateNumberController,
                        label: 'Plate Number *',
                        hint: 'e.g., ABC 1234',
                        icon: TablerIcons.bus,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Plate number is required';
                          }
                          return null;
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // Total Capacity
                      _buildTextField(
                        controller: _totalCapacityController,
                        label: 'Total Capacity',
                        hint: 'e.g., 50',
                        icon: Icons.airline_seat_recline_normal_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Total capacity is required';
                          }
                          final capacity = int.tryParse(value);
                          if (capacity == null || capacity <= 0) {
                            return 'Please enter a valid capacity';
                          }
                          return null;
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // Current Passenger Count
                      // _buildTextField(
                      //   controller: _passengerCountController,
                      //   label: 'Current Passenger Count',
                      //   hint: 'e.g., 0',
                      //   icon: Icons.people_rounded,
                      //   keyboardType: TextInputType.number,
                      //   inputFormatters: [
                      //     FilteringTextInputFormatter.digitsOnly,
                      //   ],
                      //   validator: (value) {
                      //     if (value == null || value.trim().isEmpty) {
                      //       return 'Passenger count is required';
                      //     }
                      //     final count = int.tryParse(value);
                      //     if (count == null || count < 0) {
                      //       return 'Please enter a valid count';
                      //     }
                      //     final capacity =
                      //         int.tryParse(_totalCapacityController.text) ?? 0;
                      //     if (count > capacity) {
                      //       return 'Cannot exceed total capacity';
                      //     }
                      //     return null;
                      //   },
                      //   isDark: isDark,
                      // ),
                      const SizedBox(height: AppSizes.lg),

                      // Status Dropdown
                      _buildStatusDropdown(isDark),

                      const SizedBox(height: AppSizes.xxl),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFf97316), Color(0xFFea580c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusLg),
          topRight: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : TablerIcons.bus,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: Text(
              isEditing ? 'Edit Bus' : 'Add New Bus',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: isDark
                ? AppColors.backgroundDark
                : const Color(0xFFF8F9FA),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppColors.backgroundDark
                : const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.flag_rounded, size: 20),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: _statusOptions.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xxl),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel Button
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),

          const SizedBox(width: AppSizes.md),

          // Save Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Update' : 'Create',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      const Icon(Icons.check_rounded, size: 18),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
