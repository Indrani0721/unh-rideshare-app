// API endpoint for getting car makes
// https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/car?format=json
// API endpoint for getting car models based on make
// https://vpic.nhtsa.dot.gov/api/vehicles/getmodelsformake/{make}?format=json
// API endpoint for getting car models based on make and year
// https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMakeIdYear/makeId/{MakeId}/modelyear/{year}?format=json

import 'dart:convert';

import 'package:http/http.dart' as http;

class CarMake {
  final String name;
  final String id;

  CarMake({required this.name, required this.id});
}

class CarQueryApi {
  static const String _base = 'vpic.nhtsa.dot.gov';

  Future<List<CarMake>> fetchMakeNames() async {
    final uri = Uri.https(_base, '/api/vehicles/GetMakesForVehicleType/car', {
      'format': 'json',
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch makes: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['Results'] as List<dynamic>? ?? const []);

    final names = results
        .map(
          (item) => CarMake(
            name: item['MakeName']?.toString() ?? '',
            id: item['MakeId']?.toString() ?? '',
          ),
        )
        .where((item) => item.name.trim().isNotEmpty)
        .toSet()
        .toList();

    return names;
  }

  Future<List<String>> fetchModelNamesByMake(String make) async {
    final normalizedMake = make.trim();
    if (normalizedMake.isEmpty) return const [];

    final uri = Uri.https(
      _base,
      '/api/vehicles/GetModelsForMake/$normalizedMake',
      {'format': 'json'},
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch models for $normalizedMake: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['Results'] as List<dynamic>? ?? const []);

    final names = results
        .map(
          (item) =>
              (item as Map<String, dynamic>)['Model_Name']?.toString() ?? '',
        )
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    return names;
  }

  Future<List<String>> fetchModelNamesByMakeIdAndYear(
    String makeId,
    String year,
  ) async {
    final normalizedMakeId = makeId.trim();
    final normalizedYear = year.trim();
    if (normalizedMakeId.isEmpty || normalizedYear.isEmpty) return const [];

    final uri = Uri.https(
      _base,
      '/api/vehicles/GetModelsForMakeIdYear/makeId/$normalizedMakeId/modelyear/$normalizedYear',
      {'format': 'json'},
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch models for $normalizedMakeId and $normalizedYear: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['Results'] as List<dynamic>? ?? const []);

    final names = results
        .map(
          (item) =>
              (item as Map<String, dynamic>)['Model_Name']?.toString() ?? '',
        )
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    return names;
  }
}
