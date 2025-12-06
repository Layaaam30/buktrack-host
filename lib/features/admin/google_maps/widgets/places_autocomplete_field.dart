import 'package:flutter/material.dart';
import 'dart:async';
import '../google_places_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final Function(PlaceDetails) onPlaceSelected;
  final String hintText;
  final bool isDark;
  final String? sessionId;
  final bool autofocus;

  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.onPlaceSelected,
    this.hintText = 'Search places...',
    required this.isDark,
    this.sessionId,
    this.autofocus = false,
  });

  @override
  State<PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  final GooglePlacesService _placesService = GooglePlacesService();
  final FocusNode _focusNode = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _isLoadingDetails = false;
  String? _error;
  Timer? _debounce;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay removal to allow tapping on suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    } else if (_suggestions.isNotEmpty) {
      _showOverlay();
    }
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Clear error when user starts typing again
    if (_error != null) {
      setState(() => _error = null);
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (widget.controller.text.isNotEmpty) {
        _searchPlaces(widget.controller.text);
      } else {
        _removeOverlay();
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _error = null;
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 2) return; // Minimum 2 characters

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final suggestions = await _placesService.getAutocompleteSuggestions(
        query,
        sessionToken: widget.sessionId,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isSearching = false;
          _showSuggestions = suggestions.isNotEmpty;
          _error = null;
        });

        if (suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          // Show "no results" message
          _showOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
          _suggestions = [];
        });
        _showOverlay(); // Show error in overlay
      }
    }
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    _removeOverlay();

    widget.controller.text = suggestion.description;
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _isLoadingDetails = true;
      _error = null;
    });

    try {
      // Get place details
      final details = await _placesService.getPlaceDetails(
        suggestion.placeId,
        sessionToken: widget.sessionId,
      );

      if (mounted) {
        setState(() => _isLoadingDetails = false);

        if (details != null) {
          widget.onPlaceSelected(details);
        } else {
          setState(() => _error = 'Could not get place details');
          _showErrorSnackbar('Could not get place details');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
          _error = e.toString();
        });
        _showErrorSnackbar(e.toString());
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 600,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
              child: _buildOverlayContent(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOverlayContent() {
    // Show error state
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            Text(
              'Search Error',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(widget.isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextColor(widget.isDark, isPrimary: false),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _searchPlaces(widget.controller.text);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show no results
    if (_suggestions.isEmpty && !_isSearching) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.getTextColor(widget.isDark, isPrimary: false),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No results found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(widget.isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextColor(widget.isDark, isPrimary: false),
              ),
            ),
          ],
        ),
      );
    }

    // Show suggestions list
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            suggestion.mainText,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(widget.isDark),
            ),
          ),
          subtitle: suggestion.secondaryText.isNotEmpty
              ? Text(
                  suggestion.secondaryText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextColor(
                      widget.isDark,
                      isPrimary: false,
                    ),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.north_west,
            size: 16,
            color: AppColors.getTextColor(widget.isDark, isPrimary: false),
          ),
          onTap: () => _onSuggestionSelected(suggestion),
        );
      },
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: _error != null
                ? AppColors.error
                : (widget.isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            width: _error != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: AppColors.getTextColor(widget.isDark, isPrimary: false),
              fontSize: AppSizes.fontSizeSm,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: AppColors.getTextColor(widget.isDark, isPrimary: false),
            ),
            suffixIcon: _buildSuffixIcon(),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            errorText: _error != null ? '' : null, // Show error border only
            errorStyle: const TextStyle(height: 0), // Hide error text
          ),
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.getTextColor(widget.isDark),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isLoadingDetails) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (widget.controller.text.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              widget.controller.clear();
              _removeOverlay();
              setState(() {
                _suggestions = [];
                _showSuggestions = false;
                _error = null;
              });
              _focusNode.requestFocus();
            },
            tooltip: 'Clear',
          ),
        ],
      );
    }

    return null;
  }
}
