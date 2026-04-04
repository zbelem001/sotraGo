import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  // Limites approximatives de Ouagadougou pour forcer les résultats pertinents
  final String _viewbox = '-1.75,12.55,-1.30,12.20';
  final String _countryCode = 'bf';

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.length < 3) return [];

    final encodedQuery = Uri.encodeQueryComponent(query);
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$encodedQuery'
      '&format=json'
      '&countrycodes=$_countryCode'
      '&viewbox=$_viewbox'
      '&bounded=1' // Favoriser les résultats dans la viewbox
      '&limit=8',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          // Requis par Nominatim : un User-Agent valide
          'User-Agent': 'Sira/1.0 (contact@sira-app.bf)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          // Extraire un nom court et une description détaillée
          final parts = item['display_name'].toString().split(',');
          final name = parts.isNotEmpty ? parts.first.trim() : 'Lieu inconnu';
          final details = parts.length > 1
              ? parts.sublist(1).join(',').trim()
              : item['display_name'];

          return {
            'name': name,
            'details': details,
            'location': LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
          };
        }).toList();
      }
    } catch (e) {
      throw Exception(
        "Erreur de connexion (Internet requis pour la recherche)",
      );
    }

    return [];
  }
}
