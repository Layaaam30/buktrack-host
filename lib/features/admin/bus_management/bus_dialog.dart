import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
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
  String _selectedStatus = 'active'; // Changed default to 'active'
  final List<String> _statusOptions = ['active', 'inactive', 'maintenance'];

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

    // Set status to 'active' for new buses, or keep existing status when editing
    _selectedStatus = widget.bus?.status ?? 'active';
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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isDark),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _plateNumberController,
                        label: 'Plate Number *',
                        hint: 'e.g., ABC 1234',
                        icon: TablerIcons.tag,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Plate number is required';
                          }
                          return null;
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: 20),

                      // Total Capacity
                      _buildTextField(
                        controller: _totalCapacityController,
                        label: 'Total Capacity *',
                        hint: 'e.g., 50',
                        icon: TablerIcons.users,
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

                      const SizedBox(height: 20),

                      // Status Dropdown
                      _buildStatusDropdown(isDark),

                      const SizedBox(height: 8),

                      // Info note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withOpacity(0.5)
                              : const Color(0xFFf0f9ff),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFbae6fd),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              TablerIcons.info_circle,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF7dd3fc)
                                  : const Color(0xFF0284c7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'New buses are automatically set to Active status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF7dd3fc)
                                      : const Color(0xFF0c4a6e),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFf97316), Color(0xFFea580c)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing ? TablerIcons.edit : TablerIcons.bus,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Bus' : 'Add New Bus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditing
                      ? 'Update bus information'
                      : 'Add a new bus to your fleet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFf97316), width: 2),
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: Color(0xFFf97316),
              ),
            ),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: !_isLoading,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : const Color(0xFF9CA3AF),
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF6B7280),
            ),
            filled: true,
            fillColor: isDark ? AppColors.backgroundDark : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFf97316), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
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
        const Text(
          'Status *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: _statusOptions.map((status) {
                IconData icon;
                Color color;

                switch (status) {
                  case 'active':
                    icon = TablerIcons.circle_check;
                    color = const Color(0xFF10b981);
                    break;
                  case 'inactive':
                    icon = TablerIcons.circle_x;
                    color = const Color(0xFF6b7280);
                    break;
                  case 'maintenance':
                    icon = TablerIcons.tools;
                    color = const Color(0xFFf59e0b);
                    break;
                  default:
                    icon = TablerIcons.circle;
                    color = Colors.grey;
                }

                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 12),
                      Text(status[0].toUpperCase() + status.substring(1)),
                    ],
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
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel Button
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),

          const SizedBox(width: 12),

          // Save Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFFf97316), Color(0xFFea580c)],
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSubmit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isEditing ? TablerIcons.check : TablerIcons.plus,
                      color: Colors.white,
                      size: 18,
                    ),
              label: Text(
                _isLoading
                    ? 'Processing...'
                    : (isEditing ? 'Update Bus' : 'Add Bus'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
