import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:succes/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  StreamSubscription<Position>? _positionStreamSubscription;
  bool isScouting = false;
  String? currentLine;
  bool isScoutModeEnabled = false; // Le master switch du Mode Eclaireur

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isScoutModeEnabled = prefs.getBool('scout_mode') ?? false;
  }

  Future<void> toggleScoutMode(bool value) async {
    isScoutModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scout_mode', value);
    if (!value) {
      stopScouting();
    }
  }

  String deviceId =
      "user_device_id_123"; // Plus tard on récupérera un vrai ID unique

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Demander les permissions GPS
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⛔ Permissions de localisation refusées.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        '⛔ Permissions définitivement refusées. Allez dans les paramètres.',
      );
      return false;
    }
    return true;
  }

  /// Démarre le tracking (Mode Éclaireur activé)
  Future<void> startScouting(String line) async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) return;

    isScouting = true;
    currentLine = line;
    debugPrint('🚀 Démarrage du mode éclaireur pour la ligne : $line');

    // On configure le stream GPS (mise à jour selon la précision ou la distance)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Signale un changement tous les 10 mètres
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position? position) {
          if (position != null && isScouting) {
            debugPrint(
              '📍 GPS Local : [${position.latitude}, ${position.longitude}] - Envoi au socket...',
            );

            // Envoi au Backend !
            SocketService().socket.emit('updateLocation', {
              'deviceId': deviceId,
              'line': currentLine,
              'lat': position.latitude,
              'lng': position.longitude,
            });
          }
        });
  }

  /// Stoppe le tracking
  void stopScouting() {
    isScouting = false;
    currentLine = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    debugPrint('🛑 Arrêt du mode éclaireur.');
  }
}
