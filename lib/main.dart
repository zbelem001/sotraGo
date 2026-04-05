import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'services/socket_service.dart';
import 'services/location_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService().initSocket(); 
  await LocationService().init();
  runApp(const SiraApp());
}

class SiraApp extends StatelessWidget {
  const SiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sira - SOTRACO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // S'adapte au mode de l'appareil
      home: const MainScreen(),
    );
  }
}
