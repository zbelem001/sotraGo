import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:succes/services/auth_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  late IO.Socket socket;
  bool isConnected = false;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// Initialiser la connexion au serveur WebSockets
  Future<void> initSocket() async {
    // 192.168.11.105 est l'IP locale (pour mobile physique connecté au même Wi-Fi)
    // localhost ou 127.0.0.1 pour iOS Simulator ou le Web
    String backendUrl = 'http://127.0.0.1:3000';

    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      backendUrl = 'http://192.168.11.105:3000';
    }

    // Récupérer le JWT
    String? token = await AuthService().fetchJwt();

    socket = IO.io(
      backendUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      isConnected = true;
      debugPrint('✅ Connecté au backend WebSockets avec JWT');

      // Test : abonnement à la "Ligne 1"
      socket.emit('subscribeToLine', {'line': 'Ligne 1'});
    });

    socket.onDisconnect((_) {
      isConnected = false;
      debugPrint('❌ Déconnecté du backend');
    });

    socket.onConnectError((err) {
      debugPrint("❌ Erreur de connexion WebSockets : $err");
    });

    socket.on('busLocationUpdated', (data) {
      debugPrint('📍 Nouvelle position reçue : $data');
      // Plus tard on viendra actualiser l'interface ou la Google Maps !
    });
  }

  /// Envoyer la position en temps réel de l'utilisateur (Mode Éclaireur)
  void sendLocationUpdate(String line, double lat, double lng) {
    if (isConnected) {
      socket.emit('updateLocation', {'line': line, 'lat': lat, 'lng': lng});
      debugPrint('📡 Envoi de la position pour $line : [$lat, $lng]');
    }
  }

  /// Déconnecter complètement le client
  void disconnect() {
    if (isConnected) {
      socket.disconnect();
    }
  }
}
