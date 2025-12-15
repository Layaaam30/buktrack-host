import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import 'account_model.dart';
import 'account_provider.dart';
import '../bus_management/bus_model.dart';
import '../bus_management/bus_provider.dart';

const Color _purplePrimary = Color(0xFF9333EA);
const Color _purpleLight = Color(0xFFF3E8FF);
const Color _purpleDark = Color(0xFF7E22CE);

class BusAssignmentDialog extends StatefulWidget {
  final Account account;

  const BusAssignmentDialog({super.key, required this.account});

  @override
  State<BusAssignmentDialog> createState() => _BusAssignmentDialogState();
}

class _BusAssignmentDialogState extends State<BusAssignmentDialog> {
  String? _selectedBusId;
  bool _isLoading = false;
  String? _error;
  final Map<String, String> _accountNames = {}; // Cache for account names

  @override
  void initState() {
    super.initState();
    _selectedBusId = widget.account.assignedBusId;
  }

  /// Fetch account name by ID and cache it
  Future<String?> _getAccountName(String accountId, String role) async {
    // Check cache first
    if (_accountNames.containsKey(accountId)) {
      return _accountNames[accountId];
    }

    try {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final account = await accountProvider.getAccountById(accountId, role);

      if (account != null) {
        _accountNames[accountId] = account.name;
        return account.name;
      }
    } catch (e) {
      print('Error fetching account name: $e');
    }

    return null;
  }

