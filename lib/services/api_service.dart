import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String get backendUrl {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      // 192.168.11.105 est l'IP locale de votre machine (pour un SM A165F physique)
      // Si émulateur, c'était 10.0.2.2
      return 'http://192.168.11.105:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  /// Récupère toutes les lignes depuis l'API distante.
  /// En cas d'erreur réseau, utilise le fichier local en secours.
  Future<String> fetchLinesData() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/api/lines'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        debugPrint("✅ Données des lignes chargées depuis l'API !");
        return response.body;
      } else {
        throw Exception("Erreur ${response.statusCode} de l'API");
      }
    } catch (e) {
      debugPrint(
        "⚠️ Impossible de joindre l'API des lignes ($e), utilisation du cache local.",
      );
      return await rootBundle.loadString('assets/data/sotraco_ouaga.json');
    }
  }

  /// Calcule l'itinéraire via l'API (pgRouting)
  Future<Map<String, dynamic>?> fetchItinerary(
    double origLat,
    double origLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$backendUrl/api/routing?origLat=$origLat&origLng=$origLng&destLat=$destLat&destLng=$destLng',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("❌ Erreur ${response.statusCode} de l'API de routing");
        return null;
      }
    } catch (e) {
      debugPrint("Impossible de joindre l'API de routing: $e");
      return null;
    }
  }

  /// Récupère le classement des éclaireurs
  Future<List<dynamic>?> fetchLeaderboard() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/api/gamification/leaderboard'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("❌ Erreur ${response.statusCode} de l'API leaderboard");
        return null;
      }
    } catch (e) {
      debugPrint("Impossible de joindre l'API leaderboard: $e");
      return null;
    }
  }
}
