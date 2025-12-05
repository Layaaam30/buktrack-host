import 'dart:convert';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  // TODO: Replace with your actual API key
  // For security, consider using environment variables or a config file
  static const String _apiKey = 'AIzaSyAoEBa8AQyswtb6HjSxzHSac_dwAVtHHSA';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  /// Search for places with autocomplete
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String input, {
    String? sessionToken,
  }) async {
    if (input.isEmpty) return [];

    try {
      // Build URL for Places Autocomplete
      final url = Uri.parse(
        '$_baseUrl/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$_apiKey'
        '&sessiontoken=${sessionToken ?? DateTime.now().millisecondsSinceEpoch}'
        '&components=country:ph', // Restrict to Philippines
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((p) => PlaceSuggestion.fromJson(p)).toList();
        } else {
          print('Places API error: ${data['status']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }

      return [];
    } catch (e) {
      print('Error getting autocomplete suggestions: $e');
      return [];
    }
  }

  /// Get place details by place ID
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/place/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,geometry,place_id'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          print('Place details error: ${data['status']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  /// Search for places by text query
  Future<List<PlaceDetails>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/place/textsearch/json'
        '?query=${Uri.encodeComponent(query)}'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results.map((r) => PlaceDetails.fromJson(r)).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
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
