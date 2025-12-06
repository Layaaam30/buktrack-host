import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class GooglePlacesService {
  static const String _apiKey = 'AIzaSyAoEBa8AQyswtb6HjSxzHSac_dwAVtHHSA';

  // Multiple CORS proxies for fallback
  static const List<String> _corsProxies = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/raw?url=',
    'https://cors-anywhere.herokuapp.com/',
  ];

  int _currentProxyIndex = 0;
  final Map<String, String> _sessionTokens = {};
  static const Duration _timeout = Duration(seconds: 15);

  /// Get current CORS proxy
  String get _currentProxy => _corsProxies[_currentProxyIndex];

  /// Try next proxy on failure
  void _rotateProxy() {
    _currentProxyIndex = (_currentProxyIndex + 1) % _corsProxies.length;
    print('🔄 Switching to proxy: $_currentProxy');
  }

  /// Build URL with or without CORS proxy
  String _buildUrl(String endpoint, Map<String, String> params) {
    final paramsStr = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final googleUrl =
        'https://maps.googleapis.com/maps/api$endpoint?$paramsStr';

    if (kIsWeb) {
      // For corsproxy.io, don't encode the URL
      if (_currentProxy.contains('corsproxy.io')) {
        return '$_currentProxy$googleUrl';
      }
      // For others, encode the URL
      return '$_currentProxy${Uri.encodeComponent(googleUrl)}';
    }

    return googleUrl;
  }

  /// Make request with retry logic
  Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    Map<String, String> params, {
    int maxRetries = 2,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        final url = _buildUrl(endpoint, params);
        print('🌐 Request attempt ${attempt + 1}/$maxRetries');
        print('   Using proxy: ${kIsWeb ? _currentProxy : "DIRECT"}');

        final response = await http.get(Uri.parse(url)).timeout(_timeout);

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        lastError = e as Exception;
        print('❌ Attempt ${attempt + 1} failed: $e');

        // On web, try rotating proxy
        if (kIsWeb && attempt < maxRetries - 1) {
          _rotateProxy();
        }

        attempt++;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    throw lastError ?? Exception('Request failed after $maxRetries attempts');
  }

  String _getSessionToken(String sessionId) {
    if (!_sessionTokens.containsKey(sessionId)) {
      _sessionTokens[sessionId] = DateTime.now().millisecondsSinceEpoch
          .toString();
    }
    return _sessionTokens[sessionId]!;
  }

  void clearSession(String sessionId) {
    _sessionTokens.remove(sessionId);
  }

  /// Search for places with autocomplete
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String input, {
    String? sessionToken,
  }) async {
    if (input.isEmpty) return [];

    try {
      final session = sessionToken ?? _getSessionToken('default');

      print('🔍 Searching places: $input (${kIsWeb ? "WEB" : "MOBILE"})');

      final data = await _makeRequest('/place/autocomplete/json', {
        'input': input,
        'key': _apiKey,
        'sessiontoken': session,
        'components': 'country:ph',
      });

      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        print('✅ Found ${predictions.length} suggestions');
        return predictions.map((p) => PlaceSuggestion.fromJson(p)).toList();
      } else if (data['status'] == 'ZERO_RESULTS') {
        print('ℹ️ No results found');
        return [];
      } else {
        throw PlacesApiException(
          'Search failed: ${data['error_message'] ?? data['status']}',
        );
      }
    } catch (e) {
      if (e is PlacesApiException) rethrow;
      print('❌ Error: $e');
      throw PlacesApiException('Search failed: ${e.toString()}');
    }
  }

  /// Get place details by place ID
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    try {
      final session = sessionToken ?? _getSessionToken('default');

      print('📍 Fetching place details: $placeId');

      final data = await _makeRequest('/place/details/json', {
        'place_id': placeId,
        'fields': 'name,formatted_address,geometry,place_id',
        'key': _apiKey,
        'sessiontoken': session,
      });

      if (data['status'] == 'OK') {
        print('✅ Place details loaded');
        clearSession('default');
        return PlaceDetails.fromJson(data['result']);
      } else {
        throw PlacesApiException(
          'Failed to get details: ${data['error_message'] ?? data['status']}',
        );
      }
    } catch (e) {
      if (e is PlacesApiException) rethrow;
      print('❌ Error: $e');
      throw PlacesApiException('Failed to get details: ${e.toString()}');
    }
  }

  /// Search places by text query
  Future<List<PlaceDetails>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      print('🔍 Text search: $query');

      final data = await _makeRequest('/place/textsearch/json', {
        'query': query,
        'key': _apiKey,
      });

      if (data['status'] == 'OK') {
        final results = data['results'] as List;
        print('✅ Found ${results.length} places');
        return results.map((r) => PlaceDetails.fromJson(r)).toList();
      } else if (data['status'] == 'ZERO_RESULTS') {
        return [];
      } else {
        throw PlacesApiException('Search failed: ${data['status']}');
      }
    } catch (e) {
      if (e is PlacesApiException) rethrow;
      print('❌ Error: $e');
      throw PlacesApiException('Search failed: ${e.toString()}');
    }
  }
}

/// Custom exception for Places API errors
class PlacesApiException implements Exception {
  final String message;
  PlacesApiException(this.message);

  @override
  String toString() => message;
}

/// Model for autocomplete suggestion
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};

    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
    );
  }
}

/// Model for place details
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: (location['lat'] ?? 0.0).toDouble(),
      longitude: (location['lng'] ?? 0.0).toDouble(),
    );
  }
}
