import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'services/location_service.dart';
import 'services/socket_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Maintenir l'écran de démarrage natif (Logo MoovFaso sur fond vert) affiché
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // 1. Initialiser le Socket
  SocketService().initSocket();

  // 2. Initialiser la localisation
  await LocationService().init();

  // 3. Charger les données complexes (les lignes de bus) en arrière-plan
  try {
    await ApiService().fetchLinesData();
  } catch (e) {
    debugPrint("Erreur lors du pré-chargement des lignes: $e");
  }

  // Petit délai de sécurité
  await Future.delayed(const Duration(milliseconds: 500));

  // Toutes les données sont prêtes, lancer l'application...
  runApp(const SiraApp());
  
  // ... et retirer l'écran natif de chargement !
  FlutterNativeSplash.remove();
}

class SiraApp extends StatelessWidget {
  const SiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoovFaso',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}