  /// Get available buses based on account role
  /// For drivers: show buses without a driver
  /// For conductors: show buses without a conductor
  List<Bus> _getAvailableBuses(List<Bus> allBuses) {
    if (widget.account.role == 'driver') {
      // Show buses without a driver OR the currently assigned bus
      return allBuses.where((bus) {
        return bus.driverId == null ||
            bus.driverId!.isEmpty ||
            bus.id == widget.account.assignedBusId;
      }).toList();
    } else {
      // Show buses without a conductor OR the currently assigned bus
      return allBuses.where((bus) {
        return bus.conductorId == null ||
            bus.conductorId!.isEmpty ||
            bus.id == widget.account.assignedBusId;
      }).toList();
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedBusId == null) {
      setState(() {
        _error = 'Please select a bus';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final busProvider = Provider.of<BusProvider>(context, listen: false);

    try {
      // Step 1: Assign account to bus
      final accountSuccess = await accountProvider.assignToBus(
        widget.account.id,
        widget.account.role,
        _selectedBusId!,
      );

      if (!accountSuccess) {
        throw Exception(accountProvider.error ?? 'Failed to assign account');
      }

      // Step 2: Update bus with driver/conductor ID
      if (widget.account.role == 'driver') {
        await busProvider.assignDriver(_selectedBusId!, widget.account.id);
      } else {
        await busProvider.assignConductor(_selectedBusId!, widget.account.id);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUnassign() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final busProvider = Provider.of<BusProvider>(context, listen: false);

    try {
      final currentBusId = widget.account.assignedBusId;

      // Step 1: Unassign account from bus
      final accountSuccess = await accountProvider.unassignFromBus(
        widget.account.id,
        widget.account.role,
      );

      if (!accountSuccess) {
        throw Exception(accountProvider.error ?? 'Failed to unassign account');
      }

      // Step 2: Remove driver/conductor from bus
      if (currentBusId != null && currentBusId.isNotEmpty) {
        if (widget.account.role == 'driver') {
          await busProvider.assignDriver(currentBusId, '');
        } else {
          await busProvider.assignConductor(currentBusId, '');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ BLOCK ASSIGNMENT/UNASSIGNMENT DURING ACTIVE TRIP
    final bool isInTransit = widget.account.availabilityStatus == 'in_transit';
    final bool isStandby = widget.account.availabilityStatus == 'standby';
    final bool canAssign =
        widget.account.availabilityStatus == 'available' ||
        isStandby ||
        isInTransit;

    // Block if in_transit
    if (isInTransit) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: AppColors.warning,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Title
                Text(
                  'Cannot Modify Assignment',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),

                // Message
                Text(
                  '${widget.account.name} is currently in transit. You cannot assign, reassign, or unassign while a trip is active.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Text(
                          'Please wait for the driver/conductor to end their trip before making changes.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Close Button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purplePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xl,
                      vertical: AppSizes.md + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Block if not available and not already assigned (standby)
    if (!canAssign && !isStandby) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Title
                Text(
                  'Cannot Assign Bus',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),

                // Message
                Text(
                  '${widget.account.name} has status "${widget.account.availabilityDisplayName}". Bus assignment is only allowed when status is "Available".',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xl),

                // Close Button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purplePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xl,
                      vertical: AppSizes.md + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusXl),
                  topRight: Radius.circular(AppSizes.radiusXl),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: _purplePrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus Assignment',
                          style: GoogleFonts.poppins(
                            fontSize: AppSizes.fontSizeLg,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.account.name} (${widget.account.roleDisplayName})',
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current assignment info
                  if (widget.account.isAssigned) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Text(
                              'Currently assigned to a bus',
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.fontSizeSm,
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  // Bus selection
                  Text(
                    'Select Bus',
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Bus list
                  Consumer<BusProvider>(
                    builder: (context, busProvider, child) {
                      if (busProvider.isLoading) {
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: _purplePrimary,
                          ),
                        );
                      }

                      final availableBuses = _getAvailableBuses(
                        busProvider.buses,
                      );

                      if (availableBuses.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppSizes.xl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_bus_outlined,
                                size: 48,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                'No available buses',
                                style: TextStyle(
                                  fontSize: AppSizes.fontSizeMd,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                widget.account.role == 'driver'
                                    ? 'All buses already have drivers assigned'
                                    : 'All buses already have conductors assigned',
                                style: TextStyle(
                                  fontSize: AppSizes.fontSizeSm,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: availableBuses.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          itemBuilder: (context, index) {
                            final bus = availableBuses[index];
                            final isSelected = _selectedBusId == bus.id;
                            final isCurrentlyAssigned =
                                bus.id == widget.account.assignedBusId;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedBusId = bus.id;
                                  _error = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSizes.md),
                                color: isSelected ? _purpleLight : null,
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: bus.id,
                                      groupValue: _selectedBusId,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedBusId = value;
                                          _error = null;
                                        });
                                      },
                                      activeColor: _purplePrimary,
                                    ),
                                    const SizedBox(width: AppSizes.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                bus.plateNumber,
                                                style: TextStyle(
                                                  fontSize: AppSizes.fontSizeMd,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AppColors
                                                            .textPrimaryDark
                                                      : AppColors
                                                            .textPrimaryLight,
                                                ),
                                              ),
                                              if (isCurrentlyAssigned) ...[
                                                const SizedBox(
                                                  width: AppSizes.sm,
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.info
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSizes.radiusSm,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Current',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.info,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          FutureBuilder<String>(
                                            future: _buildBusAssignmentInfo(
                                              bus,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 10,
                                                      height: 10,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color: isDark
                                                            ? AppColors
                                                                  .textTertiaryDark
                                                            : AppColors
                                                                  .textTertiaryLight,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Loading...',
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppSizes.fontSizeSm,
                                                        color: isDark
                                                            ? AppColors
                                                                  .textTertiaryDark
                                                            : AppColors
                                                                  .textTertiaryLight,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }

                                              return Text(
                                                snapshot.data ??
                                                    'No additional info',
                                                style: TextStyle(
                                                  fontSize: AppSizes.fontSizeSm,
                                                  color: isDark
                                                      ? AppColors
                                                            .textSecondaryDark
                                                      : AppColors
                                                            .textSecondaryLight,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Bus status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          bus.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusSm,
                                        ),
                                      ),
                                      child: Text(
                                        bus.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(bus.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: AppSizes.fontSizeSm,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.xl),

                  // Action buttons
                  Row(
                    children: [
                      if (widget.account.isAssigned) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleUnassign,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.link_off, size: 18),
                            label: Text(
                              'Unassign',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.md + 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleAssign,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: Text(
                            widget.account.isAssigned ? 'Reassign' : 'Assign',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purplePrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.md + 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _buildBusAssignmentInfo(Bus bus) async {
    final parts = <String>[];

    if (widget.account.role == 'driver') {
      // Show conductor info for driver
      if (bus.conductorId != null && bus.conductorId!.isNotEmpty) {
        // Try to get conductor name
        String conductorInfo = 'Conductor: ';
        final name = await _getAccountName(bus.conductorId!, 'conductor');
        conductorInfo += name ?? 'Assigned';
        parts.add(conductorInfo);
      } else {
        parts.add('No conductor assigned');
      }
    } else {
      // Show driver info for conductor
      if (bus.driverId != null && bus.driverId!.isNotEmpty) {
        // Try to get driver name
        String driverInfo = 'Driver: ';
        final name = await _getAccountName(bus.driverId!, 'driver');
        driverInfo += name ?? 'Assigned';
        parts.add(driverInfo);
      } else {
        parts.add('No driver assigned');
      }
    }

    if (bus.routeName != null && bus.routeName!.isNotEmpty) {
      parts.add('Route: ${bus.routeName}');
    }

    return parts.join(' • ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.textSecondaryLight;
      case 'maintenance':
        return AppColors.error;
      case 'standby':
        return AppColors.info;
      case 'delayed':
        return AppColors.warning;
      default:
        return AppColors.textSecondaryLight;
    }
  }
}
