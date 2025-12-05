import 'package:flutter/material.dart';
import 'dart:async';
import '../google_places_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final Function(PlaceDetails) onPlaceSelected;
  final String hintText;
  final bool isDark;

  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.onPlaceSelected,
    this.hintText = 'Search places...',
    required this.isDark,
  });

  @override
  State<PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  final GooglePlacesService _placesService = GooglePlacesService();
  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (widget.controller.text.isNotEmpty) {
        _searchPlaces(widget.controller.text);
      } else {
        _removeOverlay();
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);

    final suggestions = await _placesService.getAutocompleteSuggestions(query);

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isSearching = false;
        _showSuggestions = suggestions.isNotEmpty;
      });

      if (suggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    _removeOverlay();

    widget.controller.text = suggestion.description;
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });

    // Show loading indicator
    setState(() => _isSearching = true);

    // Get place details
    final details = await _placesService.getPlaceDetails(suggestion.placeId);

    if (mounted) {
      setState(() => _isSearching = false);

      if (details != null) {
        widget.onPlaceSelected(details);
      } else {
        // Show error if place details couldn't be fetched
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get place details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
              child: _suggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          color: AppColors.getTextColor(
                            widget.isDark,
                            isPrimary: false,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: widget.isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
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
                          onTap: () => _onSuggestionSelected(suggestion),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
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
            color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
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
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      widget.controller.clear();
                      _removeOverlay();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                    },
                  )
                : _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
          ),
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.getTextColor(widget.isDark),
          ),
        ),
      ),
    );
  }
}
