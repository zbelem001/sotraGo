import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'home_screen.dart';
import 'lines_screen.dart';
import 'events_screen.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';


class MainScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialMapLine;

  const MainScreen({super.key, this.initialIndex = 0, this.initialMapLine});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoading = true;
  late int _currentIndex;
  late List<Widget> _pages;
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const HomeScreen(),
      MapScreen(key: _mapKey, initialLineNumber: widget.initialMapLine),
      const LinesScreen(),
      const EventsScreen(),
    ];
    _initApp();
  }

  Future<void> _initApp() async {
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

    // Sécurité visuelle ou pour laisser les données s'installer
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    // Si on veut aller sur la map (1) ou les lignes (2) et que le mode éclaireur est désactivé
    if ((index == 1 || index == 2) && !LocationService().isScoutModeEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez activer le Mode Éclaireur sur l'accueil pour accéder à la carte et aux lignes.",
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (index == 1 && _currentIndex != 1) {
      _mapKey.currentState?.resetToAllLines();
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF008542), // Vert MoovFaso
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus,
                  size: 80,
                  color: Color(0xFF008542),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "MoovFaso",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Veuillez patienter...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        if (_currentIndex == 1) {
          final mapState = _mapKey.currentState;
          if (mapState != null && mapState.hasSubState) {
            mapState.handleBack();
            return; // Arrêt ici pour ne pas changer d'onglet
          }
        }

        // Si on n'est pas sur la carte, on y retourne (avec état par défaut)
        _onTabTapped(0);
      },
      child: Scaffold(
        extendBody: true, // Pour l'effet futuriste (la barre peut flotter)
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Carte',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_bus_outlined),
                activeIcon: Icon(Icons.directions_bus),
                label: 'Lignes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.campaign_outlined),
                activeIcon: Icon(Icons.campaign),
                label: 'Bons plans',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
