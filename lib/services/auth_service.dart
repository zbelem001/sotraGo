import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('deviceId');
    if (storedId != null) return storedId;

    // Si on a pas de deviceId, on le génère ou le récupère
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String newId = "unknown_device-${DateTime.now().millisecondsSinceEpoch}";
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        newId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        newId = iosInfo.identifierForVendor ?? newId;
      }
    } catch (e) {
      debugPrint("Erreur recuperation Device Info : $e");
    }

    await prefs.setString('deviceId', newId);
    return newId;
  }

  Future<String?> fetchJwt() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    // Mettre l'url du backend
    String backendUrl = 'http://127.0.0.1:3000';
    if (!kIsWeb && Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:3000';
    }

    final deviceId = await getDeviceId();

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/auth/device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['access_token'];
        if (token != null) {
          await prefs.setString('jwt_token', token);
        }
        return token;
      } else {
        debugPrint("❌ Erreur pendant la récupération du token JWT: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Erreur lors de l'appel /auth/device : $e");
    }
    return token;
  }
}
