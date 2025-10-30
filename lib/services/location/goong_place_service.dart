import 'dart:convert';

import 'package:gara/config.dart';
import 'package:http/http.dart' as http;

class GoongAutocompletePrediction {
  final String description;
  final String placeId;
  final String? mainText;
  final String? secondaryText;

  GoongAutocompletePrediction({
    required this.description,
    required this.placeId,
    this.mainText,
    this.secondaryText,
  });

  static GoongAutocompletePrediction fromJson(Map<String, dynamic> json) {
    final struct = json['structured_formatting'] as Map<String, dynamic>?;
    return GoongAutocompletePrediction(
      description: json['description'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      mainText: struct != null ? struct['main_text'] as String? : null,
      secondaryText: struct != null ? struct['secondary_text'] as String? : null,
    );
  }
}

class GoongPlaceDetailResult {
  final String placeId;
  final String formattedAddress;
  final double lat;
  final double lng;
  final String? name;

  GoongPlaceDetailResult({
    required this.placeId,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    this.name,
  });

  static GoongPlaceDetailResult fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};
    return GoongPlaceDetailResult(
      placeId: result['place_id'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0,
      lng: (location['lng'] as num?)?.toDouble() ?? 0,
      name: result['name'] as String?,
    );
  }
}

class GoongPlaceService {
  static const String _baseUrl = 'https://rsapi.goong.io';

  static Future<List<GoongAutocompletePrediction>> autocomplete({
    required String input,
    String? sessionToken,
    String? location, // "lat,lng"
    int limit = 10,
    bool moreCompound = true,
  }) async {
    if (Config.goongApiKey.isEmpty) {
      // Debug: thiếu API key
      // ignore: avoid_print
      print('[Goong] Missing API key, skip autocomplete');
      return [];
    }

    final uri = Uri.parse('$_baseUrl/Place/AutoComplete').replace(
      queryParameters: {
        'api_key': Config.goongApiKey,
        'input': input,
        if (sessionToken != null && sessionToken.isNotEmpty) 'sessiontoken': sessionToken,
        if (location != null && location.isNotEmpty) 'location': location,
        'limit': '$limit',
        'more_compound': moreCompound.toString(),
      },
    );

    // Debug: log URL
    // ignore: avoid_print
    print('[Goong][Autocomplete] GET $uri');

    http.Response res;
    try {
      res = await http.get(uri);
    } catch (e) {
      // ignore: avoid_print
      print('[Goong][Autocomplete] Network error: $e');
      return [];
    }

    // ignore: avoid_print
    print('[Goong][Autocomplete] Status: ${res.statusCode}');
    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('[Goong][Autocomplete] Body: ${res.body}');
      return [];
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final status = body['status'] as String?;
    if (status != 'OK') {
      // ignore: avoid_print
      print('[Goong][Autocomplete] API status: $status, body: ${res.body}');
      return [];
    }
    final predictions = (body['predictions'] as List<dynamic>? ?? [])
        .map((e) => GoongAutocompletePrediction.fromJson(e as Map<String, dynamic>))
        .toList();
    // ignore: avoid_print
    print('[Goong][Autocomplete] Predictions: ${predictions.length}');
    return predictions;
  }

  static Future<GoongPlaceDetailResult?> getPlaceDetail({
    required String placeId,
    String? sessionToken,
  }) async {
    if (Config.goongApiKey.isEmpty) {
      // ignore: avoid_print
      print('[Goong] Missing API key, skip place detail');
      return null;
    }
    final uri = Uri.parse('$_baseUrl/Place/Detail').replace(
      queryParameters: {
        'api_key': Config.goongApiKey,
        'place_id': placeId,
        if (sessionToken != null && sessionToken.isNotEmpty) 'sessiontoken': sessionToken,
      },
    );

    // ignore: avoid_print
    print('[Goong][Detail] GET $uri');

    http.Response res;
    try {
      res = await http.get(uri);
    } catch (e) {
      // ignore: avoid_print
      print('[Goong][Detail] Network error: $e');
      return null;
    }
    // ignore: avoid_print
    print('[Goong][Detail] Status: ${res.statusCode}');
    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('[Goong][Detail] Body: ${res.body}');
      return null;
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final status = body['status'] as String?;
    if (status != 'OK') {
      // ignore: avoid_print
      print('[Goong][Detail] API status: $status, body: ${res.body}');
      return null;
    }
    final result = GoongPlaceDetailResult.fromJson(body);
    // ignore: avoid_print
    print(
        '[Goong][Detail] placeId=${result.placeId}, lat=${result.lat}, lng=${result.lng}, addr=${result.formattedAddress}');
    return result;
  }
}
